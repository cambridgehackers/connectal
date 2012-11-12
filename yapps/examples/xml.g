#!/usr/bin/python2

# xml.g
#
# Amit J. Patel, August 2003
#
# Simple (non-conforming, non-validating) parsing of XML documents,
# based on Robert D. Cameron's "REX" shallow parser.  It doesn't
# handle CDATA and lots of other stuff; it's meant to demonstrate
# Yapps, not replace a proper XML parser.

%%

parser xml:
    token nodetext: r'[^<>]+'
    token attrtext_singlequote: "[^']*"
    token attrtext_doublequote: '[^"]*'
    token SP: r'\s'
    token id: r'[a-zA-Z_:][a-zA-Z0-9_:.-]*'

    rule node:
        r'<!--.*?-->'                   {{ return ['!--comment'] }}
      | r'<!\[CDATA\[.*?\]\]>'          {{ return ['![CDATA['] }}
      | r'<!' SP* id '[^>]*>'           {{ return ['!doctype'] }}
      | '<' SP* id SP* attributes SP*   {{ startid = id }}
        ( '>' nodes '</' SP* id SP* '>' {{ assert startid == id, 'Mismatched tags <%s> ... </%s>' % (startid, id) }}
                                        {{ return [id, attributes] + nodes }}
        | '/\s*>'                       {{ return [id, attributes] }}
        )
      | nodetext                        {{ return nodetext }}

    rule nodes:                         {{ result = [] }}
         ( node                         {{ result.append(node) }}
         ) *                            {{ return result }}

    rule attribute: id SP* '=' SP*
         ( '"' attrtext_doublequote '"' {{ return (id, attrtext_doublequote) }}
         | "'" attrtext_singlequote "'" {{ return (id, attrtext_singlequote) }}
         )

    rule attributes:                    {{ result = {} }}
         ( attribute SP*                {{ result[attribute[0]] = attribute[1] }}
         ) *                            {{ return result }}

%%

if __name__ == '__main__':
    tests = ['<!-- hello -->',
             'some text',
             '< bad xml',
             '<br />',
             '<     spacey      a  =   "foo"    /   >',
             '<a href="foo">text ... </a>',
             '<begin> middle </end>',
             '<begin> <nested attr=\'baz\' another="hey"> foo </nested> <nested> bar </nested> </begin>',
            ]
    print
    print '____Running tests_______________________________________'
    for test in tests:
        print
        try:
            parser = xml(xmlScanner(test))
            output = '%s ==> %s' % (repr(test), repr(parser.node()))
        except (yappsrt.SyntaxError, AssertionError), e:
            output = '%s ==> FAILED ==> %s' % (repr(test), e)
        print output
