#!/usr/bin/python

globaldecls = []
globalvars = {}

def add_new(decl):
    globaldecls.append(decl)
    globalvars[decl.name] = decl
