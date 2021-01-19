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
"""ADB protocol implementation.

Implements the ADB protocol as seen in android's adb/adbd binaries, but only the
host side.
"""

import struct
import time

from . import usb_exceptions


# Maximum amount of data in an ADB packet.
MAX_ADB_DATA = 4096
# ADB protocol version.
VERSION = 0x01000000

# AUTH constants for arg0.
AUTH_TOKEN = 1
AUTH_SIGNATURE = 2
AUTH_RSAPUBLICKEY = 3


class InvalidCommandError(Exception):
  """Got an invalid command over USB."""

  def __init__(self, message, response_header, response_data):
    if response_header == 'FAIL':
      message = 'Command failed, device said so. (%s)' % message
    super(InvalidCommandError, self).__init__(
        message, response_header, response_data)


class InvalidResponseError(Exception):
  """Got an invalid response to our command."""


class InvalidChecksumError(Exception):
  """Checksum of data didn't match expected checksum."""


class InterleavedDataError(Exception):
  """We only support command sent serially."""


def MakeWireIDs(ids):
  id_to_wire = {
      cmd_id: sum(ord(c) << (i * 8) for i, c in enumerate(cmd_id))
      for cmd_id in ids
  }
  wire_to_id = {wire: cmd_id for cmd_id, wire in id_to_wire.items()}
  return id_to_wire, wire_to_id


class AuthSigner(object):
  """Signer for use with authenticated ADB, introduced in 4.4.x/KitKat."""

  def Sign(self, data):
    """Signs given data using a private key."""
    raise NotImplementedError()

  def GetPublicKey(self):
    """Returns the public key in PEM format without headers or newlines."""
    raise NotImplementedError()


class _AdbConnection(object):
  """ADB Connection."""

  def __init__(self, usb, local_id, remote_id, timeout_ms):
    self.usb = usb
    self.local_id = local_id
    self.remote_id = remote_id
    self.timeout_ms = timeout_ms

  def _Send(self, command, arg0, arg1, data=''):
    message = AdbMessage(command, arg0, arg1, data)
    message.Send(self.usb, self.timeout_ms)

  def Write(self, data):
    """Write a packet and expect an Ack."""
    self._Send('WRTE', arg0=self.local_id, arg1=self.remote_id, data=data)
    # Expect an ack in response.
    cmd, okay_data = self.ReadUntil('OKAY')
    if cmd != 'OKAY':
      if cmd == 'FAIL':
        raise usb_exceptions.AdbCommandFailureException(
            'Command failed.', okay_data)
      raise InvalidCommandError(
          'Expected an OKAY in response to a WRITE, got %s (%s)',
          cmd, okay_data)
    return len(data)

  def Okay(self):
    self._Send('OKAY', arg0=self.local_id, arg1=self.remote_id)

  def ReadUntil(self, *expected_cmds):
    """Read a packet, Ack any write packets."""
    cmd, remote_id, local_id, data = AdbMessage.Read(
        self.usb, expected_cmds, self.timeout_ms)
    if local_id != 0 and self.local_id != local_id:
      raise InterleavedDataError("We don't support multiple streams...")
    if remote_id != 0 and self.remote_id != remote_id:
      raise InvalidResponseError(
          'Incorrect remote id, expected %s got %s' % (
              self.remote_id, remote_id))
    # Ack write packets.
    if cmd == 'WRTE':
      self.Okay()
    return cmd, data

  def ReadUntilClose(self):
    """Yield packets until a Close packet is received."""
    while True:
      cmd, data = self.ReadUntil('CLSE', 'WRTE')
      if cmd == 'CLSE':
        self._Send('CLSE', arg0=self.local_id, arg1=self.remote_id)
        break
      if cmd != 'WRTE':
        if cmd == 'FAIL':
          raise usb_exceptions.AdbCommandFailureException(
              'Command failed.', data)
        raise InvalidCommandError('Expected a WRITE or a CLOSE, got %s (%s)',
                                  cmd, data)
      yield data

  def Close(self):
    self._Send('CLSE', arg0=self.local_id, arg1=self.remote_id)
    cmd, data = self.ReadUntil('CLSE')
    if cmd != 'CLSE':
      if cmd == 'FAIL':
        raise usb_exceptions.AdbCommandFailureException('Command failed.', data)
      raise InvalidCommandError('Expected a CLSE response, got %s (%s)',
                                cmd, data)


class AdbMessage(object):
  """ADB Protocol and message class.

  Protocol Notes

  local_id/remote_id:
    Turns out the documentation is host/device ambidextrous, so local_id is the
    id for 'the sender' and remote_id is for 'the recipient'. So since we're
    only on the host, we'll re-document with host_id and device_id:

    OPEN(host_id, 0, 'shell:XXX')
    READY/OKAY(device_id, host_id, '')
    WRITE(0, host_id, 'data')
    CLOSE(device_id, host_id, '')
  """

  ids = ['SYNC', 'CNXN', 'AUTH', 'OPEN', 'OKAY', 'CLSE', 'WRTE']
  commands, constants = MakeWireIDs(ids)
  # An ADB message is 6 words in little-endian.
  format = '<6I'

  connections = 0

  def __init__(self, command=None, arg0=None, arg1=None, data=''):
    self.command = self.commands[command]
    self.magic = self.command ^ 0xFFFFFFFF
    self.arg0 = arg0
    self.arg1 = arg1
    self.data = data

  @property
  def checksum(self):
    return self.CalculateChecksum(self.data)

  @staticmethod
  def CalculateChecksum(data):
    # The checksum is just a sum of all the bytes. I swear.
    return sum(map(ord, data)) & 0xFFFFFFFF

  def Pack(self):
    """Returns this message in an over-the-wire format."""
    return struct.pack(self.format, self.command, self.arg0, self.arg1,
                       len(self.data), self.checksum, self.magic)

  @classmethod
  def Unpack(cls, message):
    try:
      cmd, arg0, arg1, data_length, data_checksum, unused_magic = struct.unpack(
          cls.format, message)
    except struct.error as e:
      raise ValueError('Unable to unpack ADB command.', cls.format, message, e)
    return cmd, arg0, arg1, data_length, data_checksum

  def Send(self, usb, timeout_ms=None):
    """Send this message over USB."""
    usb.BulkWrite(self.Pack(), timeout_ms)
    usb.BulkWrite(self.data, timeout_ms)

  @classmethod
  def Read(cls, usb, expected_cmds, timeout_ms=None, total_timeout_ms=None):
    """Receive a response from the device."""
    total_timeout_ms = usb.Timeout(total_timeout_ms)
    start = time.time()
    while True:
      msg = usb.BulkRead(24, timeout_ms)
      cmd, arg0, arg1, data_length, data_checksum = cls.Unpack(msg)
      command = cls.constants.get(cmd)
      if not command:
        raise InvalidCommandError(
            'Unknown command: %x' % cmd, cmd, (arg0, arg1))
      if command in expected_cmds:
        break

      if time.time() - start > total_timeout_ms:
        raise InvalidCommandError(
            'Never got one of the expected responses (%s)' % expected_cmds,
            cmd, (timeout_ms, total_timeout_ms))

    if data_length > 0:
      data = ''
      while data_length > 0:
          temp = usb.BulkRead(data_length, timeout_ms)
          data += temp
          data_length -= len(temp)
      actual_checksum = cls.CalculateChecksum(data)
      if actual_checksum != data_checksum:
        raise InvalidChecksumError(
            'Received checksum %s != %s', (actual_checksum, data_checksum))
    else:
      data = ''
    return command, arg0, arg1, data

  @classmethod
  def Connect(cls, usb, banner='notadb', rsa_keys=None, auth_timeout_ms=100):
    """Establish a new connection to the device.

    Args:
      usb: A USBHandle with BulkRead and BulkWrite methods.
      banner: A string to send as a host identifier.
      rsa_keys: List of AuthSigner subclass instances to be used for
          authentication. The device can either accept one of these via the Sign
          method, or we will send the result of GetPublicKey from the first one
          if the device doesn't accept any of them.
      auth_timeout_ms: Timeout to wait for when sending a new public key. This
          is only relevant when we send a new public key. The device shows a
          dialog and this timeout is how long to wait for that dialog. If used
          in automation, this should be low to catch such a case as a failure
          quickly; while in interactive settings it should be high to allow
          users to accept the dialog. We default to automation here, so it's low
          by default.

    Returns:
      The device's reported banner. Always starts with the state (device,
          recovery, or sideload), sometimes includes information after a : with
          various product information.

    Raises:
      usb_exceptions.DeviceAuthError: When the device expects authentication,
          but we weren't given any valid keys.
      InvalidResponseError: When the device does authentication in an
          unexpected way.
    """
    msg = cls(
        command='CNXN', arg0=VERSION, arg1=MAX_ADB_DATA,
        data='host::%s\0' % banner)
    msg.Send(usb)
    cmd, arg0, arg1, banner = cls.Read(usb, ['CNXN', 'AUTH'])
    if cmd == 'AUTH':
      if not rsa_keys:
        raise usb_exceptions.DeviceAuthError(
            'Device authentication required, no keys available.')
      # Loop through our keys, signing the last 'banner' or token.
      for rsa_key in rsa_keys:
        if arg0 != AUTH_TOKEN:
          raise InvalidResponseError(
              'Unknown AUTH response: %s %s %s' % (arg0, arg1, banner))

        signed_token = rsa_key.Sign(banner)
        msg = cls(
            command='AUTH', arg0=AUTH_SIGNATURE, arg1=0, data=signed_token)
        msg.Send(usb)
        cmd, arg0, unused_arg1, banner = cls.Read(usb, ['CNXN', 'AUTH'])
        if cmd == 'CNXN':
          return banner
      # None of the keys worked, so send a public key.
      msg = cls(
          command='AUTH', arg0=AUTH_RSAPUBLICKEY, arg1=0,
          data=rsa_keys[0].GetPublicKey() + '\0')
      msg.Send(usb)
      try:
        cmd, arg0, unused_arg1, banner = cls.Read(
            usb, ['CNXN'], timeout_ms=auth_timeout_ms)
      except usb_exceptions.BulkReadFailedError as e:
        if e.usb_error.value == -7:  # Timeout.
          raise usb_exceptions.DeviceAuthError(
              'Accept auth key on device, then retry.')
        raise
      # This didn't time-out, so we got a CNXN response.
      return banner
    return banner

  @classmethod
  def Open(cls, usb, destination, timeout_ms=None):
    """Opens a new connection to the device via an OPEN message.

    Not the same as the posix 'open' or any other google3 Open methods.

    Args:
      usb: USB device handle with BulkRead and BulkWrite methods.
      destination: The service:command string.
      timeout_ms: Timeout in milliseconds for USB packets.

    Raises:
      InvalidResponseError: Wrong local_id sent to us.
      InvalidCommandError: Didn't get a ready response.

    Returns:
      The local connection id.
    """
    local_id = 1
    msg = cls(
        command='OPEN', arg0=local_id, arg1=0,
        data=destination + '\0')
    msg.Send(usb, timeout_ms)
    cmd, remote_id, their_local_id, _ = cls.Read(usb, ['CLSE', 'OKAY'],
                                                 timeout_ms=timeout_ms)
    if local_id != their_local_id:
      raise InvalidResponseError(
          'Expected the local_id to be %s, got %s' % (local_id, their_local_id))
    if cmd == 'CLSE':
      # Device doesn't support this service.
      return None
    if cmd != 'OKAY':
      raise InvalidCommandError('Expected a ready response, got %s' % cmd,
                                cmd, (remote_id, their_local_id))
    return _AdbConnection(usb, local_id, remote_id, timeout_ms)

  @classmethod
  def Command(cls, usb, service, command='', timeout_ms=None):
    """One complete set of USB packets for a single command.

    Sends service:command in a new connection, reading the data for the
    response. All the data is held in memory, large responses will be slow and
    can fill up memory.

    Args:
      usb: USB device handle with BulkRead and BulkWrite methods.
      service: The service on the device to talk to.
      command: The command to send to the service.
      timeout_ms: Timeout for USB packets, in milliseconds.

    Raises:
      InterleavedDataError: Multiple streams running over usb.
      InvalidCommandError: Got an unexpected response command.

    Returns:
      The response from the service.
    """
    return ''.join(cls.StreamingCommand(usb, service, command, timeout_ms))

  @classmethod
  def StreamingCommand(cls, usb, service, command='', timeout_ms=None):
    """One complete set of USB packets for a single command.

    Sends service:command in a new connection, reading the data for the
    response. All the data is held in memory, large responses will be slow and
    can fill up memory.

    Args:
      usb: USB device handle with BulkRead and BulkWrite methods.
      service: The service on the device to talk to.
      command: The command to send to the service.
      timeout_ms: Timeout for USB packets, in milliseconds.

    Raises:
      InterleavedDataError: Multiple streams running over usb.
      InvalidCommandError: Got an unexpected response command.

    Yields:
      The responses from the service.
    """
    connection = cls.Open(usb, destination='%s:%s' % (service, command),
                          timeout_ms=timeout_ms)
    for data in connection.ReadUntilClose():
      yield data
