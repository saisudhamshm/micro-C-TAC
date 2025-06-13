compiler: lex.yy.o y.tab.o 220101066.o
	g++ lex.yy.o y.tab.o 220101066.o -lfl -o compiler

220101066.o: 220101066.cpp 220101066.h
	g++ -c 220101066.cpp

lex.yy.o: lex.yy.c
	g++ -c lex.yy.c

y.tab.o: y.tab.c
	g++ -c y.tab.c

lex.yy.c: 220101066.l y.tab.h 220101066.h
	flex 220101066.l

y.tab.c y.tab.h: 220101066.y 220101066.h
	bison -dty --report=all 220101066.y

clean:
	rm -f 220101066.o lex.yy.* y.tab.* y.output ./OutputFiles/*.out compiler 220101066_test*.txt *.txt

test: compiler
	./compiler < 220101066_test1.mc > 220101066_test1.txt
	./compiler < 220101066_test2.mc > 220101066_test2.txt