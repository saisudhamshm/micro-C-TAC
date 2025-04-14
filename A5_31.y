%{
    #include "A5_31_translator.h"
    extern int yylex();
    extern int yylineno;
    void yyerror(string);
    void yyinfo(string);
%}

/*
    intVal : to store the integer value
    charVal: store the char value
    stringVal: to store the string value
    unaryOperator: storing the unary operator
    instructionNumber: to store the instruction number
    parameterCount: to store the number of parameters passed to function
    symbolType: to store most recent type encountered
    expression: to store expression value
    statement: to store the statement value 
    array: store the array
    symbolType: to store the symbol type
    symbol: to store the symbol
*/

%union {
    int intVal;
    float floatVal;
    char *charVal;
    char *stringVal;
    char *unaryOperator;
    int instructionNumber;
    int parameterCount;
    Expression *expression;
    Statement *statement;
    Array *array;
    SymbolType *symbolType;
    Symbol *symbol;
    SymbolType *parameterlist;
}

/* Bison Declaration */
%token CHAR
%token ELSE	
%token FOR	
%token IF		
%token INT	
%token RETURN	
%token VOID
%token WHILE
%token DO
%token FLOAT
%token BEG
%token END

%token LSQBRACKET	
%token RSQBRACKET
%token LPARAN		
%token RPARAN		
%token ARROW		
%token BIT_AND
%token PLUS
%token SUB			
%token MULT		
%token DIV
%token MOD
%token LOGICAL_NOT	
%token LOGICAL_AND		
%token LOGICAL_OR		
%token LESS		
%token GREATER	
%token LESSEQ		
%token GREATEREQ	
%token EQUALS		
%token NOTEQ		
%token QUES		
%token COLON		
%token SEMICOLON	
%token ASSIGN		
%token COMMA
%token LSHIFT
%token RSHIFT
%token BIT_OR
%token BIT_XOR

/*
ID points to its entry in the symbol table
The remaining are constants from the code
*/

%token<symbol> ID                    // ID represents its entry into the symbol table
%token<intVal> INT_CONST             // integer constant
%token<charVal> CHAR_CONST           // character constant
%token<stringVal> STRING_CONST       // string literal
%token<floatVal> FLOAT_CONST

// for handling dangling else problem
%right THEN ELSE

%type<unaryOperator>                        //unary operator as character
    unary_operator

%type<parameterCount>                       //store parameter as integer
    argument_expression_list
    argument_expression_list_opt

%type<parameterlist>
    parameter_declaration
    parameter_list

// Expressions
%type<expression>
	expression
	primary_expression
	multiplicative_expression
	additive_expression
	relational_expression
	equality_expression
	logical_AND_expression
	logical_OR_expression
	conditional_expression
	assignment_expression
	expression_statement
    expression_opt
    shift_expression
    bitwise_AND_expression
    bitwise_OR_expression
    bitwise_XOR_expression


// Arrays
%type<array>
    postfix_expression
	unary_expression

// Statements
%type <statement>
    statement
	compound_statement
	selection_statement
	iteration_statement
	jump_statement
	block_item
	block_item_list
	block_item_list_opt
    N

// symbol type
%type<symbolType>
    pointer


// Symbol
%type<symbol>
    initialiser
    direct_declarator
    init_declarator
    declarator

// Instruction number
%type <instructionNumber>
    M

%type <symbol>
    AUG1

%start translation_unit                     //setting the start state as translation_unit

%%

/* Expressions */

/*
In case of constants(int/char/string), the constant value is stored temporarily, initialized with the initial value.
Then, we created a new expression with the symbol pointing to this generated temporary.
*/

/*
In case of identifiers, the ID is a symbol and it points to itself
in the .l file:
{ID}							{yylval.symbol = currentTable -> search(yytext); return ID;}
Here the yylval.symbol sets the semantic value of the token to 'symbol' object
& the symbol is pointing to the symbol in the symbol table entry
cases:
1. if the symbol is defined in the current symbol table: simply return the entry the current symbol table
2. if the symbol is defined in some parent of the current table: return the entry of symbol from that table
3. if the symbol is not defined: then a new entry is created in the symbol table corresponding to this ID, and then it's pointer is returned
*/

primary_expression:
                    ID
                        {
                            yyinfo("primary_expression => ID");
                            $$ = new Expression(); // create new non boolean expression and symbol is the ID
                            // expression->symbol simply points to the symbol corresponding to the ID, in the table
                            $$->symbol = $1;
                            $$->type = Expression::NONBOOLEAN;
                        }
                    | INT_CONST
                        {
                            yyinfo("primary_expression => INT_CONST");
                            $$ = new Expression();
                            // a new tempvar is created & initialised with $1 value, and the symbol points to this
                            $$->symbol = gentemp(SymbolType::INT_T, toString($1));
                            // and extra quad is entered which initialises the temp var = $1->intValue
                            // so wherever this int was used, now this temp var will be used in its place
                            emit("=", $$->symbol->name, $1);
                        }
                    | CHAR_CONST
                        {
                            yyinfo("primary_expression => CHAR_CONST");
                            // exactly similar to INT_COST
                            $$ = new Expression();
                            $$->symbol = gentemp(SymbolType::CHAR_T, $1);
                            emit("=", $$->symbol->name, $1);
                        }
                    | STRING_CONST
                        {
                            yyinfo("primary_expression => STRING_CONST");
                            $$ = new Expression();
                            // no 'string' type, but if char* str = "Vedant-Mansi"
                            // then the string "Vedant-Mansi" is identified as STRING_const/literal,
		                    $$->symbol = gentemp(SymbolType::POINTER, $1);
                            // emit("=str", $$->symbol->name, stringLiterals.size());
		                    $$->symbol->type->arrayType = new SymbolType(SymbolType::CHAR_T);
                        }
                    | LPARAN expression RPARAN
                        {
                            yyinfo("primary_expression => ( expression )");
                            $$ = $2;
                        }
                    | FLOAT_CONST
                         {
                             $$ = new Expression();
                             string val = toString($1);
                             Symbol *s = gentemp(SymbolType::FLOAT_T, val);
                             s->initialValue = val;
                             $$->symbol = s;
                         }

                    ;

postfix_expression:
                    primary_expression
                        {
                            yyinfo("postfix_expression => primary_expression");
                            $$ = new Array();                                   // creating a new array
                            $$->symbol = $1->symbol;
                            $$->temp = $$->symbol;
                            if($1->symbol)
                                $$->subArrayType = $1->symbol->type;
                            $$->trueList = $1->trueList;
                            $$->falseList = $1->falseList;
                            $$->nextList = $1->nextList;
                        }
                    | postfix_expression LSQBRACKET expression RSQBRACKET
                        {
                            // array expression
                            yyinfo("postfix_expression => postfix_expression [ expression ]");
                            $$ = new Array();           // creating new array object
                            $$->symbol = $1->symbol;    // previous symbol
                            $$->subArrayType = $1->subArrayType->arrayType;
                            $$->temp = gentemp(SymbolType::INT_T); // temporary to compute location
                            $$->type = Array::ARRAY;    // type will be array

                            if($1->type == Array::ARRAY) {
                                // adding the size of subarray and adding
                                Symbol *sym = gentemp(SymbolType::INT_T);
                                emit("*", sym->name, $3->symbol->name, toString($$->subArrayType->getSize()));
                                emit("+", $$->temp->name, $1->temp->name, sym->name);
                            } else {
                                emit("*", $$->temp->name, $3->symbol->name, toString($$->subArrayType->getSize()));
                            }

                        }
                    | postfix_expression LPARAN argument_expression_list_opt RPARAN
                        {
                            // function
                            // number of parameters - argument_expression_list
                            yyinfo("postfix_expression => postfix_expression ( argument_expression_list_opt )");
                            $$ = new Array();
                            $$->symbol = gentemp($1->symbol->type->type);

                            $$->symbol->type->arrayType = $1->symbol->type->arrayType;

                            emit("call", $$->symbol->name, $1->symbol->name, toString($3));
                        }
                    | postfix_expression ARROW ID
                        {
                            yyinfo("postfix_expression => postfix_expression -> ID");
                        }
                    ;


// represents number of parameters in the function call
argument_expression_list_opt:
                                argument_expression_list
                                    {
                                        yyinfo("argument_expression_list_opt => argument_expression_list");
                                        $$ = $1;
                                    }
                                | /* epsilon */
                                    {
                                        // empty so 0 params
                                        yyinfo("argument_expression_list_opt => epsilon");
                                        $$ = 0;
                                    }
                                ;

argument_expression_list:
                            assignment_expression
                                {
                                    // first parameter
                                    // initialise param count to 1
                                    yyinfo("argument_expression_list => assignment_expression");
                                    emit("param", $1->symbol->name);
                                    $$ = 1;
                                }
                            | argument_expression_list COMMA assignment_expression
                                {
                                    // new parameter
                                    // adding 1 to param count
                                    yyinfo("argument_expression_list => argument_expression_list , assignment_expression");
                                    emit("param", $3->symbol->name);
                                    $$ = $1 + 1;
                                }
                            ;

unary_expression:
                    postfix_expression
                        {
                            yyinfo("unary_expression => postfix_expression");
                            $$ = $1;
                        }
                    | unary_operator unary_expression
                        {
                            yyinfo("unary_expression => unary_operator unary_expression");
                            if(strcmp($1, "&") == 0) {
                                // int* p = &x;
                                // here x is the unary expression
                                $$ = new Array();
                                // i need to create a temp var for storing the address of x (&x), which needs to be pointer type
                                $$->symbol = gentemp(SymbolType::POINTER);
                                // if x is a pointer of int, then $$->symbol's type's array type is set to int
                                $$->symbol->type->arrayType = $2->symbol->type;

                                emit("=&", $$->symbol->name, $2->symbol->name);

                            } else if(strcmp($1, "*") == 0) {
                                // if y = *x;

                                $$ = new Array();
                                $$->type = Array::POINTER;
                                // $$->temp = gentemp($2->symbol->type->type);
                                $$->temp = gentemp($2->temp->type->arrayType->type);
                                // if x = *y;
                                // then temp will be t11 = int value of (*y), after dereferencing
                                $$->symbol = $2->symbol;
                                // TODO:
                                $$->temp->type->arrayType = $2->temp->type->arrayType->arrayType;
                                emit("=*", $$->temp->name, $2->symbol->name);
                            } else if(strcmp($1, "+") == 0) {
                                $$ = $2;
                            } else {

                                $$ = new Array();
                                $$->symbol = gentemp($2->symbol->type->type);
                                emit($1, $$->symbol->name, $2->symbol->name);
                            }
                        }
                    ;

/* cast_expression:
                unary_expression
                    {
                        yyinfo("cast_expression => unary_expression");
                        $$ = $1;
                    }
                ; */

// storing the unary operator

unary_operator:
                BIT_AND
                    {
                        yyinfo("unary_operator => &");
                        $$ = strdup("&");
                    }
                | MULT
                    {
                        yyinfo("unary_operator => *");
                        $$ = strdup("*");
                    }
                | PLUS
                    {
                        yyinfo("unary_operator => +");
                        $$ = strdup("+");
                    }
                | SUB
                    {
                        yyinfo("unary_operator => -");
                        $$ = strdup("=-");
                    }
                | LOGICAL_NOT
                    {
                        yyinfo("unary_operator => !");
                        $$ = strdup("!");
                    }
                ;


/*
First, we extract the base type of the array. If type is base array, then we extract the value using the indexing through symbol name.
temporary is used to calculate the location of the array
Finally, we assign it to the newly generated temporary
Then, we can perform the type checking and if it is valid, then we can perform the necessary operations.
*/

multiplicative_expression:
                            unary_expression
                                {
                                     SymbolType *baseType;
                                    if($1->symbol)
                                        baseType = $1->symbol->type;
                                    while(baseType->arrayType)
                                        baseType = baseType->arrayType;
                                    yyinfo("multiplicative_expression => unary_expression");
                                    $$ = new Expression();
                                    if($1->type == Array::ARRAY) {
                                        $$->symbol = gentemp(baseType->type);
                                        emit("=[]", $$->symbol->name, $1->symbol->name, $1->temp->name);
                                    } else if($1->type == Array::POINTER) {
                                        $$->symbol = $1->temp;
                                        emit("param", $1->temp->name);
                                    } else {
                                        $$->symbol = $1->symbol;
                                    }
                                    $$->trueList = $1->trueList;
                                    $$->falseList = $1->falseList;
                                    $$->nextList = $1->nextList;
                                }
                            | multiplicative_expression MULT unary_expression
                                {
                                    SymbolType *baseType = $3->symbol->type;
                                    while(baseType->arrayType)
                                        baseType = baseType->arrayType;
                                    Symbol *temp;
                                    if($3->type == Array::ARRAY) {
                                        temp = gentemp(baseType->type);
                                        emit("=[]", temp->name, $3->symbol->name, $3->temp->name);
                                    } else if($3->type == Array::POINTER) {
                                        temp = $3->temp;
                                    } else {
                                        temp = $3->symbol;
                                    }
                                    yyinfo("multiplicative_expression => multiplicative_expression * unary_expression");
                                    if(typeCheck($1->symbol, temp)) {
                                        $$ = new Expression();
                                        $$->symbol = gentemp($1->symbol->type->type);
                                        emit("*", $$->symbol->name, $1->symbol->name, temp->name);
                                    } else {
                                        yyerror("Type error.");
                                    }
                                }
                            | multiplicative_expression DIV unary_expression
                                {
                                    SymbolType *baseType = $3->symbol->type;
                                    while(baseType->arrayType)
                                        baseType = baseType->arrayType;
                                    Symbol *temp;
                                    if($3->type == Array::ARRAY) {
                                        temp = gentemp(baseType->type);
                                        emit("=[]", temp->name, $3->symbol->name, $3->temp->name);
                                    } else if($3->type == Array::POINTER) {
                                        temp = $3->temp;
                                    } else {
                                        temp = $3->symbol;
                                    }
                                    yyinfo("multiplicative_expression => multiplicative_expression / unary_expression");
                                    if(typeCheck($1->symbol, temp)) {
                                        $$ = new Expression();
                                        $$->symbol = gentemp($1->symbol->type->type);
                                        emit("/", $$->symbol->name, $1->symbol->name, temp->name);
                                    } else {
                                        yyerror("Type error.");
                                    }
                                }
                            | multiplicative_expression MOD unary_expression
                                {
                                    SymbolType *baseType = $3->symbol->type;
                                    while(baseType->arrayType)
                                        baseType = baseType->arrayType;
                                    Symbol *temp;
                                    if($3->type == Array::ARRAY) {
                                        temp = gentemp(baseType->type);
                                        emit("=[]", temp->name, $3->symbol->name, $3->temp->name);
                                    } else if($3->type == Array::POINTER) {
                                        temp = $3->temp;
                                    } else {
                                        temp = $3->symbol;
                                    }
                                    yyinfo("multiplicative_expression => multiplicative_expression % unary_expression");
                                    if(typeCheck($1->symbol, temp)) {
                                        $$ = new Expression();
                                        $$->symbol = gentemp($1->symbol->type->type);
                                        emit("%", $$->symbol->name, $1->symbol->name, temp->name);
                                    } else {
                                        yyerror("Type error.");
                                    }
                                }
                            ;

/*
For additive expressions, similar procedure is followed.
Then type checking is performed and then appropriate temporaries are created and stored in the new temporaries
*/
additive_expression:
                    multiplicative_expression
                        {
                            yyinfo("additive_expression => multiplicative_expression");
                            $$ = $1;
                            // emit("param", $1->symbol->name);
                        }
                    | additive_expression PLUS multiplicative_expression
                        {
                            yyinfo("additive_expression => additive_expression + multiplicative_expression");
                            if(typeCheck($1->symbol, $3->symbol)) {
                                $$ = new Expression();
                                $$->symbol = gentemp($1->symbol->type->type);
                                emit("+", $$->symbol->name, $1->symbol->name, $3->symbol->name);
                            } else {
                                yyerror("Type error.");
                            }
                        }
                    | additive_expression SUB multiplicative_expression
                        {
                            yyinfo("additive_expression => additive_expression - multiplicative_expression");
                            if(typeCheck($1->symbol, $3->symbol)) {
                                $$ = new Expression();
                                $$->symbol = gentemp($1->symbol->type->type);
                                emit("-", $$->symbol->name, $1->symbol->name, $3->symbol->name);
                            } else {
                                yyerror("Type error.");
                            }
                        }
                    ;

shift_expression
    : additive_expression
    {
        $$ = $1;
    }
    | shift_expression LSHIFT additive_expression
    {
        if(typeCheck($1->symbol, $3->symbol)) {
            $$ = new Expression();
            $$->symbol = gentemp($1->symbol->type->type);
            emit("<<", $$->symbol->name, $1->symbol->name, $3->symbol->name);
            $$->type = Expression::NONBOOLEAN;
        }
        else {
            yyerror("Type mismatch in shift expression");
        }
    }
    | shift_expression RSHIFT additive_expression
    {
        if(typeCheck($1->symbol, $3->symbol)) {
            $$ = new Expression();
            $$->symbol = gentemp($1->symbol->type->type);
            emit(">>", $$->symbol->name, $1->symbol->name, $3->symbol->name);
            $$->type = Expression::NONBOOLEAN;
        }
        else {
            yyerror("Type mismatch in shift expression");
        }
    }
    ;
// boolean expressions
// trueList and falseList are used to represent the appropriate lists. Then these lists are backpatched afterwards with the appropriate address.

relational_expression:
                        shift_expression
                            {
                                yyinfo("relational_expression => shift_expression");
                                $$ = $1;
                            }
                        | relational_expression LESS  shift_expression
                            {
                                yyinfo("relational_expression => relational_expression < shift_expression");
                                if(typeCheck($1->symbol, $3->symbol)) {
                                    $$ = new Expression();
                                    $$->type = Expression::BOOLEAN;
                                    $$->trueList = makeList(nextInstruction());
			                        $$->falseList = makeList(nextInstruction() + 1);
                                    emit("<", "", $1->symbol->name, $3->symbol->name);
                                    emit("goto", "");
                                } else {
                                    yyerror("Type error.");
                                }
                            }
                        | relational_expression GREATER shift_expression
                            {
                                yyinfo("relational_expression => relational_expression > shift_expression");
                                if(typeCheck($1->symbol, $3->symbol)) {
                                    $$ = new Expression();
                                    $$->type = Expression::BOOLEAN;
                                    $$->trueList = makeList(nextInstruction());
			                        $$->falseList = makeList(nextInstruction() + 1);
                                    emit(">", "", $1->symbol->name, $3->symbol->name);
                                    emit("goto", "");
                                } else {
                                    yyerror("Type error.");
                                }
                            }
                        | relational_expression LESSEQ shift_expression
                            {
                                yyinfo("relational_expression => relational_expression <= shift_expression");
                                if(typeCheck($1->symbol, $3->symbol)) {
                                    $$ = new Expression();
                                    $$->type = Expression::BOOLEAN;
                                    $$->trueList = makeList(nextInstruction());
			                        $$->falseList = makeList(nextInstruction() + 1);
                                    emit("<=", "", $1->symbol->name, $3->symbol->name);
                                    emit("goto", "");
                                } else {
                                    yyerror("Type error.");
                                }
                            }
                        | relational_expression GREATEREQ shift_expression
                            {
                                yyinfo("relational_expression => relational_expression >= shift_expression");
                                if(typeCheck($1->symbol, $3->symbol)) {
                                    $$ = new Expression();
                                    $$->type = Expression::BOOLEAN;
                                    $$->trueList = makeList(nextInstruction());
			                        $$->falseList = makeList(nextInstruction() + 1);
                                    emit(">=", "", $1->symbol->name, $3->symbol->name);
                                    emit("goto", "");
                                } else {
                                    yyerror("Type error.");
                                }
                            }
                        ;


/* After equality_expression and before logical_AND_expression */

bitwise_AND_expression
    : equality_expression
    {
        $$ = $1;
    }
    | bitwise_AND_expression BIT_AND equality_expression
    {
        if(typeCheck($1->symbol, $3->symbol)) {
            $$ = new Expression();
            $$->symbol = gentemp($1->symbol->type->type);
            emit("&", $$->symbol->name, $1->symbol->name, $3->symbol->name);
        }
        else {
            yyerror("Type error in bit AND operation");
        }
    }
    ;

bitwise_XOR_expression
    : bitwise_AND_expression
    {
        $$ = $1;
    }
    | bitwise_XOR_expression BIT_XOR bitwise_AND_expression
    {
        if(typeCheck($1->symbol, $3->symbol)) {
            $$ = new Expression();
            $$->symbol = gentemp($1->symbol->type->type);
            emit("^", $$->symbol->name, $1->symbol->name, $3->symbol->name);
        }
        else {
            yyerror("Type error in bit XOR operation");
        }
    }
    ;

bitwise_OR_expression
    : bitwise_XOR_expression
    {
        $$ = $1;
    }
    | bitwise_OR_expression BIT_OR bitwise_XOR_expression
    {
        if(typeCheck($1->symbol, $3->symbol)) {
            $$ = new Expression();
            $$->symbol = gentemp($1->symbol->type->type);
            emit("|", $$->symbol->name, $1->symbol->name, $3->symbol->name);
        }
        else {
            yyerror("Type error in bit OR operation");
        }
    }
    ;















equality_expression:
                    relational_expression
                        {
                            yyinfo("equality_expression => relational_expression");
                            $$ = $1;
                        }
                    | equality_expression EQUALS relational_expression
                        {
                            yyinfo("equality_expression => equality_expression == relational_expression");
                            if(typeCheck($1->symbol, $3->symbol)) {
                                $1->toInt();
                                $3->toInt();
                                $$ = new Expression();
                                $$->type = Expression::BOOLEAN;
                                $$->trueList = makeList(nextInstruction());
                                emit("==", "", $1->symbol->name, $3->symbol->name);
			                    $$->falseList = makeList(nextInstruction());
                                emit("goto", "");
                            } else {
                                yyerror("Type error.");
                            }
                        }
                    | equality_expression NOTEQ relational_expression
                        {
                            yyinfo("equality_expression => equality_expression != relational_expression");
                            if(typeCheck($1->symbol, $3->symbol)) {
                                $1->toInt();
                                $3->toInt();
                                $$ = new Expression();
                                $$->type = Expression::BOOLEAN;
                                $$->trueList = makeList(nextInstruction());
			                    $$->falseList = makeList(nextInstruction() + 1);
                                emit("!=", "", $1->symbol->name, $3->symbol->name);
                                emit("goto", "");
                            } else {
                                yyerror("Type error.");
                            }
                        }
                    ;


/*
Marker rule:
M will store the location of the quad at M.
This value will be used for backpatching later.
Gaurd rule:
N will represent the nextList, i.e, list of indices of dangling exits
*/


M:
        {
            yyinfo("M => epsilon");
            $$ = nextInstruction();
        }
    ;

N:
        {
            yyinfo("N => epsilon");
            $$ = new Statement();
            $$->nextList = makeList(nextInstruction());
            emit("goto", "");
        }
	;

/*

 logical and
backpatch(B 1 .truelist, M.instr );
B.truelist = B 2 .truelist;
B.falselist = merge(B 1 .falselist, B 2 .falselist);

 logical or
backpatch(B 1 .falselist, M.instr );
B.truelist = merge(B 1 .truelist, B 2 .truelist);
B.falselist = B 2 .falselist;

 ? :
E .loc = gentemp();
E .type = E 2 .type; // Assume E 2 .type = E 3 .type
emit(E .loc ’=’ E 3 .loc); // Control gets here by fall-through
l = makelist(nextinstr );
emit(goto .... );
backpatch(N 2 .nextlist, nextinstr );
emit(E .loc ’=’ E 2 .loc);
l = merge(l, makelist(nextinstr ));
emit(goto .... );
backpatch(N 1 .nextlist, nextinstr );
convInt2Bool(E 1 );
backpatch(E 1 .truelist, M 1 .instr );
backpatch(E 1 .falselist, M 2 .instr );
backpatch(l, nextinstr );

*/

logical_AND_expression:
                        bitwise_OR_expression
                            {
                                yyinfo("logical_AND_expression => equality_expression");
                                $$ = $1;
                            }
                        | logical_AND_expression LOGICAL_AND M bitwise_OR_expression
                            {
                                yyinfo("logical_AND_expression => logical_AND_expression && equality_expression");
                                $1->toInt();
                                $4->toInt();
                                $$ = new Expression();
                                $$->type = Expression::BOOLEAN;
                                backpatch($1->trueList, $3);
                                $$->trueList = $4->trueList;
                                $$->falseList = merge($1->falseList, $4->falseList);
                            }
                        ;

logical_OR_expression:
                        logical_AND_expression
                            {
                                yyinfo("logical_OR_expression => logical_AND_expression");
                                $$ = $1;
                            }
                        | logical_OR_expression LOGICAL_OR M logical_AND_expression
                            {
                                yyinfo("logical_OR_expression => logical_OR_expression || logical_AND_expression");
                                $1->toInt();
                                $4->toInt();
                                $$ = new Expression();
                                $$->type = Expression::BOOLEAN;
                                backpatch($1->falseList, $3);
                                $$->trueList = merge($1->trueList, $4->trueList);
                                $$->falseList = $4->falseList;
                            }
                        ;

conditional_expression:
                        logical_OR_expression
                            {
                                yyinfo("conditional_expression => logical_OR_expression");
                                $$ = $1;
                            }
                        /* | LPARAN logical_OR_expression RPARAN N QUES M expression N COLON M conditional_expression
                            {
                                yyinfo("conditional_expression => ( logical_OR_expression ) ? expression : conditional_expression");
                                $$->symbol = gentemp($7->symbol->type->type);
                                emit("=", $$->symbol->name, $11->symbol->name);
                                list<int> l = makeList(nextInstruction());
                                emit("goto", "");
                                backpatch($8->nextList, nextInstruction());
                                emit("=", $$->symbol->name, $7->symbol->name);
                                l = merge(l, makeList(nextInstruction()));
                                emit("goto", "");
                                backpatch($4->nextList, nextInstruction());
                                $2->toBool();
                                backpatch($2->trueList, $6);
                                backpatch($2->falseList, $10);
                                backpatch(l, nextInstruction());
                            } */
                        | logical_OR_expression  N QUES M expression N COLON M conditional_expression
                            // $1                $2 $3  $4 $5        $6  $7  $8 $9
                            {
                                yyinfo("conditional_expression => logical_OR_expression ? expression : conditional_expression");
                                $$->symbol = gentemp($5->symbol->type->type);
                                emit("=", $$->symbol->name, $9->symbol->name);
                                list<int> l = makeList(nextInstruction());
                                emit("goto", "");
                                backpatch($6->nextList, nextInstruction());
                                emit("=", $$->symbol->name, $5->symbol->name);
                                l = merge(l, makeList(nextInstruction()));
                                emit("goto", "");
                                backpatch($2->nextList, nextInstruction());
                                $1->toBool();
                                backpatch($1->trueList, $4);
                                backpatch($1->falseList, $8);
                                backpatch(l, nextInstruction());
                            }
                        ;

assignment_expression:
                        conditional_expression
                            {
                                yyinfo("assignment_expression => conditional_expression");
                                $$ = $1;
                                // emit("param", $1->symbol->name);
                            }
                        | unary_expression ASSIGN assignment_expression
                            {
                                yyinfo("assignment_expression => unary_expression = assignment_expression");
                                if($1->type == Array::ARRAY) {
                                    // EQUAL to array
                                    $3->symbol = $3->symbol->convert($1->subArrayType->type);
                                    emit("[]=", $1->symbol->name, $1->temp->name, $3->symbol->name);
                                } else if($1->type == Array::POINTER) {
                                    // EQUAL to pointer
                                    $3->symbol = $3->symbol->convert($1->temp->type->type);
                                    emit("*=", $1->symbol->name, $3->symbol->name);
                                } else {
                                    // EQUAL to other
                                    $3->symbol = $3->symbol->convert($1->symbol->type->type);
			                        emit("=", $1->symbol->name, $3->symbol->name);
                                }
                                $$ = $3;
                            }
                        ;

expression:
            assignment_expression
                {
                    yyinfo("expression => assignment_expression");
                    $$ = $1;
                }
            ;

//-------------------------------------------- Declarations

declaration:
            type_specifier init_declarator SEMICOLON
                {
                     yyinfo("declaration => type_specifier init_declarator ;");
                }
            ;

init_declarator:
                declarator
                    {
                        yyinfo("init_declarator => declarator");
                        $$ = $1;
                    }
                | declarator ASSIGN initialiser
                    {
                        yyinfo("init_declarator => declarator = initialiser");
                        // if there is some initial value assign it
                        if($3->initialValue != "")
                            $1->initialValue = $3->initialValue;
                        // = EQUAL
		                emit("=", $1->name, $3->name);
                    }
                ;


type_specifier:
                VOID
                    {
                        yyinfo("type_specifier => void");
                        currentType = SymbolType::VOID_T;
                    }
                | CHAR
                    {
                        yyinfo("type_specifier => char");
                        currentType = SymbolType::CHAR_T;
                    }
                | INT
                    {
                        yyinfo("type_specifier => int");
                        currentType = SymbolType::INT_T;
                    }
                |FLOAT
                     {
                         currentType = SymbolType::FLOAT_T; // Add FLOAT_T to SymbolType enum in translator.h
                     }

                ;

declarator:
            pointer direct_declarator
                {
                    yyinfo("declarator => pointer direct_declarator");
                    SymbolType *it = $1;
                    it->arrayType = $2->type; // this updates the type of 2 as pointer to int
                    // but for functions/arrays, it should be different?
                    // int* a[10] = should be array of pointers and not pointer to array
                    // int* func(){}    should's return value should be int*
                    if($2->type->type == SymbolType::ARRAY){
                        $1->arrayType = $2->type->arrayType;
                        $2->type->arrayType = $1;
                        // $$ = $2->update();
                    }
                    else if( $2->type->type == SymbolType::FUNCTION){
                        currentTable->search("return")->update($1);
                    }
                    else
                    {
                        $$ = $2->update($1);
                    }
                }
            | direct_declarator
                {
                    yyinfo("declarator => direct_declarator");
                }
            ;

// new grammar rule added
change_scope_definition:
                    {
                        if(currentSymbol->nestedTable == NULL) {
                            changeTable(new SymbolTable(""));
                        }
                        else {
                            changeTable(currentSymbol->nestedTable);
                            // emit("label", currentTable->name);
                        }
                    }
	            ;

change_scope_declaration:
                    {
                        if(currentSymbol->nestedTable == NULL) {
                            changeTable(new SymbolTable(""));
                        }
                        else {
                            changeTable(currentSymbol->nestedTable);
                            emit("label", currentTable->name);
                        }
                    }
	            ;


// grammar
AUG1: ID
    {
        $$ = $1->update(new SymbolType(currentType));
        currentSymbol = $$;
    };


/*
Declarations
*/

direct_declarator:
                    ID
                        {
                            yyinfo("direct_declarator => ID");

                            // forcefully creating a new entery inside this table
                            $1 = currentTable->search1($1->name);

                            // whenever we see a declarator, then we set it's type to the last type seen by the lexer
                            $$ = $1->update(new SymbolType(currentType)); // update type to the last type seen
                            currentSymbol = $$;
                        }
                    | direct_declarator LSQBRACKET INT_CONST RSQBRACKET     // TODO: for multiarray
                        {
                            yyinfo("direct_declarator => ID [ assignment_expression ]");

                            // forcefully creating a new entery inside this table
                            $1 = currentTable->search1($1->name);

                            SymbolType *it1 = $1->type, *it2 = NULL;

                            while(it1->type == SymbolType::ARRAY) { // go to the base level of a nested type
                                it2 = it1;
                                it1 = it1->arrayType;
                            }

                            if(it2 != NULL) {
                                // nested array case
                                it2->arrayType =  new SymbolType(SymbolType::ARRAY, it1, $3);
                                $$ = $1->update($1->type);
                            } else {
                                $$ = $1->update(new SymbolType(SymbolType::ARRAY, $1->type, $3));
                            }
                        }
                    | AUG1 LPARAN change_scope_declaration parameter_list RPARAN
                        {
                            yyinfo("direct_declarator => ID ( parameter_list )");

                            // function declaration
                            currentTable->name = $1->name;

                            $1->type->paramType = $4;

                            if($1->type->type != SymbolType::VOID_T) {
                                // set type of return value
                                currentTable->search("return")->update($1->type);
                            }

                            // move back to the global table and set the nested table for the function
                            $1->nestedTable = currentTable;
                            $1->category = Symbol::FUNCTION;
                            currentTable->parent = globalTable;
                            changeTable(globalTable);
                            currentSymbol = $$;
                        }
                    | AUG1 LPARAN change_scope_declaration RPARAN // for parameter_list_opt
                        {
                            yyinfo("direct_declarator => ID ( )");

                            // same as the previous rule
                            currentTable->name = $1->name;
                            // $1->update(new SymbolType(currentType));

                            if($1->type->type != SymbolType::VOID_T) {
                                // set type of return value
                                currentTable->search("return")->update($1->type);
                            }

                            // move back to the global table and set the nested table for the function
                            $1->nestedTable = currentTable;
                            $1->category = Symbol::FUNCTION;
                            currentTable->parent = globalTable;
                            changeTable(globalTable);
                            currentSymbol = $$;
                        }
                    ;



/*
Pointer declarations
Generating new symbol with type pointer
*/

pointer:
        MULT
            {
                yyinfo("pointer => * ");
                $$ = new SymbolType(SymbolType::POINTER);
            }
        ;

parameter_list:
                parameter_declaration
                    {
                        yyinfo("parameter_list => parameter_declaration");
                        $$ = $1;
                    }
                | parameter_list COMMA parameter_declaration
                    {
                        yyinfo("parameter_list => parameter_list , parameter_declaration");
                        // SymbolType* temp1 = $1;
                        // SymbolType* temp2 = NULL;
                        // printf("hi1\n");
                        // while(temp1 != nullptr){
                        //     printf("hi2\n");
                        //     temp2 = temp1;
                        //     temp1 = temp1->paramType;
                        // }
                        // printf("hi3\n");
                        // if(temp2)
                        // temp2->paramType = $3;
                        $$ = $1;
                    }
                ;

// TODO: CHANGED:
parameter_declaration:
                        type_specifier declarator
                            {
                                yyinfo("parameter_declaration => pointer identifier_opt");
                                $2->category = Symbol::PARAMETER;
                            }
                        | type_specifier
                            {
                                yyinfo("parameter_declaration => identifier_opt");
                            }
                        ;

identifier_opt:
                ID
                    {
                        yyinfo("identifier_opt => ID");
                    }
                | /* epsilon */
                ;

initialiser:
            assignment_expression
                {
                    yyinfo("initialiser => assignment_expression");
                    $$ = $1->symbol;
                }
            ;

/* Statements */

statement:
            compound_statement
                {
                    yyinfo("statement => compound_statement");
                    $$ = $1;
                }
            | expression_statement
                {
                    yyinfo("statement => expression_statement");
                    $$ = new Statement();
                    $$->nextList = $1->nextList;
                }
            | selection_statement
                {
                    yyinfo("statement => selection_statement");
                    $$ = $1;
                }
            | iteration_statement
                {
                    yyinfo("statement => iteration_statement");
                    $$ = $1;
                }
            | jump_statement
                {
                    yyinfo("statement => jump_statement");
                    $$ = $1;
                }
            ;


/*
Changing the symbol table on encountering new block
This will create nested symbol tables
*/

change_block:
                    {
                        string name = currentTable->name + "_" + toString(tableCount);
                        tableCount++;
                        Symbol *s = currentTable->search(name); // create new entry in symbol table
                        s->nestedTable = new SymbolTable(name, currentTable);
                        s->type = new SymbolType(SymbolType::BLOCK);
                        currentSymbol = s;
                    }
                ;

compound_statement:
                    BEG change_block change_scope_declaration block_item_list_opt END
                        {
                            yyinfo("compound_statement => { block_item_list_opt }");
                            $$ = $4;
                            changeTable(currentTable->parent); // block over, move back to the parent table
                        }
                    ;

block_item_list_opt:
                    block_item_list
                        {
                            yyinfo("block_item_list_opt => block_item_list");
                            $$ = $1;
                        }
                    |
                        {
                            yyinfo("block_item_list_opt => epsilon");
                            $$ = new Statement();
                        }
                    ;

block_item_list:
                block_item
                    {
                        yyinfo("block_item_list => block_item");
                        $$ = $1;
                    }
                | block_item_list M block_item
                    {
                        yyinfo("block_item_list => block_item_list block_item");
                        $$ = $3;
                        // after completion of block_item_list(1) we move to block_item(3)
                        backpatch($1->nextList,$2);
                    }
                ;

block_item:
            declaration
                {
                    yyinfo("block_item => declaration");
                    $$ = new Statement();
                }
            | statement
                {
                    yyinfo("block_item => statement");
                    $$ = $1;
                }
            ;

expression_statement:
                        expression_opt SEMICOLON
                            {
                                yyinfo("expression_statement => expression_opt ;");
                                $$ = $1;
                            }
                        ;

expression_opt:
                expression
                    {
                        yyinfo("expression_opt => expression");
                        $$ = $1;
                    }
                |
                    {
                        yyinfo("expression_opt => epsilon");
                        $$ = new Expression();
                    }
                ;

/*

IF ELSE

-> the %prec THEN : to remove ambiguity

S -> if (B) M S1 N
backpatch(B.truelist, M.instr )
S.nextlist = merge(B.falselist, merge(S1.nextlist, N.nextlist))

S -> if (B) M 1 S 1 N else M 2 S 2
backpatch(B.truelist, M1.instr )
backpatch(B.falselist, M2.instr )
S.nextlist = merge(merge(S1.nextlist, N.nextlist), S2 .nextlist)

*/

selection_statement:
                    IF LPARAN expression N RPARAN M statement N %prec THEN    // TODO:
                        {
                            yyinfo("selection_statement => if ( expression ) statement");
                            backpatch($4->nextList, nextInstruction());
                            $$ = new Statement();
                            $3->toBool();
                            backpatch($3->trueList, $6); // if true go to M
                            $$->nextList = merge($3->falseList, merge($7->nextList, $8->nextList)); // exits
                        }
                    | IF LPARAN expression N RPARAN M statement N ELSE M statement
                        {
                            yyinfo("selection_statement => if ( expression ) statement else statement");
                            backpatch($4->nextList, nextInstruction());
                            $$ = new Statement();
                            $3->toBool();
                            backpatch($3->trueList, $6); // if true go to M
                            backpatch($3->falseList, $10); // if false go to else
                            $$->nextList = merge($11->nextList, merge($7->nextList, $8->nextList)); // exits
                        }
                    ;

/*

LOOPS

for ( E1 ; M1 B ; M2 E2 N ) M3 S1
backpatch(B.truelist, M3.instr );
backpatch(N.nextlist, M1.instr );
backpatch(S1.nextlist, M2.instr );
emit(”goto” M2.instr );
S.nextlist = B.falselist;

*/

iteration_statement:
                    FOR LPARAN expression_opt SEMICOLON M expression_opt SEMICOLON M expression_opt N RPARAN M statement
                        {
                            yyinfo("iteration_statement => for ( expression_opt ; expression_opt ; expression_opt ) statement");
                            $$ = new Statement();
                            $6->toBool();
                            backpatch($6->trueList, $12); // if true go to M3 (loop body)
                            backpatch($10->nextList, $5); // after N go to M1 (condition check)
                            backpatch($13->nextList, $8); // after S1 (loop body) go to M2 (increment/decrement/any other operation)
                            emit("goto", toString($8));
                            $$->nextList = $6->falseList; // exit if false
                        }
                    |WHILE M LPARAN expression RPARAN M statement
                         {

                         {
                             $$ = new Statement();

                             // Evaluate the expression
                             $4->toBool();

                             // Backpatch the true list of the expression to the loop body
                             backpatch($4->trueList, $6);

                             // Backpatch the false list of the expression to the exit
                             $$->nextList = $4->falseList;

                             // Backpatch the next list of the statement to the start of condition checking (M)
                             backpatch($7->nextList, $2);

                             // Emit a GOTO to go back to the start of the loop
                             emit("goto", toString($2));
                         }

                         }
                         | DO M statement WHILE LPARAN M expression RPARAN SEMICOLON
                         {
                             $$ = new Statement();

                             // Backpatch trueList of expression to M1 (beginning of the loop)
                             backpatch($7->trueList, $2);

                             // Merge the nextList of statement with the falseList of expression
                             $$->nextList = $7->falseList;

                             // Backpatch nextList of statement to M2 (expression evaluation)
                             backpatch($3->nextList, $6);
                         }

                    ;

jump_statement:
                RETURN expression_opt SEMICOLON
                    {
                        yyinfo("jump_statement => return expression_opt ;");
                        $$ = new Statement();
                        if($2->symbol != NULL) {
                            emit("return", $2->symbol->name); // emit the current symbol name at return if it exists otherwise empty
                        } else {
                            emit("return", "");
                        }
                    }
                ;

/* External definitions */

translation_unit:
                    temp_declaration
                        {
                            yyinfo("translation_unit => temp_declaration");
                        }
                    | translation_unit temp_declaration
                        {
                            yyinfo("translation_unit => translation_unit temp_declaration");
                        }
                    ;

temp_declaration:
                        function_definition
                            {
                                yyinfo("temp_declaration => function_definition");
                            }
                        | declaration
                            {
                                yyinfo("temp_declaration => declaration");
                            }
                        ;

function_definition:  // TODO:
                    type_specifier declarator change_scope_definition BEG block_item_list_opt END
                        {
                            yyinfo("function_definition => type_specifier declarator change_scope BEG block_item_list_opt END");
                            tableCount = 0;
                            if($2->type->type != SymbolType::VOID_T){
                                currentTable->search("return")->update($2->type);
                            }
                            $2->isFunction = true;
                            // $3->type->returnType->type= $2;
                            changeTable(globalTable);
                        }
                    ;

%%

void yyerror(string s) {
    printf("ERROR at line no. %d : %s\n", yylineno, s.c_str());
}

void yyinfo(string s) {
    #ifdef _DEBUG
        printf("INFO [Line %d] : %s\n", yylineno, s.c_str());
    #endif
}
