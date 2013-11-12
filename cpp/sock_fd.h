#ifndef __SOCK_FD_H__
#define __SOCK_FD_H__

ssize_t sock_fd_write(int sock, int fd);
ssize_t sock_fd_read(int sock, int *fd);


#endif
