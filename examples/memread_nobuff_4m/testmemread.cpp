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
  runtest(argc, argv);
  exit(mismatchCount ? 1 : 0);
}
