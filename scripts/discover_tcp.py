#!/usr/bin/env python3

# Copyright (c) 2013-2015 Quanta Research Cambridge, Inc.

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

deviceAddresses = []

def ip2int(addr):
    return struct.unpack("!I", socket.inet_aton(addr))[0]

def int2ip(addr):
    return socket.inet_ntoa(struct.pack("!I", addr))

def connect_with_adb(ipaddr,port):
    global deviceAddresses
    device_serial = '%s:%d' % (ipaddr,port)
    cnt = 0
    while cnt < 5:
        try:
            connection = adb_commands.AdbCommands.ConnectDevice(serial=device_serial)
        except:
            #print 'discover_tcp: connection error to', device_serial
            pass
        else:
            if 'hostname.txt' in connection.Shell('ls /mnt/sdcard/'):
                name = connection.Shell('cat /mnt/sdcard/hostname.txt').strip()
                connection.Close()
                print('discover_tcp: ', ipaddr, name)
                deviceAddresses[ipaddr] = name
                return
            else:
                print('discover_tcp: ', ipaddr, " /mnt/sdcard/hostname.txt not found")
                deviceAddresses[ipaddr] =  ipaddr
                return
        cnt = cnt+1

def open_adb_socket(dest_addr,port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setblocking(0)
    sock.connect_ex((dest_addr,port))
    return sock

# non-Darwin version
def do_work_poll(start, end, port, get_hostname):
    print("scanning "+int2ip(start)+" to "+int2ip(end))
    connected = []
    total = end-start

    READ_ONLY = select.POLLIN | select.POLLPRI | select.POLLHUP | select.POLLERR
    READ_WRITE = READ_ONLY | select.POLLOUT
    poller = select.poll()

    while (start <= end):
        fd_map = {}
        while (start <= end):
            try:
                s = open_adb_socket(int2ip(start),port)
            except:
                break
            else:
                fd_map[s.fileno()] = (start,s)
                start = start+1
                poller.register(s, READ_WRITE)
        time.sleep(0.2)
        events = poller.poll(0.1)
        for fd,flag in events:
            (addr,sock) = fd_map[fd]
            if sock.getsockopt(socket.SOL_SOCKET, socket.SO_ERROR) == 0:
                print('ADDCON', fd, int2ip(addr))
                connected.append(int2ip(addr))
        try:
            fd_map_items = fd_map.iteritems()
        except AttributeError:
            fd_map_items = fd_map.items()  # Python 3 compatibility
        for fd,t in fd_map_items:
            poller.unregister(t[1])
            t[1].close()
        sys.stdout.write("\r%d/%d" % (total-(end-start),total))
        sys.stdout.flush()
    print()
    if get_hostname:
        for c in connected:
            connect_with_adb(c,port)

# Darwin version
def do_work_kqueue(start, end, port, get_hostname):
    print("kqueue scanning "+int2ip(start)+" to "+int2ip(end))
    connected = []
    total = end-start

    while (start <= end):
        kq = select.kqueue()
        fd_map = {}
        kevents = []
        while (start <= end):
            try:
                s = open_adb_socket(int2ip(start),port)
            except:
                break
            else:
                fd_map[s.fileno()] = (start,s)
                start = start+1
                kevents.append(select.kevent(s,filter=select.KQ_FILTER_WRITE))
        kq.control(kevents,0,0)
        time.sleep(0.2)
        for k in kq.control([],len(kevents),0.1):
            w = fd_map[k.ident][1]
            addr = fd_map[w.fileno()][0]
            if w.getsockopt(socket.SOL_SOCKET, socket.SO_ERROR) == 0:
                print('ADDCON2', k.ident, w.fileno(), int2ip(addr), fd_map[w.fileno()])
                connected.append(int2ip(addr))
        try:
            fd_map_items = fd_map.iteritems()
        except AttributeError:
            fd_map_items = fd_map.items()  # Python 3 compatibility
        for fd,t in fd_map_items:
            t[1].close()
        sys.stdout.write("\r%d/%d" % (total-(end-start),total))
        sys.stdout.flush()
    print()
    if get_hostname:
        for c in connected:
            connect_with_adb(c,port)


argparser = argparse.ArgumentParser("Discover Zedboards on a network")
argparser.add_argument('-n', '--network', help='xxx.xxx.xxx.xxx/N')
argparser.add_argument('-p', '--port', default=5555, help='Port to probe')
argparser.add_argument('-g', '--get_hostname', default=True, help='Get hostname with adb')

def do_work(start,end,port,get_hostname):
    if sys.platform == 'darwin':
        do_work_kqueue(start,end,port,get_hostname)
    else:
        do_work_poll(start,end,port,get_hostname)

def detect_network(network=None, port=5555, get_hostname=True):
    global deviceAddresses
    deviceAddresses = {}
    if network:
        nw = network.split("/")
        start = ip2int(nw[0])
        if len(nw) != 2:
            print('Usage: discover_tcp.py ipaddr/prefix_width')
            sys.exit(-1)
        end = start + (1 << (32-int(nw[1])) ) - 2
        do_work(start+1,end,port,get_hostname)
    else:
        for ifc in netifaces.interfaces():
            ifaddrs = netifaces.ifaddresses(ifc)
            if netifaces.AF_INET in ifaddrs.keys():
                af_inet = ifaddrs[netifaces.AF_INET]
                for i in af_inet:
                    if i.get('addr') == '127.0.0.1':
                        print('skipping localhost')
                    else:
                        addr = ip2int(i.get('addr'))
                        netmask = ip2int(i.get('netmask'))
                        start = addr & netmask
                        end = start + (netmask ^ 0xffffffff)
                        start = start+1
                        end = end-1
                        print((int2ip(start), int2ip(end)))
                        do_work(start, end,port,get_hostname)

if __name__ ==  '__main__':
    options = argparser.parse_args()
    detect_network(options.network,options.port,options.get_hostname)
