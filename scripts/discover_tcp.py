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
import os
import socket
import struct
import select
import time
import threading
import argparse
import netifaces

from adb import adb_commands
from adb import common

def ip2int(addr):                                                               
    return struct.unpack("!I", socket.inet_aton(addr))[0]                       

def int2ip(addr):                                                               
    return socket.inet_ntoa(struct.pack("!I", addr))

def connect_with_adb(ipaddr):
    global zedboards
    device_serial = '%s:5555' % (ipaddr)
    cnt = 0
    print 'connecting to android device %s:5555' % int2ip(ipaddr)
    while cnt < 5:
        try:
            connection = adb_commands.AdbCommands.ConnectDevice(serial=device_serial)
        except socket.error:
            pass
        else:
            if 'hostname' in connection.Shell('ls /mnt/sdcard/'):
                name = connection.Shell('cat /mnt/sdcard/hostname') 
                connection.Close()
                print name
                zedboards.append((ipaddr, name))
                return
            else:
                print "/mnt/sdcard/hostname not found"
                return
        cnt = cnt+1
    print "failed to connect"
      
def open_adb_socket(dest_addr):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setblocking(0)
    sock.connect_ex((dest_addr,5555))
    return sock

def do_work(start, end):
    print "scanning "+int2ip(start)+" to "+int2ip(end)
    connected = []
    total = end-start

    while (start <= end):
        opened = []
        addrs = {}
        cnt = 0
        while (start <= end):
            try:
                s = open_adb_socket(int2ip(start))
            except:
                break
            else:
                addrs[s.fileno()] = start
                opened.append(s)
                start = start+1
                cnt = cnt+1

        time.sleep(0.2)
        ready_to_read, ready_to_write, in_error = select.select([],opened,[],0.1)
        for w in ready_to_write:
            if w.getsockopt(socket.SOL_SOCKET, socket.SO_ERROR) == 0:
                addr = addrs[w.fileno()]
                connected.append(addr)

        for o in opened:
            o.close()

        sys.stdout.write("\r%d/%d" % (total-(end-start),total))
        sys.stdout.flush()

    print
    for c in connected:
        connect_with_adb(c)


argparser = argparse.ArgumentParser("Discover Zedboards on a network")
argparser.add_argument('-n', '--network', help='xxx.xxx.xxx.xxx/N')

def detect_network():
    global zedboards
    zedboards = []
    for ifc in netifaces.interfaces():
        ifaddrs = netifaces.ifaddresses(ifc)
        if netifaces.AF_INET in ifaddrs.keys():
            af_inet = ifaddrs[netifaces.AF_INET]
            for i in af_inet: 
                if i.get('addr') == '127.0.0.1':
                    print 'skipping localhost'
                else:
                    addr = ip2int(i.get('addr'))
                    netmask = ip2int(i.get('netmask'))
                    start = addr & netmask
                    end = start + (netmask ^ 0xffffffff) 
                    start = start+1
                    end = end-1
                    print (int2ip(start), int2ip(end)) 
                    do_work(start, end) 

if __name__ ==  '__main__':
    zedboards = []
    options = argparser.parse_args()
    if options.network == None:
        detect_network()
    else:
        nw = options.network.split("/")
        start = ip2int(nw[0])
        end = start+(1<<int(nw[1]))-2
        do_work(start+1,end)
