Running on vangogh:

1) download opencv 2.4.9 to /scratch/opencv-cuda/

   http://downloads.sourceforge.net/project/opencvlibrary/opencv-unix/2.4.9/opencv-2.4.9.zip

2) install it using the following commands (I used cmake version 2.8.11.2):
        cd opencv-2.9.4
	mkdir install
        cmake -G 'Unix Makefiles' -D WITH_CUDA=ON -D CMAKE_BUILD_TYPE=DEBUG -D BUILD_SHARED_LIBS=NO -D WITH_CUBLAS=YES -D CMAKE_INSTALL_PREFIX=./install .
	make -j 8  
	make install


3)  nm -A *.a | c++filt | grep -w T 

