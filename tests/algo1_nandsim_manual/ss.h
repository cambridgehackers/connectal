#ifndef _STRING_SEARCH_H
#define _STRING_SEARCH_H

#define MAX_FIBBLKS 32768
#define BLKSZ 4096
#define SECSZ 512

extern uint8_t* blk_buf;
typedef int (*compr_func)(const int fd_dev, const char* pattern, const int start_blk, const int len);

int sw_comp (const int fd_dev, const char* pattern, const int start_blk, const int blks);
int hw_init (char* needle_text);
int hw_destroy (void);
int hw_comp (const int fd_dev, const char* pattern, const int start_blk, const int blks);

#endif
