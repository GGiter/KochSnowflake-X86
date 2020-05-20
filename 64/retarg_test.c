#include <stdio.h>

extern int retarg(int arg0, int arg1, int arg2, int arg3, int arg4, int arg5);

int main(void)
{
	int res = retarg(0, 1, 2, 3, 4, 5);
	printf("Call retarg(0, 1, 2, 3, 4, 5) returned: %d\n", res);
  
	return 0;
}
