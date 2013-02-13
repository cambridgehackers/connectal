import syntax
import AST
import util

androidmk_template='''
LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := %(ClassName)s.cpp portal.cpp test%(classname)s.cpp
LOCAL_MODULE = test%(classname)s
LOCAL_MODULE_TAGS := optional
LOCAL_STATIC_LIBRARIES := libc libcutils liblog libstdc++

include $(BUILD_EXECUTABLE)
'''

classPrefixTemplate='''
class %(namespace)s%(className)s : public PortalInstance {
public:
    static %(className)s *create%(className)s(const char *instanceName);
'''
classSuffixTemplate='''
protected:
    void handleMessage(PortalMessage *msg);
private:
    %(className)s(const char *instanceName);
    ~%(className)s();
};
'''

creatorTemplate = '''
%(namespace)s%(className)s *%(namespace)s%(className)s::create%(className)s(const char *instanceName)
{
    %(namespace)s%(className)s *instance = new %(namespace)s%(className)s(instanceName);
    return instance;
}
'''
constructorTemplate='''
%(namespace)s%(className)s::%(className)s(const char *instanceName)
 : PortalInstance(instanceName)%(initializers)s
{
}
%(namespace)s%(className)s::~%(className)s()
{
    close();
}

'''

handleMessageTemplate='''
void %(namespace)s%(className)s::handleMessage(PortalMessage *msg)
{
    switch (msg->channel) {
%(responseCases)s
    default: break;
    }
}
'''

requestTemplate='''
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
    msg.size = sizeof(msg.request);
    msg.channelNumber = %(methodChannelOffset)s;
%(paramSetters)s
    sendMessage(&msg);
};
'''

responseTemplate='''
struct %(className)s%(methodName)sMSG : public PortalMessage
{
//fix Adapter.bsv to unreverse these
%(paramStructDeclarations)s
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
        if not self.params:
            f.write('virtual ')
        f.write('void %s ( ' % cName(self.name))
        #print parentClassName, self.name
        if self.params:
            f.write(', '.join([cName(p.type) for p in self.params]))
        else:
            f.write(resultTypeName)
        f.write(' )')
        if self.params:
            f.write(';\n')
        else:
            f.write('{ }\n')
    def emitCImplementation(self, f, className, namespace):
        params = self.params
        if not params:
            print 'no params', self.params
            print self.return_type
            params = [ AST.Param('result', self.return_type) ]
        paramDeclarations = [ '%s %s' % (p.type.cName(), p.name) for p in params]
        paramStructDeclarations = [ '        %s %s%s;\n' % (p.type.cName(), p.name, p.type.bitSpec()) for p in params]
        ## fix Adapter.bsv to eliminate the need for this reversal
        paramStructDeclarations.reverse()
        paramSetters = [ '    msg.request.%s = %s;\n' % (p.name, p.name) for p in params]
        resultTypeName = self.resultTypeName()
        substs = {
            'namespace': namespace,
            'className': className,
            'methodName': cName(self.name),
            'MethodName': capitalize(cName(self.name)),
            'paramDeclarations': ', '.join(paramDeclarations),
            'paramStructDeclarations': ''.join(paramStructDeclarations),
            'paramSetters': ''.join(paramSetters),
            'paramNames': ', '.join(['msg->%s' % p.name for p in params]),
            'resultType': resultTypeName,
            'methodChannelOffset': self.channelNumber
            }
        if self.params:
            f.write(requestTemplate % substs)
        else:
            f.write(responseTemplate % substs)

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
        f.write(classPrefixTemplate % {'className': name,
                                       'namespace': namespace})
        for d in self.decls:
            if d.type == 'Interface':
                continue
            d.emitCDeclaration(f, indentation + 4, name, namespace)
        f.write(classSuffixTemplate % {'className': name,
                                       'namespace': namespace})
        return
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
        substitutions = {'namespace': namespace,
                         'className': className,
                         'responseCases': ''.join([ '    case %d: %s(((%s%sMSG *)msg)->result); break;\n'
                                                   % (d.channelNumber, d.name, className, d.name)
                                                   for d in self.decls 
                                                   if d.type == 'Method' and not d.params])
                         }
        f.write(handleMessageTemplate % substitutions)

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
        return
    def writeAndroidMk(self, makename, silent=False):
        f = util.createDirAndOpen(makename, 'w')
        className = cName(self.name)
        substs = {
            'ClassName': className,
            'classname': className.lower()
        }
        f.write(androidmk_template % substs)
        f.close()

class ParamMixin:
    def cName(self):
        return self.name

class TypeMixin:
    def cName(self):
        cid = self.name
        cid = cid.replace(' ', '')
        if cid == 'Bit':
            print 'Bit', self.params[0]
            if self.params[0].numeric() <= 32:
                return 'unsigned long'
            elif self.params[0].numeric() <= 64:
                return 'unsigned long long'
            else:
                return 'std::bitset<%d>' % ((self.params[0].numeric() + 7) / 8)
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
