# Copyright 2014 Google Inc. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""Common code for ADB and Fastboot.

Common usb browsing, and usb communication.
"""
import logging
import socket
import threading
import weakref

try:
  basestring
except NameError:
  basestring = str  # Python 3 compatibility

try:
  import libusb1
  import usb1

  from . import usb_exceptions

  DEFAULT_TIMEOUT_MS = 1000

  _LOG = logging.getLogger('android_usb')


  def GetInterface(setting):
    """Get the class, subclass, and protocol for the given USB setting."""
    return (setting.getClass(), setting.getSubClass(), setting.getProtocol())


  def InterfaceMatcher(clazz, subclass, protocol):
    """Returns a matcher that returns the setting with the given interface."""
    interface = (clazz, subclass, protocol)
    def Matcher(device):
      for setting in device.iterSettings():
        if GetInterface(setting) == interface:
          return setting
    return Matcher


  class UsbHandle(object):
    """USB communication object. Not thread-safe.

    Handles reading and writing over USB with the proper endpoints, exceptions,
    and interface claiming.

    Important methods:
      FlushBuffers()
      BulkRead(int length)
      BulkWrite(bytes data)
    """

    _HANDLE_CACHE = weakref.WeakValueDictionary()
    _HANDLE_CACHE_LOCK = threading.Lock()

    def __init__(self, device, setting, usb_info=None, timeout_ms=None):
      """Initialize USB Handle.

      Arguments:
        device: libusb_device to connect to.
        setting: libusb setting with the correct endpoints to communicate with.
        usb_info: String describing the usb path/serial/device, for debugging.
        timeout_ms: Timeout in milliseconds for all I/O.
      """
      self._setting = setting
      self._device = device
      self._handle = None

      self._usb_info = usb_info or ''
      self._timeout_ms = timeout_ms or DEFAULT_TIMEOUT_MS

    @property
    def usb_info(self):
      try:
        sn = self.serial_number
      except libusb1.USBError:
        sn = ''
      if sn and sn != self._usb_info:
        return '%s %s' % (self._usb_info, sn)
      return self._usb_info

    def Open(self):
      """Opens the USB device for this setting, and claims the interface."""
      # Make sure we close any previous handle open to this usb device.
      port_path = tuple(self.port_path)
      with self._HANDLE_CACHE_LOCK:
        old_handle = self._HANDLE_CACHE.get(port_path)
        if old_handle is not None:
          old_handle.Close()

      self._read_endpoint = None
      self._write_endpoint = None

      for endpoint in self._setting.iterEndpoints():
        address = endpoint.getAddress()
        if address & libusb1.USB_ENDPOINT_DIR_MASK:
          self._read_endpoint = address
          self._max_read_packet_len = endpoint.getMaxPacketSize()
        else:
          self._write_endpoint = address

      assert self._read_endpoint is not None
      assert self._write_endpoint is not None

      handle = self._device.open()
      iface_number = self._setting.getNumber()
      try:
        if handle.kernelDriverActive(iface_number):
          handle.detachKernelDriver(iface_number)
      except libusb1.USBError as e:
        if e.value == libusb1.LIBUSB_ERROR_NOT_FOUND:
          _LOG.warning('Kernel driver not found for interface: %s.', iface_number)
        else:
          raise
      handle.claimInterface(iface_number)
      self._handle = handle
      self._interface_number = iface_number

      with self._HANDLE_CACHE_LOCK:
        self._HANDLE_CACHE[port_path] = self
      # When this object is deleted, make sure it's closed.
      weakref.ref(self, self.Close)

    @property
    def serial_number(self):
      return self._device.getSerialNumber()

    @property
    def port_path(self):
      return [self._device.getBusNumber()] + self._device.getPortNumberList()

    def Close(self):
      if self._handle is None:
        return
      try:
        self._handle.releaseInterface(self._interface_number)
        self._handle.close()
      except libusb1.USBError:
        _LOG.info('USBError while closing handle %s: ',
                  self.usb_info, exc_info=True)
      finally:
        self._handle = None

    def Timeout(self, timeout_ms):
      return timeout_ms if timeout_ms is not None else self._timeout_ms

    def FlushBuffers(self):
      while True:
        try:
          self.BulkRead(self._max_read_packet_len, timeout_ms=10)
        except usb_exceptions.ReadFailedError as e:
          if e.usb_error.value == libusb1.LIBUSB_ERROR_TIMEOUT:
            break
          raise

    def BulkWrite(self, data, timeout_ms=None):
      if self._handle is None:
        raise usb_exceptions.WriteFailedError(
            'This handle has been closed, probably due to another being opened.',
            None)
      try:
        return self._handle.bulkWrite(
            self._write_endpoint, data, timeout=self.Timeout(timeout_ms))
      except libusb1.USBError as e:
        raise usb_exceptions.WriteFailedError(
            'Could not send data to %s (timeout %sms)' % (
                self.usb_info, self.Timeout(timeout_ms)), e)

    def BulkRead(self, length, timeout_ms=None):
      if self._handle is None:
        raise usb_exceptions.ReadFailedError(
            'This handle has been closed, probably due to another being opened.',
            None)
      try:
        return self._handle.bulkRead(
            self._read_endpoint, length, timeout=self.Timeout(timeout_ms))
      except libusb1.USBError as e:
        raise usb_exceptions.ReadFailedError(
            'Could not receive data from %s (timeout %sms)' % (
                self.usb_info, self.Timeout(timeout_ms)), e)

    def PortPathMatcher(cls, port_path):
      """Returns a device matcher for the given port path."""
      if isinstance(port_path, basestring):
        # Convert from sysfs path to port_path.
        port_path = [int(part) for part in SYSFS_PORT_SPLIT_RE.split(port_path)]
      return lambda device: device.port_path == port_path

    @classmethod
    def SerialMatcher(cls, serial):
      """Returns a device matcher for the given serial."""
      return lambda device: device.serial_number == serial

    @classmethod
    def FindAndOpen(cls, setting_matcher,
                    port_path=None, serial=None, timeout_ms=None):
      dev = cls.Find(
          setting_matcher, port_path=port_path, serial=serial,
          timeout_ms=timeout_ms)
      dev.Open()
      dev.FlushBuffers()
      return dev

    @classmethod
    def Find(cls, setting_matcher, port_path=None, serial=None, timeout_ms=None):
      """Gets the first device that matches according to the keyword args."""
      if port_path:
        device_matcher = cls.PortPathMatcher(port_path)
        usb_info = port_path
      elif serial:
        device_matcher = cls.SerialMatcher(serial)
        usb_info = serial
      else:
        device_matcher = None
        usb_info = 'first'
      return cls.FindFirst(setting_matcher, device_matcher,
                           usb_info=usb_info, timeout_ms=timeout_ms)

    @classmethod
    def FindFirst(cls, setting_matcher, device_matcher=None, **kwargs):
      """Find and return the first matching device.

      Args:
        setting_matcher: See cls.FindDevices.
        device_matcher: See cls.FindDevices.
        **kwargs: See cls.FindDevices.

      Returns:
        An instance of UsbHandle.

      Raises:
        DeviceNotFoundError: Raised if the device is not available.
      """
      try:
        return next(cls.FindDevices(
            setting_matcher, device_matcher=device_matcher, **kwargs))
      except StopIteration:
        raise usb_exceptions.DeviceNotFoundError(
            'No device available, or it is in the wrong configuration.')

    @classmethod
    def FindDevices(cls, setting_matcher, device_matcher=None,
                    usb_info='', timeout_ms=None):
      """Find and yield the devices that match.

      Args:
        setting_matcher: Function that returns the setting to use given a
          usb1.USBDevice, or None if the device doesn't have a valid setting.
        device_matcher: Function that returns True if the given UsbHandle is
          valid. None to match any device.
        usb_info: Info string describing device(s).
        timeout_ms: Default timeout of commands in milliseconds.

      Yields:
        UsbHandle instances
      """
      ctx = usb1.USBContext()
      for device in ctx.getDeviceList(skip_on_error=True):
        setting = setting_matcher(device)
        if setting is None:
          continue

        handle = cls(device, setting, usb_info=usb_info, timeout_ms=timeout_ms)
        if device_matcher is None or device_matcher(handle):
          yield handle
except:
  pass

class TcpHandle(object):
  """TCP connection object.

     Provides same interface as UsbHandle but ignores timeout."""

  def __init__(self, serial):
    """Initialize the TCP Handle.
    Arguments:
      serial: Android device serial of the form host or host:port.

    Host may be an IP address or a host name.
    """
    if ':' in serial:
      (host, port) = serial.split(':')
    else:
      host = serial
      port = 5555

    self._connection = socket.create_connection((host, port))

  def BulkWrite(self, data, timeout=None):
      return self._connection.sendall(data)

  def BulkRead(self, numbytes, timeout=None):
      return self._connection.recv(numbytes)

  def Timeout(self, timeout_ms):
      return timeout_ms

  def Close(self):
      return self._connection.close()
