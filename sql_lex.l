%option noyywrap
%{
	#include <stdio.h>
	#include "parse_node.h"
	#include "sql_yacc.tab.h"
	
	//int yylval;
%}

%%
SELECT {printf("select\n"); return SELECT;}
FROM {printf("from\n"); return FROM;}
; {printf("end\n"); return END;}
[a-z*]+ {printf("variable is %s\n", yytext); return VARIABLE;}
[ \t] {}
%%


