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
extern %(className)sCb %(className)sProxyReq;
class %(className)sProxy : public %(parentClass)s {
    %(className)sCb *cb;
public:
    %(className)sProxy(int id, PortalPoller *poller = 0) : Portal(id, %(classNameOrig)s_reqinfo, NULL, NULL, poller), cb(&%(className)sProxyReq) {};
    %(className)sProxy(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : Portal(id, %(classNameOrig)s_reqinfo, NULL, NULL, item, param, poller), cb(&%(className)sProxyReq) {};
'''

wrapperClassPrefixTemplate='''
extern %(className)sCb %(className)s_cbTable;
class %(className)sWrapper : public %(parentClass)s {
public:
    %(className)sWrapper(int id, PortalPoller *poller = 0) : Portal(id, %(classNameOrig)s_reqinfo, %(className)s_handleMessage, (void *)&%(className)s_cbTable, poller) {
        pint.parent = static_cast<void *>(this);
    };
    %(className)sWrapper(int id, PortalItemFunctions *item, void *param, PortalPoller *poller = 0) : Portal(id, %(classNameOrig)s_reqinfo, %(className)s_handleMessage, (void *)&%(className)s_cbTable, item, param, poller) {
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
    %(classNameOrig)sData tempdata;
    connnectalJsonDecode(p, &tempdata, %(classNameOrig)sInfo[channel].param);
    switch (channel) {'''

handleMessageCase='''
    case %(channelNumber)s:
        %(responseCase)s
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

jsonStructTemplateDecl='''
static ConnectalParamJsonInfo %(channelName)sInfo[] = {
    %(paramJsonDeclarations)s
    {NULL, %(channelNumber)s},
};'''

jsonMethodTemplateDecl='''
static ConnectalMethodJsonInfo %(className)sInfo[] = {
    %(methodJsonDeclarations)s
    {NULL, NULL},
};'''

proxyMethodTableDecl='''
%(classNameOrig)sCb %(className)sProxyReq[] = {
    %(methodTable)s
};'''

proxyMethodTemplateDecl='''
int %(className)s_%(methodName)s (%(paramProxyDeclarations)s )'''

proxyMethodTemplate='''
{
    %(channelName)sData tempdata;%(paramStructMarshall)s
    connectalJsonEncode(p, &tempdata, %(channelName)sInfo);
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

def generate_demarshall(argStruct, w):
    fmt, methodName = argStruct
    word = []
    for e in w:
        # print e.name+' (d)'
        field = 'tmp'
        if typeCName(e.datatype) == 'float':
            word.append('%s = *(float*)&(%s);'%(e.name,field))
            continue
        field = '(%s)' % (field)
        if typeCName(e.datatype) == 'SpecialTypeForSendingFd':
            word.append('tempdata.%s.%s %s messageFd;'%(methodName, e.name, e.assignOp))
        else:
            word.append('tempdata.%s.%s %s (%s)(%s);'%(methodName, e.name, e.assignOp, typeCName(e.datatype), field))
    return '\n        '.join(word)

def formalParameters(params, insertPortal):
    rc = [ 'const %s %s' % (typeCName(pitem['type']), pitem['name']) for pitem in params]
    if insertPortal:
        rc.insert(0, ' struct PortalInternal *p')
    return ', '.join(rc)

def gatherMethodInfo(mname, params, itemname, classNameOrig):
    global fdName

    className = cName(itemname)
    methodName = cName(mname)
    argAtoms = sum(map(functools.partial(collectMembers, ''), params), [])
    argAtoms.reverse()
    argWords  = accumWords([], 0, argAtoms)
    fdName = '-1'

    paramStructMarshallStr = 'tempdata.%s = %s;'

    if argWords == []:
        paramStructMarshall = ['']
    else:
        paramStructMarshall = map(functools.partial(generate_marshall, paramStructMarshallStr), argWords)
        paramStructMarshall.reverse()

    chname = '%s_%s' % (classNameOrig, methodName)
    paramJsonDeclarations = [ '{"%s", Connectaloffsetof(%sData,%s)},' % (pitem['name'], chname, pitem['name']) for pitem in params]
    if not params:
        paramJsonDeclarations = ['    int padding;\n']
    respParams = ['tempdata.%s.%s' % (methodName, pitem['name']) for pitem in params]
    respParams.insert(0, 'p')
    substs = {
        'methodName': methodName,
        'paramDeclarations': formalParameters(params, False),
        'paramProxyDeclarations': formalParameters(params, True),
        'paramJsonDeclarations': '\n    '.join(paramJsonDeclarations),
        'paramStructMarshall': '\n    '.join(paramStructMarshall),
        'paramNames': ', '.join(['msg->%s' % pitem['name'] for pitem in params]),
        'wordLen': len(argWords),
        'wordLenP1': len(argWords) + 1,
        'fdName': fdName,
        'className': className,
        'classNameOrig': classNameOrig,
        'channelName': chname,
        'channelNumber': 'CHAN_NUM_%s' % chname,
        'responseCase': ('((%(className)sCb *)p->cb)->%(name)s(%(params)s);'
                          % { 'name': mname,
                              'className' : classNameOrig,
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
        f.write('{ return cb->%s (' % methodName)
        f.write(', '.join(paramValues) + '); };\n')

def generate_class(classNameOrig, declList, parentC, parentCC, generatedCFiles, create_cpp_file):
    global generatedVectors
    className = classNameOrig + 'Json'
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
    maxSize = 0
    reqChanNums = []
    methodList = []
    for mitem in declList:
        substs, t = gatherMethodInfo(mitem['name'], mitem['params'], className, classNameOrig)
        if t > maxSize:
            maxSize = t
        cpp.write((jsonStructTemplateDecl) % substs)
        cpp.write((proxyMethodTemplateDecl + proxyMethodTemplate) % substs)
        methodList.append(substs['methodName'])
        reqChanNums.append(substs['channelNumber'])
    methodJsonDeclarations = ['{"%(methodName)s", %(classNameOrig)s_%(methodName)sInfo},' % {'methodName': p, 'classNameOrig': classNameOrig} for p in methodList]
    cpp.write(jsonMethodTemplateDecl % {'className': classNameOrig, 'methodJsonDeclarations': '\n    '.join(methodJsonDeclarations)})
    methodTable = ['%(className)s_%(methodName)s,' % {'methodName': p, 'className': className} for p in methodList]
    cpp.write(proxyMethodTableDecl % {'className': className, 'classNameOrig': classNameOrig, 'methodTable': '\n    '.join(methodTable)})
    subs = {'className': classCName, 'maxSize': (maxSize+1) * sizeofUint32_t, 'parentClass': parentCC,
            'reqInfo': '0x%x' % ((len(declList) << 16) + (maxSize+1) * sizeofUint32_t),
            'classNameOrig': classNameOrig }
    hpp.write(proxyClassPrefixTemplate % subs)
    for mitem in declList:
        emitMethodDeclaration(mitem['name'], mitem['params'], hpp, classCName)
    hpp.write('};\n')
    cpp.write((handleMessageTemplateDecl % subs))
    cpp.write(handleMessageTemplate1 % subs)
    for mitem in declList:
        substs, t = gatherMethodInfo(mitem['name'], mitem['params'], className, classNameOrig)
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

def generate_cpp(project_dir, noisyFlag, jsondata):
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
    for item in jsondata['interfaces']:
        generate_class(item['name'], item['decls'], item['parentLportal'], item['parentPortal'], generatedCFiles, create_cpp_file)
    gen_makefile = util.createDirAndOpen(os.path.join(project_dir, 'jni', 'Makefile.generated_filesJson'), 'w')
    gen_makefile.write('\nGENERATED_CPP=' + ' '.join(generatedCFiles)+'\n')
    gen_makefile.close()
    return generatedCFiles
