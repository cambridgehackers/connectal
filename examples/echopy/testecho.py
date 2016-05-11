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

import ctypes, json, os, sys, threading, time, portal

class Echo:
    def __init__(self):
        #self.sem_heard2 = threading.Semaphore(0)
        self.proxy = portal.NativeProxy('EchoRequest', self, responseInterface='EchoIndication', rpc=True)

    def call_say(self, a):
        self.proxy.say(a)
        #self.sem_heard2.acquire()

    def call_say2(self, a, b):
        self.proxy.say2(a, b)
        #self.sem_heard2.acquire()

    def heard(self, v):
        print 'heard called!!!', v
        #self.sem_heard2.release()

    def heard2(self, a, b):
        print 'heard2 called!!!', a, b
        #self.sem_heard2.release()

echo = Echo()

v = 42
print "Saying %d" % v
echo.call_say(v);
echo.call_say2(v, v*3);
echo.call_say(v*5);
echo.call_say(v*17);
echo.call_say(v*93);
echo.proxy.stopPolling = True
