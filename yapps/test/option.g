
%%

parser test_option:
    ignore: r'\s+'
    token a: 'a'
    token b: 'b'
    token EOF: r'$'

    rule test_brackets: a [b] EOF

    rule test_question_mark: a b? EOF

%%

# The generated code for test_brackets and test_question_mark should
# be the same.
