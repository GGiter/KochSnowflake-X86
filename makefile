CC=gcc
ASMBIN=nasm

all : asm cc link
asm : 
	$(ASMBIN) -o kochCurve.o -f elf -l kochCurve.lst  kochCurve.asm
cc :
	$(CC) -lm -freg-struct-return -m32 -fpack-struct -c -g -O0 kochCurveTest.c
link :
	$(CC) -lm -freg-struct-return -m32 -o  kochCurveTest kochCurveTest.o kochCurve.o
clean :
	rm *.o
	rm kochCurveTest
	rm kochCurve.lst