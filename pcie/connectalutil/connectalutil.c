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

static void print_usage(const char* argv0)
{
  char* argv0_copy = strdup(argv0);
  char* pgm = basename(argv0_copy);

  printf("Usage: %s help\n", pgm);
  printf("       %s info    [ <file1> [ .. <fileN> ] ]\n", pgm);
  printf("       %s build   [ <file1> [ .. <fileN> ] ]\n", pgm);
  printf("       %s reset   [ <file1> [ .. <fileN> ] ]\n", pgm);
  printf("       %s portal  \n", pgm);
  printf("       %s tlp  \n", pgm);
  printf("       %s trace  \n", pgm);
  printf("       %s notrace  \n", pgm);
  printf("       %s mmap  \n", pgm);
  printf("\n");
  printf("Modes:\n");
  printf("  help    - Print usage information and exit.\n");
  printf("  info    - Describe the BlueNoC target(s).\n");
  printf("  build   - Display the Build number.\n");
  printf("  reset   - Reset the portals.\n");
  printf("  portal  - Describe the portal target(s).\n");
  printf("\n");
  printf("File arguments:\n");
  printf("  <file> - Operate only on the named file.\n");
  printf("\n");
  printf("Multiple files can be supplied as arguments.\n");
  printf("If no file argument is supplied, the tool will search for BlueNoC\n");
  printf("targets and operate on all of them it finds.\n");
  printf("\n");
  printf("If no mode is specified, it defaults to 'info', so the command\n");
  printf("'%s' by itself is equivalent to '%s info' (it will search out\n", pgm, pgm);
  printf("and describe all BlueNoC targets).");
  printf("\n");
  printf("Profiling commands:\n");
  printf("  start   - Begin collecting profiling data.\n");
  printf("  stop    - Stop collecting profiling data and write accumulated data\n");
  printf("            to the kernel log.\n");
  printf("\n");

  free(argv0_copy);
}

typedef enum { HELP, INFO, PORTAL, TLP, TRACE, NOTRACE, MMAP } tMode;

static int is_bluenoc_file(const struct dirent* ent)
{
  if (strncmp(ent->d_name,"fpga",4) == 0)
    return 1;
  else
    return 0;
}

static int process(const char* file, tMode mode, unsigned int strict)
{
  int ret = 0;
  tBoardInfo board_info;
  int res;
  int fd = open(file,O_RDONLY);

  if (fd == -1) {
    if (strict) {
      perror(file);
      return -1;
    }
    return 0;
  }

  res = ioctl(fd,BNOC_IDENTIFY,&board_info);
  if (res == -1) {
    if (strict) {
      perror("identify ioctl");
      ret = -1;
    }
    goto exit_process;
  }

  switch (mode) {
    case INFO: {
      printf("Found BlueNoC device at %s\n", file);
      printf("  Board number:     %d\n", board_info.board_number);
      printf("  Portal number:    %d\n", board_info.portal_number);
      ret = 1;
      break;
    }
  case PORTAL: {
    tPortalInfo portal_info;
    int res = ioctl(fd,BNOC_IDENTIFY_PORTAL,&portal_info);
    if (res == -1) {
      if (strict) {
	perror("identify_portal ioctl");
	ret = -1;
      }
      goto exit_process;
    }
    printf("  Portal interrupt_status %x\n", portal_info.interrupt_status);
    printf("  Portal interrupt_enable %x\n", portal_info.interrupt_enable);
    printf("  Portal indication_channel_count %x\n", portal_info.indication_channel_count);
    printf("  Portal base_fifo_offset %x\n", portal_info.base_fifo_offset);
    printf("  Portal request_fired_count %x\n", portal_info.request_fired_count);
    printf("  Portal response_fired_count %x\n", portal_info.response_fired_count);
    printf("  Portal magic %x\n", portal_info.magic);
    printf("  Portal put_word_count %x\n", portal_info.put_word_count);
    printf("  Portal get_word_count %x\n", portal_info.get_word_count);
    printf("  Portal fifo_status %x\n", portal_info.fifo_status);
    break;
  }
  case TLP: {
    tTraceInfo traceInfo;
    //int seqno = 0;
    int res, i, j;

    // disable tracing
    traceInfo.trace = 0;
    res = ioctl(fd,BNOC_TRACE,&traceInfo);
    // set pointer to 0
    //res = ioctl(fd,BNOC_SEQNO,&seqno);
    for (i = 0; i < sizeof(traceInfo); i++)
      printf("%08x", ((unsigned int *)&traceInfo)[i]);
    printf("\n");

    for (i = 0; i < traceInfo.traceLength; i++) {
      tTlpData tlp;
      memset(&tlp, 0x5a, sizeof(tlp));
      res = ioctl(fd,BNOC_GET_TLP,&tlp);
      if (res == -1) {
	if (strict) {
	  perror("get_tlp ioctl");
	  ret = -1;
	}
	goto exit_process;
      }
      for (j = 5; j >= 0; j--)
        printf("%08x", ((unsigned int*)&tlp)[j]);
      printf("\n");
    }
    i = 1;
    res = ioctl(fd,BNOC_ENABLE_TRACE,&i);
  } break;
  case TRACE: {
    tTraceInfo traceInfo = { trace: 1 };
    int res = ioctl(fd,BNOC_TRACE,&traceInfo);
    printf("old trace=%d traceLength=%d\n", traceInfo.trace, traceInfo.traceLength);
  } break;
  case NOTRACE: {
    tTraceInfo traceInfo = { trace: 0 };
    int res = ioctl(fd,BNOC_TRACE,&traceInfo);
    printf("old trace=%d traceLength=%d\n", traceInfo.trace, traceInfo.traceLength);
  } break;
  case MMAP: {
    int *portal = (int *)mmap(NULL, 1<<16, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
    int *regbase = (int *)(((unsigned long)portal) + (1<<14));
    if ((void*)-1 == portal) {
      printf("failed to map portal %d:%s\n", errno, strerror(errno));
    }
    printf("mmap portal=%p -1-\n", portal);
    if (1) {
      printf("%x %x\n", portal[0], portal[1]);
      portal[0] = 0x0000f00d;
      printf("portal[16]=%08x\n", portal[16]);
      portal[128] = 0xdeadbeef;
      printf("portal[256]=%08x\n", portal[256]);
    }
    if (1) {
      fprintf(stderr, "should be 6847xxxx = %x\n", *(int *)(((unsigned long)portal) + (1 << 15) + (1<<14) + 0x10));
      fprintf(stderr, "should be bad0dada = %x\n", *(int *)(((unsigned long)portal) + (1 << 15) + (0<<14) + 0x00));
      fprintf(stderr, "should be 05a005a0 = %x\n", *(int *)(((unsigned long)portal) + (0 << 15) + (1<<14) + 0x00));
      fprintf(stderr, "should be bad07ead = %x\n", *(int *)(((unsigned long)portal) + (0 << 15) + (0<<14) + 0x00));
      fprintf(stderr, "regbase[0] = %x\n", regbase[0]);
    }
  } break;
  }

 exit_process:
  close(fd);
  return ret;
}

int main(int argc, char* const argv[])
{
  int opt;
  tMode mode = INFO; /* not a recognized mode, assume it is a file name, and use INFO mode */
  int ret;
  int process_failed = 0;

  while (1) {
    opt = getopt(argc, argv, "+h");
    if (opt == -1) break;
    else if ((opt == '?') || (opt == ':') || (opt == 'h')) {
      print_usage(argv[0]);
      exit(opt == 'h' ? 0 : 1);
    }
  };

  /* determine the execution mode */
  if (optind == argc) {
    mode = INFO; /* no argument -- implies INFO */
  } else if (strcmp("help",argv[optind]) == 0) {
    mode = HELP;
  } else if (strcmp("info",argv[optind]) == 0) {
    mode = INFO;
    optind += 1;
  } else if (strcmp("portal",argv[optind]) == 0) {
    mode = PORTAL;
    optind += 1;
  } else if (strcmp("tlp",argv[optind]) == 0) {
    mode = TLP;
    optind += 1;
  } else if (strcmp("trace",argv[optind]) == 0) {
    mode = TRACE;
    optind += 1;
  } else if (strcmp("notrace",argv[optind]) == 0) {
    mode = NOTRACE;
    optind += 1;
  } else if (strcmp("mmap",argv[optind]) == 0) {
    mode = MMAP;
    optind += 1;
  }

  /* execute the requested action */

  if (mode == HELP) {
    print_usage(argv[0]);
    exit(0);
  }

  if (optind == argc) {
    /* no file arguments given, so look for all /dev/fpga* */
    struct dirent **eps;
    int res;

    res = scandir ("/dev", &eps, is_bluenoc_file, alphasort);
    if (res < 0) {
      perror("Couldn't open the /dev directory");
      exit(1);
    }
    else if (res == 0) {
      printf("No BlueNoC targets found.\n");
    }
    else {
      int cnt;
      char* filename = NULL;
      unsigned int len = 0;
      for (cnt = 0; cnt < res; ++cnt) {
        unsigned int l = 6 + strlen(eps[cnt]->d_name);
        if (l > len) {
          if (filename != NULL) free(filename);
          filename = (char*) malloc(l);
          if (filename == NULL) {
            perror("Failed to allocate file name memory");
            exit(1);
          }
          len = l;
        }
        strcpy(filename, "/dev/");
        strcpy(filename+5, eps[cnt]->d_name);
        process_failed |= (process(filename,mode,0) == -1);
      }
      if (filename != NULL) free(filename);
    }
  }
  else {
    unsigned int n;
    /* only operate on the given file arguments */
    for (n = optind; n < argc; ++n)
      process_failed |= (process(argv[n],mode,1) == -1);
  }

  exit(process_failed ? 1 : 0);
}
