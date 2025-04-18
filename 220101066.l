%{
    #include <stdio.h>
    #include <stdlib.h>
    #include "220101066.h"
    #include "y.tab.h"
%}

%option yylineno
%option noyywrap

/* Keywords */
CHAR					"char"
ELSE					"else"
FOR                     "for"
IF						"if"
INT                     "integer"
RETURN					"return"
VOID					"void"
FLOAT                    "float"
WHILE                     "while"
DO                       "do"
BEG                       "begin"
END                        "end"

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

{CHAR}							{return CHAR;}
{ELSE}							{return ELSE;}
{FOR}							{return FOR;}
{IF}							{return IF;}
{INT}							{return INT;}
{RETURN}						{return RETURN;}
{VOID}							{return VOID;}
{FLOAT}                         {return FLOAT;}
{WHILE}                         {return WHILE;}
{DO}                             {return DO;}
{BEG}                           {return BEG;}
{END}                           {return END;}

{ID}							{yylval.symbol = currentTable -> lookupSymbol(yytext); return ID;}

{INT_CONST}						{yylval.intVal = atoi(yytext); return INT_CONST;}
{CHAR_CONST}					{yylval.charVal = strdup(yytext); return CHAR_CONST;}
{STRING_CONST}					{yylval.stringVal = strdup(yytext); return STRING_CONST;}
{FLOAT_CONST}                    {yylval.floatVal = atof(yytext); return FLOAT_CONST;}
"["								{return LSQBRACKET;}
"]"								{return RSQBRACKET;}
"("								{return LPARAN;}
")"								{return RPARAN;}
"->"							{return ARROW;}
"<="							{return LESSEQ;}
">="							{return GREATEREQ;}
"=="							{return EQUALS;}
"!="							{return NOTEQ;}
"+"								{return PLUS;}
"-"								{return SUB;}
"*"								{return MULT;}
"/"								{return DIV;}
"%"								{return MOD;}
"!"								{return LOGICAL_NOT;}
"&&"							{return LOGICAL_AND;}
"||"							{return LOGICAL_OR;}
"<"								{return LESS;}
">"								{return GREATER;}
"?"								{return QUES;}
":"								{return COLON;}
";"								{return SEMICOLON;}
"="								{return ASSIGN;}
","								{return COMMA;}
"<<"                             {return LSHIFT;}
">>"                               {return RSHIFT;}
"&"								{return BIT_AND;}
"|"                                 {return BIT_OR;}
"^"                              {return BIT_XOR;}

"\n"                            {}

{WS}							{/* Ignore whitespace */}

%%