// Copyright (c) 2015 The Connectal Project

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#ifndef __CONNECTAL_CONV_H__
#define __CONNECTAL_CONV_H__
#include <stdlib.h>
#include <dlfcn.h>

#define CACCESS(A) ((Dtype *)(param->basePtr + (A)))
typedef unsigned long CPtr;
class ParamStruct {
public:
    volatile uint8_t *basePtr;
    CPtr *bottom;
    CPtr *top_diff;
    CPtr *bottom_diff;
    CPtr *top;
    CPtr bias_multiplier_;
    CPtr weight;
    CPtr bias;
    CPtr weight_diff;
    CPtr bias_diff;
    CPtr zero_region;
    int zero_region_len;
    int top_size;
    int bottom_size;
    int weight_diff_count;
    int num_;
    int num_output_;
    int group_;
    int height_out_, width_out_;
    int kernel_h_, kernel_w_;
    int conv_in_height_, conv_in_width_;
    int conv_in_channels_, conv_out_channels_;
    int weight_offset_;
    int pad_h_, pad_w_;
    int stride_h_, stride_w_;
    int portalFd_;
    int propdone_;
    int objectId_;
    int elementSize_;
    ParamStruct(): bottom(NULL), top_diff(NULL), bottom_diff(NULL), top(NULL),
        bias_multiplier_(0), weight(0), bias(0), weight_diff(0), bias_diff(0),
        zero_region(0), zero_region_len(0),
        top_size(0), bottom_size(0), weight_diff_count(0),
        num_(0), num_output_(0), group_(0), height_out_(0), width_out_(0),
        kernel_h_(0), kernel_w_(0), conv_in_height_(0), conv_in_width_(0),
        conv_in_channels_(0), conv_out_channels_(0),
        weight_offset_(0), pad_h_(0), pad_w_(0),
        stride_h_(0), stride_w_(0), portalFd_(-1), propdone_(0), objectId_(-1),
        elementSize_(0)
        { }
};

template <typename Dtype>
class ParamType: public ParamStruct {
public:
    ParamType(int size) {
        elementSize_ = size;
    }
    virtual void forward_process(void);
    virtual void backward_process(void);
};
class ConnectalMemory {
 public:
  ConnectalMemory()
      : buffer_ptr_(NULL), cpu_ptr_(NULL), size_(0), head_(UNINITIALIZED),
        own_cpu_data_(false), controlFd_(-1) {}
  explicit ConnectalMemory(size_t size)
      : buffer_ptr_(NULL), cpu_ptr_(NULL), size_(size), head_(UNINITIALIZED),
        own_cpu_data_(false), controlFd_(-1) {}
  ~ConnectalMemory();
  const void* cpu_data();
  void set_cpu_data(void* data);
  const void* gpu_data() {
      printf("[%s:%d]\n", __FUNCTION__, __LINE__);
      exit(-1);
      return NULL;
  }
  void* mutable_cpu_data();
  void* mutable_gpu_data() {
      printf("[%s:%d]\n", __FUNCTION__, __LINE__);
      exit(-1);
      return NULL;
  }
  enum ConnectalHead { UNINITIALIZED, HEAD_AT_CPU, SYNCED };
  ConnectalHead head() { return head_; }
  size_t size() { return size_; }

 private:
  void to_cpu();
  void to_gpu();
  void* buffer_ptr_;
  void* cpu_ptr_;
  size_t size_;
  ConnectalHead head_;
  bool own_cpu_data_;
  int  controlFd_;
private:
  // Disable the copy and assignment operator for a class.
  ConnectalMemory(const ConnectalMemory&);
  ConnectalMemory& operator=(const ConnectalMemory&);
};  // class ConnectalMemory
void init_connectal_conv_library(int size);
void *connectal_conv_library_param(int size);
void *alloc_portal_memory(size_t size, int cached, int *fdptr);

#ifdef DECLARE_CONNECTAL_CONV
typedef void *(*ALLOCPARAM)(int size);
typedef void *(*ALLOCMEM)(size_t size, int cached, int *fdptr);
static ALLOCPARAM creatme;
static ALLOCMEM pAlloc;
void init_connectal_conv_library()
{
    static void *handle;
    if (!handle) {
        char *libname = getenv("CONNECTAL_CONV_LIBRARY");
        if (!libname) {
            printf("%s: The environment variable CONNECTAL_CONV_LIBRARY must contain the filename of the shared library for connectal conv support\n", __FUNCTION__);
            exit(-1);
        }
        printf("%s: libname is %s\n", __FUNCTION__, libname);
        handle = dlopen(libname, RTLD_NOW);
        if (handle) {
            creatme = (ALLOCPARAM)dlsym(handle,"alloc_connectal_conv");
            pAlloc = (ALLOCMEM)dlsym(handle,"alloc_portalMem");
        }
        else {
           printf("%s: dlopen(%s) failed, %s", __FUNCTION__, libname, dlerror());
           exit(-1);
        }
        if (!creatme || !pAlloc) {
           printf("%s: dlsym('alloc_connectal_conv') failed, %s", __FUNCTION__, dlerror());
           exit(-1);
        }
    }
}
void *connectal_conv_library_param(int size)
{
    init_connectal_conv_library();
    return creatme(size);
}
ConnectalMemory::~ConnectalMemory() {
  if (cpu_ptr_ && own_cpu_data_) {
    free(buffer_ptr_);
    buffer_ptr_ = NULL;
  }
}

inline void ConnectalMemory::to_cpu() {
  switch (head_) {
  case UNINITIALIZED:
    buffer_ptr_ = malloc(size_);
    cpu_ptr_ = buffer_ptr_;
    memset(cpu_ptr_, 0, size_);
    head_ = HEAD_AT_CPU;
    own_cpu_data_ = true;
    break;
  case HEAD_AT_CPU:
  case SYNCED:
    break;
  }
}
const void* ConnectalMemory::cpu_data() {
  to_cpu();
  return (const void*)cpu_ptr_;
}
void ConnectalMemory::set_cpu_data(void* data) {
  CHECK(data);
//printf("[%s:%d] prev %p new %p\n", __FUNCTION__, __LINE__, cpu_ptr_, data);
  if (buffer_ptr_)
    memcpy(data, buffer_ptr_, size_);
  if (own_cpu_data_) {
    free(buffer_ptr_);
    buffer_ptr_ = NULL;
    //close(controlFd_);
  }
  cpu_ptr_ = data;
  head_ = HEAD_AT_CPU;
  own_cpu_data_ = false;
}
void* ConnectalMemory::mutable_cpu_data() {
  to_cpu();
  head_ = HEAD_AT_CPU;
  return cpu_ptr_;
}
void *alloc_portal_memory(size_t size, int cached, int *fdptr)
{
    init_connectal_conv_library();
    return pAlloc(size, cached, fdptr);
}
#endif
#endif // __CONNECTAL_CONV_H__
