#ifndef PARSE_NODE_H
#define PARSE_NODE_H

#include "sql_yacc.tab.h"
#include <string.h>

extern int yylineno;
void yyerror(char *s, ...);

struct ast {
	int nodetype; //节点类型
	char *val; //节点值
	struct ast *nextnode;   //兄弟节点
	struct ast *childnode;  //孩子节点
};

struct ast *newast(int nodetype, struct ast *childnode);
struct ast *newast_1(int nodetype, struct ast *childnode, char* val);
struct ast *newwheresub(int nodetype, struct ast *key, struct ast *value);
struct ast *addnewwherenode(int nodetype, struct ast *oldnode, struct ast *newnode);
struct ast *newnode_1(int nodetype, char *val);
struct ast *newnode(int nodetype);
void showtree(struct ast *node, int layer);
void createjson(struct ast *node, FILE *writerstr, int state);
void createjson_1(struct ast *node, FILE *writerstr, int state);
char *getelemname(int nodetype);

#endif
