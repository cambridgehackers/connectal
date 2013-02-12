import syntax
import AST
import util

classPrefixTemplate='''
class %(namespace)s%(className)s {
public:
    enum %(className)sResponseChannel {
        %(responseChannels)s%(className)sNumChannels
    };
    int connectHandler(%(className)sResponseChannel c, PortalInstance::MessageHandler h) {
        p->messageHandlers[c] = h;
        return 0;
    }

    static %(className)s *create%(className)s(const char *instanceName);
'''
classSuffixTemplate='''
private:
    %(className)s(PortalInstance *, int baseChannelNumber=0);
    ~%(className)s();
    PortalInstance *p;
    int baseChannelNumber;
};
'''

creatorTemplate = '''
%(namespace)s%(className)s *%(namespace)s%(className)s::create%(className)s(const char *instanceName)
{
    PortalInstance *p = portalOpen(instanceName);
    %(namespace)s%(className)s *instance = new %(namespace)s%(className)s(p);
    return instance;
}
'''
constructorTemplate='''
%(namespace)s%(className)s::%(className)s(PortalInstance *p, int baseChannelNumber)
 : p(p), baseChannelNumber(baseChannelNumber)%(initializers)s
{
  p->messageHandlers = new PortalInstance::MessageHandler [%(className)s::%(className)sNumChannels]();
}
%(namespace)s%(className)s::~%(className)s()
{
    p->close();
}

'''

methodTemplate='''
struct %(className)s%(methodName)sMSG : public PortalMessage
{
struct Request {
//fix Adapter.bsv to unreverse these
%(paramStructDeclarations)s
} request;
int channelNumber;
};

void %(namespace)s%(className)s::%(methodName)s ( %(paramDeclarations)s )
{
    %(className)s%(methodName)sMSG msg;
    msg.size = sizeof(msg.request) + sizeof(msg.channelNumber);
    msg.channelNumber = baseChannelNumber + %(methodChannelOffset)s;
%(paramSetters)s
    p->sendMessage(&msg);
};
'''

def indent(f, indentation):
    for i in xrange(indentation):
        f.write(' ')

def capitalize(s):
    return '%s%s' % (s[0].upper(), s[1:])

class NoCMixin:
    def emitCDeclaration(self, f, indentation=0, parentClassName='', namespace=''):
        pass
    def emitCImplementation(self, f):
        pass

class MethodMixin:
    def collectTypes(self):
        result = [self.return_type]
        result.append(AST.Type('Tuple', self.params))
        return result
    def resultTypeName(self):
        if (self.return_type):
            return self.return_type.cName()
        else:
            return int
    def emitCDeclaration(self, f, indentation=0, parentClassName='', namespace=''):
        indent(f, indentation)
        resultTypeName = self.resultTypeName()
        f.write('void %s ( ' % cName(self.name))
        #print parentClassName, self.name
        f.write(', '.join([cName(p.type) for p in self.params]))
        f.write(' );\n');
    def emitCImplementation(self, f, className, namespace):
        if not self.params:
            return
        paramDeclarations = [ '%s %s' % (p.type.cName(), p.name) for p in self.params]
        paramStructDeclarations = [ '%s %s%s;\n' % (p.type.cName(), p.name, p.type.bitSpec()) for p in self.params]
        ## fix Adapter.bsv to eliminate the need for this reversal
        paramStructDeclarations.reverse()
        paramSetters = [ 'msg.request.%s = %s;\n' % (p.name, p.name) for p in self.params]
        resultTypeName = self.resultTypeName()
        substs = {
            'namespace': namespace,
            'className': className,
            'methodName': cName(self.name),
            'paramDeclarations': ', '.join(paramDeclarations),
            'paramStructDeclarations': ''.join(paramStructDeclarations),
            'paramSetters': ''.join(paramSetters),
            'resultType': resultTypeName,
            'methodChannelOffset': self.channelNumber
            }
        f.write(methodTemplate % substs)

class StructMemberMixin:
    def emitCDeclaration(self, f, indentation=0, parentClassName='', namespace=''):
        indent(f, indentation)
        f.write('%s %s' % (self.type.cName(), self.tag))
        #print 'emitCDeclaration: ', self.type, self.type.isBitField, self.type.cName(), self.tag
        if self.type.isBitField():
            f.write(' : %d' % self.type.bitWidth())
        f.write(';\n')

class StructMixin:
    def collectTypes(self):
        result = [self]
        result.append(self.elements)
        return result
    def emitCDeclaration(self, f, indentation=0, parentClassName='', namespace=''):
        indent(f, indentation)
        if (indentation == 0):
            f.write('typedef ')
        f.write('struct %s {\n' % self.name.cName())
        for e in self.elements:
            e.emitCDeclaration(f, indentation+4)
        indent(f, indentation)
        f.write('}')
        if (indentation == 0):
            f.write(' %s;' % self.name.cName())
        f.write('\n')
    def emitCImplementation(self, f, className='', namespace=''):
        pass

class EnumElementMixin:
    def cName(self):
        return self.name

class EnumMixin:
    def collectTypes(self):
        result = [self]
        return result
    def emitCDeclaration(self, f, indentation=0, parentClassName='', namespace=''):
        indent(f, indentation)
        if (indentation == 0):
            f.write('typedef ')
        f.write('enum %s { ' % self.name.cName())
        indent(f, indentation)
        f.write(', '.join([e.cName() for e in self.elements]))
        indent(f, indentation)
        f.write(' }')
        if (indentation == 0):
            f.write(' %s;' % self.name.cName())
        f.write('\n')
    def emitCImplementation(self, f, className='', namespace=''):
        pass

class InterfaceMixin:
    def collectTypes(self):
        result = [d.collectTypes() for d in self.decls]
        return result
    def getSubinterface(self, name):
        subinterfaceName = name
        if not syntax.globalvars.has_key(subinterfaceName):
            return None
        subinterface = syntax.globalvars[subinterfaceName]
        #print 'subinterface', subinterface, subinterface
        return subinterface
    def assignRequestResponseChannels(self):
        channelNumber = 0
        for d in self.decls:
            if d.__class__ == AST.Interface:
                i = self.getSubinterface(d.name)
                if not i:
                    continue
                d.baseChannelNumber = channelNumber
                channelNumber = channelNumber + i.channelCount 
            elif d.__class__ == AST.Method:
                d.channelNumber = channelNumber
                channelNumber = channelNumber + 1
        self.channelCount = channelNumber
    def emitCDeclaration(self, f, indentation=0, parentClassName='', namespace=''):
        self.toplevel = (indentation == 0)
        name = cName(self.name)
        indent(f, indentation)
        responseChannels=['%sResponseChannel, ' % capitalize(d.name)
                          for d in self.decls if d.type=='Method' and not d.params]
        f.write(classPrefixTemplate % {'className': name,
                                       'namespace': namespace,
                                       'responseChannels': ''.join(responseChannels)})
        for d in self.decls:
            if d.type == 'Interface':
                continue
            if d.type != 'Method' or d.params:
                d.emitCDeclaration(f, indentation + 4, name, namespace)
        indent(f, indentation)
        f.write('private:\n')
        indent(f, indentation+4)
        f.write('%(name)s(PortalInstance *, int baseChannelNumber=0);\n' % {'name': name})
        indent(f, indentation+4)
        f.write('~%(name)s();\n' % {'name': name})
        indent(f, indentation+4)
        f.write('PortalInstance *p;\n')
        indent(f, indentation+4)
        f.write('int baseChannelNumber;\n')
        if parentClassName:
            indent(f, indentation+4)
            f.write('friend class %s%s;\n' % (namespace, parentClassName))

        ## dereference the interface, in case this is nested
        subinterface = self.getSubinterface(self.name)

        indent(f, indentation)
        f.write('}')
        if self.subinterfacename:
            f.write(' %s' % self.subinterfacename)
        f.write(';\n');
    def emitCImplementation(self, f, parentClassName='', namespace=''):
        self.assignRequestResponseChannels()
        if parentClassName:
            namespace = '%s%s::' % (namespace, parentClassName)
        className = cName(self.name)
        self.emitConstructorImplementation(f, className, namespace)
        for d in self.decls:
            if d.type == 'Interface':
                continue
            d.emitCImplementation(f, className, namespace)
    def emitConstructorImplementation(self, f, className, namespace):
        substitutions = {'namespace': namespace,
                         'className': className,
                         'initializers': ''}
        subinterfaces = []
        for d in self.decls:
            if d.__class__ == AST.Interface:
                subinterfaces.append(d.subinterfacename)
        ## not generating code for subinterfaces for now
        ## if subinterfaces:
        ##     substitutions['initializers'] = (', %s'
        ##                                      % ', '.join([ '%s(p)' % i for i in subinterfaces]))
        if self.toplevel:
            f.write(creatorTemplate % substitutions)
        f.write(constructorTemplate % substitutions)

class ParamMixin:
    def cName(self):
        return self.name

class TypeMixin:
    def cName(self):
        cid = self.name
        cid = cid.replace(' ', '')
        if cid == 'Bit':
            return 'unsigned int'
        elif cid == 'Action':
            return 'int'
        elif cid == 'ActionValue':
            return self.params[0].cName()
        if self.params:
            name = '%sL_%s_P' % (cid, '_'.join([cName(t) for t in self.params if t]))
        else:
            name = cid
        return name
    def isBitField(self):
        return self.name == 'Bit'
    def bitWidth(self):
        if self.name == 'Bit':
            return int(self.params[0].name)
        else:
            return 0
    def bitSpec(self):
        if self.isBitField():
            bw = self.bitWidth()
            if bw != 32:
                return ':%d' % bw
        return ''

def cName(x):
    if type(x) == str:
        x = x.replace(' ', '')
        x = x.replace('.', '$')
        return x
    else:
        return x.cName()
