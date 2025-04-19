#include "220101066.h"
vector<TAC *> TACArray;
SymbolTable *currentTable, *globalTable, *parentTable;
Symbol *currentSymbol;
SymbolType::SpecificType currentType;
int tableCount, temporaryCount;


TACContainer intermediateCode;

TACContainer::TACContainer() : currentIndex(0) {}

void TACContainer::addTAC(TAC* TAC) {
    TACs.push_back(TAC);
}

TAC* TACContainer::getTAC(int index) {
    if (index >= 0 && index < TACs.size()) {
        return TACs[index];
    }
    return nullptr;
}

int TACContainer::size() const {
    return TACs.size();
}

void TACContainer::optimize() {
    // You can implement optimization logic here
    // like removing redundant TACs, etc.
}

vector<TAC*>::iterator TACContainer::begin() {
    return TACs.begin();
}

vector<TAC*>::iterator TACContainer::end() {
    return TACs.end();
}


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


SymbolTable::SymbolTable(string _identifier, TableScope _scope, SymbolTable *_parent, int _nestingLevel) :
    identifier(_identifier),
    scope(_scope),
    status(ACTIVE),
    nestingLevel(_nestingLevel),
    parentTable(_parent) {}


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



void SymbolTable::displayTable() {
    const int LINE_WIDTH = 140;
    const int NAME_COL_WIDTH = 20;
    const int TYPE_COL_WIDTH = 40;
    const int CATEGORY_COL_WIDTH = 20;
    const int VALUE_COL_WIDTH = 20;
    const int OFFSET_COL_WIDTH = 20;
    const int SIZE_COL_WIDTH = 20;
    const int NESTED_COL_WIDTH = 20;

    // Print table header
    cout << string(LINE_WIDTH, '-') << endl;
    cout << "Symbol Table Name: " << setw(100) << identifier
         << "Parent Name: " << ((parentTable) ? parentTable->identifier : "None") << endl;
    cout << string(LINE_WIDTH, '-') << endl;

    // Print column headers
    cout << setw(NAME_COL_WIDTH) << "Name"
         << setw(TYPE_COL_WIDTH) << "Type"
         << setw(CATEGORY_COL_WIDTH) << "Category"
         << setw(VALUE_COL_WIDTH) << "Initial Value"
         << setw(OFFSET_COL_WIDTH) << "Offset"
         << setw(SIZE_COL_WIDTH) << "Size"
         << setw(NESTED_COL_WIDTH) << "Nested Table"
         << "\n\n";

    // Collection for nested tables to visit later
    vector<SymbolTable*> nestedTablesToVisit;

    // Print entries in current table
    for (const auto& [symbolName, symbolData] : entries) {
        // Print symbol name
        cout << setw(NAME_COL_WIDTH) << symbolName;
        fflush(stdout);

        // Print type information
        if (symbolData.category != Symbol::FUNCTION) {
            cout << setw(TYPE_COL_WIDTH) << symbolData.type->toString();
        } else {
            string functionSignature = formatFunctionSignature(symbolName);
            cout << setw(TYPE_COL_WIDTH) << functionSignature;
        }

        // Print category
        cout << setw(CATEGORY_COL_WIDTH) << getCategoryString(symbolData.category);

        // Print remaining symbol information
        cout << setw(VALUE_COL_WIDTH) << symbolData.initialValue
             << setw(OFFSET_COL_WIDTH) << symbolData.offset
             << setw(SIZE_COL_WIDTH) << symbolData.size
             << setw(NESTED_COL_WIDTH) << (symbolData.nestedTable ? symbolData.nestedTable->identifier : "NULL")
             << endl;

        // Add nested table to visit list if exists
        if (symbolData.nestedTable) {
            nestedTablesToVisit.push_back(symbolData.nestedTable);
        }
    }

    cout << string(LINE_WIDTH, '-') << endl;
    cout << "\n\n";

    // Recursively display nested tables
    for (const auto& nestedTable : nestedTablesToVisit) {
        nestedTable->displayTable();
    }
}

// Helper function to format function signatures
string SymbolTable::formatFunctionSignature(const string& functionName) {
    SymbolTable* paramTable = globalTable->lookupSymbol(functionName)->nestedTable;
    if (!paramTable) {
        return functionName;
    }

    // Collect parameter types
    vector<string> paramTypes;
    for (const auto& [_, paramData] : paramTable->entries) {
        if (paramData.category == Symbol::PARAMETER) {
            paramTypes.push_back(paramData.type->toString());
        }
    }

    // No parameters
    if (paramTypes.empty()) {
        return lookupSymbol(functionName)->type->toString();
    }

    // Format: (param1 x param2 x ...) --> (returnType)
    string signature = "(";
    for (size_t i = 0; i < paramTypes.size(); ++i) {
        signature += paramTypes[i];
        if (i < paramTypes.size() - 1) {
            signature += " x ";
        }
    }
    signature += ") --> (";
    signature += lookupSymbol(functionName)->type->toString();
    signature += ")";

    return signature;
}

// Helper function to convert category enum to string
string SymbolTable::getCategoryString(Symbol::Category category) {
    switch (category) {
        case Symbol::LOCAL:     return "local";
        case Symbol::GLOBAL:    return "global";
        case Symbol::FUNCTION:  return "function";
        case Symbol::PARAMETER: return "parameter";
        case Symbol::TEMPORARY: return "temporary";
        default:                return "unknown";
    }
}


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
        Symbol *fin_ = generateTemporary(targetType);
        emit("=", fin_->name, "INT_TO_CHAR(" + name + ")");
        return fin_;
    }
    else if ((type)->type == SymbolType::CHAR_T && targetType == SymbolType::INT_T)
    {
        Symbol *fin_ = generateTemporary(targetType);
        emit("=", fin_->name, "CHAR_TO_INT(" + name + ")");
        return fin_;
    }
    return this;
}


TAC::TAC(string result, string arg1, string op, string arg2) : result(result), op(op), arg1(arg1), arg2(arg2) {}

TAC::TAC(string result, int arg1, string op, string arg2) : result(result), op(op), arg1(toString(arg1)), arg2(arg2) {}



void TAC::print(int idx) {
    // Print the raw TAC information with consistent spacing
    cout << setw(20) << op << setw(20) << arg1 << setw(20)
         << arg2 << setw(20) << result << setw(20) << idx;

    // Format and print human-readable representation based on operation type
    if (op == "=") {
        cout << "\t" << result << " = " << arg1 << endl;
    } else if (op == "goto") {
        cout << "\tgoto " << result << endl;
    } else if (op == "return") {
        cout << "\treturn " << result << endl;
    } else if (op == "call") {
        cout << "\t" << result << " = call " << arg1 << ", " << arg2 << endl;
    } else if (op == "param") {
        cout << "\tparam " << result << endl;
    } else if (op == "label") {
        cout << result << endl;
    } else if (op == "=[]") {
        cout << "\t" << result << " = " << arg1 << "[" << arg2 << "]" << endl;
    } else if (op == "[]=") {
        cout << "\t" << result << "[" << arg1 << "] = " << arg2 << endl;
    } else if (isArithmeticOp(op)) {
        cout << "\t" << result << " = " << arg1 << " " << op << " " << arg2 << endl;
    } else if (isBitwiseOp(op)) {
        cout << "\t" << result << " = " << arg1 << " " << op << " " << arg2 << endl;
    } else if (isComparisonOp(op)) {
        cout << "\tif " << arg1 << " " << op << " " << arg2 << " goto " << result << endl;
    } else if (op == "=&" || op == "=*") {
        cout << "\t" << result << " " << op[0] << " " << op[1] << arg1 << endl;
    } else if (op == "*=") {
        cout << "\t*" << result << " = " << arg1 << endl;
    } else if (op == "=-") {
        cout << "\t" << result << " = - " << arg1 << endl;
    } else if (op == "!") {
        cout << "\t" << result << " = ! " << arg1 << endl;
    } else {
        cout << op << arg1 << arg2 << result << endl;
        cout << "INVALID OPERATOR\n";
    }
}

// Helper methods to categorize operators
bool TAC::isArithmeticOp(const string& op) {
    static const set<string> arithmeticOps = {"+", "-", "*", "/", "%", "<<", ">>"};
    return arithmeticOps.find(op) != arithmeticOps.end();
}

bool TAC::isBitwiseOp(const string& op) {
    static const set<string> bitwiseOps = {"&", "|", "^"};
    return bitwiseOps.find(op) != bitwiseOps.end();
}

bool TAC::isComparisonOp(const string& op) {
    static const set<string> comparisonOps = {"==", "!=", "<", ">", "<=", ">="};
    return comparisonOps.find(op) != comparisonOps.end();
}


void emit(string op, string result, string arg1, string arg2)
{
    TAC *q = new TAC(result, arg1, op, arg2);
    intermediateCode.addTAC(q);
}


void emit(string op, string result, int arg1, string arg2)
{
    TAC *q = new TAC(result, arg1, op, arg2);
    intermediateCode.addTAC(q);
}


void backpatch(list<int> listi, int addr)
{
    for (const int i : listi)
    {
        auto tac = intermediateCode.getTAC(i - 1);
        if (tac)
        {
            tac->result = toString(addr);
        }
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
        symbol = generateTemporary(SymbolType::SpecificType::INT_T);
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
    return intermediateCode.size() + 1;
}


Symbol *generateTemporary(SymbolType::SpecificType type, string intialValue)
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

void printTACArray() {

    int idx = 1;

    cout << string(140, '=') << endl;
    cout << string(30, ' ') << "TAC Array" << endl;
    cout << string(140, '=') << endl;

    cout << setw(20) << "Op" << setw(20) << "arg1" << setw(20) << "arg2" << setw(20) << "result" << setw(20) << "Index" << setw(20) << "Code in text\n";
    cout << setw(0) << string(140, '-') << endl;

    for (auto it = intermediateCode.begin(); it != intermediateCode.end(); it++) {
        cout << setw(20);
        (*it)->print(idx++);
    }
}

int main()
{
 
    tableCount = 0;             
    temporaryCount = 0;
    globalTable = new SymbolTable("global",SymbolTable::GLOBAL_SCOPE
,NULL);

    currentTable = globalTable;
    
    cout << left;


    yyparse();   


    globalTable->computeOffsets();
    globalTable->displayTable();

    // Printing the TACs Array
   printTACArray();
    return 0;
}