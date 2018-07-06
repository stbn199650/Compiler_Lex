/* Definition section */
%{
	#include <stdio.h>
	#include <stdlib.h>

    struct symbol{
        char name[40];
        char type_name[10];
        int type_num;   /*type==1->int type==2->float type==3->double*/
    }table[100];

    int line_num = 0;   //count how many lines
    int var_num = 0;    //count variable number
    int var_exist = 0;  //1:has var in front
    int type_buf = 0;
    int comment_line = 0;
    char type_name_buf[10];
    char id_buffer[40];

	/* Symbol table function */
	void create_symbol();
	void insert_symbol(int mode,char *symbol,char *name,int var_exist,char *id_buffer);
	int lookup_symbol(char *symbol);
	void dump_symbol();

%}

/* Define regular expression label */

letter  [a-zA-Z]
digit   [0-9]
id      {letter}+({letter}|{digit})*
number  {digit}+
%x      comment
%x      COMMENT1
%x      COMMENT2
%x      input_string
%x      INPUT_STRING1
%x      INPUT_STRING2

/* Rules section */
%%

[\n]+	{ ++line_num; var_exist=0;type_buf=0; type_name_buf[0]='\0'; id_buffer[0]='\0';}
[\t]+   { ;}

[-][-]  { printf("%s \t Decrement\n",yytext);}
[+][+]  { printf("%s \t Increment\n",yytext);}
[&][&]  { printf("%s \t And_Operator\n",yytext);}
[|][|]  { printf("%s \t Or_Operator\n",yytext);}
[<|>]       { printf("%s \t Relational\n",yytext);}
[>][=]|[<][=]|[=][=]|[!][=]      { printf("%s \t Relational\n",yytext);}
[+][=]|[-][=]|[*][=]|[/][=]|[%][=] { printf("%s \t Assignment\n",yytext);} 

" "     {;}
"+" 	{ printf("%s \t Add \n", yytext); }
"-"		{ printf("%s \t Sub \n", yytext); }
"*"     { printf("%s \t Multiply\n",yytext);}
"/"     { printf("%s \t Divide\n",yytext);}
"%"     { printf("%s \t Remainder\n",yytext);}
"^"     { printf("%s \t Exponent\n",yytext);}
"="     { printf("%s \t Assign \n",yytext);}
"!"     { printf("%s \t Not\n",yytext);}
","     { printf("%s \t Comma\n",yytext);}
";"     { printf("%s \t Semicolon\n",yytext); var_exist=0;type_buf=0; type_name_buf[0]='\0'; id_buffer[0]='\0';}
"("     { printf("%s \t LB\n",yytext);}
")"     { printf("%s \t RB\n",yytext);}
"{"     { printf("%s \t LCB\n",yytext);}
"}"     { printf("%s \t RCB\n",yytext);}

{number}                { printf("%s \t Number\n",yytext);}
{number}"."{number}     { printf("%s \t FloatNumber\n",yytext);}

[v|V][a|A][r|R]                 { var_exist=1;}
[i|I][n|N][t|T]                 { type_buf=1; strcpy(type_name_buf,yytext); insert_symbol(type_buf,yytext,type_name_buf,var_exist,id_buffer);}
[f|F][l|L][o|O][a|A][t|T]       { type_buf=2; strcpy(type_name_buf,yytext); insert_symbol(type_buf,yytext,type_name_buf,var_exist,id_buffer);}
[d|D][o|O][u|U][b|B][l|L][e|E]  { type_buf=3; strcpy(type_name_buf,yytext);}

[i|I][f|F]                      { printf("%s \t IF FUNCTION\n",yytext);}
[e|E][l|L][s|S][e|E]            { printf("%s \t ELSE FUNCTION\n",yytext);}
[f|F][o|O][r|R]                 { printf("%s \t FOR FUNCTION\n",yytext);}
[w|W][h|H][i|I][l|L][e|E]       { printf("%s \t WHILE FUNCTION\n",yytext);}
[p|P][r|R][i|I][n|N][t|T]       { printf("%s \t PRINT FUNCTION\n",yytext);}
[p|P][r|R][i|I][n|N][t|T][l|L][n|N]     { printf("%s\t PRINTLN FUNCTION\n",yytext);}

{id}	{ strcpy(id_buffer,yytext); insert_symbol(type_buf,yytext,type_name_buf,var_exist,id_buffer); }
["]     { printf("%s \t Quotation\n",yytext); BEGIN INPUT_STRING1;}
    <INPUT_STRING1>[^"]*    { printf("%s \t STRING\n",yytext); BEGIN INPUT_STRING2;}
    <INPUT_STRING2>["]      { printf("%s \t Quotation\n",yytext); BEGIN 0;} 


[\n|.]*         {;}
"//".*"\n"      { printf("%s \t C++ COMMENT \n",yytext); ++line_num; ++comment_line;}
"/*"            { printf("%s",yytext); BEGIN comment;}
    <comment>[^*\n]*        { printf("%s",yytext);}
    <comment>[*]+[^*/\n]*    { printf("%s",yytext);}
    <comment>\n             { printf("%s",yytext); ++line_num; ++comment_line;}
    <comment>[*][/]         { printf("%s\n\tC COMMENT\n",yytext); ++comment_line;BEGIN 0;}

%%

/*	C Code section */
int yywrap(void)
{
    return 1;
}

int main(int argc,char *argv[])
{
	yyin = fopen(argv[1],"r");
	if(!yyin){
        printf("Open Failed\n");
        return 0;
    }
    printf("\n");
    yylex();

    printf("\nParse over, the line number is %d\n",line_num);
	printf("comment: %d lines\n\n",comment_line);
    dump_symbol();
    printf("\n");

	return 0;
}

void create_symbol(){

    if((var_exist==0 && type_buf!=0) || (var_exist==1 && type_buf!=0))
        printf("Create a symbol table\n");
    return;
}

void insert_symbol(int mode,char *symbol,char *name,int var_exist,char *id_buffer){

    int x;

    if(var_num == 0)
        create_symbol();

    x = lookup_symbol(id_buffer);
    //first time encouter variable
    if(x == -1 && var_exist == 0 && id_buffer[0]!='\0'){

        if(mode == 0){  //not int or float or double
            strcpy(table[var_num].type_name,"Undefined");
            printf("%s \t Undefined\n",id_buffer);
        }
        else
            strcpy(table[var_num].type_name,name);
        
        //int or float or double
        if(mode == 1){
            printf("%s \t int\n",id_buffer);
        }else if(mode == 2){
            printf("%s \t float\n",id_buffer);
        }else if(mode == 3){
            printf("%s \t double\n",id_buffer);        
        }
        
        printf("Insert a symbol: %s\n",symbol);
        strcpy(table[var_num].name,symbol);
        table[var_num].type_num = mode;
        var_num++;

    }else if(x == -1 && var_exist == 1 && type_buf!=0){    //var type

        if(type_buf == 1){
            printf("%s \t int TYPE VAR\n",id_buffer);
            strcpy(table[var_num].type_name,"int TYPE VAR");
        }else if(type_buf == 2){
            printf("%s \t float TYPE VAR\n",id_buffer);
            strcpy(table[var_num].type_name,"float TYPE VAR");
        }else if(type_buf == 3){
            printf("%s \t double TYPE VAR\n",id_buffer);        
            strcpy(table[var_num].type_name,"double TYPE VAR");
        }

        printf("Insert a symbol: %s\n",id_buffer);
        strcpy(table[var_num].name,id_buffer);
        var_num++;

    }else if(x>=0 && mode!=0){  //x!=-1,redefined
        printf("%s \t Redefined\n",id_buffer); 
    }else if(mode==0 && var_exist==0 && type_buf==0 && x==-1)
        printf("%s \t Undefined\n",id_buffer);
    else if(mode==0 && type_buf==0 && x>=0)
        printf("%s \t ID\n",id_buffer);

    return;
}

int lookup_symbol(char *symbol){
    //search the index of symbol, return index
    for(int i=0;i<var_num;i++)
        if(strcmp(table[i].name,symbol) == 0)
            return i;    

    //cannot find symbol, return -1    
    return -1;
}

void dump_symbol(){

    printf("!!!Dump symbol table!!!\n");
    printf("Index\tName\tType\n");
    
    for(int i=0;i<var_num;i++)
        printf("%d\t%s\t%s\n",i,table[i].name,table[i].type_name);    
    printf("\n");

    return;
}

