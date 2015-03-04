#!/usr/bin/env python

# Copyright (c) 2013 Quanta Research Cambridge, Inc.

# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import sys
import socket
import struct
import time
import ctypes
import json
import math

class BaseClass(object):
    def __init__(self, classtype):
        self._type = classtype

class socket_client:
    def __init__(self, devaddr, devport):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((devaddr, devport))
        self.llen = ctypes.sizeof(ctypes.c_int);
    def recv(self):
        bytes_recd = 0
        while bytes_recd < self.llen:
            chunk = self.s.recv(self.llen)
            bytes_recd = len(chunk)
        liw = struct.unpack("hh", chunk)[0]
        blen = (liw-1)*self.llen
        bytes_recd = 0
        buffer = []
        while bytes_recd < blen:
            chunk = self.s.recv(blen)
            bytes_recd += len(chunk) 
            buffer.append(chunk)
        rv = buffer[0]
        for b in buffer[1:]:
            rv = rv + b
        return rv
    def send(self, d):
        data = json.dumps(d, separators=(',',':'), sort_keys=True)
        liw = math.ceil(len(data)/4.0)
        padding = ''.join([' ' for i in range(len(data), int(liw*4))])
        self.s.send(struct.pack("@i", (1+liw))+data+padding)
    def shutdown(self):
        self.s.shutdown(socket.SHUT_RDWR)
        self.s.close()


if __name__ == "__main__":
    ind_addr = "127.0.0.1"
    ind_port = 5000
    
    req_addr = "127.0.0.1"
    req_port = 5001
    
    ind_s = socket_client(ind_addr, ind_port)
    req_s = socket_client(req_addr, req_port)
    
    req_s.send({'name':'say','x':1})
    print ind_s.recv()
    req_s.send({'name':'say','x':1})
    print ind_s.recv()
    req_s.send({'name':'say2','x':2,'y':1})
    print ind_s.recv()
    req_s.send({'name':'setLeds','x':0})
    time.sleep(1)
    req_s.shutdown()
    ind_s.shutdown()
