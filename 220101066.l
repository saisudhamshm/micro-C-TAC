%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "220101066.h"
    #include "y.tab.h"
%}

%option yylineno
%option noyywrap


KEYWORD                "char"|"else"|"for"|"if"|"integer"|"return"|"void"|"float"|"while"|"do"|"begin"|"end"
PUNC                    "["|"]"|"("|")"|"->"|"!"|"+"|"-"|"*"|"/"|"|"|"<<"|">>"|"<"|">"|"<="|">="|"^"|"||"|"&&"|"=="|"&"|"%"|":"|";"|"?"|"="|","|"!="|"++"|"--"

/* Identifier */
ID						[a-zA-Z_][a-zA-Z0-9_]*


/* Constants */
NONZERO_DIGIT           [1-9]
DIGIT                   [0-9]
INT_CONST				{DIGIT}|{NONZERO_DIGIT}{DIGIT}*
ESCAPE_SEQ				[\\][']|[\\]["]|[\\][?]|[\\][\\]|[\\][a]|[\\][b]|[\\][f]|[\\][n]|[\\][r]|[\\][t]|[\\][v]
C_CHAR					[^'\n\\]|{ESCAPE_SEQ}
C_CHAR_SEQ				{C_CHAR}+
CHAR_CONST				[']{C_CHAR_SEQ}[']
S_CHAR					[^"\n\\]|{ESCAPE_SEQ}
S_CHAR_SEQ				{S_CHAR}+
STRING_CONST			["]{S_CHAR_SEQ}["]|["]["]
FLOAT_CONST             {DIGIT}+"."{DIGIT}+([eE][+-]?{DIGIT}+)?

/* White Spaces */
WS						[ \t\n]

%x SINGLE_COMMENT MULTI_COMMENT

%%

"//"			            {BEGIN(SINGLE_COMMENT);}
<SINGLE_COMMENT>[^\n]	    {}
<SINGLE_COMMENT>"\n"		{BEGIN(INITIAL);}
<SINGLE_COMMENT><<EOF>>	    {BEGIN(INITIAL);}


"/*"			            {BEGIN(MULTI_COMMENT);}
<MULTI_COMMENT>"\n"         {}
<MULTI_COMMENT>[^*]	        {}
<MULTI_COMMENT>"*"[^/]	    {}
<MULTI_COMMENT>"*/"	        {BEGIN(INITIAL);}

{KEYWORD}                        {
                                   if (strcmp(yytext, "char") == 0) return CHAR;
                                   else if (strcmp(yytext, "else") == 0) return ELSE;
                                   else if (strcmp(yytext, "for") == 0) return FOR;
                                   else if (strcmp(yytext, "if") == 0) return IF;
                                   else if (strcmp(yytext, "integer") == 0) return INT;
                                   else if (strcmp(yytext, "return") == 0) return RETURN;
                                   else if (strcmp(yytext, "void") == 0) return VOID;
                                   else if (strcmp(yytext, "float") == 0) return FLOAT;
                                   else if (strcmp(yytext, "while") == 0) return WHILE;
                                   else if (strcmp(yytext, "do") == 0) return DO;
                                   else if (strcmp(yytext, "begin") == 0) return BEG;
                                   else if (strcmp(yytext, "end") == 0) return END;
                                 }

{ID}							{yylval.symbol = currentTable -> lookupSymbol(yytext); return ID;}

{INT_CONST}						{yylval.intVal = atoi(yytext); return INT_CONST;}
{CHAR_CONST}					{yylval.charVal = strdup(yytext); return CHAR_CONST;}
{STRING_CONST}					{yylval.stringVal = strdup(yytext); return STRING_CONST;}
{FLOAT_CONST}                    {yylval.floatVal = atof(yytext); return FLOAT_CONST;}
{PUNC}                          {
                                   if (strcmp(yytext, "[") == 0) return LSQBRACKET;
                                   else if (strcmp(yytext, "]") == 0) return RSQBRACKET;
                                   else if (strcmp(yytext, "(") == 0) return LPARAN;
                                   else if (strcmp(yytext, ")") == 0) return RPARAN;
                                   else if (strcmp(yytext, "->") == 0) return ARROW;
                                   else if (strcmp(yytext, "<=") == 0) return LESSEQ;
                                   else if (strcmp(yytext, ">=") == 0) return GREATEREQ;
                                   else if (strcmp(yytext, "==") == 0) return EQUALS;
                                   else if (strcmp(yytext, "!=") == 0) return NOTEQ;
                                   else if(strcmp(yytext,"++") ==0 )  return INC;
                                   else if(strcmp(yytext,"--") ==0) return DEC;
                                   else if (strcmp(yytext, "+") == 0) return PLUS;
                                   else if (strcmp(yytext, "-") == 0) return SUB;
                                   else if (strcmp(yytext, "*") == 0) return MULT;
                                   else if (strcmp(yytext, "/") == 0) return DIV;
                                   else if (strcmp(yytext, "%") == 0) return MOD;
                                   else if (strcmp(yytext, "!") == 0) return LOGICAL_NOT;
                                   else if (strcmp(yytext, "&&") == 0) return LOGICAL_AND;
                                   else if (strcmp(yytext, "||") == 0) return LOGICAL_OR;
                                   else if (strcmp(yytext, "<") == 0) return LESS;
                                   else if (strcmp(yytext, ">") == 0) return GREATER;
                                   else if (strcmp(yytext, "?") == 0) return QUES;
                                   else if (strcmp(yytext, ":") == 0) return COLON;
                                   else if (strcmp(yytext, ";") == 0) return SEMICOLON;
                                   else if (strcmp(yytext, "=") == 0) return ASSIGN;
                                   else if (strcmp(yytext, ",") == 0) return COMMA;
                                   else if (strcmp(yytext, "<<") == 0) return LSHIFT;
                                   else if (strcmp(yytext, ">>") == 0) return RSHIFT;
                                   else if (strcmp(yytext, "&") == 0) return BIT_AND;
                                   else if (strcmp(yytext, "|") == 0) return BIT_OR;
                                   else if (strcmp(yytext, "^") == 0) return BIT_XOR;
                                 }

"\n"                            {}

{WS}							{/* Ignore whitespace */}

%%