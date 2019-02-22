#ifndef PARSE_NODE_H
#define PARSE_NODE_H

extern int yylineno;
void yyerror(char *s, ...);

struct ast {
	int nodetype;
	int size;
	char *val; 
	struct ast **nodelist;
};

struct ast *newast(int nodetype, int size, struct ast **nodelist);
struct ast *newnode(int nodetype, char *val);
void showtree(struct ast *node, int layer);

#endif
