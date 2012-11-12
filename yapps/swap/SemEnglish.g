"""

transcribed from

http://robustai.net/mentography/SyntaxSemenglish7.gif
Last Modified: Sunday, 22-Jul-01 19:59:51 GMT

other sources:

  SemEnglish Primer 
  Created 2001/1/26 last revised 2001/3/25 
  pronounced `sem.Eng.lish 
  http://robustai.net/mentography/semenglish.html
"""

%%

parser SemEnglish:

    ignore: r'[ \r\n\t\f]+'

    token Dquote: r'"[^\"]*"'
    token Squote: r"'[^\']*'"
    token Number: r'[0-9]+' # decimals? e-notation?

    token THAT: "that"
    token Word: r'[^ \n\r\t\f"\)\({}\[\];]*[^ \n\r\t\f"\)\({}\[\];\.0-9]' # @@not single quotes either
    token END: "\Z"

    rule document: Statement* END

    rule Statement: Subject Predicate AddPredicate* ["\\."]
	 {{ print "@@got one statement" }}

    rule Subject: CompoundWords
		| Word
		| Number
		| AnnNode

    rule CompoundWords: "\\(" Word+ "\\)"

    rule AnnNode: "\\[" Predicate "\\]"

    rule Predicate: Verb Object AddObject*

    rule AddPredicate: ";" Predicate

    rule Verb: CompoundWords
	     | Word

    rule Object: CompoundWords
	       | ExpObject
	       | Expression

    rule AddObject: "," Object

    rule ExpObject: Word | Number | AnnNode
		  | ReifiedStatement | Context | Literal

    rule ReifiedStatement: THAT "\\(" Subject Verb Object "\\)"

    rule Context: "{" Statement* "}"
    
    rule Literal: Dquote | Squote

    rule Expression: "exp" Nexpression

    rule Nexpression: "\\(" Verb ExpObject_ + "\\)"

    rule ExpObject_ : ExpObject
		    | Nexpression
