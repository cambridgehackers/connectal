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
#ifndef _MNIST_H_
#define _MNIST_H_

#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>
#include <opencv2/core/core.hpp>

class MnistImageFile {
public:
  MnistImageFile(const char *name) : name(name), fd(0), mapping(0), len(0) {}
  ~MnistImageFile() { 
    if (mapping)
      munmap((void*)mapping, len);
    if (fd)
      close(fd);
  }

  void open() {
    fd = ::open(name, O_RDONLY);
    if (fd < 0) {
      fprintf(stderr, "Failed to open %s errno=%d:%s\n", name, errno, strerror(errno));
    }
    mapping = (const char *)mmap(0, 4096, PROT_READ, MAP_SHARED, fd, 0);
    if (mapping == MAP_FAILED) {
      fprintf(stderr, "mmap failed on file %s errno=%d:%s\n", name, errno, strerror(errno));
    }
    int magic = *(int *)mapping;
    int dtype = mapping[2];
    int dims = mapping[3];
    int *nosizes = (int *)(mapping + 4);
    int size = 0;
    switch (dtype) {
    case 8:
    case 9:
      size = 1;
      break;
    case 0xb:
      size = 2;
      break;
    case 0xc:
      size = 4;
      break;
    case 0xe:
      size = 8;
      break;
    default:
      fprintf(stderr, "Unknown data type %x\n", dtype);
    }
    for (int i = 0; i < dims; i++) {
      sizes[i] = ntohl(nosizes[i]);
      size = size * sizes[i];
    }
    dataOffset = 4+dims*4;
    elementSize = size / sizes[0];

    len = cv::alignSize(size + dataOffset, 4096);
    fprintf(stderr, "magic=%x dtype=%x dims=%d size=%d elementSize=%d len=%d\n", ntohl(magic), dtype, dims, size, elementSize, len);
    munmap((void*)mapping, 4096);
    mapping = (const char *)mmap(0, len, PROT_READ, MAP_SHARED, fd, 0);
    if (mapping == MAP_FAILED) {
      fprintf(stderr, "mmap failed on file %s errno=%d:%s\n", name, errno, strerror(errno));
    }

  }

  int numEntries() const {
    return sizes[0];
  }
  int rows() const {
    return sizes[1];
  }
  int cols() const {
    return sizes[2];
  }

  cv::Mat mat(int i) const {
    const char *data = mapping + dataOffset + elementSize*i;
    int rows = sizes[1];
    int cols = sizes[2];
    //fprintf(stderr, "image %d rows=%d cols=%d offset=%d\n", i, rows, cols, dataOffset + elementSize*i);
    cv::Mat m(rows, cols, CV_8U);
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
	m.at<unsigned char>(i,j) = (unsigned char)data[i*cols + j];
      }
    }
    return m;
  }

private:
  const char *name;
  int fd;
  const char *mapping;
  int sizes[3];
  int len;
  int dataOffset;
  int elementSize;
};

#endif
