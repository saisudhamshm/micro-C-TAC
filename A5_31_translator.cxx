#include "A5_31_translator.h"
/**
 * @brief Global variables
 *
 * quadArray: vector of quads
 * currentTable, globalTable, parentTable : Symbol Tables
 * currentSmbol : pointer to current symbol
 * currentType : Data type of the current symbol
 * tableCount : total symbol tables
 * temporaryCount : temporary count
 */
vector<Quad *> quadArray;
SymbolTable *currentTable, *globalTable, *parentTable;
Symbol *currentSymbol;
SymbolType::typeEnum currentType;
int tableCount, temporaryCount;

/**
 * @brief Construct a new Symbol Type:: Symbol Type object
 *
 * @param type data type
 * @param arrayType type of the array
 * @param width width of array
 */
SymbolType::SymbolType(typeEnum type, SymbolType *arrayType, int width) : type(type), width(width), arrayType(arrayType) {}

/**
 * @brief function to get the size of Symbol type
 *
 * @return int
 */
int SymbolType::getSize()
{
    if(type == FUNCTION){
        cout<<"hi1\n";
    }
    if (type == CHAR_T)
        return 1;
    else if (type == INT_T || type == POINTER)
        return 4;
    else if (type == ARRAY)
        return width * (arrayType->getSize());
     else if (type == FLOAT_T)
             return 8;

    else
        return 0;
    return 0;
}

/**
 * @brief function to get the symbol type in string format
 *
 * @return string
 */
string SymbolType::toString()
{
    if (type == SymbolType::VOID_T)
        return "void";
    else if (type == SymbolType::CHAR_T)
        return "char";
    else if (type == SymbolType::INT_T)
        return "int";
    else if (type == SymbolType::POINTER)
        return "ptr(" + arrayType->toString() + ")";
    else if (type == SymbolType::FUNCTION)
        return "function";
    else if (type == SymbolType::FLOAT_T)
            return "float";

    else if (type == SymbolType::ARRAY)
        return "array(" + to_string(width) + ", " + arrayType->toString() + ")";
    else if (type == SymbolType::BLOCK)
        return "block";
    return "";
}
string toString(float f)
{
    return to_string(f);
}
/**
 * @brief Construct a new Symbol Table:: Symbol Table object
 *
 * @param name name of symbol type
 * @param parent parent of symbol type
 */
SymbolTable::SymbolTable(string name, SymbolTable *parent) : name(name), parent(parent) {}

/**
 * TODO:
 * @brief function to look for the symbol in the symbol table
 *
 * @param name name of the symbol
 * @return Symbol*
 */
Symbol *SymbolTable::search(string name)
{
    // if symbol already present
    if(symbols.find(name) != symbols.end()){
        auto it1 = symbols.find(name);
        return &(it1->second);
    }

    Symbol *ret_ptr = nullptr;

    // recursively check if the symbol is present in it's parent symbol table
    if (parent != NULL)
        ret_ptr = parent->search(name);

    // if not declared in any symbol table, then insert it as a new symbol
    if (this == currentTable && !ret_ptr)
    {
        ret_ptr = new Symbol(name);
        ret_ptr->category = Symbol::LOCAL;
        if(currentTable == globalTable){
            ret_ptr->category = Symbol::GLOBAL;
        }
        symbols.insert({name, *ret_ptr});
        return &(symbols.find(name)->second);
    }
    return ret_ptr;
}

Symbol *SymbolTable::search1(string name)
{
    
    if( symbols.find(name) != symbols.end() ){
        auto it1 = symbols.find(name);
        return &(it1->second);
    }

    // Symbol *ret_ptr = nullptr;

    // as for declaration no need to search the parent table
    
    symbols.insert({name, *(new Symbol(name))});
    return &(symbols.find(name)->second);
    // return ret_ptr;
}


/**
 * @brief function to update the offset of symbols in the symbol table
 *
 */
void SymbolTable::calculateOffset()
{
    int offset;
    vector<SymbolTable *> nestedTables;
    // traversing over the symbol table
    for(auto &x: symbols){
        
        if(x.first == symbols.begin()->first){
            x.second.offset = 0;
            if(x.second.category != Symbol::FUNCTION)
                offset = x.second.size;
            else{
                // x.second.type->type = SymbolType::FUNCTION;
                x.second.size = 0;
                offset = 0;
            }
        }else{
            x.second.offset = offset;
            if(x.second.category != Symbol::FUNCTION)
                offset += x.second.size;
            else{
                // x.second.type->type = SymbolType::FUNCTION;
                x.second.size = 0;
            }
        }
        if(x.second.nestedTable){
            nestedTables.push_back(x.second.nestedTable);
        }
    }

    for (auto &table : nestedTables)
    {
        table->calculateOffset();
    }
}

/**
 * @brief function to print the symbol table
 *
 */
void SymbolTable::print()
{
    cout << string(140, '-') << endl;
    cout << "Symbol Table Name: " << setw(100)<< name << "Parent Name: " << ((parent) ? parent->name : "None") << endl;
    cout << string(140, '-') << endl;
    cout << setw(20) << "Name" << setw(40) << "Type" <<setw(20)<<"Category"<< setw(20) << "Initial Value" << setw(20) << "Offset" << setw(20) << "Size" << setw(20) << "Nested Table"
         << "\n\n";
    
    // to store tables which are called in this currentTable
    vector<SymbolTable *> tovisit;

    // traversing the currentSymbolTable
    for (auto &x : symbols)
    {
        cout << setw(20) << x.first;            // printing the name of the symbol
        fflush(stdout);

        if(x.second.category != Symbol::FUNCTION)
            cout<<setw(40)<<x.second.type->toString();
        else{
            string tempstr = "(";
            // cout<<setw(40)<<x.second.type->toString();
            SymbolTable* temp = globalTable->search(x.first)->nestedTable;
            // cout<<"( ";
            bool chk1=false;;
            vector<string> vs1;
            for(auto y : temp->symbols){
                if(y.second.category == Symbol::PARAMETER){
                    // tempstr += y.second.type->toString();
                    vs1.push_back(y.second.type->toString());
                    // tempstr += " x "; 
                }
            }

            for(int i=0;i<vs1.size();i++){
                tempstr += vs1[i];
                if(i!=(vs1.size()-1)){
                    tempstr += " x ";
                }
            }
            tempstr+=") --> ("+ x.second.type->toString()+")";
            if(vs1.size()){
                chk1=true;
                cout<<setw(40)<<tempstr;
            }else{
                cout<<setw(40)<<x.second.type->toString();
            }
        }

        cout<<setw(20);
        if(x.second.category == Symbol::LOCAL){
            cout<<"local";
        }else if(x.second.category == Symbol::GLOBAL){
            cout<<"global";
        }else if(x.second.category == Symbol::FUNCTION){
            cout<<"function";
        }else if(x.second.category == Symbol::PARAMETER){
            cout<<"parameter";
        }else if(x.second.category == Symbol::TEMPORARY){
            cout<<"temporary";
        }

        cout << setw(20) << x.second.initialValue << setw(20) << x.second.offset << setw(20) << x.second.size;
        cout << setw(20) << (x.second.nestedTable ? x.second.nestedTable->name : "NULL") << endl;
        if (x.second.nestedTable)
        {
            tovisit.push_back(x.second.nestedTable);
        }
    }
    cout << string(140, '-') << endl;
    cout <<"\n\n";

    // recursively print all symbol tables
    for (auto &table : tovisit)
    {
        table->print();
    }
}

/**
 * @brief Constructor for Symbol Class
 *
 * @param name Name of Symbol
 * @param type symbol type
 * @param init initial value
 */
Symbol::Symbol(string name, SymbolType::typeEnum type, string init) : name(name), type(new SymbolType(type)), offset(0), nestedTable(NULL), initialValue(init), isFunction(false)
{
    size = this->type->getSize();
}
/**
 * @brief function to update the type of symbol
 *
 * @param type type of the symbol
 * @return Symbol*
 */
Symbol *Symbol::update(SymbolType *type)
{
    this->type = type;
    size = this->type->getSize();
    return this;
}
/**
 * @brief function to convert the type of the symbol
 *
 * @param targetType new type of symbol
 * @return Symbol*
 */
Symbol *Symbol::convert(SymbolType::typeEnum targetType)
{
    if ((type)->type == SymbolType::INT_T && targetType == SymbolType::CHAR_T)
    {
        Symbol *fin_ = gentemp(targetType);
        emit("=", fin_->name, "INT_TO_CHAR(" + name + ")");
        return fin_;
    }
    else if ((type)->type == SymbolType::CHAR_T && targetType == SymbolType::INT_T)
    {
        Symbol *fin_ = gentemp(targetType);
        emit("=", fin_->name, "CHAR_TO_INT(" + name + ")");
        return fin_;
    }
    return this;
}

/**
 * @brief Construct a new Quad:: Quad object
 *
 * @param result result
 * @param arg1 argument 1
 * @param op operator
 * @param arg2 argument 2
 */
Quad::Quad(string result, string arg1, string op, string arg2) : result(result), op(op), arg1(arg1), arg2(arg2) {}
/**
 * @brief Construct a new Quad:: Quad object
 *
 * @param result result
 * @param arg1 integer passed as argument 1
 * @param op operator
 * @param arg2 argument 2
 */
Quad::Quad(string result, int arg1, string op, string arg2) : result(result), op(op), arg1(toString(arg1)), arg2(arg2) {}


/**
 * @brief function to print the quadruple
 *
 */
void Quad::print(int idx)
{

    cout<<setw(20)<<op<<setw(20)<<arg1<<setw(20)<<arg2<<setw(20)<<result<<setw(20)<<idx;

    if (op == "=")
    {
        cout << "\t" << result << " = " << arg1 << endl;
    }
    else if (op == "goto")
    {
        cout << "\tgoto " << result << endl;
    }
    else if (op == "return")
    {
        cout << "\treturn " << result << endl;
    }
    else if (op == "call")
    {
        cout << "\t" << result << " = call " << arg1 << ", " << arg2 << endl;
    }
    else if (op == "param")
    {
        cout << "\t" << "param " << result << endl;
    }
    else if (op == "label")
    {
        cout << result << endl;
    }
    else if (op == "=[]")
    {
        cout << "\t" << result << " = " << arg1 << "[" << arg2 << "]" << endl;
    }
    else if (op == "[]=")
    {
        cout << "\t" << result << "[" << arg1 << "] = " << arg2 << endl;
    }
    else if (op == "+" or op == "-" or op == "*" or op == "/" or op == "%" or op == "<<" or op == ">>")
    {
        cout << "\t" << result << " = " << arg1 << " " << op << " " << arg2 << endl;
    }
    else if (op == "==" or op == "!=" or op == "<" or op == ">" or op == "<=" or op == ">=")
    {
        cout << "\tif " << arg1 << " " << op << " " << arg2 << " goto " << result << endl;
    }
    else if (op == "=&" or op == "=*")
    {
        cout << "\t" << result << " " << op[0] << " " << op[1] << arg1 << endl;
    }
    else if (op == "*=")
    {
        cout << "\t*" << result << " = " << arg1 << endl;
    }
    else if (op == "=-")
    {
        cout << "\t" << result << " = - " << arg1 << endl;
    }
    else if (op == "!")
    {
        cout << "\t" << result << " = ! " << arg1 << endl;
    }
    else
    {
        cout << op << arg1 << arg2 << result << endl;
        cout << "INVALID OPERATOR\n";
    }
}

/**
 * @brief function to create a new quadruple and store it in the quad array
 *
 * @param op operator
 * @param result result
 * @param arg1 argument 1
 * @param arg2 argument 2
 */
void emit(string op, string result, string arg1, string arg2)
{
    Quad *q = new Quad(result, arg1, op, arg2);
    quadArray.push_back(q);
}

/**
 * @brief function to create a mew quadruple and store it in the quad array if first argument is passed as integer
 *
 * @param op operator
 * @param result result
 * @param arg1 argument 1 (integer)
 * @param arg2 argument 2
 */
void emit(string op, string result, int arg1, string arg2)
{
    Quad *q = new Quad(result, arg1, op, arg2);
    quadArray.push_back(q);
}

/**
 * @brief function to backpatch the list with addr
 *
 * @param list_ list
 * @param addr address
 */
void backpatch(list<int> list_, int addr)
{
    for (auto &i : list_)
    {
        quadArray[i - 1]->result = toString(addr);
    }
}

/**
 * @brief function to create a new list with base as the only element
 *
 * @param base
 * @return list<int>
 */
list<int> makeList(int base)
{
    list<int> buff;
    buff.push_back(base);
    return buff;
}

/**
 * @brief function to merge two lists
 *
 * @param first first list
 * @param second second list
 * @return list<int>
 */
list<int> merge(list<int> first, list<int> second)
{
    list<int> ret = first;
    ret.merge(second);
    return ret;
}

/**
 * @brief function to return the expression value as integer value
 *
 */
void Expression::toInt()
{
    if (type == Expression::typeEnum::BOOLEAN)
    {
        symbol = gentemp(SymbolType::typeEnum::INT_T);
        backpatch(trueList, nextInstruction());
        emit("=", symbol->name, "true");
        emit("goto", toString(nextInstruction()+1));
        backpatch(falseList, nextInstruction());
        emit("=", symbol->name, "false");
    }
}

/**
 * @brief function to return the expression value as boolean value
 *
 */
void Expression::toBool()
{
    if (type == Expression::typeEnum::NONBOOLEAN)
    {
        falseList = makeList(nextInstruction());
        emit("==", "", symbol->name, "0");
        trueList = makeList(nextInstruction());
        emit("goto", "");
    }
}

/**
 * @brief function to get the next instruction number
 *
 * @return int
 */
int nextInstruction()
{
    return quadArray.size() + 1;
}

/**
 * @brief function to generate new temp variable and insert in the symbol table
 *
 * @param type symbol type
 * @param initialValue
 * @return Symbol*
 */
Symbol *gentemp(SymbolType::typeEnum type, string intialValue)
{
    Symbol *temp = new Symbol("t" + toString(temporaryCount++), type, intialValue);
    temp->category = Symbol::TEMPORARY;
    currentTable->symbols.insert({temp->name, *temp});
    return temp;
}

/**
 * @brief function to change the current table
 *
 * @param table new current table
 */
void changeTable(SymbolTable *table)
{
    currentTable = table;
}


bool type_comp(SymbolType* first,SymbolType* second){
    if(!first and !second){
        return true;
    }else if(!first or !second or first->type != second->type){
        return false;
    }else{
        return type_comp(first->arrayType, second->arrayType);
    }
}


/**
 * @brief function to check whether two symbols have same type
 *
 * @param a first symbol
 * @param b second symbol
 * @return true
 * @return false
 */
bool typeCheck(Symbol *&a, Symbol *&b)
{
    if (type_comp(a->type, b->type))
        return true;
    else if (a->type->type == SymbolType::INT_T or b->type->type == SymbolType::INT_T)
    {
        a = a->convert(SymbolType::INT_T);
        b = b->convert(SymbolType::INT_T);
        return true;
    }
    else
    {
        return false;
    }
}


/**
 * @brief function to convert int to string
 *
 * @param i
 * @return string
 */
string toString(int i)
{
    return to_string(i);
}


/**
 * @brief function to convert char to string
 *
 * @param c
 * @return string
 */
string toString(char c)
{
    return string(1, c);
}

/**
 * @brief main function
 *
 * @return int
 */
int main()
{
    // initializing tablecount and tempCount
    tableCount = 0;             
    temporaryCount = 0;
    globalTable = new SymbolTable("global");

    currentTable = globalTable;
    
    cout << left;
    // bool debug_on;
    // debug_on = 1;

    // yydebug = 1;

    yyparse();      // calling the parser

    // globalTable->setFunctionToZero();

    globalTable->calculateOffset();
    globalTable->print();

    // Printing the Quads Array
    int idx = 1;

    cout << string(140, '=') << endl;
    cout << string(30,' ') << "Quad Array" << endl;
    cout << string(140, '=') << endl;

    cout<<setw(20)<<"Op"<<setw(20)<<"arg1"<<setw(20)<<"arg2"<<setw(20)<<"result"<<setw(20)<<"Index"<<setw(20)<<"Code in text\n";
    cout<<setw(0) << string(140, '-') << endl;   

    for (auto it : quadArray)
    {
        // cout << setw(4) << ins++ << ": ";
        cout<<setw(20);
        it->print(idx++);
    }
    return 0;
}