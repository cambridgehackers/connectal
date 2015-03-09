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
connectal = ctypes.CDLL('./connectal.so')

def call_say(a):
    connectal.EchoRequest_say(ctypes.c_void_p(treq), a)
    sem_heard2.acquire()

def call_say2(a, b):
    connectal.EchoRequest_say2(ctypes.c_void_p(treq), a, b)

def heard(v):
    print 'heard called!!!', v
    call_say2(v, 2*v);

def heard2(a, b):
    print 'heard2 called!!!', a, b
    sem_heard2.release()

def callback(a):
    dict = json.loads(a.strip())
    #print 'callback called!!!', a, dict
    if dict['name'] == 'heard':
        heard(dict['v'])
    elif dict['name'] == 'heard2':
        heard2(dict['a'], dict['b'])

def worker():
    while not stopPolling:
        connectal.portalCheckIndication(ctypes.c_void_p(tind))

stopPolling = False
connectal.set_callback(ctypes.py_object(callback))
sem_heard2 = threading.Semaphore(0)
tr = connectal.trequest
tr.restype = ctypes.c_void_p
ti = connectal.tindication
ti.restype = ctypes.c_void_p
treq = tr()
tind = ti()
print 'JJ', '%x' % treq, '%x' % tind
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
