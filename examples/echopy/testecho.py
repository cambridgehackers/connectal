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

import ctypes, os, sys, threading, time
connectal = ctypes.CDLL('./connectal.so')
stopPolling = False

def call_say(a):
    connectal.call_say(a)
    sem_heard2.acquire()

def call_say2(a, b):
    connectal.call_say2(a, b)

def heard(a):
    print 'heard called!!!', a
    connectal.call_say2(a, 2*a);

def heard2(a, b):
    print 'heard2 called!!!', a, b
    sem_heard2.release()

def worker():
    print 'Starting worker'
    while not stopPolling:
        #print 'check'
        connectal.checkInd()
        #time.sleep(1)

connectal.jcabozo(ctypes.py_object(heard), 0)
connectal.jcabozo(ctypes.py_object(heard2), 1)
sem_heard2 = threading.Semaphore(0)
connectal.tmain()
t1 = threading.Thread(target=worker)
t1.start()
v = 42
print "Saying %d" % v
call_say(v);
call_say(v*5);
call_say(v*17);
call_say(v*93);
call_say2(v, v*3);
stopPolling = True
