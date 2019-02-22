%{
#include <stdlib.h>
#include <stdio.h>
#include "parse_node.h"
int yylex(void);
void yyerror(char *s, ...);
%}

/*union不能直接使用string*/
%union U{
struct ast *a;
char *s;
}

%token END
%token <s> VARIABLE
%token QUERY SELECT FROM
%type <a> field table value select_exp query

%%

query: /* 空规则 */
 |  select_exp
    {
        showtree($1, 0);
	//printf("%d", $1->nodelist[0]->nodelist[0]->nodetype);
	//printf("%d", $1->nodelist[1]->nodelist[0]->nodetype);
        //printf("-----select");
    }
 |  query select_exp
    {
        showtree($2, 0);
	//printf("%d", $1->nodelist[0]->nodelist[0]->nodetype);
	//printf("%d", $1->nodelist[1]->nodelist[0]->nodetype);
        //printf("-----select");
    }
 /*| insert_exp END { printf("-----insert")}*/
 /*| update_exp END { printf("-----update")}*/
 /*| delete_exp END { printf("-----delete")}*/
 ;

select_exp:
    SELECT field FROM table END
    {
        struct ast **field;
        field = (struct ast**)malloc(sizeof(struct ast*));
        field[0] = $2;
        struct ast **table;
        table = (struct ast**)malloc(sizeof(struct ast*));
        table[0] = $4;
        struct ast **exp;
	exp = (struct ast**)malloc(sizeof(struct ast*) * 2);
	exp[0] = newast(SELECT, 1, field);
        exp[1] = newast(FROM, 1, table);
        $$ = newast(QUERY, 2, exp);
    }
 ;

field:value { $$ = $1; }
 ;

table:value { $$ = $1; }
 ;

value:VARIABLE { $$ = newnode(VARIABLE, $1); }

%%

void yyerror(char *s, ...)
{
	printf("error");
}

int main()
{
	yyparse();
	return 0;
}
