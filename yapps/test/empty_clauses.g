# This parser tests the use of OR clauses with one of them being empty
#
# The output of --dump should indicate the FOLLOW set for (A | ) is 'c'.

parser Test:
    rule TestPlus: ( A | ) 'c'
    rule A: 'a'+

    rule TestStar: ( B | ) 'c'
    rule B: 'b'*