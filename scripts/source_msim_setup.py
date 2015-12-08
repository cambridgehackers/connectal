#!/usr/bin/python

import os, sys, re, shutil, subprocess

# parse tcl
# vlog
vlogRe = r'^\s+vlog(\w|\W)+QSYS_SIMDIR(\w|\W)+'

def parseSetupTcl(tcl, libdirs):
    if not os.path.exists(tcl):
        return
    print 'libdirs', libdirs
    f = open(tcl)
    for line in f:
        m = re.match(vlogRe, line)
        if m:
            match = m.group(0)
            print match
            vlog_cmd = match.strip().replace("$QSYS_SIMDIR", "%s") % sys.argv[2]
            rc = subprocess.call(vlog_cmd, shell=True)

if __name__ == "__main__":
    print 'run souce msim'
    parseSetupTcl(sys.argv[1], sys.argv[2])
