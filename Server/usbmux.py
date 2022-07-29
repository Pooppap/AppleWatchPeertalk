# -*- coding: utf-8 -*-
#
#	usbmux.py - usbmux client library for Python
#
# Copyright (C) 2009	Hector Martin "marcan" <hector@marcansoft.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 or version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

import socket, struct, select, sys

try:
    import plistlib
    haveplist = True
except:
    haveplist = False

class MuxError(Exception):
    pass

class MuxVersionError(MuxError):
    pass

class SafeStreamSocket:
    def __init__(self, address, family):
        self.sock = socket.socket(family, socket.SOCK_STREAM)
        self.sock.connect(address)
  
    def send(self, msg):
        total_sent = 0
        while total_sent < len(msg):
            sent = self.sock.send(msg[total_sent:])
            if sent == 0:
                raise MuxError("socket connection broken")
            total_sent = total_sent + sent

    def recv(self, size):
        msg = ""
        while len(msg) < size:
            chunk = self.sock.recv(size-len(msg))
            if chunk == '':
                raise MuxError("socket connection broken")
            msg = msg + chunk.decode()

        return msg

class MuxDevice(object):
    def __init__(self, dev_id, usb_prod, serial, location):
        self.dev_id = dev_id
        self.usb_prod = usb_prod
        self.serial = serial
        self.location = location

    def __str__(self):
        return "<MuxDevice: ID %d ProdID 0x%04x Serial '%s' Location 0x%x>"%(self.dev_id, self.usb_prod, self.serial, self.location)

class BinaryProtocol(object):
    TYPE_RESULT = 1
    TYPE_CONNECT = 2
    TYPE_LISTEN = 3
    TYPE_DEVICE_ADD = 4
    TYPE_DEVICE_REMOVE = 5
    VERSION = 0
 
    def __init__(self, socket):
        self.socket = socket
        self.connected = False

    def _pack(self, req, payload):
        if req == self.TYPE_CONNECT:
            return struct.pack("IH", payload['DeviceID'], payload['PortNumber']) + "\x00\x00"
        elif req == self.TYPE_LISTEN:
            return ""
        else:
            raise ValueError("Invalid outgoing request type %d"%req)
    
    def _unpack(self, resp, payload):
        if resp == self.TYPE_RESULT:
            return {'Number':struct.unpack("I", payload)[0]}
        elif resp == self.TYPE_DEVICE_ADD:
            dev_id, usbpid, serial, pad, location = struct.unpack("IH256sHI", payload)
            serial = serial.split("\0")[0]
            return {'DeviceID': dev_id, 'Properties': {'LocationID': location, 'SerialNumber': serial, 'ProductID': usbpid}}
        elif resp == self.TYPE_DEVICE_REMOVE:
            dev_id = struct.unpack("I", payload)[0]
            return {'DeviceID': dev_id}
        else:
            raise MuxError("Invalid incoming request type %d"%resp)

    def send_packet(self, req, tag, payload={}):
        payload = self._pack(req, payload)
        if self.connected:
            raise MuxError("Mux is connected, cannot issue control packets")
        length = 16 + len(payload)
        # print(type(payload))
        data = struct.pack("IIII", length, self.VERSION, req, tag) + str.encode(payload)
        self.socket.send(data)

    def get_packet(self):
        if self.connected:
            raise MuxError("Mux is connected, cannot issue control packets")
        dlen = self.socket.recv(4)
        dlen = struct.unpack("I", str.encode(dlen))[0]
        body = self.socket.recv(dlen - 4)
        version, resp, tag = struct.unpack("III", str.encode(body[:0xc]))
        if version != self.VERSION:
            raise MuxVersionError("Version mismatch: expected %d, got %d"%(self.VERSION,version))

        payload = self._unpack(resp, body[0xc:])
        return (resp, tag, payload)

class PlistProtocol(BinaryProtocol):
    TYPE_RESULT = "Result"
    TYPE_CONNECT = "Connect"
    TYPE_LISTEN = "Listen"
    TYPE_DEVICE_ADD = "Attached"
    TYPE_DEVICE_REMOVE = "Detached" #???
    TYPE_PLIST = 8
    VERSION = 1
    def __init__(self, socket):
        if not haveplist:
            raise Exception("You need the plistlib module")
        BinaryProtocol.__init__(self, socket)
    
    def _pack(self, req, payload):
        return payload
    
    def _unpack(self, resp, payload):
        return payload
    
    def send_packet(self, req, tag, payload={}):
        payload['ClientVersionString'] = 'usbmux.py by marcan'
        if isinstance(req, int):
            req = [self.TYPE_CONNECT, self.TYPE_LISTEN][req-2]

        payload['MessageType'] = req
        payload['ProgName'] = 'tcprelay'
        BinaryProtocol.send_packet(self, self.TYPE_PLIST, tag, plistlib.dumps(payload).decode())

    def get_packet(self):
        resp, tag, payload = BinaryProtocol.get_packet(self)
        if resp != self.TYPE_PLIST:
            raise MuxError("Received non-plist type %d"%resp)

        payload = plistlib.loads(str.encode(payload))
        return payload['MessageType'], tag, payload

class MuxConnection(object):
    def __init__(self, socket_path, proto_class):
        self.socket_path = socket_path
        if sys.platform in ['win32', 'cygwin']:
            family = socket.AF_INET
            address = ('127.0.0.1', 27015)
        else:
            family = socket.AF_UNIX
            address = self.socket_path
        self.socket = SafeStreamSocket(address, family)
        self.proto = proto_class(self.socket)
        self.pkttag = 1
        self.devices = []

    def _getreply(self):
        while True:
            resp, tag, data = self.proto.get_packet()
            if resp == self.proto.TYPE_RESULT:
                return tag, data
            else:
                raise MuxError("Invalid packet type received: %d"%resp)

    def _processpacket(self):
        resp, tag, data = self.proto.get_packet()
        if resp == self.proto.TYPE_DEVICE_ADD:
            self.devices.append(MuxDevice(data['DeviceID'], data['Properties']['ProductID'], data['Properties']['SerialNumber'], data['Properties']['LocationID']))
        elif resp == self.proto.TYPE_DEVICE_REMOVE:
            for dev in self.devices:
                if dev.dev_id == data['DeviceID']:
                    self.devices.remove(dev)
        elif resp == self.proto.TYPE_RESULT:
            raise MuxError("Unexpected result: %d"%resp)
        else:
            raise MuxError("Invalid packet type received: %d"%resp)

    def _exchange(self, req, payload={}):
        mytag = self.pkttag
        self.pkttag += 1
        self.proto.send_packet(req, mytag, payload)
        recvtag, data = self._getreply()
        if recvtag != mytag:
            raise MuxError("Reply tag mismatch: expected %d, got %d"%(mytag, recvtag))
        return data['Number']

    def listen(self):
        ret = self._exchange(self.proto.TYPE_LISTEN)
        if ret != 0:
            raise MuxError("Listen failed: error %d"%ret)

    def process(self, timeout=None):
        if self.proto.connected:
            raise MuxError("Socket is connected, cannot process listener events")
        rlo, wlo, xlo = select.select([self.socket.sock], [], [self.socket.sock], timeout)
        if xlo:
            self.socket.sock.close()
            raise MuxError("Exception in listener socket")
        if rlo:
            self._processpacket()

    def connect(self, device, port):
        ret = self._exchange(self.proto.TYPE_CONNECT, {'DeviceID':device.dev_id, 'PortNumber':((port<<8) & 0xFF00) | (port>>8)})
        if ret != 0:
            raise MuxError("Connect failed: error %d"%ret)
        
        self.proto.connected = True
        return self.socket.sock

    def close(self):
        self.socket.sock.close()

class USBMux(object):
    def __init__(self, socket_path=None):
        if socket_path is None:
            if sys.platform == 'darwin':
                socket_path = "/var/run/usbmuxd"
            else:
                socket_path = "/var/run/usbmuxd"

        self.socket_path = socket_path
        self.listener = MuxConnection(socket_path, BinaryProtocol)
        try:
            self.listener.listen()
            self.version = 0
            self.proto_class = BinaryProtocol
        except MuxVersionError:
            self.listener = MuxConnection(socket_path, PlistProtocol)
            self.listener.listen()
            self.proto_class = PlistProtocol
            self.version = 1

        self.devices = self.listener.devices
  
    def process(self, timeout=None):
        self.listener.process(timeout)

    def connect(self, device, port):
        connector = MuxConnection(self.socket_path, self.proto_class)
        return connector.connect(device, port)

if __name__ == "__main__":
    mux = USBMux()
    print("Waiting for devices...")
    if not mux.devices:
        mux.process(0.1)
    while True:
        print("Devices:")
        for dev in mux.devices:
            print(dev)
        mux.process()
