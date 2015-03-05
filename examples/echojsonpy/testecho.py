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

import time
import sys
import os

sys.path.append(os.path.abspath('../../scripts'))
import portalJson


if __name__ == "__main__":
    ind_addr = "127.0.0.1"
    ind_port = 5000
    
    req_addr = "127.0.0.1"
    req_port = 5001
    
    ind_s = portalJson.socket_client(ind_addr, ind_port)
    req_s = portalJson.socket_client(req_addr, req_port)
    
    d = {'name':'say','x':1}
    print d
    req_s.send(d)
    print ind_s.recv()
    d = {'name':'say','x':3}
    print d
    req_s.send(d)
    print ind_s.recv()
    d = {'name':'say2','x':2,'y':1}
    print d
    req_s.send(d)
    print ind_s.recv()
    d = {'name':'setLeds','x':0}
    print d
    req_s.send(d)
    time.sleep(1)
    req_s.shutdown()
    ind_s.shutdown()
