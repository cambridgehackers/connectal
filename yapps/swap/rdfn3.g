# rfdn3.g -- a Yapps grammar for RDF Notation 3
#
# 
# Share and Enjoy. Open Source license:
# Copyright (c) 2001 W3C (MIT, INRIA, Keio)
# http://www.w3.org/Consortium/Legal/copyright-software-19980720
# $Id: rdfn3.g,v 1.18 2002/08/15 23:20:36 connolly Exp $
# see log at end
#
# REFERENCES
# Yapps: Yet Another Python Parser System
# http://theory.stanford.edu/~amitp/Yapps/
# Sat, 18 Aug 2001 16:54:32 GMT
# Last modified 13:21 Sun 26 Nov 2000 , Amit Patel 
#
# http://www.w3.org/DesignIssues/Notation3

import string

import uripath
from ConstTerm import Symbol, StringLiteral, Namespace

RDF = Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#')
LIST = Namespace("http://www.daml.org/2001/03/daml+oil#")
DPO = Namespace("http://www.daml.org/2001/03/daml+oil#")
LOG = Namespace("http://www.w3.org/2000/10/swap/log#")

%%
parser _Parser:
    ignore: r'\s+'         # whitespace. @@count lines?
    ignore: r'#.*\r?\n'    # n3 comments; sh/perl style

    token URIREF:   r'<[^ \n>]*>'
    token PREFIX:   r'[a-zA-Z0-9_-]*:'
    token QNAME:    r'([a-zA-Z][a-zA-Z0-9_-]*)?:[a-zA-Z0-9_-]+'
    token EXVAR:    r'_:[a-zA-Z0-9_-]+'
    token UVAR:     r'\?[a-zA-Z0-9_-]+'
    token INTLIT:   r'-?\d+'
    token STRLIT1:  r'"([^\"\\\n]|\\[\\\"nrt])*"'
    token STRLIT2:  r"'([^\'\\\n]|\\[\\\'nrt])*'"
    token STRLIT3:  r'"""([^\"\\]|\\[\\\"nrt])*"""' #@@not right

    # clause terminator: . followed by }
    # @@ this should allow comments...
    token TERM:     r'\.(?=\s*})'

    # clause separator: . *not* followed by }
    token SEP:      r'\.(?!\s*})'

    # phrase terminator: ; followed by . or }
    # @@ this should allow comments...
    token PTERM:     r';(?=\s*[\.}])'

    # clause separator: . *not* followed by }
    token PSEP:     r';(?!\s*[\.}])'

    token END:      r'\Z'

    rule document:
              {{ self.bindListPrefix(); scp = self.docScope() }}
         ( directive | statement<<scp>> ) * END

    rule directive : "@prefix" PREFIX URIREF SEP
              {{ self.bind(PREFIX[:-1], URIREF) }}

    # foos0 is mnemonic for 0 or more foos
    # foos1      "          1 or more foos

    rule statement<<scp>> : clause_ind<<scp>> SEP

    rule clause_ind<<scp>>:
         phrase<<scp>>
           [predicate<<scp, phrase>>
            (PSEP [predicate<<scp, phrase>>])* ] [PTERM]
       | term<<scp>>
            predicate<<scp, term>> (PSEP [predicate<<scp, term>>])* [PTERM]

    rule term<<scp>>:
                expr<<scp>>     {{ return expr }}
              | name           {{ return name }}
              
    rule predicate<<scp,subj>>: verb<<scp>> objects1<<scp,subj,verb>>

    rule verb<<scp>> :
          term<<scp>>           {{ return (1, term) }}
        | "is" term<<scp>> "of" {{ return (-1, term) }}
    # earlier N3 specs had more verb sugar...


    # This is the central rule for recognizing a fact.
    rule objects1<<scp,subj,verb>> :
        term<<scp>>  {{ self.gotStatement(scp, subj, verb, term) }}
        ("," term<<scp>>
                     {{ self.gotStatement(scp, subj, verb, term) }}
         )*


    # details about terms...

    rule name:
                URIREF        {{ return self.uriref(URIREF) }}
              | QNAME         {{ return self.qname(QNAME) }}
              | "a"           {{ return self.termA() }}
              | "="           {{ return self.termEq() }}

    rule expr<<scp>>:
                "this"        {{ return scp }}
              | EXVAR         {{ return self.lname(EXVAR) }}
              | UVAR          {{ return self.vname(UVAR) }}
              | INTLIT        {{ return self.intLit(INTLIT) }}
              | STRLIT3       {{ return self.strlit(STRLIT3, '"""') }}
              | STRLIT1       {{ return self.strlit(STRLIT1, '"') }}
              | STRLIT2       {{ return self.strlit(STRLIT2, "'") }}
              | list<<scp>>   {{ return list }}
              | phrase<<scp>> {{ return phrase }}
              | clause_sub    {{ return clause_sub }}

    rule list<<scp>> : "\\(" {{ items = [] }}
	 item<<scp, items>> *
	 "\\)" {{ return self.mkList(scp, items) }}

    rule item<<scp, items>> : term<<scp>> {{ items.append(term) }}

    rule phrase<<scp>>:
        "\\[" {{ subj = self.something(scp) }}
        [predicate<<scp, subj>> (PSEP predicate<<scp, subj>>)* [PTERM] ]
        "\\]" {{ return subj }}

    rule clause_sub:
        "{" {{ scp = self.newScope() }}
        [ clause_ind<<scp>> (SEP clause_ind<<scp>>)* [TERM] ]
        "}" {{ return scp }}

%%

def scanner(text):
    return _ParserScanner(text)

class BadSyntax(SyntaxError):
    pass


class Parser(_Parser):
    def __init__(self, scanner, sink, baseURI):
        _Parser.__init__(self, scanner)
        self._sink = sink
	self._docScope = sink.newFormula()
        self._baseURI = baseURI
        self._prefixes = {}
        self._serial = 1
        self._lnames = {}
        self._vnames = {}

    def docScope(self):
	return self._docScope

    def uriref(self, str):
        return Symbol(uripath.join(self._baseURI, str[1:-1]))

    def qname(self, str):
        i = string.find(str, ":")
        pfx = str[:i]
        ln = str[i+1:]
        try:
            ns = self._prefixes[pfx]
        except:
            raise BadSyntax, "prefix %s not bound" % pfx
        else:
            return Symbol(ns + ln)

    def lname(self, str):
        n = str[2:]
        try:
            return self._lnames[n]
        except KeyError:
            x = self.docScope().mkVar(n)
            self._lnames[n] = x
            return x

    def vname(self, str):
        n = str[1:]
        try:
            return self._vnames[n]
        except KeyError:
            x = self.docScope().mkVar(n, 1)
            self._vnames[n] = x
            return x

    def termA(self):
        return RDF['type']
    
    def termEq(self):
        return DAML['equivalentTo']

    def strlit(self, str, delim):
        return StringLiteral(str[1:-1]) #@@BROKEN un-escaping

    def intLit(self, str):
        try:
            v = int(str)
        except ValueError:
            v = long(str)
        return IntegerLiteral(v) #@@

    def bindListPrefix(self):
        self._sink.bind("l", LIST.name())
        self._sink.bind("r", RDF.name())
    
    def bind(self, pfx, ref):
        ref = ref[1:-1] # take of <>'s
        addr = uripath.join(self._baseURI, ref)
        #DEBUG("bind", pfx, ref, addr)
        self._sink.bind(pfx, addr)
        #@@ check for pfx already bound?
        self._prefixes[pfx] = addr

    def gotStatement(self, scp, subj, verb, obj):
	#DEBUG("gotStatement:", scp, subj, verb, obj)
        
        dir, pred = verb
        if dir<0: subj, obj = obj, subj
	if scp is subj and pred is LOG['forAll']:
	    DEBUG("@@bogus forAll", obj)
	elif scp is subj and pred is LOG['forSome']:
	    DEBUG("@@bogus forSome", obj)
	else:
	    scp.add(pred, subj, obj)

    def newScope(self):
        return self._sink.newFormula()

    def something(self, scp, hint="thing",
                  univ = 0):
	return scp.mkVar(hint, univ)


    def mkList(self, scp, items):
	tail = None
	head = LIST['nil']
	say = scp.add
	for term in items:
	    cons = scp.mkVar("cons")
	    say(LIST['first'], cons, term)
	    if tail:
	        say(LIST['rest'], tail, cons)
	    tail = cons
	    if not head: head = cons
	if tail:
	    say(LIST['rest'], tail, LIST['nil'])
	return head


def DEBUG(*args):
    import sys
    for a in args:
        sys.stderr.write("%s " % (a,))
    sys.stderr.write("\n")
    
# $Log: rdfn3.g,v $
# Revision 1.18  2002/08/15 23:20:36  connolly
# fixed . separater/terminator grammar problem
#
# Revision 1.17  2002/08/13 07:55:15  connolly
# playing with a new parser/sink interface
#
# Revision 1.16  2002/08/07 16:01:23  connolly
# working on datatypes
#
# Revision 1.15  2002/06/21 16:04:02  connolly
# implemented list handling
#
# Revision 1.14  2002/01/12 23:37:14  connolly
# allow . after ;
#
# Revision 1.13  2001/09/06 19:55:13  connolly
# started N3 list semantics. got KIFSink working well enough to discuss
#
# Revision 1.12  2001/09/01 05:56:28  connolly
# the name rule does not need a scope param
#
# Revision 1.11  2001/09/01 05:31:17  connolly
# - gram2html.py generates HTML version of grammar from rdfn3.g
# - make use of [] in rdfn3.g
# - more inline terminals
# - jargon change: scopes rather than contexts
# - term rule split into name, expr; got rid of shorthand
#
# Revision 1.10  2001/08/31 22:59:58  connolly
# ?foo for universally quantified variables; document-scoped, ala _:foo
#
# Revision 1.9  2001/08/31 22:27:57  connolly
# added support for _:foo as per n-triples
#
# Revision 1.8  2001/08/31 22:15:44  connolly
# aha! fixed serious arg-ordering bug; a few other small clean-ups
#
# Revision 1.7  2001/08/31 21:28:39  connolly
# quick release for others to test
#
# Revision 1.6  2001/08/31 21:14:11  connolly
# semantic actions are starting to work;
# anonymous stuff ( {}, [] ) doesn't seem
# to be handled correctly yet.
#
# Revision 1.5  2001/08/31 19:10:58  connolly
# moved term rule for easier reading
#
# Revision 1.4  2001/08/31 19:06:20  connolly
# added END/eof token
#
# Revision 1.3  2001/08/31 18:55:47  connolly
# cosmetic/naming tweaks
#
# Revision 1.2  2001/08/31 18:46:59  connolly
# parses test/vocabCheck.n3
#
# Revision 1.1  2001/08/31 17:51:08  connolly
# starting to work...
#
