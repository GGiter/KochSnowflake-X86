#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>
#define LINE_LENGTH 17
#define DEBUG 0
#define CENTERX 200
#define CENTERY 220
struct Point{
	int x;
	int y;
};
typedef struct Point Point;
/* normalize vector and multiply it by LINE_LENGTH */
void prepare_point(Point* A)
{
	float w = sqrtf(A->x*A->x + A->y*A->y);
	float x = (A->x/w)*LINE_LENGTH;
	float y = (A->y/w)*LINE_LENGTH;
	A->x = (int)x;
	A->y = (int)y;
}
/* asm functions */
extern struct Point rotate(Point B,int clockwise);
extern void draw_line(Point A,Point B);
typedef struct
{
	unsigned short bfType; 
	unsigned long  bfSize; 
	unsigned short bfReserved1; 
	unsigned short bfReserved2; 
	unsigned long  bfOffBits; 
	unsigned long  biSize; 
	long  biWidth; 
	long  biHeight; 
	short biPlanes; 
	short biBitCount; 
	unsigned long  biCompression; 
	unsigned long  biSizeImage; 
	long biXPelsPerMeter; 
	long biYPelsPerMeter; 
	unsigned long  biClrUsed; 
	unsigned long  biClrImportant;
	unsigned long  RGBQuad_0;
	unsigned long  RGBQuad_1;
} __attribute__((__packed__)) bmpHdr;

typedef struct
{
	int width, height;		// width and height of the image
	unsigned char* pImg;	// pointer to the beginning of the pointer data
	int col;				// current color
} imgInfo;

void* freeResources(FILE* pFile, void* pFirst, void* pSnd)
{
	if (pFile != 0)
		fclose(pFile);
	if (pFirst != 0)
		free(pFirst);
	if (pSnd !=0)
		free(pSnd);
	return 0;
}
/* Reading and saving BMP file */
imgInfo* readBMP(const char* fname)
{
	imgInfo* pInfo = 0;
	FILE* fbmp = 0;
	bmpHdr bmpHead;
	int lineBytes, y;
	unsigned long imageSize = 0;
	unsigned char* ptr;

	pInfo = 0;
	fbmp = fopen(fname, "rb");
	if (fbmp == 0)
		return 0;

	fread((void *) &bmpHead, sizeof(bmpHead), 1, fbmp);
	// some basic checks
	if (bmpHead.bfType != 0x4D42 || bmpHead.biPlanes != 1 ||
		bmpHead.biBitCount != 1 ||
		(pInfo = (imgInfo *) malloc(sizeof(imgInfo))) == 0)
		return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

	pInfo->width = bmpHead.biWidth;
	pInfo->height = bmpHead.biHeight;
	imageSize = (((pInfo->width + 31) >> 5) << 2) * pInfo->height;

	if ((pInfo->pImg = (unsigned char*) malloc(imageSize)) == 0)
		return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

	// process height (it can be negative)
	ptr = pInfo->pImg;
	lineBytes = ((pInfo->width + 31) >> 5) << 2; // line size in bytes
	if (pInfo->height > 0)
	{
		// "upside down", bottom of the image first
		ptr += lineBytes * (pInfo->height - 1);
		lineBytes = -lineBytes;
	}
	else
		pInfo->height = -pInfo->height;

	// reading image
	// moving to the proper position in the file
	if (fseek(fbmp, bmpHead.bfOffBits, SEEK_SET) != 0)
		return (imgInfo*) freeResources(fbmp, pInfo->pImg, pInfo);

	for (y=0; y<pInfo->height; ++y)
	{
		fread(ptr, 1, abs(lineBytes), fbmp);
		ptr += lineBytes;
	}
	fclose(fbmp);
	return pInfo;
}

int saveBMP(const imgInfo* pInfo, const char* fname)
{
	int lineBytes = ((pInfo->width + 31) >> 5)<<2;
	bmpHdr bmpHead = 
	{
	0x4D42,				// unsigned short bfType; 
	sizeof(bmpHdr),		// unsigned long  bfSize; 
	0, 0,				// unsigned short bfReserved1, bfReserved2; 
	sizeof(bmpHdr),		// unsigned long  bfOffBits; 
	40,					// unsigned long  biSize; 
	pInfo->width,		// long  biWidth; 
	pInfo->height,		// long  biHeight; 
	1,					// short biPlanes; 
	1,					// short biBitCount; 
	0,					// unsigned long  biCompression; 
	lineBytes * pInfo->height,	// unsigned long  biSizeImage; 
	11811,				// long biXPelsPerMeter; = 300 dpi
	11811,				// long biYPelsPerMeter; 
	2,					// unsigned long  biClrUsed; 
	0,					// unsigned long  biClrImportant;
	0x00000000,			// unsigned long  RGBQuad_0;
	0x00FFFFFF			// unsigned long  RGBQuad_1;
	};

	FILE * fbmp;
	unsigned char *ptr;
	int y;

	if ((fbmp = fopen(fname, "wb")) == 0)
		return -1;
	if (fwrite(&bmpHead, sizeof(bmpHdr), 1, fbmp) != 1)
	{
		fclose(fbmp);
		return -2;
	}

	ptr = pInfo->pImg + lineBytes * (pInfo->height - 1);
	for (y=pInfo->height; y > 0; --y, ptr -= lineBytes)
		if (fwrite(ptr, sizeof(unsigned char), lineBytes, fbmp) != lineBytes)
		{
			fclose(fbmp);
			return -3;
		}
	fclose(fbmp);
	return 0;
}
/****************************************************************************************/
imgInfo* InitScreen (int w, int h)
{
	imgInfo *pImg;
	if ( (pImg = (imgInfo *) malloc(sizeof(imgInfo))) == 0)
		return 0;
	pImg->height = h;
	pImg->width = w;
	pImg->pImg = (unsigned char*) malloc((((w + 31) >> 5) << 2) * h);
	if (pImg->pImg == 0)
	{
		free(pImg);
		return 0;
	}
	memset(pImg->pImg, 0xFF, (((w + 31) >> 5) << 2) * h);
	pImg->col = 0;
	return pImg;
}

void FreeScreen(imgInfo* pInfo)
{
	if (pInfo && pInfo->pImg)
		free(pInfo->pImg);
	if (pInfo)
		free(pInfo);
}
imgInfo* ImgData;
void SetPixel(int x, int y)
{
	unsigned char *pPix = ImgData->pImg + (((ImgData->width + 31) >> 5) << 2) * y + (x >> 3);
	unsigned char mask = 0x80 >> (x & 0x07);
	if (ImgData->col)
		*pPix |= mask;
	else
		*pPix &= ~mask;
}
/* move forward and update start point */
void moveForward(Point* A,Point B)
{
	/* move vector (x2,y2) by (x1,y1) */
	B.x += A->x;
	B.y += A->y;
		
	if (DEBUG)
	{
		printf("START point X: %d , Y: %d \n",A->x,A->y);
		printf("END point X: %d , Y: %d \n",B.x,B.y);
	}
	
	/* move vector by (CENTERX,CENTERY) */
	A->x+=CENTERX;
	A->y+=CENTERY;
	B.x+=CENTERX;
	B.y+=CENTERY;
	
	draw_line(*A,B);
	
	/* set new start point */
	A->x = B.x - CENTERX;
	A->y = B.y - CENTERY;
	
}
/* append to char* helper function */
char* append(const char *input, const char c)
{
    char *newString, *ptr;
    /* alloc */
    newString = calloc((strlen(input) + 2), sizeof(char));
    /* Copy old string in new (with pointer) */
    ptr = newString;
    for(; *input; input++) {*ptr = *input; ptr++;}
    /* Copy char at end */
    *ptr = c;
    /* return new string */
    return newString;
}
/* generate l-system instructions */
char* generate_instruction(size_t generation)
{
	char* axiom = "+F--F--F";
	char* rule = "F+F--F+F";
	char plus = '+';
	char minus = '-';
	char* instruction = axiom;
	size_t i = 0;
	for(i=1;i<generation;++i)
	{
		char* new_instruction = "";
		size_t size = strlen(instruction);
		size_t j = 0;
		for(j=0;j<size;++j)
		{
			if(instruction[j]=='F')
			{
				size_t k;
				for (k=0;k<strlen(rule);++k)
				  new_instruction = append(new_instruction,rule[k]);
			}
			else if (instruction[j]=='+'){
				new_instruction = append(new_instruction,plus);
			}
			else if (instruction[j]=='-'){
				new_instruction = append(new_instruction,minus);
			}
		}
		instruction = new_instruction;
	}
	
	return instruction;
}

int main(void)
{
	
	printf("Size of bmpHeader = %d\n", sizeof(bmpHdr));
	if (sizeof(bmpHdr) != 62)
	{
		printf("Size of structure bmpHdr must be 62.\n");
		return 1;
	}
	
		
	ImgData = InitScreen(512, 512);
	/* generate instructions */
   	char* input = generate_instruction(3);
	size_t length = strlen(input);
	
	/* print instructions */
	printf("Instruction set = %s\n",input);
	
	Point start,end;
	/* main instruction loop */
	start.x = 0;
	start.y = 0;
	end.x = LINE_LENGTH;
	end.y = 0;
	size_t i = 0;
	for(i = 0; i < length; ++i)
	{
		if (input[i] == '+')
		{
			end = rotate(end,1);
			prepare_point(&end);
		}
		else if (input[i] == '-')
		{
			end = rotate(end,-1);
			prepare_point(&end);
		}
		else if (input[i] == 'F')
		{
			moveForward(&start,end);
		}	
	}
	
	if (saveBMP(ImgData, "result.bmp") != 0)
	{
		printf("Error saving file.\n");
		return 3;
	}

	FreeScreen(ImgData);
	return 0;
}