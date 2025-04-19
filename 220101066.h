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
#include <set>
using namespace std;

class Symbol;
class SymbolType;
class SymbolTable;
class TAC;
class Array;
class Expression;
class Statement;

extern int yyparse();




class SymbolType {
public:
    // Base category (high-level classification)
    enum BaseCategory {
        PRIMITIVE,   // Basic data types
        COMPOSITE,   // Types composed of other types
        FUNCTIONAL,  // Function-related types
        SPECIAL      // Special purpose types
    };
    
    // Specific type (more detailed classification)
    enum SpecificType {
        // PRIMITIVE types
        INT_T,    // Integer type
        FLOAT_T,       // Floating-point type
        CHAR_T,  // Character type
        VOID_T,       // Void type
        
        // COMPOSITE types
        POINTER,        // Pointer type
        ARRAY,        // Array type
        
        // FUNCTIONAL types
        FUNCTION,       // Function type
        PARAMETER,      // Parameter type
        
        // SPECIAL types
        BLOCK         // Block type
    }type;
    
    BaseCategory baseCategory;
    SpecificType specificType;
    
    int width;
    SymbolType* arrayType;
    SymbolType* returnType;
    SymbolType* paramType;
    
    // Constructor takes specific type and derives the base category
    SymbolType(SpecificType type, SymbolType* _arrayType = NULL, int _width = 1);
    
    // Helper method to determine base category from specific type
    static BaseCategory deriveBaseCategory(SpecificType type);
    
    string toString();
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

        Symbol(string _name, SymbolType::SpecificType
 _type = SymbolType::INT_T, string _value = "");
        Symbol *update(SymbolType * _type);
        Symbol *convert(SymbolType::SpecificType
 _type);
};



class SymbolTable {
public:
    // New enum types
    enum TableScope {
        GLOBAL_SCOPE,
        FUNCTION_SCOPE,
        BLOCK_SCOPE,
        CLASS_SCOPE  // For future extension
    };

    enum TableStatus {
        ACTIVE,      // Currently in use
        INACTIVE,    // Not currently in scope
        COMPLETE     // Fully processed
    };


    string identifier;
    TableScope scope;
    TableStatus status;
    int nestingLevel;
    map<string, Symbol> entries;
    SymbolTable *parentTable;
    vector<SymbolTable*> childTables;

    SymbolTable(string _identifier = "NULL",
                TableScope _scope = GLOBAL_SCOPE,
                SymbolTable *_parent = NULL,
                int _nestingLevel = 0);


    Symbol *lookupSymbol(string name);
    Symbol *lookupLocalSymbol(string name);
    void resetFunctionEntries();
    void computeOffsets();
    void displayTable();


    void addChildTable(SymbolTable* child);
    SymbolTable* createChildTable(string identifier, TableScope scope);
    int getSymbolCount();
    bool hasSymbol(string name);
    void markComplete();
    string getCategoryString(Symbol::Category category);
    string formatFunctionSignature(const string& functionName);
};

class TAC{

    public:
        string result;
        string arg1;
        string op;
        string arg2;
        
        TAC(string _result, string _arg1, string _op = "=", string _arg2 = "");
        TAC(string _result, int _arg1, string _op = "=", string _arg2 = "");
        void print(int idx);
        bool isArithmeticOp(const string& op);
        bool isComparisonOp(const string& op);
        bool isBitwiseOp(const string& op);
};

class TACContainer {
private:
    vector<TAC*> TACs;
    int currentIndex;

public:
    TACContainer();
    void addTAC(TAC* TAC);
    TAC* getTAC(int index);
    int size() const;
    void optimize();
    vector<TAC*>::iterator begin();
    vector<TAC*>::iterator end();
};

extern TACContainer intermediateCode;
class Array
{
    public:
        Symbol *temp; 
        enum SpecificType

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
        enum SpecificType

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
Symbol *generateTemporary(SymbolType::SpecificType
, string = ""); 
void changeTable(SymbolTable *);

bool typeCheck(Symbol *&s1, Symbol *&s2);


string toString(int i);
string toString(char c);
string toString(float f);

//extern vector<TAC *> TACArray;
extern SymbolTable *currentTable, *globalTable;
extern Symbol *currentSymbol;
extern SymbolType::SpecificType currentType;
extern int tableCount, temporaryCount;

#endif