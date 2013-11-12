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
static int pa_fd[16];
static unsigned long long *buffer[16];
static int ptr[16];

extern "C" {

  void init_pareff(){

    pthread_t tid;

    struct channel* rc;
    struct channel* wc;

    fprintf(stderr, "BsimDMA::init_pareff()");

    rc = &(p_fd.read);
    snprintf(rc->path, sizeof(rc->path), "/tmp/fd_sock_rc");

    wc = &(p_fd.write);
    snprintf(wc->path, sizeof(wc->path), "/tmp/fd_sock_wc");

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
    buffer[pref][offset] = data;
  }

  void pareff(unsigned long off, unsigned long pref){
    assert(off < 16);
    assert(pref < 16);
    assert(off == pref);

    sock_fd_read(p_fd.write.s2, &pa_fd[off]);
    buffer[off] = (unsigned long long *)mmap(0, 1024, PROT_WRITE|PROT_WRITE|PROT_EXEC, MAP_SHARED, pa_fd[off], 0);
    ptr[off] = 0;
    fprintf(stderr, "BsimDMA::pareff off=%ld, pref=%ld, fd=%08x, buffer=%08lx\n", off, pref, p_fd.write.s2, buffer[off]);
  }

}
