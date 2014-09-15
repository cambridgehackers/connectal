#include<iostream>
#include<cstdio>
#include<opencv2/core/core.hpp>
#include<opencv2/highgui/highgui.hpp>
#include<cuda_runtime.h>
#include<cuda_runtime_api.h>

using std::cout;
using std::endl;

void convert_to_gray(const cv::Mat& input, cv::Mat& output);

int main()
{
	std::string imagePath = "image.jpg";

	//Read input image from the disk
	cv::Mat input = cv::imread(imagePath,CV_LOAD_IMAGE_COLOR);

	if(input.empty())
	{
		std::cout<<"Image Not Found!"<<std::endl;
		std::cin.get();
		return -1;
	}

	//Create output image
	cv::Mat output(input.rows,input.cols,CV_8UC1);

	//Call the wrapper function
	convert_to_gray(input,output);

	//Show the input and output
	cv::imshow("Input",input);
	cv::imshow("Output",output);
	
	//Wait for key press
	cv::waitKey();

	return 0;
}
