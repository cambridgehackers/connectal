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

import functools, math, os, re, sys, util

sizeofUint32_t = 4
generatedVectors = []

proxyClassPrefixTemplate='''
class %(className)sProxy : public %(parentClass)s {
public:
    %(className)sProxy(int id, PortalPoller *poller = 0) : Portal(id, %(className)s_reqinfo, NULL, NULL, poller) {};
    %(className)sProxy(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : Portal(id, %(className)s_reqinfo, NULL, NULL, item, param, poller) {};
'''

wrapperClassPrefixTemplate='''
extern %(className)sCb %(className)s_cbTable;
class %(className)sWrapper : public %(parentClass)s {
public:
    %(className)sWrapper(int id, PortalPoller *poller = 0) : Portal(id, %(className)s_reqinfo, %(className)s_handleMessage, (void *)&%(className)s_cbTable, poller) {
        pint.parent = static_cast<void *>(this);
    };
    %(className)sWrapper(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : Portal(id, %(className)s_reqinfo, %(className)s_handleMessage, (void *)&%(className)s_cbTable, item, param, poller) {
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
        %(paramStructDeclarations)s
        p->item->recv(p, temp_working_addr, %(wordLen)s, &tmpfd);
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
int %(className)s_%(methodName)s (%(paramProxyDeclarations)s )'''

proxyMethodTemplate='''
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, %(channelNumber)s);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    %(paramStructMarshall)s
    p->item->send(p, temp_working_addr_start, (%(channelNumber)s << 16) | %(wordLenP1)s, %(fdName)s);
    return 0;
};
'''

def indent(f, indentation):
    for i in xrange(indentation):
        f.write(' ')

def cName(x):
    if type(x) == str or type(x) == unicode:
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
    membtype = pitem['type']
    while 1:
        if membtype['name'] == 'Bit' or membtype['name'] == 'Int' or membtype['name'] == 'UInt' \
            or membtype['name'] == 'Float' or membtype['name'] == 'Bool':
            return [('%s%s'%(scope,pitem['name']),membtype)]
        elif membtype['name'] == 'SpecialTypeForSendingFd':
            return [('%s%s'%(scope,pitem['name']),membtype)]
        elif membtype['name'] == 'Vector':
            nElt = int(membtype['params'][0]['name'])
            retitem = []
            ind = 0;
            while ind < nElt:
                retitem.append([('%s%s'%(scope,pitem['name']+'['+str(ind)+']'),membtype['params'][1])])
                ind = ind + 1
            return sum(retitem, [])
        else:
            td = globalv_globalvars[membtype['name']]
            #print 'instantiate', membtype['params']
            tdtype = td['tdtype']
            #print '           ', membtype
            if tdtype['type'] == 'Struct':
                ns = '%s%s.' % (scope,pitem['name'])
                rv = map(functools.partial(collectMembers, ns), tdtype['elements'])
                return sum(rv,[])
            membtype = tdtype
            if tdtype['type'] == 'Enum':
                return [('%s%s'%(scope,pitem['name']),membtype)]
            #print 'resolved to type', membtype['type'], membtype['name'], membtype

def typeNumeric(item):
    if globalv_globalvars.has_key(item['name']):
        decl = globalv_globalvars[item['name']]
        if decl['type'] == 'TypeDef':
            return typeNumeric(decl['tdtype'])
    elif item['name'] in ['TAdd', 'TSub', 'TMul', 'TDiv', 'TLog', 'TExp', 'TMax', 'TMin']:
        values = [typeNumeric(p) for p in item['params']]
        if item['name'] == 'TAdd':
            return values[0] + values[1]
        elif item['name'] == 'TSub':
            return values[0] - values[1]
        elif item['name'] == 'TMul':
            return values[0] * values[1]
        elif item['name'] == 'TDiv':
            return math.ceil(values[0] / float(values[1]))
        elif item['name'] == 'TLog':
            return math.ceil(math.log(values[0], 2))
        elif item['name'] == 'TExp':
            return math.pow(2, values[0])
        elif item['name'] == 'TMax':
            return max(values[0], values[1])
        elif item['name'] == 'TMax':
            return min(values[0], values[1])
    return int(item['name'])

def typeCName(item):
    global generatedVectors
    if item['type'] == 'Type':
        cid = item['name'].replace(' ', '')
        if cid == 'Bit':
            if typeNumeric(item['params'][0]) <= 32:
                return 'uint32_t'
            elif typeNumeric(item['params'][0]) <= 64:
                return 'uint64_t'
            else:
                return 'std::bitset<%d>' % (typeNumeric(item['params'][0]))
        elif cid == 'Bool':
            return 'int'
        elif cid == 'Int':
            if typeNumeric(item['params'][0]) == 32:
                return 'int'
            else:
                assert(False)
        elif cid == 'UInt':
            if typeNumeric(item['params'][0]) == 32:
                return 'unsigned int'
            else:
                assert(False)
        elif cid == 'Float':
            return 'float'
        elif cid == 'Vector':
            t = [typeNumeric(item['params'][0]), typeCName(item['params'][1])]
            if t not in generatedVectors:
                generatedVectors.append(t)
            return 'bsvvector_L%s_L%d' % (t[1], t[0])
        elif cid == 'Action':
            return 'int'
        elif cid == 'ActionValue':
            assert(False)
        if item['params']:
            name = '%sL_%s_P' % (cid, '_'.join([typeCName(t) for t in item['params'] if t]))
        else:
            name = cid
        return name
    return item['name']

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
    aw = 32
    #print '%d %d %d' %(aw, pro, w)
    s.append(paramInfo(name,aw,pro,thisType,'='))
    #print '%s (1)'% (name)
    return accumWords(s,0,memberList[1:])

def generate_marshall(pfmt, w):
    global fdName
    word = []
    fmt = pfmt
    outstr = ''
    for e in w:
        field = e.name
        if typeCName(e.datatype) == 'float':
            return pfmt % (e.name, '*(int*)&' + e.name)
        word.append((field, field))
        if typeCName(e.datatype) == 'SpecialTypeForSendingFd':
            fdName = field
            fmt = 'p->item->writefd(p, &temp_working_addr, %s);'
        outstr += '\n    ' + fmt % (e.name, e.name)
    return outstr

def generate_demarshall(fmt, w):
    word = []
    for e in w:
        # print e.name+' (d)'
        field = 'tmp'
        if typeCName(e.datatype) == 'float':
            word.append('%s = *(float*)&(%s);'%(e.name,field))
            continue
        field = '(%s)' % (field)
        if typeCName(e.datatype) == 'SpecialTypeForSendingFd':
            word.append('%s %s messageFd;'%(e.name, e.assignOp))
        else:
            word.append('%s %s (%s)%s;'%(e.name, e.assignOp, typeCName(e.datatype), fmt % e.name))
    return '\n        '.join(word)

def formalParameters(params, insertPortal):
    rc = [ 'const %s %s' % (typeCName(pitem['type']), pitem['name']) for pitem in params]
    if insertPortal:
        rc.insert(0, ' struct PortalInternal *p')
    return ', '.join(rc)

def gatherMethodInfo(mname, params, itemname):
    global fdName

    argAtoms = sum(map(functools.partial(collectMembers, ''), params), [])
    argAtoms.reverse()
    argWords  = accumWords([], 0, argAtoms)
    fdName = '-1'

    paramStructMarshallStr = 'p->item->write(p, &temp_working_addr, "%s", %s);'
    paramStructDemarshallStr = 'p->item->read(p, "%s", &temp_working_addr)'

    if argWords == []:
        paramStructMarshall = [paramStructMarshallStr % ('NULLNAME','0')]
        paramStructDemarshall = [paramStructDemarshallStr]
    else:
        paramStructMarshall = map(functools.partial(generate_marshall, paramStructMarshallStr), argWords)
        paramStructMarshall.reverse()
        paramStructDemarshall = map(functools.partial(generate_demarshall, paramStructDemarshallStr), argWords)
        paramStructDemarshall.reverse()

    paramStructDeclarations = [ '%s %s;' % (typeCName(pitem['type']), pitem['name']) for pitem in params]
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
        f.write('virtual void')
    else:
        f.write('int')
    f.write((' %s ( ' % methodName) + formalParameters(params, False) + ' ) ')
    if className == '':
        f.write('= 0;\n')
    else:
        f.write('{ return %s_%s (' % (className, methodName))
        f.write(', '.join(paramValues) + '); };\n')

def generate_class(className, declList, parentC, parentCC, generatedCFiles, create_cpp_file, generated_cpp):
    global generatedVectors
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
        generatedVectors = []
        reqChanNums.append(substs['channelNumber'])
    subs = {'className': classCName, 'maxSize': (maxSize+1) * sizeofUint32_t, 'parentClass': parentCC, \
            'reqInfo': '0x%x' % ((len(declList) << 16) + (maxSize+1) * sizeofUint32_t) }
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
    hpp.write(wrapperClassPrefixTemplate % subs)
    for mitem in declList:
        emitMethodDeclaration(mitem['name'], mitem['params'], hpp, '')
    hpp.write('};\n')
    for mitem in declList:
        paramValues = ', '.join([pitem['name'] for pitem in mitem['params']])
        formalParamStr = formalParameters(mitem['params'], True)
        methodName = cName(mitem['name'])
        generated_cpp.write(('void %s%s_cb ( ' % (classCName, methodName)) + formalParamStr + ' ) {\n')
        indent(generated_cpp, 4)
        generated_cpp.write(('(static_cast<%sWrapper *>(p->parent))->%s ( ' % (classCName, methodName)) + paramValues + ');\n};\n')
    generated_cpp.write('%sCb %s_cbTable = {\n' % (classCName, classCName))
    for mitem in declList:
        generated_cpp.write('    %s%s_cb,\n' % (classCName, mitem['name']))
    generated_cpp.write('};\n')
    hpp.write('#endif // _%(name)s_H_\n' % {'name': className.upper()})
    hpp.close()
    cpp.close()

def emitStructMember(item, f, indentation):
    indent(f, indentation)
    f.write('%s %s' % (typeCName(item['type']), item['name']))
    f.write(';\n')

def emitStruct(item, name, f, indentation):
    indent(f, indentation)
    if (indentation == 0):
        f.write('typedef ')
    f.write('struct %s {\n' % name)
    for e in item['elements']:
        emitStructMember(e, f, indentation+4)
    indent(f, indentation)
    f.write('}')
    if (indentation == 0):
        f.write(' %s;' % name)
    f.write('\n')

def emitEnum(item, name, f, indentation):
    indent(f, indentation)
    if (indentation == 0):
        f.write('typedef ')
    f.write('enum %s { ' % name)
    indent(f, indentation)
    f.write(', '.join(['%s_%s' % (name, e) for e in item['elements']]))
    indent(f, indentation)
    f.write(' }')
    if (indentation == 0):
        f.write(' %s;' % name)
    f.write('\n')

def generate_cppjson(project_dir, noisyFlag, jsondata):
    global globalv_globalvars
    def create_cpp_file(name):
        fname = os.path.join(project_dir, 'jni', name)
        f = util.createDirAndOpen(fname, 'w')
        if noisyFlag:
            print "Writing file ",fname
        f.write('#include "GeneratedTypes.h"\n')
        return f

    generatedCFiles = []
    globalv_globalvars = jsondata['globalvars']
    hname = os.path.join(project_dir, 'jni', 'GeneratedTypes.h')
    cppname = 'GeneratedCppCallbacksJson.cpp'
    generated_cpp = create_cpp_file(cppname)
    generatedCFiles.append(cppname)
    generated_cpp.write('\n#ifndef NO_CPP_PORTAL_CODE\n')
    for item in jsondata['interfaces']:
        generate_class(item['name']+'Json', item['decls'], item['parentLportal'], item['parentPortal'], generatedCFiles, create_cpp_file, generated_cpp)
    generated_cpp.write('#endif //NO_CPP_PORTAL_CODE\n')
    generated_cpp.close()
    gen_makefile = util.createDirAndOpen(os.path.join(project_dir, 'jni', 'Makefile.generated_filesJson'), 'w')
    gen_makefile.write('\nGENERATED_CPP=' + ' '.join(generatedCFiles)+'\n')
    gen_makefile.close()
    return generatedCFiles
