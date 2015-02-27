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
import os
import argparse
import json
import math

class socket_client:
    def __init__(self, devaddr, devport):
        self.s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.s.connect((devaddr, devport))
        self.llen = ctypes.sizeof(ctypes.c_int);
    def recv_frame(self):
        bytes_recd = 0
        while bytes_recd < self.llen:
            chunk = self.s.recv(self.llen)
            bytes_recd = len(chunk)
        blen = struct.unpack("!i", chunk)[0]
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
    def send_frame(self, data):
        liw = math.ceil(len(data)/4.0)+1
        print "send_frame %d %s" % (liw, data)
        self.s.send(struct.pack("@i", liw)+data)
    def shutdown(self):
        self.s.shutdown(socket.SHUT_RDWR)
        self.s.close()

ind_addr = "127.0.0.1"
ind_port = 5000

req_addr = "127.0.0.1"
req_port = 5001

ind_s = socket_client(ind_addr, ind_port)
req_s = socket_client(req_addr, req_port)

json_data=open('./bluesim/generatedDesignInterfaceFile.json')
data = json.load(json_data)
json_data.close()

def toascii(u):
    return u.encode('ascii', 'replace')

def createSendMethod((methname, params)):
    def method(self, *args):
        d = zip(params,args)
        d.insert(0,('name',methname))
        js = json.dumps(dict(d), separators=(',',':'), sort_keys=True)
        self.s.send_frame(js)
    return (methname,method)

class BaseClass(object):
    def __init__(self, classtype):
        self._type = classtype

def ProxyClassFactoryy(name, meths, BaseClass=BaseClass):
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)
        BaseClass.__init__(self, name[:-len("Class")])
    newclass = type(toascii(name), (BaseClass,),dict([("__init__",__init__)]+map(createSendMethod, meths)))
    return newclass

def intersperse(e, l):
    return reduce(lambda x,y: x+y, zip(l, [e]*len(l)))[:-1]

classes = []
for ifc in data['interfaces']:
    print ifc['name']
    methods = []
    for decl in ifc['decls']:
        param_names = [param['name'] for param in decl['params']]
        sys.stdout.write(" "+decl['name']+'(')
        sys.stdout.write(''.join(intersperse(',', param_names)))
        sys.stdout.write(")\n")
        methods.append((decl['name'], param_names))
    classes.append(ProxyClassFactoryy(ifc['name'], methods))


EchoRequest = classes[0]
SwallowRequest = classes[1]
EchoIndication = classes[2]

er = EchoRequest(s = req_s)
er.say(1)
er.say2(2,1)
er.setLeds(0)
time.sleep(1)
req_s.shutdown()
