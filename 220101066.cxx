#include "220101066.h"
vector<Quad *> quadArray;
SymbolTable *currentTable, *globalTable, *parentTable;
Symbol *currentSymbol;
SymbolType::SpecificType currentType;
int tableCount, temporaryCount;


SymbolType::SymbolType(SpecificType type, SymbolType* _arrayType, int _width) : 
    specificType(type), 
    baseCategory(deriveBaseCategory(type)), 
    width(_width), 
    arrayType(_arrayType) {}

SymbolType::BaseCategory SymbolType::deriveBaseCategory(SpecificType type) {
    switch(type) {
        case INT_T:
        case FLOAT_T:
        case CHAR_T:
        case VOID_T:
            return PRIMITIVE;
            
        case POINTER:
        case ARRAY:
            return COMPOSITE;
            
        case FUNCTION:
        case PARAMETER:
            return FUNCTIONAL;
            
        case BLOCK:
            return SPECIAL;
            
        default:
            return SPECIAL; // Default case
    }
}

int SymbolType::getSize() {
    if(specificType == FUNCTION) {
        cout<<"nah man\n";
    }

    switch(specificType) {
        case CHAR_T:
            return 1;
        case INT_T:
        case POINTER:
            return 4;
        case ARRAY:
            return width * (arrayType->getSize());
        case FLOAT_T:
            return 8;
        default:
            return 0;
    }
}



string SymbolType::toString() {
    switch(specificType) {
        case VOID_T:
            return "void";
        case CHAR_T:
            return "char";
        case INT_T:
            return "int";
        case POINTER:
            return "ptr(" + arrayType->toString() + ")";
        case FUNCTION:
            return "function";
        case FLOAT_T:
            return "float";
        case ARRAY:
            return "array(" + to_string(width) + ", " + arrayType->toString() + ")";
        case BLOCK:
            return "block";
        default:
            return "";
    }
}

string toString(float f)
{

return to_string(f);
}

// SymbolTable::SymbolTable(string name, SymbolTable *parent) : name(name), parent(parent) {}
//
//
// Symbol *SymbolTable::search(string name)
// {
//     // if symbol already present
//     if(symbols.find(name) != symbols.end()){
//         auto it1 = symbols.find(name);
//         return &(it1->second);
//     }
//
//     Symbol *ret_ptr = nullptr;
//
//     // recursively check if the symbol is present in it's parent symbol table
//     if (parent != NULL)
//         ret_ptr = parent->search(name);
//
//     // if not declared in any symbol table, then insert it as a new symbol
//     if (this == currentTable && !ret_ptr)
//     {
//         ret_ptr = new Symbol(name);
//         ret_ptr->category = Symbol::LOCAL;
//         if(currentTable == globalTable){
//             ret_ptr->category = Symbol::GLOBAL;
//         }
//         symbols.insert({name, *ret_ptr});
//         return &(symbols.find(name)->second);
//     }
//     return ret_ptr;
// }
//
// Symbol *SymbolTable::search1(string name)
// {
//
//     if( symbols.find(name) != symbols.end() ){
//         auto it1 = symbols.find(name);
//         return &(it1->second);
//     }
//
//     // Symbol *ret_ptr = nullptr;
//
//     // as for declaration no need to search the parent table
//
//     symbols.insert({name, *(new Symbol(name))});
//     return &(symbols.find(name)->second);
//     // return ret_ptr;
// }
//
//
//
// void SymbolTable::calculateOffset()
// {
//     int offset;
//     vector<SymbolTable *> nestedTables;
//     // traversing over the symbol table
//     for(auto &x: symbols){
//
//         if(x.first == symbols.begin()->first){
//             x.second.offset = 0;
//             if(x.second.category != Symbol::FUNCTION)
//                 offset = x.second.size;
//             else{
//                 // x.second.type->type = SymbolType::FUNCTION;
//                 x.second.size = 0;
//                 offset = 0;
//             }
//         }else{
//             x.second.offset = offset;
//             if(x.second.category != Symbol::FUNCTION)
//                 offset += x.second.size;
//             else{
//                 // x.second.type->type = SymbolType::FUNCTION;
//                 x.second.size = 0;
//             }
//         }
//         if(x.second.nestedTable){
//             nestedTables.push_back(x.second.nestedTable);
//         }
//     }
//
//     for (auto &table : nestedTables)
//     {
//         table->calculateOffset();
//     }
// }
//
//
// void SymbolTable::print()
// {
//     cout << string(140, '-') << endl;
//     cout << "Symbol Table Name: " << setw(100)<< name << "Parent Name: " << ((parent) ? parent->name : "None") << endl;
//     cout << string(140, '-') << endl;
//     cout << setw(20) << "Name" << setw(40) << "Type" <<setw(20)<<"Category"<< setw(20) << "Initial Value" << setw(20) << "Offset" << setw(20) << "Size" << setw(20) << "Nested Table"
//          << "\n\n";
//
//     // to store tables which are called in this currentTable
//     vector<SymbolTable *> tovisit;
//
//     // traversing the currentSymbolTable
//     for (auto &x : symbols)
//     {
//         cout << setw(20) << x.first;            // printing the name of the symbol
//         fflush(stdout);
//
//         if(x.second.category != Symbol::FUNCTION)
//             cout<<setw(40)<<x.second.type->toString();
//         else{
//             string tempstr = "(";
//             // cout<<setw(40)<<x.second.type->toString();
//             SymbolTable* temp = globalTable->search(x.first)->nestedTable;
//             // cout<<"( ";
//             bool chk1=false;;
//             vector<string> vs1;
//             for(auto y : temp->symbols){
//                 if(y.second.category == Symbol::PARAMETER){
//                     // tempstr += y.second.type->toString();
//                     vs1.push_back(y.second.type->toString());
//                     // tempstr += " x ";
//                 }
//             }
//
//             for(int i=0;i<vs1.size();i++){
//                 tempstr += vs1[i];
//                 if(i!=(vs1.size()-1)){
//                     tempstr += " x ";
//                 }
//             }
//             tempstr+=") --> ("+ x.second.type->toString()+")";
//             if(vs1.size()){
//                 chk1=true;
//                 cout<<setw(40)<<tempstr;
//             }else{
//                 cout<<setw(40)<<x.second.type->toString();
//             }
//         }
//
//         cout<<setw(20);
//         if(x.second.category == Symbol::LOCAL){
//             cout<<"local";
//         }else if(x.second.category == Symbol::GLOBAL){
//             cout<<"global";
//         }else if(x.second.category == Symbol::FUNCTION){
//             cout<<"function";
//         }else if(x.second.category == Symbol::PARAMETER){
//             cout<<"parameter";
//         }else if(x.second.category == Symbol::TEMPORARY){
//             cout<<"temporary";
//         }
//
//         cout << setw(20) << x.second.initialValue << setw(20) << x.second.offset << setw(20) << x.second.size;
//         cout << setw(20) << (x.second.nestedTable ? x.second.nestedTable->name : "NULL") << endl;
//         if (x.second.nestedTable)
//         {
//             tovisit.push_back(x.second.nestedTable);
//         }
//     }
//     cout << string(140, '-') << endl;
//     cout <<"\n\n";
//
//     // recursively print all symbol tables
//     for (auto &table : tovisit)
//     {
//         table->print();
//     }
// }
// Update constructor
SymbolTable::SymbolTable(string _identifier, TableScope _scope, SymbolTable *_parent, int _nestingLevel) :
    identifier(_identifier),
    scope(_scope),
    status(ACTIVE),
    nestingLevel(_nestingLevel),
    parentTable(_parent) {}

// Update lookupSymbol method (was search)
Symbol *SymbolTable::lookupSymbol(string name) {
    // If symbol already present in current table
    if(entries.find(name) != entries.end()) {
        auto it = entries.find(name);
        return &(it->second);
    }

    Symbol *foundSymbol = nullptr;

    // Recursively check if the symbol is present in parent symbol tables
    if (parentTable != NULL)
        foundSymbol = parentTable->lookupSymbol(name);

    // If not found and we're in the current active table, create new symbol
    if (this == currentTable && !foundSymbol) {
        foundSymbol = new Symbol(name);
        foundSymbol->category = (scope == GLOBAL_SCOPE) ? Symbol::GLOBAL : Symbol::LOCAL;
        entries.insert({name, *foundSymbol});
        return &(entries.find(name)->second);
    }
    return foundSymbol;
}

// Update lookupLocalSymbol method (was search1)
Symbol *SymbolTable::lookupLocalSymbol(string name) {
    // Only check the current table, don't recurse to parent
    if(entries.find(name) != entries.end()) {
        auto it = entries.find(name);
        return &(it->second);
    }

    // Create new symbol in this table
    entries.insert({name, *(new Symbol(name))});
    return &(entries.find(name)->second);
}

// Update computeOffsets method (was calculateOffset)
void SymbolTable::computeOffsets() {
    int currentOffset = 0;

    // Traverse entries in the symbol table
    for(auto &entry : entries) {
        Symbol &symbol = entry.second;

        // First symbol starts at offset 0
        if(entry.first == entries.begin()->first) {
            symbol.offset = 0;
            if(symbol.category != Symbol::FUNCTION)
                currentOffset = symbol.size;
            else {
                symbol.size = 0;
                currentOffset = 0;
            }
        } else {
            symbol.offset = currentOffset;
            if(symbol.category != Symbol::FUNCTION)
                currentOffset += symbol.size;
            else {
                symbol.size = 0;
            }
        }

        // Process nested table if any
        if(symbol.nestedTable) {
            symbol.nestedTable->computeOffsets();
        }
    }

    // Process all child tables
    for(auto &childTable : childTables) {
        if(childTable) {
            childTable->computeOffsets();
        }
    }
}

// Update resetFunctionEntries method (was setFunctionToZero)
void SymbolTable::resetFunctionEntries() {
    // Implementation depends on your original code
    // Generally resets function parameters/variables
}

// Update displayTable method (was print)
void SymbolTable::displayTable() {
    cout << string(140, '-') << endl;
       cout << "Symbol Table Name: " << setw(100)<< identifier << "Parent Name: " << ((parentTable) ? parentTable->identifier : "None") << endl;
       cout << string(140, '-') << endl;
       cout << setw(20) << "Name" << setw(40) << "Type" <<setw(20)<<"Category"<< setw(20) << "Initial Value" << setw(20) << "Offset" << setw(20) << "Size" << setw(20) << "Nested Table"
            << "\n\n";

       // to store tables which are called in this currentTable
       vector<SymbolTable *> tovisit;

       // traversing the currentSymbolTable
       for (auto &x : entries)
       {
           cout << setw(20) << x.first;            // printing the name of the symbol
           fflush(stdout);

           if(x.second.category != Symbol::FUNCTION)
               cout<<setw(40)<<x.second.type->toString();
           else{
               string tempstr = "(";
               // cout<<setw(40)<<x.second.type->toString();
               SymbolTable* temp = globalTable->lookupSymbol(x.first)->nestedTable;
               // cout<<"( ";
               bool chk1=false;;
               vector<string> vs1;
               for(auto y : temp->entries){
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
           cout << setw(20) << (x.second.nestedTable ? x.second.nestedTable->identifier : "NULL") << endl;
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
           table->displayTable();
       }
}

// Add new methods
void SymbolTable::addChildTable(SymbolTable* child) {
    childTables.push_back(child);
    child->parentTable = this;
    child->nestingLevel = this->nestingLevel + 1;
}

SymbolTable* SymbolTable::createChildTable(string identifier, TableScope scope) {
    SymbolTable* child = new SymbolTable(identifier, scope, this, this->nestingLevel + 1);
    childTables.push_back(child);
    return child;
}

void SymbolTable::markComplete() {
    this->status = COMPLETE;
}

bool SymbolTable::hasSymbol(string name) {
    return entries.find(name) != entries.end();
}

int SymbolTable::getSymbolCount() {
    return entries.size();
}

Symbol::Symbol(string name, SymbolType::SpecificType type, string init) : name(name), type(new SymbolType(type)), offset(0), nestedTable(NULL), initialValue(init), isFunction(false)
{
    size = this->type->getSize();
}

Symbol *Symbol::update(SymbolType *type)
{
    this->type = type;
    size = this->type->getSize();
    return this;
}

Symbol *Symbol::convert(SymbolType::SpecificType targetType)
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


Quad::Quad(string result, string arg1, string op, string arg2) : result(result), op(op), arg1(arg1), arg2(arg2) {}

Quad::Quad(string result, int arg1, string op, string arg2) : result(result), op(op), arg1(toString(arg1)), arg2(arg2) {}



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
    else if (op == "&" or op == "|" or op == "^")
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


void emit(string op, string result, string arg1, string arg2)
{
    Quad *q = new Quad(result, arg1, op, arg2);
    quadArray.push_back(q);
}


void emit(string op, string result, int arg1, string arg2)
{
    Quad *q = new Quad(result, arg1, op, arg2);
    quadArray.push_back(q);
}


void backpatch(list<int> list_, int addr)
{
    for (auto &i : list_)
    {
        quadArray[i - 1]->result = toString(addr);
    }
}


list<int> makeList(int base)
{
    list<int> buff;
    buff.push_back(base);
    return buff;
}


list<int> merge(list<int> first, list<int> second)
{
    list<int> ret = first;
    ret.merge(second);
    return ret;
}


void Expression::toInt()
{
    if (type == Expression::SpecificType::BOOLEAN)
    {
        symbol = gentemp(SymbolType::SpecificType::INT_T);
        backpatch(trueList, nextInstruction());
        emit("=", symbol->name, "true");
        emit("goto", toString(nextInstruction()+1));
        backpatch(falseList, nextInstruction());
        emit("=", symbol->name, "false");
    }
}


void Expression::toBool()
{
    if (type == Expression::SpecificType::NONBOOLEAN)
    {
        falseList = makeList(nextInstruction());
        emit("==", "", symbol->name, "0");
        trueList = makeList(nextInstruction());
        emit("goto", "");
    }
}


int nextInstruction()
{
    return quadArray.size() + 1;
}


Symbol *gentemp(SymbolType::SpecificType type, string intialValue)
{
    Symbol *temp = new Symbol("t" + toString(temporaryCount++), type, intialValue);
    temp->category = Symbol::TEMPORARY;
    currentTable->entries.insert({temp->name, *temp});
    return temp;
}


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



string toString(int i)
{
    return to_string(i);
}



string toString(char c)
{
    return string(1, c);
}


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

    globalTable->computeOffsets();
    globalTable->displayTable();

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