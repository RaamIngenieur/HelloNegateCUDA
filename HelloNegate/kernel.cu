
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <png.hpp>

cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size);


class UCarray
{
public:
	unsigned char *Pix;
	UCarray(int r, int c);
	~UCarray();
	void ImagetoArray(png::image<png::gray_pixel>* input);
	void operator=(const UCarray& other);
	void ArraytoImage(png::image<png::gray_pixel>* output);
private:
	int row, column;

};

__global__ void negateKernel(unsigned char* img, int N)
{
	int i = blockIdx.x*blockDim.x + threadIdx.x;
	if (i<N)
	img[i] = 255 - img[i];
}

UCarray::UCarray(int r, int c)
{
	row = r;
	column = c;
	Pix = (unsigned char*)malloc(row * column * sizeof(unsigned char));
	if (Pix == NULL)
	{
		fprintf(stderr, "out of memory\n");
	}

}

UCarray::~UCarray()
{
	free(Pix);
}

void UCarray::ImagetoArray(png::image<png::gray_pixel>* input)
{
	for (int i = 0; i < row; i++)
	{
		for (int j = 0; j < column; j++)
		{
			*(Pix + i*column + j) = (*input)[i][j];
		}
	}
}

void UCarray::ArraytoImage(png::image<png::gray_pixel>* output)
{
	for (int i = 0; i < row; i++)
	{
		for (int j = 0; j < column; j++)
		{
			(*output)[i][j] = *(Pix + i*column + j);
		}
	}
}

void UCarray:: operator =(const UCarray&  other)
{
	for (int i = 0; i < row; i++)
	{
		for (int j = 0; j < column; j++)
		{
			*(Pix + i*column + j) = *(other.Pix + i*column + j);
		}
	}
}


int main()
{

	png::image< png::gray_pixel > image("tsukuba_daylight_L_00001.png");

	int row = image.get_height(), column = image.get_width(), N= row*column;

	UCarray UCInput(row, column);

	UCInput.ImagetoArray(&image);

	unsigned char *d_x;

	cudaMalloc(&d_x, N*sizeof(unsigned char));

	cudaMemcpy(d_x, UCInput.Pix, N*sizeof(unsigned char), cudaMemcpyHostToDevice);

	negateKernel <<<(N + 255) / 256, 256 >>>(d_x, N);

	cudaMemcpy(UCInput.Pix, d_x, N*sizeof(unsigned char), cudaMemcpyDeviceToHost);

	UCInput.ArraytoImage(&image);

	image.write("negated.png");

    return 0;
}

