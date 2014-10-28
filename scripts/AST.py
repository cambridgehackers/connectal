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

import cppgen, bsvgen

class Method(cppgen.MethodMixin,bsvgen.MethodMixin):
    def __init__(self, name, return_type, params):
        self.type = 'Method'
        self.name = name
        self.return_type = return_type
        self.params = params
    def __repr__(self):
        sparams = [p.__repr__() for p in self.params]
        return '<method: %s %s %s>' % (self.name, self.return_type, sparams)
    def instantiate(self, paramBindings):
        #print 'instantiate method', self.name, self.params
        return Method(self.name,
                      self.return_type.instantiate(paramBindings),
                      [ p.instantiate(paramBindings) for p in self.params])

class Function(cppgen.NoCMixin):
    def __init__(self, name, return_type, params):
        self.type = 'Function'
        self.name = name
        self.return_type = return_type
        self.params = params
    def __repr__(self):
        sparams = map(str, self.params)
        return '<function: %s %s %s>' % (self.name, self.return_type, sparams)

class Variable:
    def __init__(self, name, t):
        self.type = 'Variable'
        self.name = name
        self.type = t
    def __repr__(self):
        return '<variable: %s : %s>' % (self.name, self.type)

class Interface(cppgen.InterfaceMixin,bsvgen.InterfaceMixin):
    def __init__(self, name, params, decls, subinterfacename, packagename):
        self.type = 'Interface'
        self.name = name
        self.params = params
        self.decls = decls
        self.subinterfacename = subinterfacename
        self.typeClassInstances = []
        self.hasSource = True
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
        newInterface.hasSource = self.hasSource
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

class Module(cppgen.NoCMixin):
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
    def collectTypes(self):
        result = []
        for d in self.decls:
            if d:
                result.extend(d.collectTypes())
        return result

class EnumElement(cppgen.EnumElementMixin):
    def __init__(self, name, qualifiers, value):
        self.qualifiers = qualifiers
        self.value = value
    def __repr__(self):
        return '{enumelt: %s}' % (self.name)

class Enum(cppgen.EnumMixin,bsvgen.EnumMixin):
    def __init__(self, elements):
        self.type = 'Enum'
        self.elements = elements
    def __repr__(self):
        return '{enum: %s}' % (self.elements)

class StructMember(cppgen.StructMemberMixin):
    def __init__(self, t, name):
        self.type = t
        self.name = name
    def __repr__(self):
        return '{field: %s %s}' % (self.type, self.name)

class Struct(cppgen.StructMixin):
    def __init__(self, elements):
        self.type = 'Struct'
        self.elements = elements
    def __repr__(self):
        return '{struct: %s}' % (self.elements)


class TypeDef(cppgen.TypeDefMixin):
    def __init__(self, tdtype, name):
        self.name = name
        self.tdtype = tdtype
        if tdtype.type != 'Type':
            tdtype.name = name
        self.type = 'TypeDef'
    def __repr__(self):
        return '{typedef: %s %s}' % (self.tdtype, self.name)

class Param(cppgen.ParamMixin,bsvgen.ParamMixin):
    def __init__(self, name, t):
        self.name = name
        self.type = t
    def __repr__(self):
        return '{param %s: %s}' % (self.name, self.type)
    def instantiate(self, paramBindings):
        return Param(self.name,
                     self.type.instantiate(paramBindings))

class Type(cppgen.TypeMixin,bsvgen.TypeMixin):
    def __init__(self, name, params):
        self.type = 'Type'
        self.name = name
        if params:
            self.params = params
        else:
            self.params = []
    def __repr__(self):
        sparams = map(str, self.params)
        return '{type: %s %s}' % (self.name, sparams)
    def instantiate(self, paramBindings):
        #print 'instantiate', self.name
        if paramBindings.has_key(self.name):
            return paramBindings[self.name]
        else:
            return Type(self.name, [p.instantiate(paramBindings) for p in self.params])
    def numeric(self):
        return int(self.name)
