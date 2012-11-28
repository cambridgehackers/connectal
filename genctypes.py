#!/usr/bin/python
import os, sys

import newrt
import syntax

if __name__=='__main__':
    newrt.printtrace = True
    s = open(sys.argv[1]).read() + '\n'
    s1 = syntax.parse('goal', s)
    print s1
    if (len(sys.argv) > 2):
        for ident in sys.argv[2:]:
            print
            print s1[ident]
            print s1[ident].generateCTypes()
