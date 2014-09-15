NVCC = /usr/local/cuda-5.5/bin/nvcc

default: cuda_opencv_example

main.o:
	$(NVCC) -I/usr/local/cuda-5.5/targets/x86_64-linux/include/ -I/scratch/opencv-cuda/opencv-2.4.9/install/include -c /scratch/mdk/xbsv/tests/testmm_cuda_perf/cuda_opencv_example/main.cu

cuda_opencv_example: main.o
	g++ -I/usr/local/cuda-5.5/targets/x86_64-linux/include/ -I/scratch/opencv-cuda/opencv-2.4.9/install/include -o cuda_opencv_example main.o /scratch/mdk/xbsv/tests/testmm_cuda_perf/cuda_opencv_example/main.cpp \
	-L/scratch/opencv-cuda/opencv-2.4.9/install/lib -L/usr/local/cuda-5.5/lib64 \
	-lcuda -lopencv_core  -lopencv_gpu -lcudart -lopencv_core 


run:
	LD_LIBRARY_PATH=/usr/local/cuda-5.5/lib64 ./cuda_opencv_example