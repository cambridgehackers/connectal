#!/usr/bin/python
# Copyright (c) 2014 Quanta Research Cambridge, Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

import ctypes, json, os, sys, threading, time
if os.environ.has_key('LD_LIBRARY_PATH'):
    connectal = ctypes.CDLL('connectal.so')
else:
    connectal = ctypes.CDLL('./connectal.so')

class NativeProxy:
    def __init__(self, interfaceName, handler):
        self.interfaceName
        self.handler = handler
        self.stopPolling = False
        self.methods = {}
        connectal.set_callback(ctypes.py_object(self))
        tr = connectal.trequest
        tr.restype = ctypes.c_void_p
        ti = connectal.tindication
        ti.restype = ctypes.c_void_p
        self.treq = tr()
        self.tind = ti()
        print 'JJ', '%x' % self.treq, '%x' % self.tind
        self.t1 = threading.Thread(target=self.worker)
        self.t1.start()

    def callback(self, a):
        vec = json.loads(a.strip())
        print 'callback called!!!', a, vec
        if hasattr(self.handler, vec[0]):
            getattr(self.handler, vec[0])(*vec[1:])

    def worker(self):
        while not self.stopPolling:
            connectal.portal_event(ctypes.c_void_p(self.tind))

    def __hasattr__(self, name):
        print '__hasattr__', name
        return (name in methods) or hasattr(connectal, '%s_%s' % (self.interfaceName, name))
    def __getattr__(self, name, default=None):
        print '__getattr__', name, default
        if name in self.methods:
            return self.methods[name]
        m = getattr(connectal, '%s_%s' % ('EchoRequest', name), None)
        if m:
            print m
            def fcn (*args):
                treq = ctypes.c_void_p(self.treq)
                print m, args
                if len(args) == 1:
                    m(treq, args[0])
                elif len(args) == 2:
                    m(treq, args[0], args[1])
            #self.methods[name] = fcn
            return fcn
        else:
            return default

class Echo:
    def __init__(self):
        self.sem_heard2 = threading.Semaphore(0)
        self.proxy = NativeProxy('EchoRequest', self)

    def call_say(self, a):
        self.proxy.say(a)
        self.sem_heard2.acquire()

    def call_say2(self, a, b):
        self.proxy.say2(a, b)
        self.sem_heard2.acquire()

    def heard(self, v):
        print 'heard called!!!', v
        self.sem_heard2.release()

    def heard2(self, a, b):
        print 'heard2 called!!!', a, b
        self.sem_heard2.release()

echo = Echo()

v = 42
print "Saying %d" % v
echo.call_say(v);
echo.call_say2(v, v*3);
echo.call_say(v*5);
echo.call_say(v*17);
echo.call_say(v*93);
echo.proxy.stopPolling = True
