#!/usr/bin/python

import os, sys, re, shutil, subprocess

# parse tcl
# vlog
vlogRe = r'^\s+vlog(\w|\W)+QSYS_SIMDIR(\w|\W)+'
vlibRe = r'^\s+vlog(\w|\W)+QUARTUS_INSTALL_DIR(\w|\W)+'

def parseSetupTcl(tcl):
    if not os.path.exists(tcl):
        return
    f = open(tcl)
    for line in f:
        m = re.match(vlogRe, line)
        if m:
            match = m.group(0)
            #print match
            vlog_cmd = match.strip().replace("$QSYS_SIMDIR", "%s") % sys.argv[2]
            rc = subprocess.call(vlog_cmd, shell=True)

        n = re.match(vlibRe, line.split("-work")[0])
        if n:
            match = n.group(0)
            #print "QUARTUS_INSTALL_DIR", match
            vlib_cmd = match.strip().replace("$QUARTUS_INSTALL_DIR", "%s") % sys.argv[3]
            rc = subprocess.call(vlib_cmd, shell=True)

if __name__ == "__main__":
    parseSetupTcl(sys.argv[1])
