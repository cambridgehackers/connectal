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

verbose = False
sizeofUint32_t = 4
generatedVectors = []
itypeNames = ['int8_t', 'uint8_t', 'int16_t', 'uint16_t', 'int32_t', 'uint32_t', 'uint64_t', 'SpecialTypeForSendingFd', 'ChannelType', 'DmaDbgRec']

proxyClassPrefixTemplate='''
class %(className)sProxy : public Portal {
    %(classNameOrig)sCb *cb;
public:
    %(className)sProxy(int id, int tile = DEFAULT_TILE, %(classNameOrig)sCb *cbarg = &%(className)sProxyReq, int bufsize = %(classNameOrig)s_reqinfo, PortalPoller *poller = 0) :
        Portal(id, tile, bufsize, NULL, NULL, this, poller), cb(cbarg) {};
    %(className)sProxy(int id, PortalTransportFunctions *item, void *param, %(classNameOrig)sCb *cbarg = &%(className)sProxyReq, int bufsize = %(classNameOrig)s_reqinfo, PortalPoller *poller = 0) :
        Portal(id, DEFAULT_TILE, bufsize, NULL, NULL, item, param, this, poller), cb(cbarg) {};
    %(className)sProxy(int id, PortalPoller *poller) :
        Portal(id, DEFAULT_TILE, %(classNameOrig)s_reqinfo, NULL, NULL, NULL, NULL, this, poller), cb(&%(className)sProxyReq) {};
'''

wrapperClassPrefixTemplate='''
extern %(classNameOrig)sCb %(className)s_cbTable;
class %(className)sWrapper : public Portal {
public:
    %(className)sWrapper(int id, int tile = DEFAULT_TILE, PORTAL_INDFUNC cba = %(className)s_handleMessage, int bufsize = %(classNameOrig)s_reqinfo, PortalPoller *poller = 0) :
           Portal(id, tile, bufsize, cba, (void *)&%(className)s_cbTable, this, poller) {
    };
    %(className)sWrapper(int id, PortalTransportFunctions *item, void *param, PORTAL_INDFUNC cba = %(className)s_handleMessage, int bufsize = %(classNameOrig)s_reqinfo, PortalPoller *poller=0):
           Portal(id, DEFAULT_TILE, bufsize, cba, (void *)&%(className)s_cbTable, item, param, this, poller) {
    };
    %(className)sWrapper(int id, PortalPoller *poller) :
           Portal(id, DEFAULT_TILE, %(classNameOrig)s_reqinfo, %(className)s_handleMessage, (void *)&%(className)s_cbTable, this, poller) {
    };
    %(className)sWrapper(int id, PortalTransportFunctions *item, void *param, PortalPoller *poller):
           Portal(id, DEFAULT_TILE, %(classNameOrig)s_reqinfo, %(className)s_handleMessage, (void *)&%(className)s_cbTable, item, param, this, poller) {
    };
    virtual void disconnect(void) {
        printf("%(className)sWrapper.disconnect called %%d\\n", pint.client_fd_number);
    };
'''

handleMessageTemplateDecl='''
int %(className)s_handleMessage(struct PortalInternal *p, unsigned int channel, int messageFd)'''

messageStructTemplate='''
typedef struct {
    %(paramStructDeclarations)s
} %(channelName)sData;'''

portalStructTemplate='''
typedef union {
    %(messageStructDeclarations)s
} %(className)sData;'''

handleMessageTemplate1='''
{
    static int runaway = 0;
    int   tmp __attribute__ ((unused));
    int tmpfd __attribute__ ((unused));
    %(classNameOrig)sData tempdata __attribute__ ((unused));
    %(handleStartup)s
    switch (channel) {'''

handleMessagePrep='''
        p->item->recv(p, temp_working_addr, %(wordLen)s, &tmpfd);
        %(paramStructDemarshall)s'''

handleMessageCase='''
    case %(channelNumber)s: {
        %(responseCase)s
      } break;'''

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
    {"%(methodName)s", ((ConnectalParamJsonInfo[]){
        %(paramJsonDeclarations)s
        {NULL, %(channelNumber)s}}) },'''

jsonMethodTemplateDecl='''
static ConnectalMethodJsonInfo %(classNameOrig)sInfo[] = {'''

proxyMethodTableDecl='''
%(classNameOrig)sCb %(className)sProxyReq = {
    %(methodTable)s
};'''

proxyMethodTemplateDecl='''
int %(className)s_%(methodName)s (%(paramProxyDeclarations)s )'''

proxyMethodTemplate='''
{
    volatile unsigned int* temp_working_addr_start = p->item->mapchannelReq(p, %(channelNumber)s, %(wordLenP1)s);
    volatile unsigned int* temp_working_addr = temp_working_addr_start;
    if (p->item->busywait(p, %(channelNumber)s, "%(className)s_%(methodName)s")) return 1;
    %(paramStructMarshall)s
    p->item->send(p, temp_working_addr_start, (%(channelNumber)s << 16) | %(wordLenP1)s, %(fdName)s);
    return 0;
};
'''

proxyJMethodTemplate='''
{
    %(channelName)sData tempdata;
    %(paramStructMarshall)s
    connectalJsonEncodeAndSend(p, &tempdata, &%(classNameOrig)sInfo[%(channelNumber)s]);
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
    if verbose:
        print 'collectM', pitem
    membtype = pitem['ptype']
    while 1:
        if membtype['name'] == 'Bit' or membtype['name'] == 'Int' or membtype['name'] == 'UInt' \
            or membtype['name'] == 'Float' or membtype['name'] == 'Bool' or membtype['name'] == 'fixed32':
            return [('%s%s'%(scope,pitem['pname']),membtype)]
        elif membtype['name'] == 'SpecialTypeForSendingFd':
            return [('%s%s'%(scope,pitem['pname']),membtype)]
        elif membtype['name'] == 'Vector':
            nElt = int(membtype['params'][0]['name'])
            retitem = []
            ind = 0;
            while ind < nElt:
                retitem.append([('%s%s'%(scope,pitem['pname']+'['+str(ind)+']'),membtype['params'][1])])
                ind = ind + 1
            return sum(retitem, [])
        else:
            td = globalv_globalvars[membtype['name']]
            #print 'instantiate', membtype['params']
            tdtype = td['tdtype']
            #print '           ', membtype
            if tdtype.get('type') == 'Struct':
                ns = '%s%s.' % (scope,pitem['pname'])
                rv = map(functools.partial(collectMembers, ns), tdtype['elements'])
                return sum(rv,[])
            membtype = tdtype
            if tdtype.get('type') == 'Enum':
                return [('%s%s'%(scope,pitem['pname']),membtype)]
            #print 'resolved to type', membtype.get('type'), membtype['name'], membtype

def typeNumeric(item):
    global bsvdefines
    tstr = item.get('name')
    if globalv_globalvars.has_key(tstr):
        decl = globalv_globalvars[tstr]
        if decl.get('dtype') == 'TypeDef':
            return typeNumeric(decl['tdtype'])
    elif tstr in ['TAdd', 'TSub', 'TMul', 'TDiv', 'TLog', 'TExp', 'TMax', 'TMin']:
        values = [typeNumeric(p) for p in item['params']]
        if tstr == 'TAdd':
            return values[0] + values[1]
        elif tstr == 'TSub':
            return values[0] - values[1]
        elif tstr == 'TMul':
            return values[0] * values[1]
        elif tstr == 'TDiv':
            return math.ceil(values[0] / float(values[1]))
        elif tstr == 'TLog':
            return math.ceil(math.log(values[0], 2))
        elif tstr == 'TExp':
            return math.pow(2, values[0])
        elif tstr == 'TMax':
            return max(values[0], values[1])
        elif tstr == 'TMax':
            return min(values[0], values[1])
    if tstr[0] == '`':
        var = tstr[1:]
        if bsvdefines.has_key(var):
            return int(bsvdefines[var])
    if tstr[0] >= 'A' and tstr[0] <= 'Z':
        return tstr
    return int(tstr)

def typeCName(item):
    global generatedVectors
    if item.get('type') == None:
        cid = item['name'].replace(' ', '')
        if cid == 'Bit':
            numbits = typeNumeric(item['params'][0])
            if numbits <= 8:
                return 'uint8_t'
            elif numbits <= 16:
                return 'uint16_t'
            elif numbits <= 32:
                return 'uint32_t'
            elif numbits <= 64:
                return 'uint64_t'
            else:
                return 'std::bitset<%d>' % (numbits)
        elif cid == 'Bool':
            return 'int'
        elif cid == 'Int':
            numbits = typeNumeric(item['params'][0])
            if numbits <= 8:
                return 'int8_t'
            elif numbits <= 16:
                return 'int16_t'
            elif numbits <= 32:
                return 'int32_t'
            elif numbits <= 64:
                return 'int64_t'
            else:
                assert(False)
        elif cid == 'UInt':
            numbits = typeNumeric(item['params'][0])
            if numbits <= 8:
                return 'uint8_t'
            if numbits <= 16:
                return 'uint16_t'
            elif numbits <= 32:
                return 'uint32_t'
            elif numbits <= 64:
                return 'uint64_t'
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
        if item.get('params'):
            name = '%sL_%s_P' % (cid, '_'.join([typeCName(t) for t in item['params'] if t]))
        else:
            name = cid
        return name
    return item['name']

def signCName(item):
    global generatedVectors
    if item.get('type') == None:
        cid = item['name'].replace(' ', '')
        if cid == 'Bool':
            return '1L'
        elif cid == 'Int':
            numbits = typeNumeric(item['params'][0])
            if numbits <= 16:
                return '0xffffL'
            elif numbits <= 32:
                return '0xffffffffL'
    return None

def typeJson(item):
    tname = typeCName(item)
    if tname not in itypeNames:
        print 'typeJson.other', tname, tname in itypeNames
        return 'other'
    return tname

def hasBitWidth(item):
    return item['name'] == 'Bit' or item['name'] == 'Int' or item['name'] == 'UInt' or item['name'] == 'fixed32'

def getNumeric(item):
   if globalv_globalvars.has_key(item['name']):
       decl = globalv_globalvars[item['name']]
       if decl.get('type') == 'TypeDef':
           return getNumeric(decl['tdtype'])
   elif item['name'] in ['TAdd', 'TSub', 'TMul', 'TDiv', 'TLog', 'TExp', 'TMax', 'TMin']:
       values = [getNumeric(p) for p in item['params']]
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
   elif item['name'].startswith('`'):
       return int(bsvdefines[item['name'][1:]])
   return int(item['name'])

def typeBitWidth(item):
    if item['name'] == 'Bool':
        return 1
    if item['name'] == 'Float':
        return 32
    if item['name'] == 'fixed32':
        return 32
    if item['name'] == 'SpecialTypeForSendingFd':
        return 32
    if item.get('type') == 'Enum':
        return int(math.ceil(math.log(len(item['elements']))))
    if hasBitWidth(item):
        width = item['params'][0]['name']
        while globalv_globalvars.has_key(width):
            decl = globalv_globalvars[width]
            if decl.get('type') != 'TypeDef':
                break
            print 'Resolving width', width, decl['tdtype']
            width = decl['tdtype']['name']
        if re.match('[0-9]+', width):
            return int(width)
        return getNumeric(decl['tdtype'])
    return 0

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
    aw = typeBitWidth(thisType)
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
    outstr = ''
    for e in w:
        field = e.name
        if typeCName(e.datatype) == 'float':
            return pfmt % ('*(int*)&' + e.name)
        mask = signCName(e.datatype)
        if mask:
            field = '(%s & %s)' % (field, mask)
        if e.shifted:
            field = '(%s>>%s)' % (field, e.shifted)
        if off:
            field = '(((unsigned long)%s)<<%s)' % (field, off)
        if typeBitWidth(e.datatype) > 64:
            field = '(const %s & std::bitset<%d>(0xFFFFFFFF)).to_ulong()' % (field, typeBitWidth(e.datatype))
        word.append(field)
        off = off+e.width-e.shifted
        if typeCName(e.datatype) == 'SpecialTypeForSendingFd':
            fdName = field
            fmt = 'p->item->writefd(p, &temp_working_addr, %s);'
    return fmt % (''.join(util.intersperse('|', word)))

def generate_demarshall(argStruct, w):
    fmt, methodName = argStruct
    off = 0
    word = []
    word.append(fmt)
    for e in w:
        # print e.name+' (d)'
        field = 'tmp'
        if typeCName(e.datatype) == 'float':
            word.append('tempdata.%s.%s %s *(float *)&(%s);'%(methodName, e.name, e.assignOp, field))
            continue
        if off:
            field = '%s>>%s' % (field, off)
        #print 'JJJ', e.name, '{{'+field+'}}', typeBitWidth(e.datatype), e.shifted, e.assignOp, off
        fieldWidth = 32 - off     # number of valid data bits in source
        fieldWidth += e.shifted   # number of valid data bits after shifting
        if fieldWidth > typeBitWidth(e.datatype): # if num bits in type < num of valid bits
            fieldWidth = typeBitWidth(e.datatype)
        field = '((%s)&0x%xul)' % (field, ((1 << (fieldWidth - e.shifted))-1))
        if e.shifted:
            field = '((%s)(%s)<<%s)' % (typeCName(e.datatype),field, e.shifted)
        if typeCName(e.datatype) == 'SpecialTypeForSendingFd':
            word.append('tempdata.%s.%s %s messageFd;'%(methodName, e.name, e.assignOp))
        else:
            word.append('tempdata.%s.%s %s (%s)(%s);'%(methodName, e.name, e.assignOp, typeCName(e.datatype), field))
        off = off+e.width-e.shifted
    return '\n        '.join(word)

def formalParameters(params, insertPortal):
    rc = [ 'const %s %s' % (typeCName(pitem['ptype']), pitem['pname']) for pitem in params]
    if insertPortal:
        rc.insert(0, ' struct PortalInternal *p')
    return ', '.join(rc)

def gatherMethodInfo(mname, params, itemname, classNameOrig, classVariant):
    global fdName

    className = cName(itemname)
    methodName = cName(mname)
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
        paramStructDemarshall = map(functools.partial(generate_demarshall, [paramStructDemarshallStr, methodName]), argWords)
        paramStructDemarshall.reverse()

    chname = '%s_%s' % (classNameOrig, methodName)
    if verbose:
        for pitem in params:
            print 'gatherMI', pitem
            break
    if classVariant:
        paramStructMarshall = []
        for pitem in params:
            pname = pitem['pname']
            if typeJson(pitem['ptype']) == 'other':
                titem = 'memcpy(&tempdata.%s, &%s, sizeof(tempdata.%s));' % (pname,pname,pname)
            else:
                titem = 'tempdata.%s = %s;' % (pname,pname)
            paramStructMarshall.append(titem)
    paramStructDeclarations = [ '%s %s;' % (typeCName(pitem['ptype']), pitem['pname']) for pitem in params]
    paramJsonDeclarations = [ '{"%s", Connectaloffsetof(%sData,%s), ITYPE_%s},' % \
        (pitem['pname'], chname, pitem['pname'], typeJson(pitem['ptype'])) for pitem in params]
    if not params:
        paramStructDeclarations = ['    int padding;\n']
        paramJsonDeclarations = ['']
    respParams = ['tempdata.%s.%s' % (methodName, pitem['pname']) for pitem in params]
    respParams.insert(0, 'p')
    substs = {
        'methodName': methodName,
        'paramDeclarations': formalParameters(params, False),
        'paramProxyDeclarations': formalParameters(params, True),
        'paramStructDeclarations': '\n    '.join(paramStructDeclarations),
        'paramStructMarshall': '\n    '.join(paramStructMarshall),
        'paramJsonDeclarations': '\n        '.join(paramJsonDeclarations),
        'paramStructDemarshall': '\n        '.join(paramStructDemarshall),
        'paramNames': ', '.join(['msg->%s' % pitem['pname'] for pitem in params]),
        'wordLen': len(argWords),
        'wordLenP1': len(argWords) + 1,
        'fdName': fdName,
        'className': className,
        'classNameOrig': classNameOrig,
        'channelName': chname,
        'channelNumber': 'CHAN_NUM_%s' % chname,
        'name': mname,
        'params': ', '.join(respParams),
        }
# 'className' : classNameOrig,
    respCase = '((%(classNameOrig)sCb *)p->cb)->%(name)s(%(params)s);'
    if not classVariant:
        respCase = handleMessagePrep + respCase
    substs['responseCase'] = respCase % substs
    return substs, len(argWords)

def emitMethodDeclaration(mname, params, f, className):
    paramValues = [pitem['pname'] for pitem in params]
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

wrapperStartTemplate = '''
/************** Start of %(className)sWrapper CPP ***********/
#include "%(classNameOrig)s.h"
int %(classNameOrig)sdisconnect_cb (struct PortalInternal *p) {
    (static_cast<%(classNameOrig)sWrapper *>(p->parent))->disconnect();
    return 0;
};
'''

def generate_class(classNameOrig, classVariant, declList, generatedCFiles, create_cpp_file, generated_hpp, generated_cpp):
    global generatedVectors
    className = classNameOrig + classVariant
    classCName = cName(className)
    cppname = '%s.c' % className
    hppname = '%s.h' % className
    if cppname in generatedCFiles:
        return
    generatedCFiles.append(cppname)
    cpp = create_cpp_file(cppname)
    maxSize = 0
    reqChanNums = []
    methodList = []
    cnSubst = {'className': className, 'classNameOrig': classNameOrig}
    if classVariant:
        cpp.write(jsonMethodTemplateDecl % cnSubst)
    else:
        hpp = create_cpp_file(hppname)
        hpp.write('#ifndef _%(name)s_H_\n#define _%(name)s_H_\n' % {'name': className.upper()})
        hpp.write('#include "portal.h"\n')
        generated_cpp.write(wrapperStartTemplate % cnSubst)
    for mitem in declList:
        if verbose:
            print'gcl/mitem', mitem
        substs, t = gatherMethodInfo(mitem['dname'], mitem['dparams'], className, classNameOrig, classVariant)
        if t > maxSize:
            maxSize = t
        if classVariant:
            cpp.write((jsonStructTemplateDecl) % substs)
        methodList.append(substs['methodName'])
        reqChanNums.append(substs['channelNumber'])
    methodJsonDeclarations = ['{"%(methodName)s", %(classNameOrig)s_%(methodName)sInfo},' % {'methodName': p, 'classNameOrig': classNameOrig} for p in methodList]
    if classVariant:
        cpp.write('{}};\n')
    for mitem in declList:
        substs, t = gatherMethodInfo(mitem['dname'], mitem['dparams'], className, classNameOrig, classVariant)
        if classVariant:
            cpp.write((proxyMethodTemplateDecl + proxyJMethodTemplate) % substs)
        else:
            cpp.write((proxyMethodTemplateDecl + proxyMethodTemplate) % substs)
            for t in generatedVectors:
                #'Vector'
                generated_hpp.write('\ntypedef %s bsvvector_L%s_L%d[%d];' % (t[1], t[1], t[0], t[0]))
            generatedVectors = []
    for mitem in declList:
        substs, t = gatherMethodInfo(mitem['dname'], mitem['dparams'], className, classNameOrig, classVariant)
        generated_hpp.write((proxyMethodTemplateDecl % substs) + ';')
    methodTable = ['%(className)s_%(methodName)s,' % {'methodName': p, 'className': className} for p in methodList]
    cpp.write(proxyMethodTableDecl % {'className': className, 'classNameOrig': classNameOrig, 'methodTable': '\n    '.join(['portal_disconnect,'] + methodTable)})
    subs = {'className': classCName, 'maxSize': (maxSize+1) * sizeofUint32_t,
            'reqInfo': '0x%x' % ((len(declList) << 16) + (maxSize+1) * sizeofUint32_t),
            'classNameOrig': classNameOrig }
    if classVariant:
        subs['handleStartup'] = 'channel = connnectalJsonDecode(p, channel, &tempdata, %(classNameOrig)sInfo);' % subs
    else:
        subs['handleStartup'] = 'volatile unsigned int* temp_working_addr = p->item->mapchannelInd(p, channel);'
        generated_hpp.write('\nenum { ' + ','.join(reqChanNums) + '};\n#define %(className)s_reqinfo %(reqInfo)s\n' % subs)
        hpp.write(proxyClassPrefixTemplate % subs)
        for mitem in declList:
            emitMethodDeclaration(mitem['dname'], mitem['dparams'], hpp, classCName)
        hpp.write('};\n')
    cpp.write((handleMessageTemplateDecl % subs))
    cpp.write(handleMessageTemplate1 % subs)
    for mitem in declList:
        substs, t = gatherMethodInfo(mitem['dname'], mitem['dparams'], className, classNameOrig, classVariant)
        if not classVariant:
            generated_hpp.write(messageStructTemplate % substs)
        cpp.write(handleMessageCase % substs)
    if not classVariant:
        elemList = []
        for mitem in declList:
            substs, t = gatherMethodInfo(mitem['dname'], mitem['dparams'], className, className, classVariant)
            elemList.append('%(channelName)sData %(methodName)s;' % substs)
        generated_hpp.write(portalStructTemplate % {'className': classCName, 'messageStructDeclarations': '\n    '.join(elemList)})
    cpp.write(handleMessageTemplate2 % subs)
    generated_hpp.write((handleMessageTemplateDecl % subs)+ ';\n')
    if not classVariant:
        hpp.write(wrapperClassPrefixTemplate % subs)
        for mitem in declList:
            emitMethodDeclaration(mitem['dname'], mitem['dparams'], hpp, '')
        hpp.write('};\n')
        cCNSubst = { 'classCName': classCName}
        generated_hpp.write('typedef struct {\n    PORTAL_DISCONNECT disconnect;\n')
        for mitem in declList:
            if verbose:
                for pitem in mitem['dparams']:
                    print 'generatecl/dparam', pitem
                    break
            paramValues = ', '.join([pitem['pname'] for pitem in mitem['dparams']])
            formalParamStr = formalParameters(mitem['dparams'], True)
            methodName = cName(mitem['dname'])
            generated_hpp.write(('    int (*%s) ( ' % methodName) + formalParamStr + ' );\n')
            generated_cpp.write(('int %s%s_cb ( ' % (classCName, methodName)) + formalParamStr + ' ) {\n')
            indent(generated_cpp, 4)
            generated_cpp.write(('(static_cast<%sWrapper *>(p->parent))->%s ( ' % (classCName, methodName)) + paramValues + ');\n')
            indent(generated_cpp, 4)
            generated_cpp.write('return 0;\n};\n')
        generated_hpp.write('} %(classCName)sCb;\n' % cCNSubst)
        generated_cpp.write('%(classCName)sCb %(classCName)s_cbTable = {\n    %(classCName)sdisconnect_cb,\n' % cCNSubst)
        for mitem in declList:
            generated_cpp.write('    %s%s_cb,\n' % (classCName, mitem['dname']))
        generated_cpp.write('};\n')
        hpp.write('#endif // _%(name)s_H_\n' % {'name': className.upper()})
        hpp.close()
    generated_hpp.write('extern %(classNameOrig)sCb %(className)sProxyReq;\n' % subs)
    cpp.close()

def emitStructMember(item, f, indentation):
    if verbose:
        print 'emitSM', item
    indent(f, indentation)
    f.write('%s %s' % (typeCName(item['ptype']), item['pname']))
    if hasBitWidth(item['ptype']):
        f.write(' : %d' % typeBitWidth(item['ptype']))
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

def emitType(item, name, f, indentation):
    indent(f, indentation)
    tmp = typeCName(item)
    if re.match('[0-9]+', tmp):
        if True or verbose:
            print 'cppgen/emitType: INFO ignore numeric typedef for', tmp
        return
    if not tmp or tmp[0] == '`' or tmp == 'Empty' or tmp[-2:] == '_P':
        if True or verbose:
            print 'cppgen/emitType: INFO ignore typedef for', tmp
        return
    if (indentation == 0):
        f.write('typedef ')
    f.write(tmp)
    if (indentation == 0):
        f.write(' %s;' % name)
    f.write('\n')

def emitEnum(item, name, f, indentation):
    indent(f, indentation)
    if (indentation == 0):
        f.write('typedef ')
    f.write('enum %s { ' % name)
    indent(f, indentation)
    for val in item['elements']:
        temp = val[0]
        if val[1] != None:
            temp += '=' + val[1]
        f.write(temp + ', ')
    indent(f, indentation)
    f.write(' }')
    if (indentation == 0):
        f.write(' %s;' % name)
    f.write('\n')

def emitCD(item, generated_hpp, indentation):
    if verbose:
        print 'cppgen/emitCD:', item
    n = item['tname']
    td = item['tdtype']
    t = td.get('type')
    if t == 'Enum':
        emitEnum(td, n, generated_hpp, indentation)
    elif t == 'Struct':
        emitStruct(td, n, generated_hpp, indentation)
    elif t == 'Type' or t == None:
        emitType(td, n, generated_hpp, indentation)
    else:
        print 'EMITCD', n, t, td

def generate_cpp(project_dir, noisyFlag, jsondata):
    global globalv_globalvars, verbose, bsvdefines
    def create_cpp_file(name):
        fname = os.path.join(project_dir, 'jni', name)
        f = util.createDirAndOpen(fname, 'w')
        if verbose:
            print "Writing file ",fname
        f.write('#include "GeneratedTypes.h"\n')
        return f

    verbose = noisyFlag
    bsvdefines = {}
    for binding in jsondata['bsvdefines']:
        if '=' in binding:
            print 'split', binding.split('=')
            var,val = binding.split('=')
            bsvdefines[var] = val
        else:
            bsvdefines[binding] = binding
    generatedCFiles = []
    globalv_globalvars = {}
    hname = os.path.join(project_dir, 'jni', 'GeneratedTypes.h')
    generated_hpp = util.createDirAndOpen(hname, 'w')
    generated_hpp.write('#ifndef __GENERATED_TYPES__\n')
    generated_hpp.write('#define __GENERATED_TYPES__\n')
    generated_hpp.write('#include "portal.h"\n')
    generated_hpp.write('#ifdef __cplusplus\n')
    generated_hpp.write('extern "C" {\n')
    generated_hpp.write('#endif\n')
    # global type declarations used by interface mthods
    for v in jsondata['globaldecls']:
        if v['dtype'] == 'TypeDef':
            globalv_globalvars[v['tname']] = v
            if v.get('tparams'):
                print 'Skipping C++ declaration for parameterized type', v['tname']
                continue
            emitCD(v, generated_hpp, 0)
    generated_hpp.write('\n')
    cppname = 'GeneratedCppCallbacks.cpp'
    generated_cpp = create_cpp_file(cppname)
    generatedCFiles.append(cppname)
    generated_cpp.write('\n#ifndef NO_CPP_PORTAL_CODE\n')
    for item in jsondata['interfaces']:
        if verbose:
            print 'generateclass', item
        generate_class(item['cname'],     '', item['cdecls'], generatedCFiles, create_cpp_file, generated_hpp, generated_cpp)
        generate_class(item['cname'], 'Json', item['cdecls'], generatedCFiles, create_cpp_file, generated_hpp, generated_cpp)
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
