#!/usr/bin/env python3
# Copyright (c) 2016 Connectal Project
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

if 'LD_LIBRARY_PATH' in os.environ:
    connectal = ctypes.CDLL('connectal.so')
else:
    connectal = ctypes.CDLL('./connectal.so')

class JsonObject:
    def __init__(self, d=None, **kwargs):
        if d:
            for k in d:
                setattr(self, k, d[k])
        if kwargs:
            for k in kwargs:
                setattr(self, k, kwargs[k])

def json_object_hook(d, encoding=None):
    result = JsonObject(d)
    return result

class NativeProxy:
    def __init__(self, interfaceName, handler, responseInterface=None, rpc=False, multithreaded=False):
        self.interfaceName = interfaceName
        self.handler = handler
        self.rpc = rpc
        self.multithreaded = multithreaded
        if rpc:
            if multithreaded:
                self.sem_response = threading.Semaphore(0)
                self._response = False
        self.stopPolling = False
        self.methods = {}
        newRequestPortal = connectal.newRequestPortal
        newRequestPortal.restype = ctypes.c_void_p
        newIndicationPortal = connectal.newIndicationPortal
        newIndicationPortal.restype = ctypes.c_void_p
        reqifcname = ctypes.c_int.in_dll(connectal, 'ifcNames_%sS2H' % interfaceName)
        reqinfo = ctypes.c_int.in_dll(connectal, '%s_reqinfo' % interfaceName)
        #print('reqifcname=', reqifcname, ' reqinfo=', reqinfo)
        self.requestPortal = newRequestPortal(reqifcname, reqinfo)
        respifcname = ctypes.c_int.in_dll(connectal, 'ifcNames_%sH2S' % responseInterface)
        respinfo = ctypes.c_int.in_dll(connectal, '%s_reqinfo' % responseInterface)
        resphandlemessage = getattr(connectal, '%s_handleMessage' % responseInterface)
        respproxyreq = ctypes.c_long.in_dll(connectal, 'p%sJsonProxyReq' % responseInterface)
        #print('respproxyreq=', respproxyreq)
        self.responsePortal = newIndicationPortal(respifcname, respinfo, resphandlemessage, respproxyreq)
        connectal.set_callback(self.responsePortal, ctypes.py_object(self))
        #print('JJ', '%x' % self.requestPortal, '%x' % self.responsePortal)
        if multithreaded:
            self.t1 = threading.Thread(target=self.worker)
            self.t1.start()

    def callback(self, a):
        ## use json_object_hook to convert JSON dictionaries to python objects
        vec = json.loads(a.strip(), None, None, json_object_hook)
        #print('callback called!!!', a, vec)
        if hasattr(self.handler, vec[0]):
            getattr(self.handler, vec[0])(*vec[1:])
            if self.rpc:
                if self.multithreaded:
                    self.sem_response.release()
                else:
                    self._response = True

    def worker(self):
        while not self.stopPolling:
            connectal.portal_event(ctypes.c_void_p(self.responsePortal))

    def __getattr__(self, name, default=None):
        #print('__getattr__', name, default)
        if name in self.methods:
            return self.methods[name]
        m = getattr(connectal, '%s_%s' % (self.interfaceName, name), None)
        if m:
            def fcn (*args):
                requestPortal = ctypes.c_void_p(self.requestPortal)
                #print(m, args)
                if len(args) == 1:
                    m(requestPortal, args[0])
                elif len(args) == 2:
                    m(requestPortal, args[0], args[1])
                if self.rpc:
                    if self.multithreaded:
                        self.sem_response.acquire()
                    else:
                        self._response = False
                        while not self._response:
                            connectal.portal_event(ctypes.c_void_p(self.responsePortal))
            self.methods[name] = fcn
            return fcn
        else:
            return default
