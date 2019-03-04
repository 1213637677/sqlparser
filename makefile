sql-parser: sql_lex.l sql_yacc.y parse_node.h
	bison -dv sql_yacc.y
	flex -osql_lex.lex.c sql_lex.l
	gcc -o $@ sql_yacc.tab.c sql_lex.lex.c parse_node.c
