#!/usr/bin/python
import os, sys, shutil
import AST
import newrt
import syntax
import bsvgen

creatorTemplate = '''
%(namespace)s%(className)s *%(namespace)s%(className)s::create%(className)s(const char *instanceName)
{
    UshwInstance *p = ushwOpen(instanceName);
    %(namespace)s%(className)s *instance = new %(namespace)s%(className)s(p);
    return instance;
}

'''
constructorTemplate='''
%(namespace)s%(className)s::%(className)s(UshwInstance *p, int baseChannelNumber)
 : p(p), baseChannelNumber(baseChannelNumber)%(initializers)s
{
}
%(namespace)s%(className)s::~%(className)s()
{
    p->close();
}

'''

methodTemplate='''
struct %(className)s%(methodName)sMSG : public UshwMessage
{
struct Request {
//fix Adapter.bsv to unreverse these
%(paramStructDeclarations)s
int channelNumber;
} request;
struct Response {
//fix Adapter.bsv to unreverse these
%(resultType)s response;
int responseChannel;
} response;
};

%(resultType)s %(namespace)s%(className)s::%(methodName)s ( %(paramDeclarations)s )
{
    %(className)s%(methodName)sMSG msg;
    msg.argsize = sizeof(msg.request);
    msg.resultsize = sizeof(msg.response);
    msg.request.channelNumber = baseChannelNumber + %(methodChannelOffset)s;
%(paramSetters)s
    p->sendMessage(&msg);
    return msg.response.response;
};
'''

def indent(f, indentation):
    for i in xrange(indentation):
        f.write(' ')

class MethodMixin:
    def collectTypes(self):
        result = [self.return_type]
        result.append(AST.Type('Tuple#', self.params))
        return result
    def resultTypeName(self):
        if (self.return_type):
            return self.return_type.cName()
        else:
            return int
    def emitCDeclaration(self, f, indentation=0, parentClassName='', namespace=''):
        indent(f, indentation)
        resultTypeName = self.resultTypeName()
        f.write('%s %s ( ' % (resultTypeName, cName(self.name)))
        print parentClassName, self.name
        f.write(', '.join([cName(p.type) for p in self.params]))
        f.write(' );\n');
    def emitCImplementation(self, f, className, namespace):
        paramDeclarations = [ '%s %s' % (p.type.cName(), p.name) for p in self.params]
        paramStructDeclarations = [ '%s %s;\n' % (p.type.cName(), p.name) for p in self.params]
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
        subinterfaceName = name.replace(' ', '')
        subinterface = syntax.globalvars[subinterfaceName]
        print 'subinterface', subinterface, subinterface
        return subinterface
    def assignFriends(self):
        self.friends = []
        for d in self.decls:
            if d.__class__ == AST.Interface:
                i.friends.append(self.name)
        print self.friends, self
    def assignRequestResponseChannels(self):
        channelNumber = 0
        for d in self.decls:
            if d.__class__ == AST.Interface:
                i = self.getSubinterface(d.name)
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
        f.write('class %s {\n' % name)
        indent(f, indentation)
        f.write('public:\n')
        if (not indentation):
            indent(f, indentation+4)
            f.write('static %(name)s *create%(name)s(const char *instanceName);\n'
                    % {'name': name})
        for d in self.decls:
            d.emitCDeclaration(f, indentation + 4, name, namespace)
        indent(f, indentation)
        f.write('private:\n')
        indent(f, indentation+4)
        f.write('%(name)s(UshwInstance *, int baseChannelNumber=0);\n' % {'name': name})
        indent(f, indentation+4)
        f.write('~%(name)s();\n' % {'name': name})
        indent(f, indentation+4)
        f.write('UshwInstance *p;\n')
        indent(f, indentation+4)
        f.write('int baseChannelNumber;\n')
        if parentClassName:
            indent(f, indentation+4)
            f.write('friend class %s%s;\n' % (namespace, parentClassName))

        ## dereference the interface, in case this is nested
        subinterface = self.getSubinterface(self.name)
        ## and declare our friends
        for friend in subinterface.friends:
            indent(f, indentation+4)
            f.write('friend class %s;\n' % friend)

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
            d.emitCImplementation(f, className, namespace)
    def emitConstructorImplementation(self, f, className, namespace):
        substitutions = {'namespace': namespace,
                         'className': className,
                         'initializers': ''}
        subinterfaces = []
        for d in self.decls:
            if d.__class__ == AST.Interface:
                subinterfaces.append(d.subinterfacename)
        if subinterfaces:
            substitutions['initializers'] = (', %s'
                                             % ', '.join([ '%s(p)' % i for i in subinterfaces]))
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
        if cid == 'Bit#':
            return 'unsigned int'
        elif cid == 'Action':
            return 'int'
        elif cid == 'ActionValue#':
            ## this is a Param but should be a Type
            return self.params[0].type.cName()
        cid = cid.replace('#', '_')
        if self.params:
            name = '%sL_%s_P' % (cid, '_'.join([cName(t) for t in self.params if t]))
        else:
            name = cid
        return name
    def isBitField(self):
        return self.name == 'Bit#'
    def bitWidth(self):
        if self.name == 'Bit#':
            return int(self.params[0])
        else:
            return 0
    
def cName(x):
    if type(x) == str:
        x = x.replace(' ', '')
        return x.replace('#', '_')
    else:
        return x.cName()

AST.Method.__bases__ += (MethodMixin,bsvgen.MethodMixin)
AST.StructMember.__bases__ += (StructMemberMixin,)
AST.Struct.__bases__ += (StructMixin,bsvgen.NullMixin)
AST.EnumElement.__bases__ += (EnumElementMixin,)
AST.Enum.__bases__ += (EnumMixin,bsvgen.NullMixin)
AST.Type.__bases__ += (TypeMixin,bsvgen.TypeMixin)
AST.Param.__bases__ += (ParamMixin,)
AST.Interface.__bases__ += (InterfaceMixin,bsvgen.InterfaceMixin)

if __name__=='__main__':
    newrt.printtrace = True
    s = open(sys.argv[1]).read() + '\n'
    s1 = syntax.parse('goal', s)
    print s1
    cppname = None
    if len(sys.argv) > 2:
        mainInterfaceName = os.path.basename(sys.argv[2])
    else:
        sys.exit(-1)
    h = open('%s.h' % sys.argv[2], 'w')
    cppname = '%s.cpp' % sys.argv[2]
    bsvname = '%sWrapper.bsv' % sys.argv[2]
    cpp = open(cppname, 'w')
    cpp.write('#include "ushw.h"\n')
    cpp.write('#include "%s.h"\n' % mainInterfaceName)
    bsv = open(bsvname, 'w')
    bsvgen.emitPreamble(bsv, sys.argv[1:])

    ## prepass
    for v in syntax.globaldecls:
        try:
            v.assignFriends()
        except:
            print 'no assignFriends', v
    ## code generation pass
    for v in syntax.globaldecls:
        print v.name
        print v.collectTypes()
        v.emitCDeclaration(h)
        v.emitCImplementation(cpp)
    if (syntax.globalvars.has_key(mainInterfaceName)):
        subinterface = syntax.globalvars[mainInterfaceName]
        subinterface.emitBsvImplementation(bsv)
    if cppname:
        srcdir = os.path.dirname(sys.argv[0]) + '/cpp'
        dstdir = os.path.dirname(cppname)
        for f in ['ushw.h', 'ushw.cpp']:
            shutil.copyfile(os.path.join(srcdir, f), os.path.join(dstdir, f))
