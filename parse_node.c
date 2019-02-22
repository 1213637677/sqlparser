#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "parse_node.h"

struct ast *newast(int nodetype, int size, struct ast **nodelist)
{
	struct ast *a = (struct ast *)malloc(sizeof(struct ast));
	
	if(!a) {
		yyerror("out of space");
		exit(0);
	}
	a->nodetype = nodetype;
	a->nodelist = nodelist;
	a->size = size;
	return a;
}

struct ast *newnode(int nodetype, char *val)
{
	struct ast *a = (struct ast *)malloc(sizeof(struct ast));

	if(!a) {
		yyerror("out of space");
		exit(0);
	}
	a->nodetype = nodetype;
	a->size = 0;
	a->nodelist = NULL;
	a->val = val;
	return a;
}

/*深度遍历编译树*/
void showtree(struct ast *node, int layer)
{
	if(node == NULL) return;
	else{
		for(int i = 0; i < layer; i++) printf("\t");
		printf("nodetype is %d", node->nodetype);
		printf(" size is %lu\n",sizeof(node->nodelist));
		if(node->size != 0){
			for(int i = 0; i < node->size; i++){
				struct ast *temp = node->nodelist[i];
				showtree(temp, layer+1);
			} 
		}
	}
	return;
}

