#include <stdio.h>
#include <sys/mman.h>
#include <sys/wait.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <semaphore.h>
#include <monkit.h>

#include "testmemwrite.h"

int main(int argc, const char **argv)
{
  int sv[2];
  int pid;
  int status;
  
  if (socketpair(AF_LOCAL, SOCK_STREAM, 0, sv) < 0) {
    perror("error: socketpair");
    exit(1);
  }
  switch ((pid = fork())) {
  case 0:
    close(sv[0]);
    child(sv[1]);
    break;
  case -1:
    perror("error: fork");
    exit(1);
  default:
    parent(sv[1],sv[0]);
    waitpid(pid, &status, 0);
    break;
  }
  exit(status);
}
