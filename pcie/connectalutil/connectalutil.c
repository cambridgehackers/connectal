#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <getopt.h>
#include <string.h>
#include <libgen.h>
#include <dirent.h>
#include <time.h>
#include <sys/mman.h>
#include <errno.h>
#include <stdint.h>

#include "../../drivers/pcieportal/pcieportal.h"

tTraceInfo traceInfo;

int main(int argc, char* const argv[])
{
  int ret = 0;
  int fd = open("/dev/portal0",O_RDONLY);

  if (fd == -1) {
printf("[%s:%d] error opening /dev/portal0\n", __FUNCTION__, __LINE__);
      return -1;
  }

    int res, i, j;

    res = ioctl(fd,BNOC_TRACE,&traceInfo);
    for (i = 0; i < sizeof(traceInfo); i++)
      printf("%08x", ((unsigned int *)&traceInfo)[i]);
    printf("\n");

    for (i = 0; i < traceInfo.traceLength; i++) {
      tTlpData tlp;
      memset(&tlp, 0x5a, sizeof(tlp));
      res = ioctl(fd,BNOC_GET_TLP,&tlp);
      if (res == -1) {
	  perror("get_tlp ioctl");
	  ret = -1;
	goto exit_process;
      }
      for (j = 5; j >= 0; j--)
        printf("%08x", ((unsigned int*)&tlp)[j]);
      printf("\n");
    }
    i = 1;
    res = ioctl(fd,BNOC_ENABLE_TRACE,&i);

 exit_process:
  exit(ret ? 1 : 0);
}
