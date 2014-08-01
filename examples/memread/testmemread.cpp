#include <stdio.h>
#include <sys/mman.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <pthread.h>
#include <monkit.h>

#include "testmemread.h"

int main(int argc, const char **argv)
{
  int ret = runtest(argc, argv);
  exit(ret ? 1 : 0);
}
