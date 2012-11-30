
class Method:
    def __init__(self, name, return_type, params):
        self.type = 'Method'
        self.name = name
        self.return_type = return_type
        self.params = params
    def __repr__(self):
        sparams = map(str, self.params)
        return '<method: %s %s %s>' % (self.name, self.return_type, sparams)

class Interface:
    def __init__(self, name, decls, subinterfacename=None):
        self.type = 'Interface'
        self.name = name
        self.decls = decls
        self.subinterfacename = subinterfacename
    def __repr__(self):
        return '{interface: %s}' % self.name

class Module:
    def __init__(self, name, decls):
        self.type = 'Module'
        self.name = name
        self.decls = decls
    def __repr__(self):
        return '{module: %s %s}' % (self.name, self.decls)
    def collectTypes(self):
        result = []
        for d in self.decls:
            if d:
                result.extend(d.collectTypes())
        return result

class EnumElement:
    def __init__(self, name, qualifiers, value):
        self.name = name
        self.qualifiers = qualifiers
        self.value = value
    def __repr__(self):
        return '{enumelt: %s}' % (self.name)

class Enum:
    def __init__(self, name, elements):
        self.type = 'Enum'
        self.name = name
        self.elements = elements
    def __repr__(self):
        return '{enum: %s %s}' % (self.name, self.elements)

class StructMember:
    def __init__(self, t, tag):
        self.type = t
        self.tag = tag
    def __repr__(self):
        return '{field: %s %s}' % (self.type, self.tag)

class Struct:
    def __init__(self, name, elements):
        self.type = 'Struct'
        self.name = name
        self.elements = elements
    def __repr__(self):
        return '{struct: %s %s}' % (self.name, self.elements)

class Param:
    def __init__(self, name, t):
        self.name = name
        self.type = t
    def __repr__(self):
        return '{param %s: %s}' % (self.name, self.type)

class Type:
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
