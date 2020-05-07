#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>
#define _cdecl __attribute__((__cdecl__))
struct Point{
	int x;
	int y;
};
//typedef struct Point Point;
extern struct Point rotateRight(struct Point A, struct Point B,int clockwise);
extern struct Point rotateLeft(struct Point A, struct Point B,int clockwise);
//extern Point bresenham(Point A,Point B);

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
	int width, height;		// szerokosc i wysokosc obrazu
	unsigned char* pImg;	// wskazanie na poczatek danych pikselowych
	int cX, cY;				// "aktualne wspólrzedne" 
	int col;				// "aktualny kolor"
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
	pImg->cX = 0;
	pImg->cY = 0;
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
imgInfo* SetColor(imgInfo* pImg, int col)
{
	pImg->col = col != 0;
	return pImg;
}

imgInfo* MoveTo(imgInfo* pImg, int x, int y)
{
	if (x >= 0 && x < pImg->width)
		pImg->cX = x;
	if (y >= 0 && y < pImg->height)
		pImg->cY = y;
	return pImg;
}
imgInfo* ImgData;
void SetPixel(int x, int y)
{
	unsigned char *pPix = ImgData->pImg + (((ImgData->width + 31) >> 5) << 2) * y + (x >> 3);
	unsigned char mask = 0x80 >> (x & 0x07);
	if (pImg->col)
		*pPix |= mask;
	else
		*pPix &= ~mask;
}
imgInfo* LineTo(imgInfo* pImg, int x, int y)
{
	// draws line segment between current position and (x,y)
	int cx = pImg->cX, cy = pImg->cY;
	int dx = x - cx, xi = 1, dy = y - cy, yi = 1;
	int d, ai, bi;

	if (dx < 0)
	{ 
		xi = -1;
		dx = -dx;
	} 

	if (dy < 0)
	{ 
		yi = -1;
		dy = -dy;
	} 

	// first pixel
	SetPixel(pImg, cx, cy);

	// horizontal drawing 
	if (dx > dy)
	{
		ai = (dy - dx) * 2;
		bi = dy * 2;
		d = bi - dx;
		// for each x
		while (cx != x)
		{ 
			// check line move indicator
			if (d >= 0)
			{ 
				cx += xi;
				cy += yi;
				d += ai;
			} 
			else
			{
				d += bi;
				cx += xi;
			}
			SetPixel(pImg, cx, cy);
		}
	} 
	// vertical drawing
	else
	{ 
		ai = ( dx - dy ) * 2;
		bi = dx * 2;
		d = bi - dy;
		// for each y
		while (cy != y)
		{ 
			// check column move indicator
			if (d >= 0)
			{ 
				cx += xi;
				cy += yi;
				d += ai;
			}
			else
			{
				d += bi;
				cy += yi;
			}
			SetPixel(pImg, cx, cy);
		}
	}
	pImg->cX = x;
	pImg->cY = y;
	return pImg;
}

struct Point last_Point;
struct Point start,end;

#define CENTERX 200
#define CENTERY 220

void MoveForward(imgInfo* pInfo,struct Point A,struct Point B)
{
	
	// move vector (x2,y2) by (x1,y1)
	B.x = B.x + last_Point.x;
	B.y = B.y + last_Point.y;
	
	A = last_Point;
	
	printf("START point X: %d , Y: %d \n",A.x,A.y);
	printf("END point X: %d , Y: %d \n",B.x,B.y);
	
	A.x+=CENTERX;
	A.y+=CENTERY;
	B.x+=CENTERX;
	B.y+=CENTERY;
	
	
	
	MoveTo(pInfo,A.x,A.y);
	LineTo(pInfo,B.x,B.y);
	
	last_Point.x = B.x - CENTERX;
	last_Point.y = B.y - CENTERY;
	
	A.x-=CENTERX;
	A.y-=CENTERY;
	
	start = last_Point;
	

}

char* generate_instruction(size_t generation)
{
	char* axiom = "+F--F--F";
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
				char *temp = malloc(strlen(new_instruction)+8);
				stpcpy(temp,new_instruction);
				strcat(temp,"F+F--F+F");
				new_instruction = temp;
			}
			else{
				char *temp = malloc(strlen(new_instruction)+1);
				stpcpy(temp,new_instruction);
				if(instruction[j]=='+')
				strcat(temp,"+");
				else
				strcat(temp,"-");	
				new_instruction = temp;
			}
		}
		instruction = new_instruction;
	}
	
	return instruction;
}

int main(void)
{
	imgInfo* pInfo;
	
	last_Point.x=0;
	last_Point.y=0;

	printf("Size of bmpHeader = %d\n", sizeof(bmpHdr));
	printf("Size of Point = %d\n", sizeof(struct Point));
	if (sizeof(bmpHdr) != 62)
	{
		printf("Size of structure bmpHdr must be 62.\n");
		return 1;
	}
	
		
	

	pInfo = InitScreen(512, 512);
	ImgData = pInfo;


   	char* input = generate_instruction(1);
	size_t length = strlen(input);
	
	printf("Length of input = %d\n",length);
	printf("Instruction set = %s\n",input);

	start.x = 0;
	start.y = 0;
	end.x = 17;
	end.y = 0;
	size_t i = 0;
	struct Point zero;
	zero.x=0;
	zero.y=0;
	for(i = 0; i < length; ++i)
	{
		if (input[i] == '+')
		{
			end = rotateRight(zero,end,1);	
			printf("start point X: %d , Y: %d \n",start.x,start.y);			
			printf("end point X: %d , Y: %d \n",end.x,end.y);
		}
		else if (input[i] == '-')
		{
			end = rotateLeft(zero,end,-1);
			printf("start point X: %d , Y: %d \n",start.x,start.y);	
			printf("end point X: %d , Y: %d \n",end.x,end.y);
		}
		else if (input[i] == 'F')
		{
			MoveForward(pInfo,start,end);
		}	
	}
	


	if (saveBMP(pInfo, "result.bmp") != 0)
	{
		printf("Error saving file.\n");
		return 3;
	}

	FreeScreen(pInfo);
	return 0;
}