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

import os
import socket
import struct
import select
import time
import threading
import argparse

from adb import adb_commands
from adb import common

def connect_with_adb(ipaddr):
    connected = False
    device_serial = '%s:5555' % (ipaddr)
    print 'connecting to android device %s' % device_serial
    while not connected:
        try:
            connection = adb_commands.AdbCommands.ConnectDevice(serial=device_serial)
            connected = True
        except socket.error:
            pass
    if 'hostname' in connection.Shell('ls /mnt/sdcard/'):
        print connection.Shell('cat /mnt/sdcard/hostname')
    else:
        print "/mnt/sdcard/hostname not found"


def calcsum(source_string):
    sum = 0
    for i in range(0,len(source_string),2):
        sum = sum + ord(source_string[i+1])*256 + ord(source_string[i])
    sum = (sum >> 16) + (sum & 0xFFFF)
    sum += (sum >> 16)
    sum = (~sum) & 0xFFFF
    return sum >> 8 | (sum << 8 & 0xFF00)

def receive_ping(timeout):
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
        if packetID == icmp_ID:
            return addr
        rem = rem - c
        if rem <= 0:
            return

def send_ping(dest_addr):
    dest_addr  =  socket.gethostbyname(dest_addr)
    header = struct.pack("bbHHh", 8, 0, 0, icmp_ID, 1)
    data = "AAAAAAAA"
    cs = calcsum(header + data)
    header = struct.pack("bbHHh", 8, 0, socket.htons(cs), icmp_ID, 1)
    packet = header + data
    icmp_socket.sendto(packet, (dest_addr, 1))

def check_adb_port(dest_addr):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.1)
    result = sock.connect_ex((dest_addr,5555))
    return result == 0

def ping_request(dest_addr):
    try:
        send_ping(dest_addr)
    except socket.gaierror, e:
        print "%s failed. (socket error: '%s')" % (dest_addr, e[1])

def ping_response(timeout = 0.1):
    try:
        addr = receive_ping(timeout)
    except socket.gaierror, e:
        print "failed. (socket error: '%s')" % e[1]
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

argparser = argparse.ArgumentParser("Discover Zedboards on a network")
argparser.add_argument('-n', '--network', help='xxx.xxx.xxx.xxx/N')

if __name__ ==  '__main__':
    responders = []
    stop = False
    options = argparser.parse_args()
    nw = options.network.split("/")
    low_addr = ip2int(nw[0])
    num_addrs = (1<<int(nw[1]))-2
    high_addr = low_addr+num_addrs
    low_addr = low_addr+1
    print "pinging "+int2ip(low_addr)+" to "+int2ip(high_addr)

    icmp = socket.getprotobyname("icmp")
    icmp_socket = socket.socket(socket.AF_INET, socket.SOCK_RAW, icmp)
    icmp_ID = os.getpid() & 0xFFFF

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
        connect_with_adb(o)

    icmp_socket.close()
