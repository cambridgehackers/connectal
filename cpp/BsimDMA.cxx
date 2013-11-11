#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/un.h>
#include <pthread.h>
#include <assert.h>


#include "sock_fd.h"
#include "sock_utils.h"

extern "C" {
  void pareff(unsigned long off, unsigned long pref){
    fprintf(stderr, "BsimDMA::pareff(%ld, %ld)", off, pref);
  }
}
