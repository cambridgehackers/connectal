#!/usr/bin/env python3

globaldecls = []
globalvars = {}

def add_new(decl):
    if decl:
        globaldecls.append(decl)
        globalvars[decl.name] = decl
