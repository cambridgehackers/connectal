import syntax
import AST
import util

applicationmk_template='''
APP_STL                 := stlport_static
'''

androidmk_template='''
LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_ARM_MODE := arm
LOCAL_SRC_FILES := %(ClassName)s.cpp portal.cpp test%(classname)s.cpp
LOCAL_MODULE = test%(classname)s
LOCAL_MODULE_TAGS := optional
LOCAL_LDLIBS := -llog
LOCAL_CPPFLAGS := "-march=armv7-a"
LOCAL_CXXFLAGS := -DZYNQ -DMMAP_HW

include $(BUILD_EXECUTABLE)
'''

linuxmakefile_template='''
CFLAGS = -DMMAP_HW -O -g -I. -I../../cpp

test%(classname)s: %(ClassName)s.cpp ../../cpp/portal.cpp ../../examples/%(classname)s/test%(classname)s.cpp
	g++ $(CFLAGS) -o %(classname)s %(ClassName)s.cpp ../../cpp/portal.cpp ../../examples/%(classname)s/test%(classname)s.cpp -pthread
'''


classPrefixTemplate='''
class %(namespace)s%(className)s : public %(parentClass)s {
public:
    static %(className)s *create%(className)s(%(indicationName)s *indication);
    static void methodName(unsigned long v, char *dst);
'''
classSuffixTemplate='''
protected:
    %(className)s(const char *instanceName, %(indicationName)s *indication);
    ~%(className)s();
};
'''

indicationClassPrefixTemplate='''
class %(namespace)s%(className)s : public %(parentClass)s {
public:
    %(className)s();
    virtual ~%(className)s();
'''
indicationClassSuffixTemplate='''
protected:
#ifdef MMAP_HW
    virtual int handleMessage(unsigned int channel, volatile unsigned int* ind_fifo_base);
#else
    virtual int handleMessage(unsigned int channel, PortalRequest* instance);
#endif
    friend class PortalRequest;
};
'''


creatorTemplate = '''
%(namespace)s%(className)s *%(namespace)s%(className)s::create%(className)s(%(indicationName)s *indication)
{
#ifdef ZYNQ
    const char *instanceName = \"fpga%(portalNum)s\"; 
#else
    const char *instanceName = \"bluenoc_1\"; 
#endif
    %(namespace)s%(className)s *instance = new %(namespace)s%(className)s(instanceName, indication);
    return instance;
}
'''

methodNameTemplate = '''

void %(namespace)s%(className)s::methodName(unsigned long idx, char* dst)
{
   const char* methodNameStrings[] = {%(methodNames)s};
   const char* src = methodNameStrings[idx];
   strcpy(dst, src);
}
'''

constructorTemplate='''
%(namespace)s%(className)s::%(className)s(const char *instanceName, %(indicationName)s *indication)
 : %(parentClass)s(instanceName, indication)%(initializers)s
{
}
%(namespace)s%(className)s::~%(className)s()
{
    close();
}
'''

indicationConstructorTemplate='''
%(namespace)s%(className)s::%(className)s()
{
}
%(namespace)s%(className)s::~%(className)s()
{
}
'''

putFailedTemplate='''
void %(namespace)s%(className)s::putFailed(unsigned long v){
    char buff[100];
    %(instName)s::methodName(v, buff);
    fprintf(stderr, "putFailed: %%s\\n", buff);
    exit(1);
  }
'''

handleMessageTemplate='''
#ifdef MMAP_HW
int %(namespace)s%(className)s::handleMessage(unsigned int channel, volatile unsigned int* ind_fifo_base)
{    
    unsigned int buf[1024];
    memset(buf, 0, 1024);
    PortalMessage *msg = 0x0;
    
    switch (channel) {
%(responseSzCases)s
    }

    // mutex_lock(&portal_data->reg_mutex);
    // mutex_unlock(&portal_data->reg_mutex);
    for (int i = (msg->size()/4)-1; i >= 0; i--) {
        unsigned int val = *((volatile unsigned int*)(((unsigned long)ind_fifo_base) + channel * 256));
        buf[i] = val;
        //fprintf(stderr, "%%08x\\n", val);
    }
    msg->demarshall(buf);
    msg->indicate(this);
    delete msg;
    return 0;
}
#else
int %(namespace)s%(className)s::handleMessage(unsigned int channel, PortalRequest* instance)
{    
    unsigned int buf[1024];
    memset(buf, 0, 1024);
    PortalMessage *msg = 0x0;
    
    switch (channel) {
%(responseSzCases)s
    }

    for (int i = (msg->size()/4)-1; i >= 0; i--) {
	unsigned long addr = instance->ind_fifo_base + (channel * 256);
	struct memrequest foo = {false,addr,0};
        //fprintf(stderr, "xxx %%08x\\n", addr);
	if (send(instance->p.read.s2, &foo, sizeof(foo), 0) != sizeof(foo)) {
	  fprintf(stderr, "(%%s) send error\\n", instance->instanceName);
	  exit(1);
	}
        unsigned int val;
	if(recv(instance->p.read.s2, &val, sizeof(val), 0) != sizeof(val)){
	  fprintf(stderr, "(%%s) recv error\\n", instance->instanceName);
	  exit(1);	  
	}
        //fprintf(stderr, "%%08x\\n", val);
        buf[i] = val;
    }
    msg->demarshall(buf);
    msg->indicate(this);
    delete msg;
    return 0;
}
#endif

'''

requestTemplate='''
void %(namespace)s%(className)s::%(methodName)s ( %(paramDeclarations)s )
{
    %(className)s%(methodName)sMSG msg;
    msg.channel = %(methodChannelOffset)s;
%(paramSetters)s
    sendMessage(&msg);
};
'''

msgTemplate='''
class %(className)s%(methodName)sMSG : public PortalMessage
{
public:
    struct {
%(paramStructDeclarations)s
    } payload;
    size_t size(){return %(payloadSize)s;}
    void marshall(unsigned int *buff) {
        memcpy(buff,&payload,sizeof(payload));
    }
    void demarshall(unsigned int *buff){
        memcpy(&payload,buff,sizeof(payload));
    }
    void indicate(void *ind){ %(responseCase)s }
};
'''



def indent(f, indentation):
    for i in xrange(indentation):
        f.write(' ')

def capitalize(s):
    return '%s%s' % (s[0].upper(), s[1:])

class NoCMixin:
    def emitCDeclaration(self, f, indentation=0, namespace=''):
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
    def formalParameters(self, params):
        return [ '%s%s %s' % (p.type.cName(), p.type.refParam(), p.name) for p in params]
    def emitCDeclaration(self, f, indentation=0, namespace=''):
        indent(f, indentation)
        resultTypeName = self.resultTypeName()
        if self.isIndication:
            f.write('virtual ')
        f.write('void %s ( ' % cName(self.name))
        f.write(', '.join(self.formalParameters(self.params)))
        f.write(' )')
        if (self.isIndication and not self.aug):
            f.write('= 0;\n')
        else:
            f.write(';\n')
    def emitCImplementation(self, f, className, namespace):
        params = self.params
        paramDeclarations = self.formalParameters(params)
        paramStructDeclarations = [ '        %s %s%s;\n' % (p.type.cName(), p.name, p.type.bitSpec()) for p in params]
        if not params:
            paramStructDeclarations = ['        int padding;\n']
        # reversing order for bsv/c++ compatability
        paramStructDeclarations.reverse()
        paramSetters = [ '    msg.payload.%s = %s;\n' % (p.name, p.name) for p in params]
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
            'methodChannelOffset': self.channelNumber,
            # if message is empty, we still send an int of padding
            'payloadSize' : max(4, 4*((sum([p.numBitsBSV() for p in self.params])+31)/32)) 
            }
        if not self.isIndication:
            substs['responseCase'] = 'assert(false);'
            f.write(msgTemplate % substs)
            f.write(requestTemplate % substs)
        else:
            substs['responseCase'] = ('((%(className)s *)ind)->%(name)s(%(params)s);\n'
                                      % { 'name': self.name,
                                          'className' : className,
                                          'params': ', '.join(['payload.%s' % (p.name) for p in self.params])})
            f.write(msgTemplate % substs)


class StructMemberMixin:
    def emitCDeclaration(self, f, indentation=0, namespace=''):
        indent(f, indentation)
        f.write('%s %s' % (self.type.cName(), self.tag))
        #print 'emitCDeclaration: ', self.type, self.type.isBitField, self.type.cName(), self.tag
        if self.type.isBitField():
            f.write(' : %d' % self.type.bitWidth())
        f.write(';\n')

class TypeDefMixin:
    def emitCDeclaration(self,f,indentation=0, namespace=''):
        if self.tdtype.type == 'Struct':
            self.tdtype.emitCDeclaration(self.name,f,indentation,namespace)

class StructMixin:
    def collectTypes(self):
        result = [self]
        result.append(self.elements)
        return result
    def emitCDeclaration(self, name, f, indentation=0, namespace=''):
        indent(f, indentation)
        if (indentation == 0):
            f.write('typedef ')
        f.write('struct %s {\n' % name)
        for e in reversed(self.elements):
            e.emitCDeclaration(f, indentation+4)
        indent(f, indentation)
        f.write('}')
        if (indentation == 0):
            f.write(' %s;' % name)
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
    def emitCDeclaration(self, f, indentation=0, namespace=''):
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
    def insertPutErrorMethod(self):
        meth_name = "putFailed"
        meth_type = AST.Type("Action",[])
        meth_formal_params = [AST.Param("v", AST.Type("Bit",[AST.Type(32,[])]))]
        self.decls = self.decls + [AST.Method(meth_name, meth_type, meth_formal_params,True)]
    def assignRequestResponseChannels(self, channelNumber=0):
        for d in self.decls:
            if d.__class__ == AST.Method:
                d.channelNumber = channelNumber
                channelNumber = channelNumber + 1
        self.channelCount = channelNumber
    def emitCDeclaration(self, f, indentation=0, namespace=''):
        self.toplevel = (indentation == 0)
        name = cName(self.name)
        indent(f, indentation)
        subs = {'className': name,
                'namespace': namespace,
                'portalNum': self.portalNum}
        if self.isIndication:
            prefixTemplate = indicationClassPrefixTemplate
            suffixTemplate= indicationClassSuffixTemplate
            subs['parentClass'] =  'PortalIndication'
        else:
            prefixTemplate = classPrefixTemplate
            suffixTemplate = classSuffixTemplate
            subs['indicationName'] = self.ind.name
            subs['parentClass'] =  'PortalRequest' if (len(self.typeClassInstances)==0) else (self.typeClassInstances[0])
        f.write(prefixTemplate % subs)
        for d in self.decls:
            if d.type == 'Interface':
                continue
            d.isIndication = self.isIndication
            d.emitCDeclaration(f, indentation + 4, namespace)
        f.write(suffixTemplate % subs)
        return
    def emitCImplementation(self, f, namespace=''):
        className = cName(self.name)
        self.emitConstructorImplementation(f, className, namespace)
        for d in self.decls:
            if d.type == 'Interface':
                continue
            d.emitCImplementation(f, className, namespace)

        substitutions = {'namespace': namespace,
                         'className': className,
                         # this is a horrible hack (mdk)
                         'instName' : className.replace('Indication', 'Request'),
                         'responseSzCases': ''.join(['    case %(channelNumber)s: { msg = new %(msg)s(); break; }\n'
                                                     % { 'channelNumber': d.channelNumber,
                                                         'msg': '%s%sMSG' % (className, d.name)}
                                                     for d in self.decls 
                                                     if d.type == 'Method' and d.return_type.name == 'Action'
                                                     ])
                         }



        if self.isIndication:
            f.write(handleMessageTemplate % substitutions)
            f.write(putFailedTemplate % substitutions)

    def emitConstructorImplementation(self, f, className, namespace):
        substitutions = {'namespace': namespace,
                         'className': className,
                         'portalNum': self.portalNum,
                         'initializers': '',
                         'methodNames': ', '.join('"%s"' % (d.name) for d in self.decls if d.__class__ == AST.Method )}
        subinterfaces = []
        for d in self.decls:
            if d.__class__ == AST.Interface:
                subinterfaces.append(d.subinterfacename)
        ## not generating code for subinterfaces for now
        ## if subinterfaces:
        ##     substitutions['initializers'] = (', %s'
        ##                                      % ', '.join([ '%s(p)' % i for i in subinterfaces]))
        if self.toplevel:
            if not self.isIndication:
                substitutions['indicationName'] = self.ind.name
                f.write(creatorTemplate % substitutions)
                f.write(methodNameTemplate % substitutions)
        if self.isIndication:
            f.write(indicationConstructorTemplate % substitutions)
        else:
            substitutions['parentClass'] =  'PortalRequest' if (len(self.typeClassInstances)==0) else (self.typeClassInstances[0])
            f.write(constructorTemplate % substitutions)
        return
    def writeAndroidMk(self, androidmkname, applicationmkname, silent=False):
        f = util.createDirAndOpen(androidmkname, 'w')
        className = cName(self.base)
        substs = {
            'ClassName': className,
            'classname': className.lower()
        }
        f.write(androidmk_template % substs)
        f.close()
        f = util.createDirAndOpen(applicationmkname, 'w')
        className = cName(self.name)
        f.write(applicationmk_template % substs)
        f.close()
    def writeLinuxMk(self, linuxmkname, silent=False):
        f = util.createDirAndOpen(linuxmkname, 'w')
        className = cName(self.base)
        substs = {
            'ClassName': className,
            'classname': className.lower()
        }
        f.write(linuxmakefile_template % substs)
        f.close()

class ParamMixin:
    def cName(self):
        return self.name
    def emitCDeclaration(self, f, indentation=0, namespace=''):
        indent(f, indentation)
        f.write('s %s' % (self.type, self.name))

class TypeMixin:
    def refParam(self):
        if (self.isBitField() and self.bitWidth() <= 64):
            return ''
        else:
            return '&'
    def cName(self):
        cid = self.name
        cid = cid.replace(' ', '')
        if cid == 'Bit':
            if self.params[0].numeric() <= 32:
                return 'unsigned long'
            elif self.params[0].numeric() <= 64:
                return 'unsigned long long'
            else:
                return 'std::bitset<%d>' % (self.params[0].numeric())
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
