%{
#include <stdlib.h>
#include <stdio.h>
#include "parse_node.h"
int yylex(void);
void yyerror(char *s, ...);
int select_opt_state = 0;
%}

/*union不能直接使用string*/
%union U{
	struct ast *a;
	char *strval;
	int intval;
}

/*基本数据类型*/
%token <strval> NAME
%token <strval> STRING
%token <strval> INTNUM
%token <strval> BOOL
%token <strval> APPROXNUM

/*操作符优先级*/
%right ASSIGN
%left OR
%left XOR
%left AND
%nonassoc IN IS LIKE REGEXP
%left NOT '!'
%left BETWEEN
%left <strval> COMPARISON
%left '|'
%left '&'
%left <strval> SHIFT
%left '+' '-'
%left '*' '/' '%' MOD
%left '^'
%nonassoc UMINUS

/*新关键字*/
%token ADD SUB MUL DIV MOD AND OR XOR OROP ANDOP XOROP SHIFT NOT COMPARISON COMPARISON_ANY COMPARISON_SOME COMPARISON_ALL BETWEEN BTWAND LIKE NOTLIKE IS ISNOT NULLX IN NOTIN EXISTS SELECT SELECT_QUERY FROM WHERE GROUP BY GROUP_BY BY_NODE ASC DESC WITH_ROLLUP HAVING ORDER ORDER_BY LIMIT INTO ALL DISTINCT DISTINCTROW HIGH_PRIORITY STRAIGHT_JOIN SQL_SMALL_RESULT SQL_BIG_RESULT SQL_CALC_FOUND_ROWS ALLCOLUMN AS DTNAME JOIN JOINTYPE INNER CROSS OUTER LEFT RIGHT ON USING USE INDEXTYPE KEY INDEX FOR NATURAL FORCE IGNORE WITH ROLLUP ANY SOME TFNAME FUNC_NAME FCOUNT

/*新节点值*/
%type <a> stmt_list stmt expr val_list select_stmt opt_where opt_groupby groupby_list opt_asc_desc opt_with_rollup opt_having opt_orderby opt_limit opt_into_list column_list select_opts select_expr_list select_expr opt_as_alias table_references table_reference table_factor opt_as join_table opt_join_condition join_condition index_hint_list index_hint index_list table_subquery opt_val_list
%type <intval> opt_inner_cross opt_outer left_or_right opt_left_or_right key_or_index opt_for_join 

%%

/***顶层分析***/

stmt_list: stmt ';' { showtree($1,0); $$ = $1; }
 |  stmt_list stmt ';' { showtree($2,0); $2->nextnode = $1; $$ = $2; }
 ;

/***表达式***/
expr: NAME { $$ = newnode_1(NAME, $1); }
 |  NAME '.' NAME { struct ast *child = newnode_1(NAME, $1); child->nextnode = newnode_1(NAME, $3); $$ = newast(TFNAME, child); }
 |  STRING { $$ = newnode_1(STRING, $1); }
 |  INTNUM { $$ = newnode_1(INTNUM, $1); }
 |  BOOL { $$ = newnode_1(BOOL, $1); }
 |  APPROXNUM { $$ = newnode_1(APPROXNUM, $1); }
 ;
expr: expr '+' expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(ADD, child); }
 |  expr '-' expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(SUB, child); }
 |  expr '*' expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(MUL, child); }
 |  expr '/' expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(DIV, child); }
 |  expr '%' expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(MOD, child); }
 |  expr MOD expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(MOD, child); }
 |  '-' expr %prec UMINUS { $$ = newast(UMINUS, $2); }
 |  expr AND expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(AND, child); }
 |  expr OR expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(OR, child); }
 |  expr XOR expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(XOR, child); }
 |  expr '|' expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(OROP, child); }
 |  expr '&' expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(ANDOP, child); }
 |  expr '^' expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(XOROP, child); }
 |  expr SHIFT expr { struct ast *child = $1; child->nextnode = $3; $$ = newast_1(SHIFT, child, $2); }
 |  NOT expr { $$ = newast(NOT, $2); }
 |  '!' expr { $$ = newast(NOT, $2); }
 |  expr COMPARISON expr { struct ast *child = $1; child->nextnode = $3; $$ = newast_1(COMPARISON, child, $2); }
 |  expr BETWEEN expr BTWAND expr %prec BETWEEN { struct ast *child = $1; child->nextnode = $3; child->nextnode->nextnode = $5; $$ = newast(BETWEEN, child); }
 |  expr LIKE expr { struct ast *child = $1; child->nextnode = $3; $$ = newast(LIKE, child); }
 |  expr NOT LIKE expr { struct ast *child = $1; child->nextnode = $4; $$ = newast(NOTLIKE, child); }
/*递归select和比较表达式*/
 |  expr COMPARISON '(' select_stmt ')' { struct ast *child = $1; child->nextnode = $4; $$ = newast_1(COMPARISON, child, $2); }
 |  expr COMPARISON ANY '(' select_stmt ')' { struct ast *child = $1; child->nextnode = $5; $$ = newast_1(COMPARISON_ANY, child, $2); }
 |  expr COMPARISON SOME '(' select_stmt ')' { struct ast *child = $1; child->nextnode = $5; $$ = newast_1(COMPARISON_SOME, child, $2); }
 |  expr COMPARISON ALL '(' select_stmt ')' { struct ast *child = $1; child->nextnode = $5; $$ = newast_1(COMPARISON_ALL, child, $2); }
 ;
expr: expr IS NULLX { struct ast *child = $1; child->nextnode = newnode(NULLX); $$ = newast(IS, child); }
 |  expr IS NOT NULLX { struct ast *child = $1; child->nextnode = newnode(NULLX); $$ = newast(ISNOT, child); }
 |  expr IS BOOL { struct ast *child = $1; child->nextnode = newnode_1(BOOL, $3); $$ = newast(IS, child); }
 |  expr IS NOT BOOL { struct ast *child = $1; child->nextnode = newnode_1(BOOL, $4); $$ = newast(ISNOT, child); }
 ;
val_list: expr { $$ = $1; }
 |  expr ',' val_list { $1->nextnode = $3; $$ = $1; }
 ;
opt_val_list: /* 空规则 */ { $$ = NULL; }
 | val_list { $$ = $1; }
 ;
expr: expr IN '(' val_list ')' { struct ast *child = $1; child->nextnode = $4; $$ = newast(IN, child); }
 |  expr NOT IN '(' val_list ')' { struct ast *child = $1; child->nextnode = $5; $$ = newast(NOTIN, child); }
 |  expr IN '(' select_stmt ')' { struct ast *child = $1; child->nextnode = $4; $$ = newast(IN, child); }
 |  expr NOT IN '(' select_stmt ')' { struct ast *child = $1; child->nextnode = $5; $$ = newast(NOTIN, child); }
 |  EXISTS '(' select_stmt ')' { struct ast *child = $3; $$ = newast(EXISTS, child); }
 ;
/*函数*/
expr: NAME '(' opt_val_list ')' { struct ast *rtn = newnode_1(FUNC_NAME, $1); rtn->childnode = $3; $$ = rtn; }
 ;
expr: FCOUNT '(' '*' ')' { struct ast *rtn = newnode_1(FUNC_NAME, "COUNT"); rtn->childnode = newnode(ALLCOLUMN); $$ = rtn; }
 |  FCOUNT '(' expr ')' { struct ast *rtn = newnode_1(FUNC_NAME, "COUNT"); rtn->childnode = $3; $$ = rtn; }
/***select语句***/
stmt: select_stmt { $$ = $1; }
 ;

select_stmt: SELECT select_opts select_expr_list { struct ast *temp = $3; if(temp->nextnode != NULL) temp = temp->nextnode; temp->nextnode = $2; $$ = newast(SELECT_QUERY, newast(SELECT, $3)); }
 |  SELECT select_opts select_expr_list FROM table_references opt_where opt_groupby opt_having opt_orderby opt_limit opt_into_list
    {
        struct ast *temp = $3; if(temp->nextnode != NULL) temp = temp->nextnode; temp->nextnode = $2; struct ast *child = newast(SELECT, $3); struct ast *it = child; it->nextnode = newast(FROM, $5); it = it->nextnode;
        if($6 != NULL) { it->nextnode = $6; it = it->nextnode; } if($7 != NULL) { it->nextnode = $7; it = it->nextnode; } if($8 != NULL) { it->nextnode = $8; it = it->nextnode; } if($9 != NULL) { it->nextnode = $9; it = it->nextnode; } if($10 != NULL) { it->nextnode = $10; it = it->nextnode; } if($11 != NULL) { it->nextnode = $11; it = it->nextnode; }
        $$ = newast(SELECT_QUERY, child);
    }
 ;

opt_where: /* 空规则 */ { $$ = NULL; }
 |  WHERE expr { $$ = newast(WHERE, $2); }
 ;

opt_groupby: /* 空规则 */ { $$ = NULL; }
 |  GROUP BY groupby_list opt_with_rollup { if($4 != NULL) { $4->nextnode = $3; $$ = newast(GROUP_BY, $4); } else $$ = newast(GROUP_BY, $3); }
 ;

groupby_list: expr opt_asc_desc { if($2 != NULL) { struct ast *child = $1; child->nextnode = $2; $$ = newast(BY_NODE, child); } else $$ = $1; }
 | groupby_list ',' expr opt_asc_desc { if($4 != NULL) { struct ast *child = $3; child->nextnode = $4; child = newast(BY_NODE, child); child->nextnode = $1; $$ = child; } else { $3->nextnode = $1; $$ = $3; }; }
 ;

opt_asc_desc: /* 空规则 */ { $$ = NULL; }
 |  ASC { $$ = newnode(ASC); }
 |  DESC { $$ = newnode(DESC); }
 ;

opt_with_rollup: /* 空规则 */ { $$ = NULL; }
 |  WITH ROLLUP { $$ = newnode(WITH_ROLLUP); }
 ;

opt_having: /* 空规则 */ { $$ = NULL; }
 |  HAVING expr { $$ = newast(HAVING, $2); }
 ;

opt_orderby: /* 空规则 */ { $$ = NULL; }
 |  ORDER BY groupby_list { $$ = newast(ORDER_BY, $3); }
 ;

opt_limit: /* 空规则 */ { $$ = NULL; }
 |  LIMIT expr { $$ = newast(LIMIT, $2); }
 |  LIMIT expr ',' expr { $2->nextnode = $4; $$ = newast(LIMIT, $2); }
 ;

opt_into_list: /* 空规则 */ { $$ = NULL; }
 |  INTO column_list { $$ = newast(INTO, $2); }
 ;

column_list: NAME { $$ = newnode_1(NAME, $1); }
 |  column_list ',' NAME { struct ast *node = newnode_1(NAME, $3); node->nextnode = $1; $$ = node; }
 ;
/***select选项和表引用***/
select_opts: { select_opt_state = 0; $$ = NULL; }
 |  select_opts ALL { if(select_opt_state & 01) yyerror("duplicate A-D-D option"); select_opt_state = select_opt_state | 01; struct ast *nodelist = newnode(ALL); nodelist->nextnode = $1; $$ = nodelist; }
 |  select_opts DISTINCT { if(select_opt_state & 01) yyerror("duplicate A-D-D option"); select_opt_state = select_opt_state | 01; struct ast *nodelist = newnode(DISTINCT); nodelist->nextnode = $1; $$ = nodelist; }
 |  select_opts DISTINCTROW { if(select_opt_state & 01) yyerror("duplicate A-D-D option"); select_opt_state = select_opt_state | 01; struct ast *nodelist = newnode(DISTINCTROW); nodelist->nextnode = $1; $$ = nodelist; }
 |  select_opts HIGH_PRIORITY { if(select_opt_state & 02) yyerror("duplicate HIGH_PRIORITY option"); select_opt_state = select_opt_state | 02; struct ast *nodelist = newnode(HIGH_PRIORITY); nodelist->nextnode = $1; $$ = nodelist; }
 |  select_opts STRAIGHT_JOIN { if(select_opt_state & 04) yyerror("duplicate STRAIGHT_JOIN option"); select_opt_state = select_opt_state | 04; struct ast *nodelist = newnode(STRAIGHT_JOIN); nodelist->nextnode = $1; $$ = nodelist; }
 |  select_opts SQL_SMALL_RESULT { if(select_opt_state & 010) yyerror("duplicate SQL_SMALL_RESULT option"); select_opt_state = select_opt_state | 010; struct ast *nodelist = newnode(SQL_SMALL_RESULT); nodelist->nextnode = $1; $$ = nodelist; }
 |  select_opts SQL_BIG_RESULT { if(select_opt_state & 020) yyerror("duplicate SQL_BIG_RESULT option"); select_opt_state = select_opt_state | 020; struct ast *nodelist = newnode(SQL_BIG_RESULT); nodelist->nextnode = $1; $$ = nodelist; }
 |  select_opts SQL_CALC_FOUND_ROWS { if(select_opt_state & 040) yyerror("duplicate SQL_CALC_FOUND_ROWS option"); select_opt_state = select_opt_state | 040; struct ast *nodelist = newnode(SQL_CALC_FOUND_ROWS); nodelist->nextnode = $1; $$ = nodelist; }
 ;

select_expr_list: select_expr { $$ = $1; }
 |  select_expr_list ',' select_expr { struct ast *child = $3; child->nextnode = $1; $$ = child; }
 |  '*' { $$ = newnode(ALLCOLUMN); }
 ;
/*应该还可以添加*/
//select_expr: expr { $$ = $1; }
// |  expr AS NAME { struct ast *child = $1; child->nextnode = newnode(NAME, $3); $$ = newast(AS, child); }
// |  expr NAME { struct ast *child = $1; child->nextnode = newnode(NAME, $2); $$ = newast(AS, child); }
// ;
select_expr: expr opt_as_alias { if($2 == NULL) $$ = $1; else { $1->nextnode = $2->childnode; $2->childnode = $1; $$ = $2; } }
 ;
opt_as_alias: AS NAME { $$ = newast(AS, newnode_1(NAME, $2)); }
 |  NAME { $$ = newast(AS, newnode_1(NAME, $1)); }
 |  /*空规则*/ { $$ = NULL; }
 ;
/***select表引用***/
table_references: table_reference { $$ = $1; }
 |  table_references ',' table_reference { struct ast *child = $3; $3->nextnode = $1; $$ = $1; }
 ;

table_reference: table_factor { $$ = $1; }
 |  join_table { $$ = $1; }
 ;

table_factor: NAME opt_as_alias index_hint_list { struct ast *node = newnode_1(NAME, $1); node->childnode = $3; if($2 == NULL) $$ = node; else { node->nextnode = $2->childnode; $2->childnode = node; $$ = $2; } }
 |  NAME '.' NAME opt_as_alias 
    { 
        struct ast *child = newnode_1(NAME, $1); child->nextnode = newnode_1(NAME, $3); child = newast(DTNAME, child); 
        if($4 == NULL) $$ = child; else { child->nextnode = $4->childnode; $4->childnode = child; $$ = $4; }
    }
 |  table_subquery opt_as NAME { struct ast *child = $1; child->nextnode = newnode_1(NAME, $3); $$ = newast(AS, child); }
 |  '(' table_references ')' { $$ = $2; }
 ;

opt_as: AS { $$ = NULL; }
 |  /* 空规则 */ { $$ = NULL; }
 ;

join_table: table_reference opt_inner_cross JOIN table_factor opt_join_condition
    {
        struct ast *child = $1; child->nextnode = $4; child->nextnode->nextnode = $5;
        struct ast *rtn;
	switch($2) { case 0: rtn = newnode_1(JOINTYPE, "JOIN"); break; case 1: rtn = newnode_1(JOINTYPE, "INNER_JOIN"); break; case 2: rtn = newnode_1(JOINTYPE, "CROSS_JOIN"); break; }
	rtn->childnode = child;
        $$ = rtn;
    }
 |  table_reference STRAIGHT_JOIN table_factor opt_join_condition 
    { struct ast *child = $1; child->nextnode = $3; child->nextnode->nextnode = $4; struct ast *rtn = newnode_1(JOINTYPE, "STRAIGHT_JOIN"); rtn->childnode = child; $$ = rtn; }
 |  table_reference left_or_right opt_outer JOIN table_factor join_condition 
    {
        struct ast *child = $1; child->nextnode = $5; child->nextnode->nextnode = $6; struct ast *rtn;
        if($2 == 1 && $3 == 0) rtn = newnode_1(JOINTYPE, "LEFT_JOIN"); else if($2 == 1 && $3 == 1) rtn = newnode_1(JOINTYPE, "LEFT_OUTER_JOIN"); else if($2 == 2 && $3 == 0) rtn = newnode_1(JOINTYPE, "RIGHT_JOIN"); else if($2 == 2 && $3 == 1) rtn = newnode_1(JOINTYPE, "RIGHT_OUTER_JOIN");
        rtn->childnode = child; $$ = rtn;
    }
 |  table_reference NATURAL opt_left_or_right JOIN table_factor
    {
        struct ast *child = $1; child->nextnode = $5; struct ast *rtn;
        switch($3) { case 0: rtn = newnode_1(JOINTYPE, "NATURAL_JOIN"); break; case 1: rtn = newnode_1(JOINTYPE, "NATURAL_LEFT_JOIN"); break; case 2: rtn = newnode_1(JOINTYPE, "NATURAL_LEFT_OUTER_JOIN"); break; case 3: rtn = newnode_1(JOINTYPE, "NATURAL_RIGHT_JOIN"); break; case 4: rtn = newnode_1(JOINTYPE, "NATURAL_RIGHT_OUTER_JOIN"); break; case 5: rtn = newnode_1(JOINTYPE, "NATURAL_INNER_JOIN"); break; }
        rtn->childnode = child; $$ = rtn;
    }
 ;

opt_inner_cross: /* 空规则 */ { $$ = 0; }
 |  INNER { $$ = 1; }
 |  CROSS { $$ = 2; }
 ;

opt_outer: /* 空规则 */ { $$ = 0; }
 |  OUTER { $$ = 1; }
 ;

left_or_right: LEFT { $$ = 1; }
 |  RIGHT { $$ = 2; }
 ;

opt_left_or_right: LEFT opt_outer { if($2 == 0) $$ = 1; else $$ = 2; }
 |  RIGHT opt_outer { if($2 == 0) $$ = 3; else $$ = 4; }
 |  INNER { $$ = 5; }
 |  /* 空规则 */ { $$ = 0; }
 ;

opt_join_condition: /* 空规则 */ { $$ = NULL; }
 | join_condition { $$ = $1; }
 ;

join_condition: ON expr { $$ = newast(ON, $2); }
 |  USING '(' column_list ')' { $$ = newast(USING, $3); }
 ;

index_hint_list: index_hint { $$ = $1; }
 |  index_hint_list index_hint { struct ast *child = $2; child->nextnode = $1; $$ = $1; }
 |  /*空规则*/ { $$ = NULL; }
 ;

index_hint: USE key_or_index opt_for_join '(' index_list ')'
    { struct ast *rtn; if($2 == 1 && $3 == 0) rtn = newnode_1(INDEXTYPE, "USE_KEY"); else if($2 == 1 && $3 == 1) rtn = newnode_1(INDEXTYPE, "USE_KEY_FOR_JOIN"); else if($2 == 1 && $3 == 2) rtn = newnode_1(INDEXTYPE, "USE_KEY_FOR_ORDER_BY"); else if($2 == 1 && $3 == 3) rtn = newnode_1(INDEXTYPE, "USE_KEY_FOR_GROUP_BY"); else if($2 == 2 && $3 == 0) rtn = newnode_1(INDEXTYPE, "USE_INDEX"); else if($2 == 2 && $3 == 1) rtn = newnode_1(INDEXTYPE, "USE_INDEX_FOR_JOIN"); else if($2 == 2 && $3 == 2) rtn = newnode_1(INDEXTYPE, "USE_INDEX_FOR_ORDER_BY"); else if($2 == 2 && $3 == 3) rtn = newnode_1(INDEXTYPE, "USE_INDEX_FOR_GROUP_BY"); rtn->childnode = $5; $$ = rtn; }
 |  IGNORE key_or_index opt_for_join '(' index_list ')'
    { struct ast *rtn; if($2 == 1 && $3 == 0) rtn = newnode_1(INDEXTYPE, "IGNORE_KEY"); else if($2 == 1 && $3 == 1) rtn = newnode_1(INDEXTYPE, "IGNORE_KEY_FOR_JOIN"); else if($2 == 1 && $3 == 2) rtn = newnode_1(INDEXTYPE, "IGNORE_KEY_FOR_ORDER_BY"); else if($2 == 1 && $3 == 3) rtn = newnode_1(INDEXTYPE, "IGNORE_KEY_FOR_GROUP_BY"); else if($2 == 2 && $3 == 0) rtn = newnode_1(INDEXTYPE, "IGNORE_INDEX"); else if($2 == 2 && $3 == 1) rtn = newnode_1(INDEXTYPE, "IGNORE_INDEX_FOR_JOIN"); else if($2 == 2 && $3 == 2) rtn = newnode_1(INDEXTYPE, "IGNORE_INDEX_FOR_ORDER_BY"); else if($2 == 2 && $3 == 3) rtn = newnode_1(INDEXTYPE, "IGNORE_INDEX_FOR_GROUP_BY"); rtn->childnode = $5; $$ = rtn; }
 |  FORCE key_or_index opt_for_join '(' index_list ')'
    { struct ast *rtn; if($2 == 1 && $3 == 0) rtn = newnode_1(INDEXTYPE, "FORCE_KEY"); else if($2 == 1 && $3 == 1) rtn = newnode_1(INDEXTYPE, "FORCE_KEY_FOR_JOIN"); else if($2 == 1 && $3 == 2) rtn = newnode_1(INDEXTYPE, "FORCE_KEY_FOR_ORDER_BY"); else if($2 == 1 && $3 == 3) rtn = newnode_1(INDEXTYPE, "FORCE_KEY_FOR_GROUP_BY"); else if($2 == 2 && $3 == 0) rtn = newnode_1(INDEXTYPE, "FORCE_INDEX"); else if($2 == 2 && $3 == 1) rtn = newnode_1(INDEXTYPE, "FORCE_INDEX_FOR_JOIN"); else if($2 == 2 && $3 == 2) rtn = newnode_1(INDEXTYPE, "FORCE_INDEX_FOR_ORDER_BY"); else if($2 == 2 && $3 == 3) rtn = newnode_1(INDEXTYPE, "FORCE_INDEX_FOR_GROUP_BY"); rtn->childnode = $5; $$ = rtn; }
 ;

key_or_index: KEY { $$ = 1; }
 |  INDEX { $$ = 2; }
 ;

opt_for_join: FOR JOIN { $$ = 1; }
 |  FOR ORDER BY { $$ = 2; }
 |  FOR GROUP BY { $$ = 3; }
 |  /* 空规则 */ { $$ = 0; }
 ;

index_list: NAME { $$ = newnode_1(NAME, $1); }
 |  index_list ',' NAME { struct ast *rtn = newnode_1(NAME, $3); rtn->nextnode = $1; $$ = rtn; }
 ;

table_subquery: '(' select_stmt ')' { $$ = $2; }
 ;


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
