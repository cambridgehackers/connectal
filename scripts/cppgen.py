##
## Copyright (C) 2013 Nokia, Inc
## Copyright (c) 2013-2014 Quanta Research Cambridge, Inc.

## Permission is hereby granted, free of charge, to any person
## obtaining a copy of this software and associated documentation
## files (the "Software"), to deal in the Software without
## restriction, including without limitation the rights to use, copy,
## modify, merge, publish, distribute, sublicense, and/or sell copies
## of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:

## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.

## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
## BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
## ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
## CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
## SOFTWARE.

import os
import sys
import traceback
import globalv
import AST
import util
import functools
import math

def dtInfo(name, cName, bitWidth, params):
    rc = {}
    rc['name'] = name
    rc['cName'] = cName
    rc['bitWidth'] = bitWidth
    rc['params'] = params
    return rc

sizeofUint32_t = 4

proxyClassPrefixTemplate='''
class %(className)sProxy : public %(parentClass)s {
public:
    %(className)sProxy(int id, PortalPoller *poller = 0) : Portal(id, %(className)s_reqsize, NULL, NULL, poller) {};
    %(className)sProxy(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : Portal(id, %(className)s_reqsize, NULL, NULL, item, param, poller) {};
'''

wrapperClassPrefixTemplate='''
extern %(className)sCb %(className)s_cbTable;
class %(className)sWrapper : public %(parentClass)s {
public:
    %(className)sWrapper(int id, PortalPoller *poller = 0) : Portal(id, %(className)s_reqsize, %(className)s_handleMessage, (void *)&%(className)s_cbTable, poller) {
        pint.parent = static_cast<void *>(this);
    };
    %(className)sWrapper(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : Portal(id, %(className)s_reqsize, %(className)s_handleMessage, (void *)&%(className)s_cbTable, item, param, poller) {
        pint.parent = static_cast<void *>(this);
    };
'''

handleMessageTemplateDecl='''
int %(className)s_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)'''

handleMessageTemplate1='''
{
    static int runaway = 0;
    int tmpfd;
    unsigned int tmp;
    volatile unsigned int* temp_working_addr = p->item->mapchannelInd(p, channel);
    switch (channel) {'''

handleMessageCase='''
    case %(channelNumber)s:
        {
        p->item->recv(p, temp_working_addr, %(wordLen)s, &tmpfd);
        %(paramStructDeclarations)s
        %(paramStructDemarshall)s
        %(responseCase)s
        }
        break;'''

handleMessageTemplate2='''
    default:
        PORTAL_PRINTF("%(className)s_handleMessage: unknown channel 0x%%x\\n", channel);
        if (runaway++ > 10) {
            PORTAL_PRINTF("%(className)s_handleMessage: too many bogus indications, exiting\\n");
#ifndef __KERNEL__
            exit(-1);
#endif
        }
        return 0;
    }
    return 0;
}
'''

proxyMethodTemplateDecl='''
void %(className)s_%(methodName)s (%(paramProxyDeclarations)s )'''

proxyMethodTemplate='''
{
    volatile unsigned int* temp_working_addr = p->item->mapchannelReq(p, %(channelNumber)s);
    if (p->item->busywait(p, temp_working_addr, "%(className)s_%(methodName)s")) return;
    %(paramStructMarshall)s
    p->item->send(p, (%(channelNumber)s << 16) | %(wordLenP1)s, %(fdName)s);
};
'''

def indent(f, indentation):
    for i in xrange(indentation):
        f.write(' ')

class NoCMixin:
    def emitCDeclaration(self, f, indentation):
        pass

class MethodMixin:
    def collectTypes(self):
        result = [self.return_type]
        result.append(AST.Type('Tuple', self.params))
        return result

class StructMemberMixin:
    def emitCDeclaration(self, f, indentation):
        indent(f, indentation)
        f.write('%s %s' % (self.type.cName(), self.name))
        if self.type.isBitField():
            f.write(' : %d' % self.type.bitWidth())
        f.write(';\n')

class TypeDefMixin:
    def emitCDeclaration(self,f,indentation):
        #print 'TypeDefMixin.emitCdeclaration', self.tdtype.type, self.name, self.tdtype
        if self.tdtype.type == 'Struct' or self.tdtype.type == 'Enum':
            self.tdtype.emitCDeclaration(self.name,f,indentation)
        elif self.name == 'SpecialTypeForSendingFd':
            pass
        elif False and self.tdtype.type == 'Type':
            tdtype = self.tdtype
            #print 'resolving', tdtype.type, tdtype
            while tdtype.type == 'Type' and globalv.globalvars.has_key(tdtype.name):
                td = globalv.globalvars[tdtype.name]
                tdtype = td.tdtype.instantiate(dict(zip(td.params, tdtype.params)))
                #print 'resolved to', tdtype.type, tdtype
            if tdtype.type != 'Type':
                #print 'emitting declaration'
                tdtype.emitCDeclaration(self.name,f,indentation)

class StructMixin:
    def collectTypes(self):
        result = [self]
        result.append(self.elements)
        return result
    def emitCDeclaration(self, name, f, indentation):
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

class EnumElementMixin:
    def cName(self):
        return self.name

class EnumMixin:
    def cName(self):
        return self.name
    def collectTypes(self):
        return [self]
    def emitCDeclaration(self, name, f, indentation):
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
    def bitWidth(self):
        return int(math.ceil(math.log(len(self.elements))))

class InterfaceMixin:
    def collectTypes(self):
        return [d.collectTypes() for d in self.decls]
    def getSubinterface(self, name):
        subinterfaceName = name
        if not globalv.globalvars.has_key(subinterfaceName):
            return None
        subinterface = globalv.globalvars[subinterfaceName]
        #print 'subinterface', subinterface, subinterface
        return subinterface
    def assignRequestResponseChannels(self, channelNumber=0):
        for d in self.decls:
            if d.__class__ == AST.Method:
                d.channelNumber = channelNumber
                channelNumber = channelNumber + 1
        self.channelCount = channelNumber
    def parentClass(self, default):
        rv = default if (len(self.typeClassInstances)==0) else (self.typeClassInstances[0])
        return rv
    def global_name(self, s, suffix):
        return '%s%s_%s' % (cName(self.name), suffix, s)

class ParamMixin:
    def cName(self):
        return self.name
    def emitCDeclaration(self, f, indentation):
        indent(f, indentation)
        f.write('s %s' % (self.type, self.name))

class TypeMixin:
    def cName(self):
        cid = self.name.replace(' ', '')
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
        elif cid == 'UInt':
            if self.params[0].numeric() == 32:
                return 'unsigned int'
            else:
                assert(False)
        elif cid == 'Float':
            return 'float'
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
        return self.name == 'Bit' or self.name == 'Int' or self.name == 'UInt'
    def bitWidth(self):
        if self.name == 'Bit' or self.name == 'Int' or self.name == 'UInt':
            width = self.params[0].name
            while globalv.globalvars.has_key(width):
                decl = globalv.globalvars[width]
                if decl.type != 'TypeDef':
                    break
                print 'Resolving width', width, decl.tdtype
                width = decl.tdtype.name
            return int(width)
        if self.name == 'Float':
            return 32
        else:
            return 0

def cName(x):
    if type(x) == str:
        x = x.replace(' ', '')
        x = x.replace('.', '$')
        return x
    else:
        return x.cName()

class paramInfo:
    def __init__(self, name, width, shifted, datatype, assignOp):
        self.name = name
        self.width = width
        self.shifted = shifted
        self.datatype = datatype
        self.assignOp = assignOp

# resurse interface types and flattening all structs into a list of types
def collectMembers(scope, pitem):
    membtype = dtInfo(pitem['type'].name, pitem['type'].cName(), pitem['type'].bitWidth(), pitem['type'].params)
    while 1:
        if membtype['name'] == 'Bit':
            return [('%s%s'%(scope,pitem['name']),membtype)]
        elif membtype['name'] == 'Int' or membtype['name'] == 'UInt':
            return [('%s%s'%(scope,pitem['name']),membtype)]
        elif membtype['name'] == 'Float':
            return [('%s%s'%(scope,pitem['name']),membtype)]
        elif membtype['name'] == 'Vector':
            return [('%s%s'%(scope,pitem['name']),membtype)]
        elif membtype['name'] == 'SpecialTypeForSendingFd':
            return [('%s%s'%(scope,pitem['name']),membtype)]
        else:
            td = globalv.globalvars[membtype['name']]
            #print 'instantiate', membtype['params']
            tdtype = td.tdtype.instantiate(dict(zip(td.params, membtype['params'])))
            #print '           ', membtype
            if tdtype.type == 'Struct':
                ns = '%s%s.' % (scope,pitem['name'])
                rv = map(functools.partial(collectMembers, ns), tdtype.elements)
                return sum(rv,[])
            membtype = dtInfo(tdtype.name, tdtype.cName(), tdtype.bitWidth(), tdtype.params if tdtype.type == 'Type' else None)
            if tdtype.type == 'Enum':
                return [('%s%s'%(scope,pitem['name']),membtype)]
            #print 'resolved to type', membtype['type'], membtype['name'], membtype

# pack flattened struct-member list into 32-bit wide bins.  If a type is wider than 32-bits or
# crosses a 32-bit boundary, it will appear in more than one bin (though with different ranges).
# This is intended to mimick exactly Bluespec struct packing.  The padding must match the code
# in Adapter.bsv.  the argument s is a list of bins, atoms is the flattened list, and pro represents
# the number of bits already consumed from atoms[0].
def accumWords(s, pro, memberList):
    if len(memberList) == 0:
        if len(s) == 0:
             return []
        else:
             return [s]
    w = sum([x.width-x.shifted for x in s])
    mitem = memberList[0]
    name = mitem[0]
    thisType = mitem[1]
    aw = thisType['bitWidth']
    #print '%d %d %d' %(aw, pro, w)
    if (aw-pro+w == 32):
        s.append(paramInfo(name,aw,pro,thisType,'='))
        #print '%s (0)'% (name)
        return [s]+accumWords([],0,memberList[1:])
    if (aw-pro+w < 32):
        s.append(paramInfo(name,aw,pro,thisType,'='))
        #print '%s (1)'% (name)
        return accumWords(s,0,memberList[1:])
    else:
        s.append(paramInfo(name,pro+(32-w),pro,thisType,'|='))
        #print '%s (2)'% (name)
        return [s]+accumWords([],pro+(32-w), memberList)

def generate_marshall(pfmt, w):
    global fdName
    off = 0
    word = []
    fmt = pfmt
    for e in w:
        field = e.name
        if e.datatype['cName'] == 'float':
            return pfmt % ('*(int*)&' + e.name)
        if e.shifted:
            field = '(%s>>%s)' % (field, e.shifted)
        if off:
            field = '(%s<<%s)' % (field, off)
        if e.datatype['bitWidth'] > 64:
            field = '(const %s & std::bitset<%d>(0xFFFFFFFF)).to_ulong()' % (field, e.datatype['bitWidth'])
        word.append(field)
        off = off+e.width-e.shifted
        if e.datatype['cName'] == 'SpecialTypeForSendingFd':
            fdName = field
            fmt = 'p->item->writefd(p, &temp_working_addr, %s);'
    return fmt % (''.join(util.intersperse('|', word)))

def generate_demarshall(fmt, w):
    off = 0
    word = []
    word.append(fmt)
    for e in w:
        # print e.name+' (d)'
        field = 'tmp'
        if e.datatype['cName'] == 'float':
            word.append('%s = *(float*)&(%s);'%(e.name,field))
            continue
        if off:
            field = '%s>>%s' % (field, off)
        #print 'JJJ', e.name, '{{'+field+'}}', e.datatype['bitWidth'], e.shifted, e.assignOp, off
        #if e.datatype['bitWidth'] < 32:
        field = '((%s)&0x%xul)' % (field, ((1 << (e.datatype['bitWidth']-e.shifted))-1))
        if e.shifted:
            field = '((%s)(%s)<<%s)' % (e.datatype['cName'],field, e.shifted)
        if e.datatype['cName'] == 'SpecialTypeForSendingFd':
            word.append('%s %s messageFd;'%(e.name, e.assignOp))
        else:
            word.append('%s %s (%s)(%s);'%(e.name, e.assignOp, e.datatype['cName'], field))
        off = off+e.width-e.shifted
    return '\n        '.join(word)

def formalParameters(params, insertPortal):
    rc = [ 'const %s %s' % (pitem['type'].cName(), pitem['name']) for pitem in params]
    if insertPortal:
        rc.insert(0, ' struct PortalInternal *p')
    return ', '.join(rc)

def gatherMethodInfo(mname, params, itemname):
    global fdName

    argAtoms = sum(map(functools.partial(collectMembers, ''), params), [])
    argAtoms.reverse()
    argWords  = accumWords([], 0, argAtoms)
    fdName = '-1'

    paramStructMarshallStr = 'p->item->write(p, &temp_working_addr, %s);'
    paramStructDemarshallStr = 'tmp = p->item->read(p, &temp_working_addr);'

    if argWords == []:
        paramStructMarshall = [paramStructMarshallStr % '0']
        paramStructDemarshall = [paramStructDemarshallStr]
    else:
        paramStructMarshall = map(functools.partial(generate_marshall, paramStructMarshallStr), argWords)
        paramStructMarshall.reverse()
        paramStructDemarshall = map(functools.partial(generate_demarshall, paramStructDemarshallStr), argWords)
        paramStructDemarshall.reverse()

    paramStructDeclarations = [ '%s %s;' % (pitem['type'].cName(), pitem['name']) for pitem in params]
    if not params:
        paramStructDeclarations = ['        int padding;\n']
    respParams = [pitem['name'] for pitem in params]
    respParams.insert(0, 'p')
    substs = {
        'methodName': cName(mname),
        'paramDeclarations': formalParameters(params, False),
        'paramProxyDeclarations': formalParameters(params, True),
        'paramStructDeclarations': '\n        '.join(paramStructDeclarations),
        'paramStructMarshall': '\n    '.join(paramStructMarshall),
        'paramStructDemarshall': '\n        '.join(paramStructDemarshall),
        'paramNames': ', '.join(['msg->%s' % pitem['name'] for pitem in params]),
        'wordLen': len(argWords),
        'wordLenP1': len(argWords) + 1,
        'fdName': fdName,
        'className': cName(itemname),
        'channelNumber': 'CHAN_NUM_%s_%s' % (cName(itemname), cName(mname)),
        'responseCase': ('((%(className)sCb *)p->cb)->%(name)s(%(params)s);'
                          % { 'name': mname,
                              'className' : cName(itemname),
                              'params': ', '.join(respParams)})
        }
    return substs, len(argWords)

def emitMethodDeclaration(mname, params, f, className):
    paramValues = [pitem['name'] for pitem in params]
    paramValues.insert(0, '&pint')
    methodName = cName(mname)
    indent(f, 4)
    if className == '':
        f.write('virtual ')
    f.write(('void %s ( ' % methodName) + formalParameters(params, False) + ' ) ')
    if className == '':
        f.write('= 0;\n')
    else:
        f.write('{ %s_%s (' % (className, methodName))
        f.write(', '.join(paramValues) + '); };\n')

def generate_class(className, declList, parentC, parentCC, generatedCFiles, create_cpp_file, generated_hpp, generated_cpp):
    classCName = cName(className)
    cppname = '%s.c' % className
    hppname = '%s.h' % className
    if cppname in generatedCFiles:
        return
    generatedCFiles.append(cppname)
    hpp = create_cpp_file(hppname)
    cpp = create_cpp_file(cppname)
    hpp.write('#ifndef _%(name)s_H_\n#define _%(name)s_H_\n' % {'name': className.upper()})
    hpp.write('#include "%s.h"\n' % parentC)
    generated_cpp.write('\n/************** Start of %sWrapper CPP ***********/\n' % className)
    generated_cpp.write('#include "%s"\n' % hppname)
    maxSize = 0
    reqChanNums = []
    for mitem in declList:
        substs, t = gatherMethodInfo(mitem['name'], mitem['params'], className)
        if t > maxSize:
            maxSize = t
        cpp.write((proxyMethodTemplateDecl + proxyMethodTemplate) % substs)
        generated_hpp.write((proxyMethodTemplateDecl % substs) + ';')
        reqChanNums.append(substs['channelNumber'])
    subs = {'className': classCName, 'maxSize': maxSize * sizeofUint32_t, 'parentClass': parentCC}
    generated_hpp.write('\nenum { ' + ','.join(reqChanNums) + '};\n#define %(className)s_reqsize %(maxSize)s\n' % subs)
    hpp.write(proxyClassPrefixTemplate % subs)
    for mitem in declList:
        emitMethodDeclaration(mitem['name'], mitem['params'], hpp, classCName)
    hpp.write('};\n')
    cpp.write((handleMessageTemplateDecl % subs))
    cpp.write(handleMessageTemplate1 % subs)
    for mitem in declList:
        substs, t = gatherMethodInfo(mitem['name'], mitem['params'], className)
        cpp.write(handleMessageCase % substs)
    cpp.write(handleMessageTemplate2 % subs)
    generated_hpp.write((handleMessageTemplateDecl % subs)+ ';\n')
    hpp.write(wrapperClassPrefixTemplate % subs)
    for mitem in declList:
        emitMethodDeclaration(mitem['name'], mitem['params'], hpp, '')
    hpp.write('};\n')
    generated_hpp.write('typedef struct {\n')
    for mitem in declList:
        paramValues = ', '.join([pitem['name'] for pitem in mitem['params']])
        formalParamStr = formalParameters(mitem['params'], True)
        methodName = cName(mitem['name'])
        generated_hpp.write(('    void (*%s) ( ' % methodName) + formalParamStr + ' );\n')
        generated_cpp.write(('void %s%s_cb ( ' % (classCName, methodName)) + formalParamStr + ' ) {\n')
        indent(generated_cpp, 4)
        generated_cpp.write(('(static_cast<%sWrapper *>(p->parent))->%s ( ' % (classCName, methodName)) + paramValues + ');\n};\n')
    generated_hpp.write('} %sCb;\n' % classCName)
    generated_cpp.write('%sCb %s_cbTable = {\n' % (classCName, classCName))
    for mitem in declList:
        generated_cpp.write('    %s%s_cb,\n' % (classCName, mitem['name']))
    generated_cpp.write('};\n')
    hpp.write('#endif // _%(name)s_H_\n' % {'name': className.upper()})
    hpp.close()
    cpp.close()

def piInfo(name, type):
    rc = {}
    rc['name'] = name
    rc['type'] = type
    return rc

def declInfo(name, params):
    rc = {}
    rc['name'] = name
    rc['params'] = []
    for pitem in params:
        rc['params'].append(piInfo(pitem.name, pitem.type))
    return rc

def classInfo(name, decls, parentLportal, parentPortal):
    rc = {}
    rc['name'] = name
    rc['parentLportal'] = parentLportal
    rc['parentPortal'] = parentPortal
    rc['decls'] = []
    for mitem in decls:
        rc['decls'].append(declInfo(mitem.name, mitem.params))
    return rc

def generate_cpp(globaldecls, project_dir, noisyFlag, interfaces):
    def create_cpp_file(name):
        fname = os.path.join(project_dir, 'jni', name)
        f = util.createDirAndOpen(fname, 'w')
        if noisyFlag:
            print "Writing file ",fname
        f.write('#include "GeneratedTypes.h"\n')
        return f

    itemlist = []
    for item in interfaces:
        itemlist.append(classInfo(item.name, item.decls, item.parentClass("portal"), item.parentClass("Portal")))
    generatedCFiles = []
    hname = os.path.join(project_dir, 'jni', 'GeneratedTypes.h')
    generated_hpp = util.createDirAndOpen(hname, 'w')
    generated_hpp.write('#ifndef __GENERATED_TYPES__\n')
    generated_hpp.write('#define __GENERATED_TYPES__\n')
    generated_hpp.write('#include "portal.h"\n')
    generated_hpp.write('#ifdef __cplusplus\n')
    generated_hpp.write('extern "C" {\n')
    generated_hpp.write('#endif\n')
    # global type declarations used by interface mthods
    for v in globaldecls:
        if (v.type == 'TypeDef'):
            if v.params:
                print 'Skipping C++ declaration for parameterized type', v.name
                continue
            try:
                v.emitCDeclaration(generated_hpp, 0)
            except:
                print 'Skipping typedef', v.name
                traceback.print_exc()
    generated_hpp.write('\n')
    cppname = 'GeneratedCppCallbacks.cpp'
    generated_cpp = create_cpp_file(cppname)
    generatedCFiles.append(cppname)
    generated_cpp.write('\n#ifndef NO_CPP_PORTAL_CODE\n')
    for item in itemlist:
        generate_class(item['name'], item['decls'], item['parentLportal'], item['parentPortal'], generatedCFiles, create_cpp_file, generated_hpp, generated_cpp)
    generated_cpp.write('#endif //NO_CPP_PORTAL_CODE\n')
    generated_cpp.close()
    generated_hpp.write('#ifdef __cplusplus\n')
    generated_hpp.write('}\n')
    generated_hpp.write('#endif\n')
    generated_hpp.write('#endif //__GENERATED_TYPES__\n')
    generated_hpp.close()
    gen_makefile = util.createDirAndOpen(os.path.join(project_dir, 'jni', 'Makefile.generated_files'), 'w')
    gen_makefile.write('\nGENERATED_CPP=' + ' '.join(generatedCFiles)+'\n')
    gen_makefile.close()
    return generatedCFiles
