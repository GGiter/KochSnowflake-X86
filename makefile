CC=gcc
ASMBIN=nasm

all : asm cc link
asm : 
	$(ASMBIN) -o kochCurve.o -f elf -l kochCurve.lst  kochCurve.asm
cc :
	$(CC) -m32 -c -g -O0 kochCurvetest.c
link :
	$(CC) -m32 -o kochCurvetest kochCurvetest.o kochCurve.o
clean :
	rm *.o
	rm kochCurvetest
	rm kochCurve.lst