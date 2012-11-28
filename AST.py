
class Method:
    def __init__(self, name, type_decl, params):
        self.name = name
        self.type_decl = type_decl
        self.params = params
    def __repr__(self):
        sparams = map(str, self.params)
        return '<method: %s %s %s>' % (self.name, self.type_decl, sparams)
    def generateCTypes(self):
        result = [self.type_decl]
        result.append(Type('Tuple#', self.params))
        return result

class Interface:
    def __init__(self, name, decls):
        self.name = name
        self.decls = decls
    def __repr__(self):
        return '{interface: %s}' % self.name

class Module:
    def __init__(self, name, decls):
        self.name = name
        self.decls = decls
    def __repr__(self):
        return '{module: %s %s}' % (self.name, self.decls)
    def generateCTypes(self):
        result = []
        for d in self.decls:
            if d:
                result.extend(d.generateCTypes())
        return result

class Type:
    def __init__(self, name, params):
        self.name = name
        if params:
            self.params = params
        else:
            self.params = []
    def __repr__(self):
        sparams = map(str, self.params)
        return '{type: %s %s}' % (self.name, sparams)
