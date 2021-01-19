# Copyright (c) 2014 Quanta Research Cambridge, Inc
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
#

from __future__ import print_function

import math
import re
import functools
import json
import os
import sys
import traceback

import AST
import globalv
import util

verbose = False
tempFilename = 'generatedDesignInterfaceFile.json'
lookupTable = {}

class InterfaceMixin:
    def getSubinterface(self, name):
        subinterfaceName = name
        if not subinterfaceName in globalv.globalvars:
            return None
        subinterface = globalv.globalvars[subinterfaceName]
        #print('subinterface', subinterface, subinterface)
        return subinterface
    def parentClass(self, default):
        rv = default if (len(self.typeClassInstances)==0) else (self.typeClassInstances[0])
        return rv

def dtInfo(arg):
    rc = {}
    if hasattr(arg, 'name'):
        rc['name'] = arg.name
        if lookupTable.get(arg.name):
            rc['name'] = lookupTable[arg.name]
    if hasattr(arg, 'type') and arg.type != 'Type':
        rc['type'] = arg.type
        if lookupTable.get(arg.type):
            rc['type'] = lookupTable[arg.type]
    if hasattr(arg, 'params'):
        if arg.params is not None and arg.params != []:
            rc['params'] = [dtInfo(p) for p in arg.params]
    if hasattr(arg, 'elements'):
        if arg.type == 'Enum':
            rc['elements'] = arg.elements
        else:
            rc['elements'] = [piInfo(p) for p in arg.elements]
    return rc

def piInfo(pitem):
    rc = {}
    rc['pname'] = pitem.name
    rc['ptype'] = dtInfo(pitem.type)
    if hasattr(pitem, 'oldtype'):
        rc['oldtype'] = dtInfo(pitem.oldtype)
    return rc

def declInfo(mitem):
    rc = {}
    rc['dname'] = mitem.name
    rc['dparams'] = []
    for pitem in mitem.params:
        rc['dparams'].append(piInfo(pitem))
    return rc

def classInfo(item):
    rc = {
        'Package': os.path.splitext(os.path.basename(item.package))[0],
        'cname': item.name,
        'cdecls': [],
    }
    for mitem in item.decls:
        rc['cdecls'].append(declInfo(mitem))
    return rc

def serialize_json(interfaces, globalimports, bsvdefines):
    global verbose
    itemlist = []
    for item in interfaces:
        itemlist.append(classInfo(item))
    jfile = open(tempFilename, 'w')
    toplevel = {}
    toplevel['interfaces'] = itemlist
    gdlist = []
    for item in globalv.globaldecls:
        if item.type == 'TypeDef':
            newitem = {'dtype': item.type}
            newitem['tname'] = item.name
            newitem['tdtype'] = dtInfo(item.tdtype)
            if item.params:
                 newitem['tparams'] = item.params
            if verbose:
                print('TYPEDEF globaldecl:', item, newitem)
            gdlist.append(newitem)
        elif verbose:
            print('Unprocessed globaldecl:', item)
    toplevel['globaldecls'] = gdlist
    toplevel['globalimports'] = globalimports
    toplevel['bsvdefines'] = bsvdefines
    if True:
        try:
            json.dump(toplevel, jfile, sort_keys = True, indent = 4)
            jfile.close()
            j2file = open(tempFilename).read()
            toplevelnew = json.loads(j2file)
        except:
            print('Unable to encode json file', tempFilename)
            #print('WWWW', toplevel)
            sys.exit(-1)
    return toplevel

class Method:
    def __init__(self, name, return_type, params):
        self.type = 'Method'
        self.name = name
        self.return_type = return_type
        self.params = params
    def __repr__(self):
        sparams = [p.__repr__() for p in self.params]
        return '<method: %s %s %s>' % (self.name, self.return_type, sparams)
    def instantiate(self, paramBindings):
        #print('instantiate method', self.name, self.params)
        return Method(self.name,
                      self.return_type.instantiate(paramBindings),
                      [ p.instantiate(paramBindings) for p in self.params])

class Function:
    def __init__(self, name, return_type, params):
        self.type = 'Function'
        self.name = name
        self.return_type = return_type
        self.params = params
    def __repr__(self):
        if not self.params:
            return '<function: %s %s NONE>' % (self.name, self.return_type)
        sparams = list(map(str, self.params))
        return '<function: %s %s %s>' % (self.name, self.return_type, sparams)

class Variable:
    def __init__(self, name, t, value):
        self.type = 'Variable'
        self.name = name
        self.type = t
        self.value = value
        if t and t.type == 'Type' and t.name == 'Integer' and value and value.type == 'Type':
            lookupTable[name] = value.name
    def __repr__(self):
        return '<variable: %s : %s>' % (self.name, self.type)

class Interface(InterfaceMixin):
    def __init__(self, name, params, decls, subinterfacename, packagename):
        self.type = 'Interface'
        self.name = name
        self.params = params
        self.decls = decls
        self.subinterfacename = subinterfacename
        self.typeClassInstances = []
        self.package = packagename
    def interfaceType(self):
        return Type(self.name,self.params)
    def __repr__(self):
        return '{interface: %s (%s) : %s}' % (self.name, self.params, self.typeClassInstances)
    def instantiate(self, paramBindings):
        newInterface = Interface(self.name, [],
                                 [d.instantiate(paramBindings) for d in self.decls],
                                 self.subinterfacename,
                                 self.package)
        newInterface.typeClassInstances = self.typeClassInstances
        return newInterface

class Typeclass:
    def __init__(self, name):
        self.name = name
        self.type = 'TypeClass'
    def __repr__(self):
        return '{typeclass %s}' % (self.name)

class TypeclassInstance:
    def __init__(self, name, params, provisos, decl):
        self.name = name
        self.params = params
        self.provisos = provisos
        self.decl = decl
        self.type = 'TypeclassInstance'
    def __repr__(self):
        return '{typeclassinstance %s %s}' % (self.name, self.params)

class Module:
    def __init__(self, moduleContext, name, params, interface, provisos, decls):
        self.type = 'Module'
        self.name = name
        self.moduleContext = moduleContext
        self.interface = interface
        self.params = params
        self.provisos = provisos
        self.decls = decls
    def __repr__(self):
        return '{module: %s %s}' % (self.name, self.decls)

class EnumElement:
    def __init__(self, name, qualifiers, value):
        self.qualifiers = qualifiers
        self.value = value
    def __repr__(self):
        return '{enumelt: %s}' % (self.name)

class Enum:
    def __init__(self, elements):
        self.type = 'Enum'
        self.elements = elements
    def __repr__(self):
        return '{enum: %s}' % (self.elements)
    def instantiate(self, paramBindings):
        return self

class StructMember:
    def __init__(self, t, name):
        self.type = t
        self.name = name
    def __repr__(self):
        return '{field: %s %s}' % (self.type, self.name)
    def instantiate(self, paramBindings):
        return StructMember(self.type.instantiate(paramBindings), self.name)

class Struct:
    def __init__(self, elements):
        self.type = 'Struct'
        self.elements = elements
    def __repr__(self):
        return '{struct: %s}' % (self.elements)
    def instantiate(self, paramBindings):
        return Struct([e.instantiate(paramBindings) for e in self.elements])

class TypeDef:
    def __init__(self, tdtype, name, params):
        self.name = name
        self.params = params
        self.type = 'TypeDef'
        self.tdtype = tdtype
        if tdtype and tdtype.type != 'Type':
            tdtype.name = name
        self.type = 'TypeDef'
    def __repr__(self):
        return '{typedef: %s %s}' % (self.tdtype, self.name)

class Param:
    def __init__(self, name, t):
        self.name = name
        self.type = t
    def __repr__(self):
        return '{param %s: %s}' % (self.name, self.type)
    def instantiate(self, paramBindings):
        return Param(self.name,
                     self.type.instantiate(paramBindings))

class Type:
    def __init__(self, name, params):
        self.type = 'Type'
        self.name = name
        if params:
            self.params = params
        else:
            self.params = []
    def __repr__(self):
        sparams = list(map(str, self.params))
        return '{type: %s %s}' % (self.name, sparams)
    def instantiate(self, paramBindings):
        #print('Type.instantiate', self.name, paramBindings)
        if self.name in paramBindings:
            return paramBindings[self.name]
        else:
            return Type(self.name, [p.instantiate(paramBindings) for p in self.params])
