import os
import syntax
import AST
import util
import functools
import math

applicationmk_template='''
APP_STL                 := stlport_static
'''

androidmk_template='''
include $(CLEAR_VARS)
LOCAL_ARM_MODE := arm
APP_SRC_FILES := $(addprefix %(project_dir)s/jni/,  %(generatedCFiles)s) %(cfiles)s
PORTAL_SRC_FILES := $(addprefix %(xbsvdir)s/cpp/, portal.cpp PortalMemory.cpp sock_fd.cxx sock_utils.cxx)
LOCAL_SRC_FILES := $(APP_SRC_FILES) $(PORTAL_SRC_FILES)

LOCAL_PATH :=
LOCAL_MODULE := %(exe)s
LOCAL_MODULE_TAGS := optional
LOCAL_LDLIBS := -llog
LOCAL_CPPFLAGS := "-march=armv7-a"
LOCAL_CXXFLAGS := -DZYNQ -DMMAP_HW -I%(xbsvdir)s -I%(xbsvdir)s/cpp -I%(project_dir)s/jni

#NDK_OUT := obj/

include $(BUILD_EXECUTABLE)
'''

linuxmakefile_template='''
CFLAGS = -DMMAP_HW -O -g -I. -I%(xbsvdir)s/cpp -I%(xbsvdir)s %(sourceincludes)s

PORTAL_CPP_FILES = $(addprefix %(xbsvdir)s/cpp/, portal.cpp PortalMemory.cpp sock_fd.cxx sock_utils.cxx)


test%(classname)s: %(swProxies)s %(swWrappers)s $(PORTAL_CPP_FILES) %(source)s
	g++ $(CFLAGS) -o %(classname)s %(swProxies)s %(swWrappers)s $(PORTAL_CPP_FILES) %(source)s %(clibs)s -pthread 
'''


proxyClassPrefixTemplate='''
class %(namespace)s%(className)s : public %(parentClass)s {
//proxyClass
    %(statusDecl)s
public:
    %(className)s(int id, PortalPoller *poller = 0);
'''
proxyClassSuffixTemplate='''
};
'''

wrapperClassPrefixTemplate='''
class %(namespace)s%(className)s : public %(parentClass)s {
//wrapperClass
public:
    %(className)s(PortalInternal *p, PortalPoller *poller = 0);
    %(className)s(int id, PortalPoller *poller = 0);
'''
wrapperClassSuffixTemplate='''
protected:
    virtual int handleMessage(unsigned int channel);
};
'''

proxyConstructorTemplate='''
%(namespace)s%(className)s::%(className)s(int id, PortalPoller *poller)
 : %(parentClass)s(id)
{
    %(statusInstantiate)s
}
'''

wrapperConstructorTemplate='''
%(namespace)s%(className)s::%(className)s(PortalInternal *p, PortalPoller *poller)
 : %(parentClass)s(p, poller)
{}
%(namespace)s%(className)s::%(className)s(int id, PortalPoller *poller)
 : %(parentClass)s(id, poller)
{}
'''

putFailedMethodName = "putFailed"

putFailedTemplate='''
void %(namespace)s%(className)s::%(putFailedMethodName)s(uint32_t v){
    const char* methodNameStrings[] = {%(putFailedStrings)s};
    fprintf(stderr, "putFailed: %%s\\n", methodNameStrings[v]);
    //exit(1);
  }
'''

responseSzCaseTemplate='''
    case %(channelNumber)s: 
    { 
        %(msg)s msg;
        for (int i = (msg.size()/4)-1; i >= 0; i--) {
            volatile unsigned int *ptr = (volatile unsigned int*)(((long)ind_fifo_base) + channel * 256);
#ifdef MMAP_HW
            unsigned int val = *ptr;
#else
            unsigned int val = read_portal(p, ptr, name);
#endif
            buf[i] = val;
        }
        msg.demarshall(buf);
        msg.indicate(this);
        break;
    }
'''

handleMessageTemplate='''
int %(namespace)s%(className)s::handleMessage(unsigned int channel)
{    
    unsigned int buf[1024];
    static int runaway = 0;
    
    switch (channel) {
%(responseSzCases)s
    default:
        printf("%(namespace)s%(className)s::handleMessage: unknown channel 0x%%x\\n", channel);
        if (runaway++ > 10) {
            printf("%(namespace)s%(className)s::handleMessage: too many bogus indications, exiting\\n");
            exit(-1);
        }
        return 0;
    }
    return 0;
}
'''

proxyMethodTemplate='''
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
        int i = 0;
%(paramStructMarshall)s
    }
    void demarshall(unsigned int *buff){
        int i = 0;
%(paramStructDemarshall)s
    }
    void indicate(void *ind){ %(responseCase)s }
};
'''



def writeAndroidMk(cfiles, generatedCFiles, androidmkname, applicationmkname, xbsvdir, project_dir, silent=False):
        f = util.createDirAndOpen(androidmkname, 'w')
        substs = {
            'cfiles': ' '.join([os.path.abspath(x) for x in cfiles]),
	    'generatedCFiles': ' '.join(generatedCFiles),
            'xbsvdir': xbsvdir,
	    'project_dir': os.path.abspath(project_dir),
	    'exe' : 'android_exe'
        }
        f.write(androidmk_template % substs)
        f.close()
        f = util.createDirAndOpen(applicationmkname, 'w')
        f.write(applicationmk_template % substs)
        f.close()

def writeLinuxMk(base, linuxmkname, xbsvdir, sourcefiles, swProxies, swWrappers, clibs):
        f = util.createDirAndOpen(linuxmkname, 'w')
        className = cName(base)
        substs = {
            'ClassName': className,
            'classname': className.lower(),
            'xbsvdir': xbsvdir,
	    'swProxies': ' '.join(['%sProxy.cpp' % p.name for p in swProxies]),
	    'swWrappers': ' '.join(['%sWrapper.cpp' % w.name for w in swWrappers]),
            'source': ' '.join([os.path.abspath(sf) for sf in sourcefiles]) if sourcefiles else '',
            'sourceincludes': ' '.join(['-I%s' % os.path.dirname(os.path.abspath(sf)) for sf in sourcefiles]) if sourcefiles else '',
	    'clibs': ' '.join(['-l%s' % l for l in clibs])
        }
        f.write(linuxmakefile_template % substs)
        f.close()


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
        return [ 'const %s%s %s' % (p.type.cName(), p.type.refParam(), p.name) for p in params]
    def emitCDeclaration(self, f, proxy, indentation=0, namespace=''):
        indent(f, indentation)
        resultTypeName = self.resultTypeName()
        if (not proxy):
            f.write('virtual ')
        f.write('void %s ( ' % cName(self.name))
        f.write(', '.join(self.formalParameters(self.params)))
        f.write(' )')
	# ugly hack
        if ((not proxy) and (not (self.name == putFailedMethodName))):
            f.write('= 0;\n')
        else:
            f.write(';\n')
    def emitCImplementation(self, f, className, namespace, proxy):

        # resurse interface types and flattening all structs into a list of types
        def collectMembers(scope, member):
            t = member.type
            tn = member.type.name
            if tn == 'Bit':
                return [('%s.%s'%(scope,member.name),t)]
            elif tn == 'Int':
                return [('%s.%s'%(scope,member.name),t)]
            elif tn == 'Vector':
                return [('%s.%s'%(scope,member.name),t)]
            else:
                td = syntax.globalvars[tn]
                tdtype = td.tdtype
                if tdtype.type == 'Struct':
                    ns = '%s.%s' % (scope,member.name)
                    rv = map(functools.partial(collectMembers, ns), tdtype.elements)
                    return sum(rv,[])
                elif tdtype.type == 'Enum':
                    return [('%s.%s'%(scope,member.name),tdtype)]
                else:
                    return self.collectMembers(scope, tdtype.type)

        # pack flattened struct-member list into 32-bit wide bins.  If a type is wider than 32-bits or 
        # crosses a 32-bit boundary, it will appear in more than one bin (though with different ranges).  
        # This is intended to mimick exactly Bluespec struct packing.  The padding must match the code 
        # in Adapter.bsv.  the argument s is a list of bins, atoms is the flattened list, and pro represents
        # the number of bits already consumed from atoms[0].
        def accumWords(s, pro, atoms):
            if len(atoms) == 0:
                return [] if len(s) == 0 else [s]
            w = sum([x[1]-x[2] for x in s])
            a = atoms[0]
            aw = a[1].bitWidth();
            #print '%d %d %d' %(aw, pro, w)
            if (aw-pro+w == 32):
                ns = s+[(a[0],aw,pro,a[1],pro==0)]
                #print '%s (0)'% (a[0])
                return [ns]+accumWords([],0,atoms[1:])
            if (aw-pro+w < 32):
                ns = s+[(a[0],aw,pro,a[1],pro==0)]
                #print '%s (1)'% (a[0])
                return accumWords(ns,0,atoms[1:])
            else:
                ns = s+[(a[0],pro+(32-w),pro,a[1],pro==0)]
                #print '%s (2)'% (a[0])
                return [ns]+accumWords([],pro+(32-w), atoms)

        params = self.params
        paramDeclarations = self.formalParameters(params)
        paramStructDeclarations = [ '        %s %s%s;\n' % (p.type.cName(), p.name, p.type.bitSpec()) for p in params]
        
        argAtoms = sum(map(functools.partial(collectMembers, 'payload'), params), [])

        # for a in argAtoms:
        #     print a[0]
        # print ''

        argAtoms.reverse();
        argWords  = accumWords([], 0, argAtoms)

        # for a in argWords:
        #     for b in a:
        #         print '%s[%d:%d]' % (b[0], b[1], b[2])
        # print ''

        def marshall(w):
            off = 0
            word = []
            for e in w:
                field = e[0];
                if e[2]:
                    field = '(%s>>%s)' % (field, e[2])
                if off:
                    field = '(%s<<%s)' % (field, off)
                if e[3].bitWidth() > 64:
                    field = '(const %s & std::bitset<%d>(0xFFFFFFFF)).to_ulong()' % (field, e[3].bitWidth())
                word.append(field)
                off = off+e[1]-e[2]
            return '        buff[i++] = %s;\n' % (''.join(util.intersperse('|', word)))

        def demarshall(w):
            off = 0
            word = []
            for e in w:
                # print e[0]+' (d)'
                ass = '=' if e[4] else '|='
                field = 'buff[i]'
                if off:
                    field = '(%s>>%s)' % (field, off)
                field = '(%s&0x%xul)' % (field, ((1 << e[3].bitWidth())-1))
                if e[2]:
                    field = '((%s)%s<<%s)' % (e[3].cName(),field, e[2])
                word.append('        %s %s (%s)%s;\n'%(e[0],ass,e[3].cName(),field))
                off = off+e[1]-e[2]
            word.append('        i++;\n');
            # print ''
            return ''.join(word)

        paramStructMarshall = map(marshall, argWords)
        paramStructDemarshall = map(demarshall, argWords)

        if not params:
            paramStructDeclarations = ['        int padding;\n']
        paramSetters = [ '    msg.payload.%s = %s;\n' % (p.name, p.name) for p in params]
        resultTypeName = self.resultTypeName()
        substs = {
            'namespace': namespace,
            'className': className,
            'methodName': cName(self.name),
            'MethodName': capitalize(cName(self.name)),
            'paramDeclarations': ', '.join(paramDeclarations),
            'paramStructDeclarations': ''.join(paramStructDeclarations),
            'paramStructMarshall': ''.join(paramStructMarshall),
            'paramStructDemarshall': ''.join(paramStructDemarshall),
            'paramSetters': ''.join(paramSetters),
            'paramNames': ', '.join(['msg->%s' % p.name for p in params]),
            'resultType': resultTypeName,
            'methodChannelOffset': self.channelNumber,
            # if message is empty, we still send an int of padding
            'payloadSize' : max(4, 4*((sum([p.numBitsBSV() for p in self.params])+31)/32)) 
            }
        if (not proxy):
            substs['responseCase'] = ('((%(className)s *)ind)->%(name)s(%(params)s);\n'
                                      % { 'name': self.name,
                                          'className' : className,
                                          'params': ', '.join(['payload.%s' % (p.name) for p in self.params])})
            f.write(msgTemplate % substs)
        else:
            substs['responseCase'] = 'assert(false);'
            f.write(msgTemplate % substs)
            f.write(proxyMethodTemplate % substs)


class StructMemberMixin:
    def emitCDeclaration(self, f, indentation=0, namespace=''):
        indent(f, indentation)
        f.write('%s %s' % (self.type.cName(), self.name))
        if self.type.isBitField():
            f.write(' : %d' % self.type.bitWidth())
        f.write(';\n')

class TypeDefMixin:
    def emitCDeclaration(self,f,indentation=0, namespace=''):
        if self.tdtype.type == 'Struct' or self.tdtype.type == 'Enum':
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
        for e in self.elements:
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
    def cName(self):
        return self.name
    def collectTypes(self):
        result = [self]
        return result
    def emitCDeclaration(self, name, f, indentation=0, namespace=''):
        indent(f, indentation)
        if (indentation == 0):
            f.write('typedef ')
        f.write('enum %s { ' % name)
        indent(f, indentation)
        f.write(', '.join(['%s_%s' % (name, e) for e in self.elements]))
        indent(f, indentation)
        f.write(' }')
        if (indentation == 0):
            f.write(' %s;' % name)
        f.write('\n')
    def emitCImplementation(self, f, className='', namespace=''):
        pass
    def bitWidth(self):
        return int(math.ceil(math.log(len(self.elements))))

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
    def insertPutFailedMethod(self):
        meth_name = putFailedMethodName
        meth_type = AST.Type("Action",[])
        meth_formal_params = [AST.Param("v", AST.Type("Bit",[AST.Type(32,[])]))]
        self.decls = self.decls + [AST.Method(meth_name, meth_type, meth_formal_params)]
    def assignRequestResponseChannels(self, channelNumber=0):
        for d in self.decls:
            if d.__class__ == AST.Method:
                d.channelNumber = channelNumber
                channelNumber = channelNumber + 1
        self.channelCount = channelNumber
    def parentClass(self, default):
        rv = default if (len(self.typeClassInstances)==0) else (self.typeClassInstances[0])
        return rv
    def hasPutFailed(self):
	rv = True in [d.name == putFailedMethodName for d in self.decls]
	return rv
    def emitCProxyDeclaration(self, f, suffix, indentation=0, namespace=''):
        className = "%s%s" % (cName(self.name), suffix)
        statusDecl = "%s%s *proxyStatus;" % (cName(self.name), 'ProxyStatus')
        subs = {'className': className,
                'namespace': namespace,
		'statusDecl' : '' if self.hasPutFailed() else statusDecl,
                'parentClass': self.parentClass('PortalInternal')}
        f.write(proxyClassPrefixTemplate % subs)
        for d in self.decls:
            d.emitCDeclaration(f, True, indentation + 4, namespace)
        f.write(proxyClassSuffixTemplate % subs)
    def emitCWrapperDeclaration(self, f, suffix, indentation=0, namespace=''):
        className = "%s%s" % (cName(self.name), suffix)
        indent(f, indentation)
        subs = {'className': className,
                'namespace': namespace,
                'parentClass': self.parentClass('Portal')}
        f.write(wrapperClassPrefixTemplate % subs)
        for d in self.decls:
            d.emitCDeclaration(f, False, indentation + 4, namespace)
        f.write(wrapperClassSuffixTemplate % subs)
    def emitCProxyImplementation(self, f,  suffix, namespace=''):
        className = "%s%s" % (cName(self.name), suffix)
	statusName = "%s%s" % (cName(self.name), 'ProxyStatus')
	statusInstantiate = '' if self.hasPutFailed() else 'proxyStatus = new %s(this, poller);\n' % statusName
        substitutions = {'namespace': namespace,
                         'className': className,
			 'statusInstantiate' : statusInstantiate,
                         'parentClass': self.parentClass('PortalInternal')}
        f.write(proxyConstructorTemplate % substitutions)
        for d in self.decls:
            d.emitCImplementation(f, className, namespace,True)
    def emitCWrapperImplementation (self, f,  suffix, namespace=''):
        className = "%s%s" % (cName(self.name), suffix)
        emitPutFailed = self.hasPutFailed()
        substitutions = {'namespace': namespace,
                         'className': className,
			 'putFailedMethodName' : putFailedMethodName,
                         'parentClass': self.parentClass('Portal'),
                         'responseSzCases': ''.join([responseSzCaseTemplate % { 'channelNumber': d.channelNumber,
                                                                                'msg': '%s%sMSG' % (className, d.name)}
                                                     for d in self.decls 
                                                     if d.type == 'Method' and d.return_type.name == 'Action']),
                         'putFailedStrings': '' if (not emitPutFailed) else ', '.join('"%s"' % (d.name) for d in self.req.decls if d.__class__ == AST.Method )}
        f.write(wrapperConstructorTemplate % substitutions)
        for d in self.decls:
            d.emitCImplementation(f, className, namespace, False);
        if emitPutFailed:
            f.write(putFailedTemplate % substitutions)
        f.write(handleMessageTemplate % substitutions)


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
                return 'uint32_t'
            elif self.params[0].numeric() <= 64:
                return 'uint64_t'
            else:
                return 'std::bitset<%d>' % (self.params[0].numeric())
        elif cid == 'Int':
            if self.params[0].numeric() == 32:
                return 'int'
            else:
                assert(False)
        elif cid == 'Vector':
            return 'bsvvector<%d,%s>' % (self.params[0].numeric(), self.params[1].cName())
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
        return self.name == 'Bit' or self.name == 'Int'
    def bitWidth(self):
        if self.name == 'Bit' or self.name == 'Int':
            return int(self.params[0].name)
        else:
            return 0
    def bitSpec(self):
        if self.isBitField():
            bw = self.bitWidth()
            if bw <= 64:
                return ':%d' % bw
            else:
                ## not compatible with use of std::bitset
                return ''
        return ''

def cName(x):
    if type(x) == str:
        x = x.replace(' ', '')
        x = x.replace('.', '$')
        return x
    else:
        return x.cName()
