/* Copyright (c) 2014 Quanta Research Cambridge, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included
 * in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h> 
#include <string.h>
#include <sys/stat.h>
#include <errno.h>
#include <linux/fs.h>
#include <sys/time.h>

#include "ss.h"

extern uint32_t io_time;
extern uint32_t comp_time;


int sw_comp_display (const int fd_dev, const char* pattern, const int blk_ofs, const int blk_len)
{
	printf ("%15d\t%15d\t%15d\n", blk_ofs, blk_ofs + blk_len - 1, blk_len);
	return 0;
}

static uint32_t time_get_timestamp_in_us (void)
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return tv.tv_sec * 1000000 + tv.tv_usec;
}

int sw_comp_4K (const int fd_dev, const char* pattern, const int blk_ofs, const int blk_len)
{
	int match = 0;
	off64_t ofs = 0, len = 0;

	uint32_t start = time_get_timestamp_in_us ();

	ofs = blk_ofs;
	ofs = ofs * BLKSZ;
	if (lseek64 (fd_dev, ofs, SEEK_SET) < 0) {
		fprintf (stderr, "lseek failed: blk_ofs=%d %s\n", blk_ofs, strerror (errno));
		return -1;
	}

	ofs = 0;
	len = blk_len * BLKSZ;
	while (ofs < len) {
		int ret;
		if ((ret = read (fd_dev, blk_buf + ofs, len - ofs)) < 0) {
			printf ("%s\n", strerror (errno));
		}
		ofs += ret;
	}

	io_time += time_get_timestamp_in_us () - start;

	start = time_get_timestamp_in_us ();

	for (ofs = 0; ofs <= len - (off64_t)strlen (pattern); ofs++) {
		if (bcmp (blk_buf + ofs, pattern, strlen (pattern)) == 0) {
			match++;
		}
	}

	comp_time += time_get_timestamp_in_us () - start;

	return match;
}

int sw_comp (const int fd_dev, const char* pattern, const int blk_ofs, const int blk_len)
{
	int match = 0;

	for (int i = blk_ofs; i < blk_ofs + blk_len; i++) {
		match += sw_comp_4K (fd_dev, pattern, i, 1);
	}

	return match;
}

