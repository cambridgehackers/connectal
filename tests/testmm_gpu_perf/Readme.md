Running on vangogh:

1) download opencv 2.4.9 to /scratch/opencv-cuda/

   http://downloads.sourceforge.net/project/opencvlibrary/opencv-unix/2.4.9/opencv-2.4.9.zip

2) install it using the following commands:
        cd opencv-2.9.4
	mkdir install
        cmake -G 'Unix Makefiles' -D WITH_CUDA=ON -D CMAKE_BUILD_TYPE=DEBUG -D CMAKE_INSTALL_PREFIX=./install .
	make -j 8  
	make install

