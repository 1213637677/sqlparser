#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "parse_node.h"
#include "sql_yacc.tab.h"

/*新树*/
struct ast *newast(int nodetype, struct ast *childnode)
{
	struct ast *a = (struct ast *)malloc(sizeof(struct ast));
	
	if(!a) {
		yyerror("out of space");
		exit(0);
	}
	a->nodetype = nodetype;
	a->nextnode = NULL;
	a->childnode = childnode;
	return a;
}
struct ast *newast_1(int nodetype, struct ast *childnode, char* val)
{
	struct ast *a = (struct ast *)malloc(sizeof(struct ast));
	
	if(!a) {
		yyerror("out of space");
		exit(0);
	}
	a->nodetype = nodetype;
	a->nextnode = NULL;
	a->childnode = childnode;
	a->val = val;
	return a;
}

/*新节点*/
struct ast *newnode_1(int nodetype, char *val)
{
	struct ast *a = (struct ast *)malloc(sizeof(struct ast));

	if(!a) {
		yyerror("out of space");
		exit(0);
	}
	a->nodetype = nodetype;
	//a->size = 0;
	a->nextnode = NULL;
	a->childnode = NULL;
	a->val = val;
	return a;
}
struct ast *newnode(int nodetype)
{
	struct ast *a = (struct ast *)malloc(sizeof(struct ast));

	if(!a) {
		yyerror("out of space");
		exit(0);
	}
	a->nodetype = nodetype;
	a->nextnode = NULL;
	a->childnode = NULL;
	return a;
}

/*构造where中的子节点*/
struct ast *newwheresub(int nodetype, struct ast *key, struct ast *value)
{
	key->childnode = newast(nodetype, value);
	return key;
}

struct ast *addnewwherenode(int nodetype, struct ast *oldnode, struct ast *newnode)
{
	if(oldnode->nodetype != nodetype){
		oldnode->nextnode = newnode;
		return newast(nodetype, oldnode);
	}
	else{
		struct ast *temp = oldnode->childnode;
		while(temp != NULL) temp = temp->nextnode;
		temp = newnode;
		return oldnode;
	}
}

/*深度遍历编译树*/
void showtree(struct ast *node, int layer)
{
	if(node == NULL) return;
	else{
		for(int i = 0; i < layer; i++) printf("\t");
		if(node->val == NULL) printf("%s\n", getelemname(node->nodetype));
		else printf("%s\n", node->val);
		//printf("1");
		//char * str = getelemname(node->nodetype);
		//printf("%s\n", str);
		if(node->childnode != NULL){
			/*for(int i = 0; i < node->size; i++){
				struct ast *temp = node->nodelist[i];
				showtree(temp, layer+1);
			}*/
			struct ast *temp = node->childnode;
			while(temp != NULL){
				showtree(temp, layer+1);
				temp = temp->nextnode;
			}
		}
	}
	return;
}

/* 将枚举类型转化为char* */
char *getelemname(int nodetype)
{
	char* s;
	switch(nodetype)
	{
		case ADD : s = "+"; break;
		case SUB : s = "-"; break;
		case MUL : s = "*"; break;
		case DIV : s = "/"; break;
		case MOD : s = "%"; break;
		case AND : s = "AND"; break;
		case OR : s = "OR"; break;
		case XOR : s = "XOR"; break;
		case OROP : s = "|"; break;
		case ANDOP : s = "&"; break;
		case XOROP : s = "^"; break;
		case NOT : s = "NOT"; break;
		case BETWEEN : s = "BETWEEN"; break;
		case LIKE : s = "LIKE"; break;
		case NOTLIKE : s = "NOTLIKE"; break;
		case IS : s = "IS"; break;
		case ISNOT : s = "ISNOT"; break;
		case IN : s = "IN"; break;
		case NOTIN : s = "NOTIN"; break;
		case EXISTS : s = "EXISTS"; break;
		case SELECT_QUERY : s = "SELECT_QUERY"; break;
		case SELECT : s = "SELECT"; break;
		case FROM : s = "FROM"; break;
		case WHERE : s = "WHERE"; break;
		case GROUP_BY : s = "GROUP_BY"; break;
		case BY_NODE : s = "BY_NODE"; break;
		case ASC : s = "ASC"; break;
		case DESC : s = "DESC"; break;
		case WITH_ROLLUP : s = "WITH_ROLLUP"; break;
		case HAVING : s = "HAVING"; break;
		case ORDER_BY : s = "ORDER_BY"; break;
		case LIMIT : s = "LIMIT"; break;
		case INTO : s = "INTO"; break;
		case ALL : s = "ALL"; break;
		case DISTINCT : s = "DISTINCT"; break;
		case DISTINCTROW : s = "DISTINCTROW"; break;
		case HIGH_PRIORITY : s = "HIGH_PRIORITY"; break;
		case STRAIGHT_JOIN : s = "STRAIGHT_JOIN"; break;
		case SQL_SMALL_RESULT : s = "SQL_SMALL_RESULT"; break;
		case SQL_BIG_RESULT : s = "SQL_BIG_RESULT"; break;
		case SQL_CALC_FOUND_ROWS : s = "SQL_CALC_FOUND_ROWS"; break;
		case AS : s = "AS"; break;
		case DTNAME : s = "DTNAME"; break;
		case ON : s = "ON"; break;
		case USING : s = "USING"; break;
		case ALLCOLUMN : s = "*"; break;
		case FUNC_NAME : s = "FUNC_NAME"; break;
	}
	return s;
}

