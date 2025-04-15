#ifndef TRANSLATOR_H
#define TRANSLATOR_H

#include <iostream>
#include <vector>
#include <map>
#include <list>
#include <iomanip>
#include <functional>
#include <string>
#include <string.h>

using namespace std;

class Symbol;
class SymbolType;
class SymbolTable;
class Quad;
class Array;
class Expression;
class Statement;

extern int yyparse();
extern int yydebug;
extern bool debug_on;

class SymbolType{
    public:
        enum typeEnum
            {
               FLOAT_T, VOID_T, CHAR_T, INT_T, POINTER, FUNCTION, ARRAY, BLOCK, PARAMETER
            } type;

        int width;

        SymbolType *arrayType;  // if the type is pointer/array, then arrayType contains the type of pointer/array

        SymbolType* returnType;

        SymbolType* paramType;

        SymbolType(typeEnum _type, SymbolType * _arrayType = NULL, int _width= 1);
        string toString(); // simply just convert the type to string
        int getSize();
};

class Symbol{
    public:
        string name;
        int size;
        int offset;
        SymbolType *type;
        SymbolTable *nestedTable;
        string initialValue;

        enum Category{
            LOCAL,
            GLOBAL,
            PARAMETER,
            TEMPORARY,
            FUNCTION
        } category ;

        bool isFunction;

        // SymbolType* parameters;

        Symbol(string _name, SymbolType::typeEnum _type = SymbolType::INT_T, string _value = "");
        Symbol *update(SymbolType * _type);
        Symbol *convert(SymbolType::typeEnum _type);
};

class SymbolTable{
    public:
        string name;
        map<string, Symbol> symbols;
        SymbolTable *parent;

        SymbolTable(string _name= "NULL", SymbolTable *_parent = NULL);
        Symbol *search(string);
        Symbol *search1(string);
        void setFunctionToZero();
        void calculateOffset();
        void print();
};

class Quad{

    public:
        string result;
        string arg1;
        string op;
        string arg2;
        
        Quad(string _result, string _arg1, string _op = "=", string _arg2 = "");
        Quad(string _result, int _arg1, string _op = "=", string _arg2 = "");
        void print(int idx);
};

class Array
{
    public:
        Symbol *temp; 
        enum typeEnum
        {
            OTHER,
            POINTER,
            ARRAY
        } type;                  
        Symbol *symbol;           
        SymbolType *subArrayType; 
        list<int> trueList, falseList, nextList;
};

class Expression
{
    public:
        Symbol *symbol;
        enum typeEnum
        {
            NONBOOLEAN,
            BOOLEAN
        } type;  
                                        
        list<int> trueList, falseList, nextList; 

        void toInt();  
        void toBool(); 
};

class Statement
{
    public:
        list<int> nextList; 
};

void emit(string _op, string _result, string _arg1 = "", string _arg2 = ""); 
void emit(string _op, string _result, int _arg1, string _arg2 = "");   

void backpatch(list<int> _list, int add);       
list<int> makeList(int i);              
list<int> merge(list<int>, list<int>); 

int nextInstruction();                              
Symbol *gentemp(SymbolType::typeEnum, string = ""); 
void changeTable(SymbolTable *);                    // changes the current symbol table to the given one

bool typeCheck(Symbol *&s1, Symbol *&s2);       //same type symbols


string toString(int i);
string toString(char c);
string toString(float f);

extern vector<Quad *> quadArray;
extern SymbolTable *currentTable, *globalTable;
extern Symbol *currentSymbol;
extern SymbolType::typeEnum currentType;
extern int tableCount, temporaryCount;

#endif