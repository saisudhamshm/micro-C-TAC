# Micro-C Compiler 
## Overview
This project implements a compiler for a subset of C programming language with custom syntax modifications. The compiler is built using Flex for lexical analysis, Bison for parsing, and C++ for code generation. It produces three-address code as its output.
## Language Features
The compiler supports a language similar to C but with the following notable differences:
- Uses `integer` keyword instead of `int` for integer type declarations
- Uses `begin` and `end` keywords instead of braces `{}` for code blocks
- Includes standard types: `integer`, `char`, `float`, `void`
- Supports arrays, pointers, and functions
- Provides standard control structures: if-else, for, while, do-while
- Includes logical, arithmetic, bitwise, and relational operators

## Project Structure
- **220101066.y**: Bison grammar file defining the language syntax
- **220101066.l**: Flex lexical analyzer for tokenizing input
- **220101066.h**: Header file containing class definitions for the compiler
- **220101066.cxx**: Implementation of the compiler components
- **Makefile**: Build system configuration

## Key Components
### Symbol Table
The symbol table manages program variables, functions, and temporaries. It provides:
- Scoped variable lookup
- Type checking
- Offset calculation for memory allocation

### Intermediate Code Generation
The compiler generates three-address code represented as quadruples. Each quad has:
- An operation
- A result
- Up to two operands

### Type System
Types supported:
- Basic types: `integer`, `char`, `float`, `void`
- Derived types: pointers, arrays, functions

## How to Build
``` bash
make
```
This will generate the `parser` executable.
## How to Run
``` bash
./parser < input_file.mc > output_file.txt
```
Where `.mc` is the extension for Mini-C source files.
## Testing
The project includes a test target to validate the compiler with sample programs:
``` bash
make test
```
This will run the compiler on test input files and generate the corresponding output files.
## Sample Syntax
Below is a sample program in the Mini-C language:
``` 
// Function to add two integers
integer add(integer a, integer b)
begin
    return a + b;
end

// Main function
integer main(void)
begin
    integer x = 5;
    integer y = 10;
    integer result;
    
    result = add(x, y);
    
    if (result > 10)
    begin
        result = result * 2;
    end
    else
    begin
        result = result / 2;
    end
    
    return 0;
end
```
## Cleaning Up
To clean the generated files:
``` bash
make clean
```
## Implementation Details
The compiler follows a standard structure:
1. **Lexical Analysis**: Converts source code into tokens
2. **Syntax Analysis**: Validates program structure according to grammar
3. **Semantic Analysis**: Ensures type correctness and builds symbol tables
4. **Intermediate Code Generation**: Produces three-address code

The three-address code can be further used for optimization and target code generation.
