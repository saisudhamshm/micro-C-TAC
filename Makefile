parser.out: lex.yy.o y.tab.o A5_31_translator.o
	g++ lex.yy.o y.tab.o A5_31_translator.o -lfl -o parser.out

A5_31_translator.o: A5_31_translator.cxx A5_31_translator.h
	g++ -c A5_31_translator.cxx

lex.yy.o: lex.yy.c
	g++ -c lex.yy.c

y.tab.o: y.tab.c
	g++ -c y.tab.c

lex.yy.c: A5_31.l y.tab.h A5_31_translator.h
	flex A5_31.l

y.tab.c y.tab.h: A5_31.y A5_31_translator.h
	bison -dty --report=all A5_31.y

clean:
	rm -f A5_31_translator.o lex.yy.* y.tab.* y.output ./OutputFiles/*.out parser.out

test: parser.out
	./parser.out < ./InputFiles/test1.c > ./OutputFiles/quads1.out
	./parser.out < ./InputFiles/test2.c > ./OutputFiles/quads2.out
	./parser.out < ./InputFiles/test3.c > ./OutputFiles/quads3.out
	./parser.out < ./InputFiles/test4.c > ./OutputFiles/quads4.out
	./parser.out < ./InputFiles/test5.c > ./OutputFiles/quads5.out
	./parser.out < ./InputFiles/test6.c > ./OutputFiles/quads6.out
	./parser.out < ./InputFiles/test7.c > ./OutputFiles/quads7.out
	./parser.out < ./InputFiles/test8.c > ./OutputFiles/quads8.out
	./parser.out < ./InputFiles/test9.c > ./OutputFiles/quads9.out
	./parser.out < ./InputFiles/test10.c > ./OutputFiles/quads10.out