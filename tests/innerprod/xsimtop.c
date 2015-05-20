#include "svdpi.h"
#include <stdio.h>

int dpi_msgSink_beat()
{
  fprintf(stderr, "dpi_msgSink_beat() called\n");
  return 0xbad0da7a;
}
int dpi_msgSink_src_rdy_b()
{
  fprintf(stderr, "dpi_msgSink_src_rdy_b() called\n");
  return 0;
}

void dpi_msgSource_beat(int v)
{
  fprintf(stderr, "dpi_msgSource_beat() called v=%08x\n", v);
}
int dpi_msgSource_dst_rdy_b()
{
  fprintf(stderr, "dpi_msgSource_dst_rdy_b() called\n");
  return 1;
}
