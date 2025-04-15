// Sample test file for the grammar specified in 220101066.y

// Global variable declarations
integer globalVar = 10;
float pi = 3.14159;
char letter = 'A';

// Function declaration
integer add(integer a, integer b)
begin
    return a + b;
end

// Function with array parameter
void printArray(integer *arr, integer size)
begin
    integer i;
    for(i = 0; i < size; i = i + 1)
    begin
        // This is a function body
    end
end

// Function with pointer
integer* createArray(integer size)
begin
    integer* arr;
    return arr;
end

// Main function
integer main(void)
begin
    // Local variable declarations
    integer a = 5;
    integer b = 10;
    float result;
    char c = 'X';

    // Array declaration
    integer numbers[10];

    // Assignment
    numbers[0] = 42;

    // Arithmetic operations
    result = a + b * 2;
    result = (a + b) / 2;
    result = a % b;

    // Unary operations
    a = -a;
    b = !b;

    // Pointer
    integer* ptr = &a;

    // Conditional statements
    if (a > b)
    begin
        a = a + 1;
    end
    else
    begin
        b = b - 1;
    end

    // Conditional expression
    integer max = (a > b) ? a : b;

    // Logical operators
    if (a > 0 && b < 20)
    begin
        a = 0;
    end

    if (a == 0 || b == 0)
    begin
        b = 0;
    end

    // Loops
    while (a < 10)
    begin
        a = a + 1;
    end

    do
    begin
        b = b - 1;
    end while (b > 0);

    for (a = 0; a < 10; a = a + 1)
    begin
        if (a == 5) continue;
        if (a == 8) break;
    end

    // Bitwise operations
    integer bits = a & b;
    bits = a | b;
    bits = a ^ b;
    bits = a << 2;
    bits = b >> 1;

    // Function calls
    integer sum = add(a, b);
    printArray(numbers, 10);

    return 0;
end