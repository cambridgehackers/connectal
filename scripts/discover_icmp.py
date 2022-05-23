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

def connect_with_adb(ipaddr):
    connected = False
    device_serial = '%s:5555' % (ipaddr)
    print('connecting to android device %s' % device_serial)
    while not connected:
        try:
            connection = adb_commands.AdbCommands.ConnectDevice(serial=device_serial)
            connected = True
        except socket.error:
            pass
    if 'hostname' in connection.Shell('ls /mnt/sdcard/'):
        name = connection.Shell('cat /mnt/sdcard/hostname') 
        print(name)
        return (ipaddr, name)
    else:
        print("/mnt/sdcard/hostname not found")


def calcsum(source_string):
    sum = 0
    for i in range(0,len(source_string),2):
        sum = sum + ord(source_string[i+1])*256 + ord(source_string[i])
    sum = (sum >> 16) + (sum & 0xFFFF)
    sum += (sum >> 16)
    sum = (~sum) & 0xFFFF
    return sum >> 8 | (sum << 8 & 0xFF00)

def receive_ping(timeout):
    global recv_cnt
    rem = timeout
    while True:
        a = time.time()
        b = select.select([icmp_socket], [], [], rem)
        c = (time.time() - a)
        if b[0] == []:
            return
        rp, addr = icmp_socket.recvfrom(1024)
        icmpHeader = rp[20:28]
        type, code, checksum, packetID, sequence = struct.unpack(
            "bbHHh", icmpHeader
        )
        if packetID == icmp_id:
            recv_cnt = recv_cnt+1
            # print "recv_cnt: %x" % recv_cnt
            return addr
        rem = rem - c
        if rem <= 0:
            return


def send_ping(dest_addr):
    global send_cnt
    send_cnt = send_cnt+1
    dest_addr  =  socket.gethostbyname(dest_addr)
    header = struct.pack("bbHHh", 8, 0, 0, icmp_id, 1)
    header = struct.pack("bbHHh", 8, 0, socket.htons(calcsum(header)), icmp_id, 1)
    try:
        # print header.encode('hex')
        # if (send_cnt > 1024):
        #     time.sleep(0.1)
        icmp_socket.sendto(header, (dest_addr, 1))
    except socket.error as e:
        print((dest_addr,e))
        raise
      
def check_adb_port(dest_addr):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.1)
    result = sock.connect_ex((dest_addr,5555))
    return result == 0

def ping_request(dest_addr):
    try:
        send_ping(dest_addr)
    except socket.gaierror as e:
        print("%s failed. (socket error: '%s')" % (dest_addr, e[1]))

def ping_response(timeout = 0.1):
    try:
        addr = receive_ping(timeout)
    except socket.gaierror as e:
        print("failed. (socket error: '%s')" % e[1])
    if (addr != None):
        responders.append(addr[0])

def ip2int(addr):                                                               
    return struct.unpack("!I", socket.inet_aton(addr))[0]                       

def int2ip(addr):                                                               
    return socket.inet_ntoa(struct.pack("!I", addr))

def send_pings():
    for i in range(low_addr,high_addr+1):
        ping_request(int2ip(i))

def get_pings():
    while (not stop):
        ping_response(0)

def do_work(start, end):
    global responders
    global stop
    global low_addr
    global high_addr
    global icmp_socket
    global icmp_id
    global zedboards
    global send_cnt
    global recv_cnt

    send_cnt = 0
    recv_cnt = 0
    responders = []
    stop = False
    low_addr = start
    high_addr = end
    print("pinging "+int2ip(low_addr)+" to "+int2ip(high_addr))

    icmp = socket.getprotobyname("icmp")
    icmp_socket = socket.socket(socket.AF_INET, socket.SOCK_RAW, icmp)
    icmp_socket.setsockopt(socket.SOL_SOCKET, socket.SO_SNDBUF, (start-end)*64)
    icmp_id = os.getpid() & 0xFFFF

    t0 = threading.Thread(target=send_pings)
    t1 = threading.Thread(target=get_pings)
    
    t0.start()
    t1.start()
        
    t0.join()
    time.sleep(3)
    stop = True
    t1.join()

    open = []
    for r in responders:
        if check_adb_port(r):
            open.append(r)

    for o in open:
        zedboards.append(connect_with_adb(o))

    icmp_socket.close()

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
                    print('skipping localhost')
                else:
                    addr = ip2int(i.get('addr'))
                    netmask = ip2int(i.get('netmask'))
                    start = addr & netmask
                    end = start + (netmask ^ 0xffffffff) 
                    print((int2ip(start), int2ip(end)))
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
