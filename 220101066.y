%{
    #include "220101066.h"
    extern int yylex();
    extern int yylineno;
    void yyerror(string);

%}


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
%token IFX
%token INC
%token DEC

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
%nonassoc IFX
%nonassoc ELSE

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


primary_expression:
                    ID
                        {

                            $$ = new Expression(); // create new non boolean expression and symbol is the ID
                            // expression->symbol simply points to the symbol corresponding to the ID, in the table
                            $$->symbol = $1;
                            $$->type = Expression::NONBOOLEAN;
                        }
                    | INT_CONST
                        {

                            $$ = new Expression();
                            // a new tempvar is created & initialised with $1 value, and the symbol points to this
                            $$->symbol = generateTemporary(SymbolType::INT_T, toString($1));
                            // and extra quad is entered which initialises the temp var = $1->intValue
                            // so wherever this int was used, now this temp var will be used in its place
                            emit("=", $$->symbol->name, $1);
                        }
                    | CHAR_CONST
                        {


                            $$ = new Expression();
                            $$->symbol = generateTemporary(SymbolType::CHAR_T, $1);
                            emit("=", $$->symbol->name, $1);
                        }
                    | STRING_CONST
                        {

                            $$ = new Expression();


		                    $$->symbol = generateTemporary(SymbolType::POINTER, $1);

		                    $$->symbol->type->arrayType = new SymbolType(SymbolType::CHAR_T);
                        }
                    | LPARAN expression RPARAN
                        {

                            $$ = $2;
                        }
                    | FLOAT_CONST
                         {
                             $$ = new Expression();
                             string val = toString($1);
                             Symbol *s = generateTemporary(SymbolType::FLOAT_T, val);
                             s->initialValue = val;
                             $$->symbol = s;
                         }

                    ;

postfix_expression:
                    primary_expression
                        {

                            $$ = new Array();
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


                            $$ = new Array();
                            $$->symbol = $1->symbol;
                            $$->subArrayType = $1->subArrayType->arrayType;
                            $$->temp = generateTemporary(SymbolType::INT_T);
                            $$->type = Array::ARRAY;

                            if($1->type == Array::ARRAY) {

                                Symbol *sym = generateTemporary(SymbolType::INT_T);
                                emit("*", sym->name, $3->symbol->name, toString($$->subArrayType->getSize()));
                                emit("+", $$->temp->name, $1->temp->name, sym->name);
                            } else {
                                emit("*", $$->temp->name, $3->symbol->name, toString($$->subArrayType->getSize()));
                            }

                        }
                    | postfix_expression LPARAN argument_expression_list_opt RPARAN
                        {


                            $$ = new Array();
                            $$->symbol = generateTemporary($1->symbol->type->type);

                            $$->symbol->type->arrayType = $1->symbol->type->arrayType;

                            emit("call", $$->symbol->name, $1->symbol->name, toString($3));
                        }
                    | postfix_expression ARROW ID
                        {

                        }
                    |postfix_expression INC
                             {
                                 $$ = new Array();
                                 $$->symbol = generateTemporary($1->symbol->type->type);
                                 emit("=", $$->symbol->name, $1->symbol->name);
                                 emit("+", $1->symbol->name, $1->symbol->name, "1");
                             }
                    |postfix_expression DEC
                             {
                                 $$ = new Array();
                                 $$->symbol = generateTemporary($1->symbol->type->type);
                                emit("=", $$->symbol->name, $1->symbol->name);
                                emit("-", $1->symbol->name, $1->symbol->name, "1");
                             }
                    ;



argument_expression_list_opt:
                                argument_expression_list
                                    {

                                        $$ = $1;
                                    }
                                | /* epsilon */
                                    {


                                        $$ = 0;
                                    }
                                ;

argument_expression_list:
                            assignment_expression
                                {


                                    emit("param", $1->symbol->name);
                                    $$ = 1;
                                }
                            | argument_expression_list COMMA assignment_expression
                                {


                                    emit("param", $3->symbol->name);
                                    $$ = $1 + 1;
                                }
                            ;

unary_expression:
                    postfix_expression
                        {

                            $$ = $1;
                        }
                    | unary_operator unary_expression
                        {

                            if(strcmp($1, "&") == 0) {

                                $$ = new Array();

                                $$->symbol = generateTemporary(SymbolType::POINTER);

                                $$->symbol->type->arrayType = $2->symbol->type;

                                emit("=&", $$->symbol->name, $2->symbol->name);

                            } else if(strcmp($1, "*") == 0) {


                                $$ = new Array();
                                $$->type = Array::POINTER;

                                $$->temp = generateTemporary($2->temp->type->arrayType->type);

                                $$->symbol = $2->symbol;
                                $$->temp->type->arrayType = $2->temp->type->arrayType->arrayType;
                                emit("=*", $$->temp->name, $2->symbol->name);
                            } else if(strcmp($1, "+") == 0) {
                                $$ = $2;
                            } else {

                                $$ = new Array();
                                $$->symbol = generateTemporary($2->symbol->type->type);
                                emit($1, $$->symbol->name, $2->symbol->name);
                            }
                        }
                    ;


unary_operator:
                BIT_AND
                    {

                        $$ = strdup("&");
                    }
                | MULT
                    {

                        $$ = strdup("*");
                    }
                | PLUS
                    {

                        $$ = strdup("+");
                    }
                | SUB
                    {

                        $$ = strdup("=-");
                    }
                | LOGICAL_NOT
                    {

                        $$ = strdup("!");
                    }
                | INC
                {
                $$=strdup("++");
                }
                | DEC
                {
                $$=strdup("--");
                }
                ;


multiplicative_expression:
                            unary_expression
                                {
                                     SymbolType *baseType;
                                    if($1->symbol)
                                        baseType = $1->symbol->type;
                                    while(baseType->arrayType)
                                        baseType = baseType->arrayType;

                                    $$ = new Expression();
                                    if($1->type == Array::ARRAY) {
                                        $$->symbol = generateTemporary(baseType->type);
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
                                        temp = generateTemporary(baseType->type);
                                        emit("=[]", temp->name, $3->symbol->name, $3->temp->name);
                                    } else if($3->type == Array::POINTER) {
                                        temp = $3->temp;
                                    } else {
                                        temp = $3->symbol;
                                    }

                                    if(typeCheck($1->symbol, temp)) {
                                        $$ = new Expression();
                                        $$->symbol = generateTemporary($1->symbol->type->type);
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
                                        temp = generateTemporary(baseType->type);
                                        emit("=[]", temp->name, $3->symbol->name, $3->temp->name);
                                    } else if($3->type == Array::POINTER) {
                                        temp = $3->temp;
                                    } else {
                                        temp = $3->symbol;
                                    }

                                    if(typeCheck($1->symbol, temp)) {
                                        $$ = new Expression();
                                        $$->symbol = generateTemporary($1->symbol->type->type);
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
                                        temp = generateTemporary(baseType->type);
                                        emit("=[]", temp->name, $3->symbol->name, $3->temp->name);
                                    } else if($3->type == Array::POINTER) {
                                        temp = $3->temp;
                                    } else {
                                        temp = $3->symbol;
                                    }

                                    if(typeCheck($1->symbol, temp)) {
                                        $$ = new Expression();
                                        $$->symbol = generateTemporary($1->symbol->type->type);
                                        emit("%", $$->symbol->name, $1->symbol->name, temp->name);
                                    } else {
                                        yyerror("Type error.");
                                    }
                                }
                            ;


additive_expression:
                    multiplicative_expression
                        {

                            $$ = $1;

                        }
                    | additive_expression PLUS multiplicative_expression
                        {

                            if(typeCheck($1->symbol, $3->symbol)) {
                                $$ = new Expression();
                                $$->symbol = generateTemporary($1->symbol->type->type);
                                emit("+", $$->symbol->name, $1->symbol->name, $3->symbol->name);
                            } else {
                                yyerror("Type error.");
                            }
                        }
                    | additive_expression SUB multiplicative_expression
                        {

                            if(typeCheck($1->symbol, $3->symbol)) {
                                $$ = new Expression();
                                $$->symbol = generateTemporary($1->symbol->type->type);
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
            $$->symbol = generateTemporary($1->symbol->type->type);
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
            $$->symbol = generateTemporary($1->symbol->type->type);
            emit(">>", $$->symbol->name, $1->symbol->name, $3->symbol->name);
            $$->type = Expression::NONBOOLEAN;
        }
        else {
            yyerror("Type mismatch in shift expression");
        }
    }
    ;

relational_expression:
                        shift_expression
                            {

                                $$ = $1;
                            }
                        | relational_expression LESS  shift_expression
                            {

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


bitwise_AND_expression
    : equality_expression
    {
        $$ = $1;
    }
    | bitwise_AND_expression BIT_AND equality_expression
    {
        if(typeCheck($1->symbol, $3->symbol)) {
            $$ = new Expression();
            $$->symbol = generateTemporary($1->symbol->type->type);
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
            $$->symbol = generateTemporary($1->symbol->type->type);
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
            $$->symbol = generateTemporary($1->symbol->type->type);
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

                            $$ = $1;
                        }
                    | equality_expression EQUALS relational_expression
                        {

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




M:
        {

            $$ = nextInstruction();
        }
    ;

N:
        {

            $$ = new Statement();
            $$->nextList = makeList(nextInstruction());
            emit("goto", "");
        }
	;



logical_AND_expression:
                        bitwise_OR_expression
                            {

                                $$ = $1;
                            }
                        | logical_AND_expression LOGICAL_AND M bitwise_OR_expression
                            {

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

                                $$ = $1;
                            }
                        | logical_OR_expression LOGICAL_OR M logical_AND_expression
                            {

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

                                $$ = $1;
                            }

                        | logical_OR_expression  N QUES M expression N COLON M conditional_expression
                            {

                                $$->symbol = generateTemporary($5->symbol->type->type);
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

                                $$ = $1;

                            }
                        | unary_expression ASSIGN assignment_expression
                            {

                                if($1->type == Array::ARRAY) {

                                    $3->symbol = $3->symbol->convert($1->subArrayType->type);
                                    emit("[]=", $1->symbol->name, $1->temp->name, $3->symbol->name);
                                } else if($1->type == Array::POINTER) {

                                    $3->symbol = $3->symbol->convert($1->temp->type->type);
                                    emit("*=", $1->symbol->name, $3->symbol->name);
                                } else {

                                    $3->symbol = $3->symbol->convert($1->symbol->type->type);
			                        emit("=", $1->symbol->name, $3->symbol->name);
                                }
                                $$ = $3;
                            }
                        ;

expression:
            assignment_expression
                {

                    $$ = $1;
                }
            ;



declaration:
            type_specifier init_declarator SEMICOLON
            ;

init_declarator:
                declarator
                    {

                        $$ = $1;
                    }
                | declarator ASSIGN initialiser
                    {


                        if($3->initialValue != "")
                            $1->initialValue = $3->initialValue;

		                emit("=", $1->name, $3->name);
                    }
                ;


type_specifier:
                VOID
                    {

                        currentType = SymbolType::VOID_T;
                    }
                | CHAR
                    {

                        currentType = SymbolType::CHAR_T;
                    }
                | INT
                    {

                        currentType = SymbolType::INT_T;
                    }
                |FLOAT
                     {
                         currentType = SymbolType::FLOAT_T;
                     }

                ;

declarator:
            pointer direct_declarator
                {

                    SymbolType *it = $1;
                    it->arrayType = $2->type;

                    if($2->type->type == SymbolType::ARRAY){
                        $1->arrayType = $2->type->arrayType;
                        $2->type->arrayType = $1;

                    }
                    else if( $2->type->type == SymbolType::FUNCTION){
                        currentTable->lookupSymbol("return")->update($1);
                    }
                    else
                    {
                        $$ = $2->update($1);
                    }
                }
            | direct_declarator
                {

                }
            ;


change_scope_definition:
                    {
                        if(currentSymbol->nestedTable == NULL) {
                            changeTable(new SymbolTable(""));
                        }
                        else {
                            changeTable(currentSymbol->nestedTable);

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
                            emit("label", currentTable->identifier);
                        }
                    }
	            ;



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



                            $1 = currentTable->lookupLocalSymbol($1->name);


                            $$ = $1->update(new SymbolType(currentType)); // update type to the last type seen
                            currentSymbol = $$;
                        }
                    | direct_declarator LSQBRACKET INT_CONST RSQBRACKET     // TODO: for multiarray
                        {



                            $1 = currentTable->lookupLocalSymbol($1->name);

                            SymbolType *it1 = $1->type, *it2 = NULL;

                            while(it1->type == SymbolType::ARRAY) { // go to the base level of a nested type
                                it2 = it1;
                                it1 = it1->arrayType;
                            }

                            if(it2 != NULL) {

                                it2->arrayType =  new SymbolType(SymbolType::ARRAY, it1, $3);
                                $$ = $1->update($1->type);
                            } else {
                                $$ = $1->update(new SymbolType(SymbolType::ARRAY, $1->type, $3));
                            }
                        }
                    | AUG1 LPARAN change_scope_declaration parameter_list RPARAN
                        {



                            currentTable->identifier = $1->name;

                            $1->type->paramType = $4;

                            if($1->type->type != SymbolType::VOID_T) {

                                currentTable->lookupSymbol("return")->update($1->type);
                            }


                            $1->nestedTable = currentTable;
                            $1->category = Symbol::FUNCTION;
                            currentTable->parentTable = globalTable;
                            changeTable(globalTable);
                            currentSymbol = $$;
                        }
                    | AUG1 LPARAN change_scope_declaration RPARAN // for parameter_list_opt
                        {



                            currentTable->identifier = $1->name;


                            if($1->type->type != SymbolType::VOID_T) {

                                currentTable->lookupSymbol("return")->update($1->type);
                            }


                            $1->nestedTable = currentTable;
                            $1->category = Symbol::FUNCTION;
                            currentTable->parentTable = globalTable;
                            changeTable(globalTable);
                            currentSymbol = $$;
                        }
                    ;




pointer:
        MULT
            {

                $$ = new SymbolType(SymbolType::POINTER);
            }
        ;

parameter_list:
                parameter_declaration
                    {

                        $$ = $1;
                    }
                | parameter_list COMMA parameter_declaration
                    {

                        $$ = $1;
                    }
                ;


parameter_declaration:
                        type_specifier declarator
                            {

                                $2->category = Symbol::PARAMETER;
                            }
                        | type_specifier
                            {

                            }
                        ;



initialiser:
            assignment_expression
                {

                    $$ = $1->symbol;
                }
            ;

/* Statements */

statement:
            compound_statement
                {

                    $$ = $1;
                }
            | expression_statement
                {

                    $$ = new Statement();
                    $$->nextList = $1->nextList;
                }
            | selection_statement
                {

                    $$ = $1;
                }
            | iteration_statement
                {

                    $$ = $1;
                }
            | jump_statement
                {

                    $$ = $1;
                }
            ;



change_block:
                    {
                        string name = currentTable->identifier + "_" + toString(tableCount);
                        tableCount++;
                        Symbol *s = currentTable->lookupSymbol(name);
                        s->nestedTable = new SymbolTable(name,SymbolTable::BLOCK_SCOPE
 ,currentTable);
                        s->type = new SymbolType(SymbolType::BLOCK);
                        currentSymbol = s;
                    }
                ;

compound_statement:
                    BEG change_block change_scope_declaration block_item_list_opt END
                        {

                            $$ = $4;
                            changeTable(currentTable->parentTable);
                        }
                    ;

block_item_list_opt:
                    block_item_list
                        {

                            $$ = $1;
                        }
                    |
                        {

                            $$ = new Statement();
                        }
                    ;

block_item_list:
                block_item
                    {

                        $$ = $1;
                    }
                | block_item_list M block_item
                    {

                        $$ = $3;
                        backpatch($1->nextList,$2);
                    }
                ;

block_item:
            declaration
                {

                    $$ = new Statement();
                }
            | statement
                {

                    $$ = $1;
                }
            ;

expression_statement:
                        expression_opt SEMICOLON
                            {

                                $$ = $1;
                            }
                        ;

expression_opt:
                expression
                    {

                        $$ = $1;
                    }
                |
                    {

                        $$ = new Expression();
                    }
                ;


selection_statement:
                    IF LPARAN expression N RPARAN M statement N %prec IFX //ERR:
                        {

                            backpatch($4->nextList, nextInstruction());
                            $$ = new Statement();
                            $3->toBool();
                            backpatch($3->trueList, $6);
                            $$->nextList = merge($3->falseList, merge($7->nextList, $8->nextList));
                        }
                    | IF LPARAN expression N RPARAN M statement N ELSE M statement
                        {

                            backpatch($4->nextList, nextInstruction());
                            $$ = new Statement();
                            $3->toBool();
                            backpatch($3->trueList, $6);
                            backpatch($3->falseList, $10);
                            $$->nextList = merge($11->nextList, merge($7->nextList, $8->nextList));
                        }
                    ;



iteration_statement:
                    FOR LPARAN expression_opt SEMICOLON M expression_opt SEMICOLON M expression_opt N RPARAN M statement
                        {

                            $$ = new Statement();
                            $6->toBool();
                            backpatch($6->trueList, $12);
                            backpatch($10->nextList, $5);
                            backpatch($13->nextList, $8);
                            emit("goto", toString($8));
                            $$->nextList = $6->falseList;
                        }
                    |WHILE M LPARAN expression RPARAN M statement
                         {

                         {
                             $$ = new Statement();


                             $4->toBool();


                             backpatch($4->trueList, $6);


                             $$->nextList = $4->falseList;


                             backpatch($7->nextList, $2);


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
                    | translation_unit temp_declaration

                    ;

temp_declaration:
                        function_definition
                        | declaration

                        ;

function_definition:
                    type_specifier declarator change_scope_definition BEG block_item_list_opt END
                        {

                            tableCount = 0;
                            if($2->type->type != SymbolType::VOID_T){
                                currentTable->lookupSymbol("return")->update($2->type);
                            }
                            $2->isFunction = true;
                            changeTable(globalTable);
                        }
                    ;

%%

void yyerror(string s) {
    printf("ERROR at line no. %d : %s\n", yylineno, s.c_str());
}



