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
"""A libusb1-based ADB reimplementation.

ADB was giving us trouble with its client/server architecture, which is great
for users and developers, but not so great for reliable scripting. This will
allow us to more easily catch errors as Python exceptions instead of checking
random exit codes, and all the other great benefits from not going through
subprocess and a network socket.

All timeouts are in milliseconds.
"""

try:
  import cStringIO
except ImportError:
  import io as cStringIO  # Python 3 compatibility
import os
import socket

from . import adb_protocol
from . import common
from . import filesync_protocol

try:
    basestring
except NameError:
    basestring = str  # Python 3 compatibility

try:
    import libusb1
    # From adb.h
    CLASS = 0xFF
    SUBCLASS = 0x42
    PROTOCOL = 0x01
    # pylint: disable=invalid-name
    DeviceIsAvailable = common.InterfaceMatcher(CLASS, SUBCLASS, PROTOCOL)
except:
    # no libusb1 support
    pass

try:
    from M2Crypto import RSA

    class M2CryptoSigner(adb_protocol.AuthSigner):
      """AuthSigner using M2Crypto."""

      def __init__(self, rsa_key_path):
        with open(rsa_key_path + '.pub') as rsa_pub_file:
          self.public_key = rsa_pub_file.read()

        self.rsa_key = RSA.load_key(rsa_key_path)

      def Sign(self, data):
        return self.rsa_key.sign(data, 'sha1')

      def GetPublicKey(self):
        return self.public_key
except:
  #print 'Install M2Crypto in order to use adb debug'
  pass

class AdbCommands(object):
  """Exposes adb-like methods for use.

  Some methods are more-pythonic and/or have more options.
  """
  protocol_handler = adb_protocol.AdbMessage
  filesync_handler = filesync_protocol.FilesyncProtocol

  @classmethod
  def ConnectDevice(
      cls, port_path=None, serial=None, default_timeout_ms=None, **kwargs):
    """Convenience function to get an adb device from usb path or serial.
    
    Args:
      port_path: The filename of usb port to use.
      serial: The serial number of the device to use.
      default_timeout_ms: The default timeout in milliseconds to use.

    If serial specifies a TCP address:port, then a TCP connection is
    used instead of a USB connection.
    """
    if serial and ':' in serial:
        handle = common.TcpHandle(serial)
    else:
        handle = common.UsbHandle.FindAndOpen(
            DeviceIsAvailable, port_path=port_path, serial=serial,
            timeout_ms=default_timeout_ms)
    return cls.Connect(handle, **kwargs)

  def __init__(self, handle, device_state):
    self._handle = handle
    self._device_state = device_state

  @property
  def usb_handle(self):
    return self._handle

  def Close(self):
    self._handle.Close()

  @classmethod
  def Connect(cls, usb, banner=None, **kwargs):
    """Connect to the device.

    Args:
      usb: UsbHandle or TcpHandle instance to use.
      banner: See protocol_handler.Connect.
      **kwargs: See protocol_handler.Connect for kwargs. Includes rsa_keys,
          and auth_timeout_ms.
    Returns:
      An instance of this class if the device connected successfully.
    """
    if not banner:
      banner = socket.gethostname()
    device_state = cls.protocol_handler.Connect(usb, banner=banner, **kwargs)
    # Remove banner and colons after device state (state::banner)
    device_state = device_state.split(':')[0]
    return cls(usb, device_state)

  @classmethod
  def Devices(cls):
    """Get a generator of UsbHandle for devices available."""
    return common.UsbHandle.FindDevices(DeviceIsAvailable)

  def GetState(self):
    return self._device_state

  def Install(self, apk_path, destination_dir=None, timeout_ms=None):
    """Install apk to device.

    Doesn't support verifier file, instead allows destination directory to be
    overridden.

    Arguments:
      apk_path: Local path to apk to install.
      destination_dir: Optional destination directory. Use /system/app/ for
        persistent applications.
      timeout_ms: Expected timeout for pushing and installing.

    Returns:
      The pm install output.
    """
    if not destination_dir:
      destination_dir = '/data/local/tmp/'
    basename = os.path.basename(apk_path)
    destination_path = destination_dir + basename
    self.Push(apk_path, destination_path, timeout_ms=timeout_ms)
    return self.Shell('pm install -r "%s"' % destination_path,
                      timeout_ms=timeout_ms)

  def Push(self, source_file, device_filename, mtime='0', timeout_ms=None):
    """Push source_file to file on device.

    Arguments:
      source_file: Either a filename or file-like object to push to the device.
      device_filename: The filename on the device to write to.
      mtime: Optional, modification time to set on the file.
      timeout_ms: Expected timeout for any part of the push.
    """
    connection = self.protocol_handler.Open(
        self._handle, destination='sync:',
        timeout_ms=timeout_ms)
    if isinstance(source_file, basestring):
      source_file = open(source_file)
    self.filesync_handler.Push(connection, source_file, device_filename,
                               mtime=int(mtime))
    connection.Close()

  def Pull(self, device_filename, dest_file=None, timeout_ms=None):
    """Pull file from device.

    Arguments:
      device_filename: The filename on the device to pull.
      dest_file: If set, a filename or writable file-like object.
      timeout_ms: Expected timeout for any part of the pull.

    Returns:
      The file data if dest_file is not set.
    """
    if isinstance(dest_file, basestring):
      dest_file = open(dest_file, 'w')
    elif not dest_file:
      dest_file = cStringIO.StringIO()
    connection = self.protocol_handler.Open(
        self._handle, destination='sync:',
        timeout_ms=timeout_ms)
    self.filesync_handler.Pull(connection, device_filename, dest_file)
    connection.Close()
    try:
      # An empty call to cStringIO.StringIO returns an instance of
      # cStringIO.OutputType on Python 2.
      StringIOType = cStringIO.OutputType
    except AttributeError:
      # On Python 3, this object just an instance of StringIO.
      StringIOType = cStringIO.StringIO
    if isinstance(dest_file, StringIOType):
      return dest_file.getvalue()

  def Stat(self, device_filename):
    """Get a file's stat() information."""
    connection = self.protocol_handler.Open(self._handle, destination='sync:')
    mode, size, mtime = self.filesync_handler.Stat(
        connection, device_filename)
    connection.Close()
    return mode, size, mtime

  def List(self, device_path):
    """Return a directory listing of the given path."""
    connection = self.protocol_handler.Open(self._handle, destination='sync:')
    listing = self.filesync_handler.List(connection, device_path)
    connection.Close()
    return listing

  def Reboot(self, destination=''):
    """Reboot device, specify 'bootloader' for fastboot."""
    self.protocol_handler.Open(self._handle, 'reboot:%s' % destination)

  def RebootBootloader(self):
    """Reboot device into fastboot."""
    self.Reboot('bootloader')

  def Remount(self):
    """Remount / as read-write."""
    return self.protocol_handler.Command(self._handle, service='remount')

  def Root(self):
    """Restart adbd as root on device."""
    return self.protocol_handler.Command(self._handle, service='root')

  def Shell(self, command, timeout_ms=None):
    """Run command on the device, returning the output."""
    return self.protocol_handler.Command(
        self._handle, service='shell', command=command,
        timeout_ms=timeout_ms)

  def StreamingShell(self, command, timeout_ms=None):
    """Run command on the device, returning the output.

    Args:
      command: the command to run on the target.
      timeout_ms: Maximum time to allow the command to run.

    Yields:
      The responses from the shell command.
    """
    return self.protocol_handler.StreamingCommand(
        self._handle, service='shell', command=command,
        timeout_ms=timeout_ms)

  def Logcat(self, options, timeout_ms=None):
    """Run 'shell logcat' and stream the output to stdout."""
    return self.protocol_handler.StreamingCommand(
        self._handle, service='shell', command='logcat %s' % options,
        timeout_ms=timeout_ms)
