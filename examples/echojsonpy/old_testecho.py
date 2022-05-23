#!/usr/bin/env python3

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

from __future__ import print_function

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
    def recv_frame(self):
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
    def send_frame(self, data):
        liw = math.ceil(len(data)/4.0)
        padding = ''.join([' ' for i in range(len(data), int(liw*4))])
        print("send_frame (%d) %d %s" % (len(data),liw, data))
        self.s.send(struct.pack("@i", (1+liw))+data+padding)
    def shutdown(self):
        self.s.shutdown(socket.SHUT_RDWR)
        self.s.close()

def toascii(u):
    return u.encode('ascii', 'replace')

def createSendMethod(methname):
    def method(self, d):
        d['name'] = methname
        js = json.dumps(d, separators=(',',':'), sort_keys=True)
        self.s.send_frame(js)
    return (methname,method)

def createDefaultCallbackMethod(methname):
    def method(self, d):
        print("default %s(%s)" %(methname, str(d)))
    return (methname,method)

def createWrapperEvent(meths):
    def method(self):
        msg = self.s.recv_frame()
        d = json.loads(msg)
        n = d.pop('name')
        getattr(self, n)(d)
    return method

def ProxyClassFactory(name, meths, BaseClass=BaseClass):
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)
        BaseClass.__init__(self, name[:-len("Class")])
    newclass = type(toascii(name), (BaseClass,),dict([("__init__",__init__)]+list(map(createSendMethod, meths))))
    return newclass

def WrapperClassFactory(name, meths, BaseClass=BaseClass):
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)
        BaseClass.__init__(self, name[:-len("Class")])
    newclass = type(toascii(name), (BaseClass,),dict([("__init__",__init__), ("event", createWrapperEvent(meths))]+list(map(createDefaultCallbackMethod, meths))))
    return newclass


if __name__ == "__main__":
    ind_addr = "127.0.0.1"
    ind_port = 5000
    
    req_addr = "127.0.0.1"
    req_port = 5001
    
    ind_s = socket_client(ind_addr, ind_port)
    req_s = socket_client(req_addr, req_port)
    
    json_data=open('./bluesim/generatedDesignInterfaceFile.json')
    data = json.load(json_data)
    json_data.close()
    
    proxy_classes = {}
    wrapper_classes = {}
    for ifc in data['interfaces']:
        methods = [decl['name'] for decl in ifc['decls']]
        proxy_classes[ifc['name']] = ProxyClassFactory(ifc['name'], methods)
        wrapper_classes[ifc['name']] = WrapperClassFactory(ifc['name'], methods)
        
    ei = wrapper_classes['EchoIndication'](s=ind_s)
    er = proxy_classes['EchoRequest'](s=req_s)
    
    def new_heard(d):
        print("new heard(%s)" %(str(d)))

    er.say({'x':1})
    ei.event()
    er.say({'x':1})
    setattr(ei,'heard', new_heard)
    ei.event()
    er.say2({'x':2,'y':1})
    ei.event()
    er.setLeds({'x':0})
    time.sleep(1)
    req_s.shutdown()
    ind_s.shutdown()
