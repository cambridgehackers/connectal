/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
#include<iostream>
#include<cstdio>
#include<opencv2/core/core.hpp>
#include<opencv2/highgui/highgui.hpp>
#include<cuda_runtime.h>
#include<cuda_runtime_api.h>

using std::cout;
using std::endl;

void convert_to_gray(const cv::Mat& input, cv::Mat& output);
void map_sigmoid(const cv::Mat& input, cv::Mat& output);
float sigmoid(float x);


#define SIGMOID
#ifdef SIGMOID

int main()
{
  int A = 128;
  int B = 128;

  srand(A*B);

  cv::Mat input(A,B,CV_32F);
  cv::Mat output(A,B,CV_32F);

  for(int a = 0; a < A; a++)
    for(int b = 0; b < B; b++)
      input.at<float>(a,b) = (float)(rand() % 10);

  fprintf(stderr, "about to call kernel\n");
  map_sigmoid(input,output);
  fprintf(stderr, "successfully called kernel\n");
  
  bool match = true;
  float epsilon = 0.00001;
  for(int a = 0; a < A; a++) {
    for(int b = 0; b < B; b++) {
      float ref = sigmoid(input.at<float>(a,b));
      float gpuv = output.at<float>(a,b);
      float err = fabs(ref - gpuv);//ref;
      bool eq = (epsilon > err);
      match &= eq;
      if (!eq) fprintf(stderr, "(%d,%d) %f %f\n", a,b,ref,gpuv);
    }
  }
  return !match;
}

#else // SIGMOID
int main()
{
	std::string imagePath = "image.jpg";

	//Read input image from the disk
	cv::Mat input = cv::Mat::zeros(100,100,CV_LOAD_IMAGE_COLOR); //cv::imread(imagePath,CV_LOAD_IMAGE_COLOR);

	if(input.empty())
	{
		std::cout<<"Image Not Found!"<<std::endl;
		std::cin.get();
		return -1;
	}

	//Create output image
	cv::Mat output(input.rows,input.cols,CV_8UC1);

	fprintf(stderr, "about to call kernel\n");

	//Call the wrapper function
	convert_to_gray(input,output);

	//Show the input and output
	//cv::imshow("Input",input);
	//cv::imshow("Output",output);
	
	//Wait for key press
	//cv::waitKey();

	fprintf(stderr, "successfully called kernel\n");

	return 0;
}
#endif // SIGMOID
