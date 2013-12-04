#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <assert.h>
#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>

#include <portal.h>

#include "sock_fd.h"
#include "sock_utils.h"

static struct portal p_fd = iport;
static int fd[16];
static unsigned long long *buffer[16];
static int ptr[16];

extern "C" {

  void init_pareff(){

    pthread_t tid;

    struct channel* rc;
    struct channel* wc;

    fprintf(stderr, "BsimDMA::init_pareff()\n");

    rc = &(p_fd.read);
    snprintf(rc->path, sizeof(rc->path), "fd_sock_rc");

    wc = &(p_fd.write);
    snprintf(wc->path, sizeof(wc->path), "fd_sock_wc");

    if(pthread_create(&tid, NULL,  init_socket, (void*)rc)){
      fprintf(stderr, "error creating init thread\n");
      exit(1);
    }

    if(pthread_create(&tid, NULL,  init_socket, (void*)wc)){
      fprintf(stderr, "error creating init thread\n");
      exit(1);
    }

  }

  void write_pareff(unsigned long pref, unsigned long offset, unsigned long long data){
    buffer[pref-1][offset] = data;
    //fprintf(stderr, "write_pareff(%08lx, %08lx, %016llx) [%ld]\n", pref, offset, data, fd[pref]);
  }

  unsigned long long read_pareff(unsigned long pref, unsigned long offset){
    return buffer[pref-1][offset];
  }

  void pareff(unsigned long pref, unsigned long size){
    assert(pref < 16);
    sock_fd_read(p_fd.write.s2, &(fd[pref-1]));
    buffer[pref-1] = (unsigned long long *)mmap(0, size, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, fd[pref-1], 0);
    // fprintf(stderr, "BsimDMA::pareff pref=%ld, buffer=%08lx\n", pref, buffer[pref]);
    ptr[pref-1] = 0;
  }

}
