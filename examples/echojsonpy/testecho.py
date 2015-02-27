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
import pprint

# ind_addr = 127.0.0.1
# ind_port = 5000

# req_addr = 127.0.0.1
# req_port = 5001

# ind_s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# ind_s.connect((ind_addr, ind_port))

# req_s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
# req_s.connect((req_addr, req_port))

json_data=open('./bluesim/generatedDesignInterfaceFile.json')
data = json.load(json_data)
pprint.pprint(data['interfaces'])
json_data.close()

def createMethod((methname, param)):
    def method(self, *args):
        print ' '.join([(str(p)+':'+str(a)) for p,a, in zip(param,args)])
    return (methname,method)

class BaseClass(object):
    def __init__(self, classtype):
        self._type = classtype

def ClassFactory(name, argnames, BaseClass=BaseClass):
    def __init__(self, classtype):
        self._type = classtype

def ClassFactory(name, meths, BaseClass=BaseClass):
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)
        BaseClass.__init__(self, name[:-len("Class")])
    newclass = type(name, (BaseClass,),dict([("__init__",__init__)]+map(createMethod, meths)))
    return newclass

Foo = ClassFactory("Foo", [("m1",['a', 'b', 'c']),("m2", ['d','e','f'])])
s = Foo()
s.m1(1,2,3)
s.m2(4,5,6)



