#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <math.h>
struct Point(
	int x;
	int y;
}
extern Point rotateRight(Point A,Point B);
extern Point rotateLeft(Point A,Point B);
extern Point bresenham(Point A,Point B);

typedef struct
{
	int width, height;
	unsigned char* pImg;
	int imgSize;
	// proszê pamiêtaæ, ¿e to jest struktura, któr¹ Pañstwo zarz¹dzacie
	// mo¿na tu dodaæ kolejne pola, które bêd¹ dla Was u¿yteczne
} imgInfo;

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
} _attribute__((__packed_)) bmpHdr;

mgInfo* InitImage(int w, int h)
{
	imgInfo *pImg;
	if ((pImg = (imgInfo *)malloc(sizeof(imgInfo))) == 0)
		return 0;
	pImg->height = h;
	pImg->width = w;
	pImg->pImg = (unsigned char*)malloc((((w * 3 + 3) >> 2) << 2) * h);
	if (pImg->pImg == 0)
	{
		free(pImg);
		return 0;
	}
	memset(pImg->pImg, 0, (((w * 3 + 3) >> 2) << 2) * h);
	return pImg;
}

imgInfo * copyImage(const imgInfo* pImg)
{
	imgInfo *pNew = InitImage(pImg->width, pImg->height);
	if (pNew != 0)
		memcpy(pNew->pImg, pImg->pImg, pNew->imgSize);
	return pNew;
}

imgInfo* readBMP(const char* fname)
{
	imgInfo* pInfo = 0;
	FILE* fbmp = 0;
	bmpHdr bmpHead;
	int lineBytes, y;
	unsigned char* ptr;

	pInfo = 0;
	fbmp = fopen(fname, "rb");
	if (fbmp == 0)
		return 0;

	fread((void *)&bmpHead, sizeof(bmpHead), 1, fbmp);
	// parê sprawdzeñ
	if (bmpHead.bfType != 0x4D42 || bmpHead.biPlanes != 1 ||
		bmpHead.biBitCount != 24 ||
		(pInfo = (imgInfo *)malloc(sizeof(imgInfo))) == 0)
		return (imgInfo*)freeResources(fbmp, pInfo ? pInfo->pImg : 0, pInfo);

	pInfo->width = bmpHead.biWidth;
	pInfo->height = bmpHead.biHeight;
	if ((pInfo->pImg = (unsigned char*)malloc(bmpHead.biSizeImage)) == 0)
		return (imgInfo*)freeResources(fbmp, pInfo->pImg, pInfo);

	// porz¹dki z wysokoœci¹ (mo¿e byæ ujemna)
	ptr = pInfo->pImg;
	lineBytes = ((pInfo->width * 3 + 3) >> 2) << 2; // rozmiar linii w bajtach
	if (pInfo->height > 0)
	{
		// "do góry nogami", na pocz¹tku dó³ obrazu
		ptr += lineBytes * (pInfo->height - 1);
		lineBytes = -lineBytes;
	}
	else
		pInfo->height = -pInfo->height;

	// sekwencja odczytu obrazu 
	// przesuniêcie na stosown¹ pozycjê w pliku
	if (fseek(fbmp, bmpHead.bfOffBits, SEEK_SET) != 0)
		return (imgInfo*)freeResources(fbmp, pInfo->pImg, pInfo);

	for (y = 0; y < pInfo->height; ++y)
	{
		fread(ptr, 1, abs(lineBytes), fbmp);
		ptr += lineBytes;
	}
	fclose(fbmp);
	return pInfo;
}

int saveBMP(const imgInfo* pInfo, const char* fname)
{
	int lineBytes = ((pInfo->width * 3 + 3) >> 2) << 2;
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
	24,					// short biBitCount; 
	0,					// unsigned long  biCompression; 
	lineBytes * pInfo->height,	// unsigned long  biSizeImage; 
	11811,				// long biXPelsPerMeter; = 300 dpi
	11811,				// long biYPelsPerMeter; 
	2,					// unsigned long  biClrUsed; 
	0,					// unsigned long  biClrImportant;
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
	for (y = pInfo->height; y > 0; --y, ptr -= lineBytes)
		if (fwrite(ptr, sizeof(unsigned char), lineBytes, fbmp) != lineBytes)
		{
			fclose(fbmp);
			return -3;
		}
	fclose(fbmp);
	return 0;
}

void putPixel(imgInfo *pInfo, int x, int y, int *rgb)
{
	int lineBytes = ((pInfo->width * 3 + 3) >> 2) << 2;
	unsigned char *pAddr = pInfo->pImg + y * lineBytes + x * 3;
	*pAddr = rgb[0] >> 16;
	*(pAddr + 1) = rgb[1] >> 16;
	*(pAddr + 2) = rgb[2] >> 16;
}

void FreeImage(imgInfo* pInfo)
{
	if (pInfo && pInfo->pImg)
		free(pInfo->pImg);
	if (pInfo)
		free(pInfo);
}

void MoveForward(Point& A,Point& B)
{
	
}

int main(void)
{
	imgInfo* pInfo;


	if (sizeof(bmpHdr) != 54)
	{
		printf("Size of structure bmpHdr must be 54.\n");
		return 1;
	}

	pInfo = InitImage(256, 256);

   	char* input = "+F+F--F+F+F+F--F+F--F+F--F+F+F+F--F+F--F+F--F+F+F+F--F+F--F+F--F+F+F+F--F+F--F+F--F+F+F+F--F+F--F+F--F+F+F+F--F+F";
	int length = 114;
	Point start,end;
	start.x = 0;
	start.y = 0;
	end.x = 0;
	end.y = 0;
	for(unsigned int i = 0; i < length; ++i)
	{
		if (input[i] == '+')
		{
			end = rotateRight(start,end);
		}
		else if (input[i] == '-')
		{
			end = rotateRight(start,end);
		}
		else if (input[i] == 'F')
		{
			MoveForward(start,end);
		}
		printf("End point X: %d , Y: %d \n",end.x,end.y);
	}
	


	if (saveBMP(pInfo, "triangles.bmp") != 0)
	{
		printf("Error saving file.\n");
		return 3;
	}

	FreeImage(pInfo);
	return 0;
}