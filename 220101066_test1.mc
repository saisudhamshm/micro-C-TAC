// Add two numbers
integer main() begin
integer x = 2;
float y = 3;
integer a=1;
integer b=2;
integer c=3;
a=b|c;
integer z;
z = x + y;
printInt(x);
printStr("+");
printInt(y);
printStr(" = ");
printInt(z);
while(x<=1) begin
x = x-1;
z=x<<2;
end
return 0;
end