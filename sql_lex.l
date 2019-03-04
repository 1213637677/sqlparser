%option noyywrap nodefault yylineno case-insensitive
%{
	#include <stdio.h>
	
	#include "parse_node.h"
	#include "sql_yacc.tab.h"
	
	//int yylval;

//; { printf("end\n"); return END; }
//"=" { printf("equal\n"); return EQUAL; }
//">" { printf("great\n"); return GREAT; }
//"<" { printf("less\n"); return LESS; }
//">=" { printf("greatequal\n"); return GREATEQUAL; }
//"<=" { printf("lessequal\n"); return LESSEQUAL; }
%}
%x BTWMODE

%%
SELECT { printf("select\n"); return SELECT; }
FROM { printf("from\n"); return FROM; }
WHERE { printf("where\n"); return WHERE; }
AND { printf("and\n"); return AND; }
OR { printf("or\n"); return OR; }
XOR { printf("xor\n"); return XOR; }
NOT { printf("not\n"); return NOT; }
LIKE { printf("like\n"); return LIKE; }
IS { printf("is\n"); return IS; }
NULL { printf("null\n"); return NULLX; }
IN { printf("in\n"); return IN; }
EXISTS { printf("exists\n"); return EXISTS; }
GROUP { printf("group\n"); return GROUP; }
BY { printf("by\n"); return BY; }
ASC { printf("asc\n"); return ASC; }
DESC { printf("desc\n"); return DESC; }
WITH { printf("with\n"); return WITH; }
ROLLUP { printf("rollup\n"); return ROLLUP; }
HAVING { printf("having\n"); return HAVING; }
ORDER { printf("order\n"); return ORDER; }
LIMIT { printf("limit\n"); return LIMIT; }
INTO { printf("into\n"); return INTO; }
ALL { printf("all\n"); return ALL; }
DISTINCT { printf("distinct\n"); return DISTINCT; }
DISTINCTROW { printf("distinctrow\n"); return DISTINCTROW; }
HIGH_PRIORITY { printf("high_priority\n"); return HIGH_PRIORITY; }
STRAIGHT_JOIN { printf("straight_join\n"); return STRAIGHT_JOIN; }
SQL_SMALL_RESULT { printf("sql_small_result\n"); return SQL_SMALL_RESULT; }
SQL_BIG_RESULT { printf("sql_big_result\n"); return SQL_BIG_RESULT; }
SQL_CALC_FOUND_ROWS { printf("sql_calc_found_rows\n"); return SQL_CALC_FOUND_ROWS; }
AS { printf("as\n"); return AS; }
JOIN { printf("join\n"); return JOIN; }
INNER { printf("inner\n"); return INNER; }
CROSS { printf("cross\n"); return CROSS; }
OUTER { printf("outer\n"); return OUTER; }
LEFT { printf("left\n"); return LEFT; }
RIGHT { printf("RIGHT\n"); return RIGHT; }
ON { printf("on\n"); return ON; }
USING { printf("using\n"); return USING; }
USE { printf("use\n"); return USE; }
KEY { printf("key\n"); return KEY; }
INDEX { printf("index\n"); return INDEX; }
FOR { printf("for\n"); return FOR; }
NATURAL { printf("natural\n"); return NATURAL; }
BETWEEN { BEGIN(BTWMODE); return BETWEEN; }
<BTWMODE>AND { BEGIN(INITIAL); return BTWAND; }
FORCE {printf("force"); BEGIN INITIAL; return FORCE; }
IGNORE {printf("ignore"); BEGIN INITIAL; return IGNORE; }
ANY {printf("any"); BEGIN INITIAL; return ANY; }
SOME {printf("some"); BEGIN INITIAL; return SOME; }
COUNT {printf("count"); return FCOUNT; }

-?[0-9]+ { yylval.strval = strdup(yytext); return INTNUM; }

-?[0-9]+"."[0-9]* |
-?"."[0-9]+ |
-?[0-9]+E[-+]?[0-9]+ |
-?[0-9]+"."[0-9]*E[-+]?[0-9]+ |
-?"."[0-9]+E[-+]?[0-9]+ { yylval.strval = strdup(yytext); return APPROXNUM; }

TRUE |
UNKNOWN |
FALSE { yylval.strval = strdup(yytext); return BOOL; }

'(\\.|''|[^'\n])*' |
\"(\\.|\"\"|[^"\n])*\" { yylval.strval = strdup(yytext); return STRING; }
'(\\.|[^'\n])*$ { yyerror("Unterminated string %s", yytext); }
\"(\\.|[^"\n])*$ { yyerror("Unterminated string %s", yytext); }

X'[0-9A-F]+' |
OX[0-9A-F]+ { yylval.strval = strdup(yytext); return STRING; }

OB[01]+ |
B'[01]+' { yylval.strval = strdup(yytext); return STRING; }


[-+&~|^/%*(),.;!] { return yytext[0]; }
"&&" { return AND; }
"||" { return OR; }
"=" |
"<=>" |
">=" |
">" |
"<=" |
"<" |
"!=" |
"<>" { yylval.strval = strdup(yytext); return COMPARISON; }
"<<" |
">>" { yylval.strval = strdup(yytext); return SHIFT; }
":=" { return ASSIGN; }


[A-Za-z][A-Za-z0-9_]* { yylval.strval = strdup(yytext); return NAME; }
`[^`/\\.\n]+` {yylval.strval = strdup(yytext+1); yylval.strval[yyleng-2] = 0; return NAME; }
`[^`\n]*$ { yyerror("unterminated quoted name %s", yytext); }

[ \t] {}
. { printf("unknown character in input: %c\n", *yytext); }
%%


