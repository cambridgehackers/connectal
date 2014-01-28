// Copyright (c) 2013 Quanta Research Cambridge, Inc.

// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy,
// modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
// BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
// ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <termios.h>
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/select.h> // in MacOSX, poll() does not work with devices!!
#include <dirent.h>
#include <unistd.h>

#ifdef __APPLE__
#define TTYCLASS "tty.usbmodem"
#else
#define TTYCLASS "ttyACM"
#endif

static struct termios orig_terminfo;
static void signal_handler(int signame)
{
    tcsetattr(0, TCSANOW, &orig_terminfo);
    printf("[%s:%d] signal %d\n", __FUNCTION__, __LINE__, signame);
    exit(0);
}

static char buf[1000];
int main(int argc, char **argv)
{
    struct termios terminfo;
    struct sigaction sact;
    int fd = -1;
    int rc;
    fd_set fdset;
    int number_fds = 1;
    int fdlist[2];
    struct timeval timeout;
    int maxfd = 1;
    int fdsindex;

    fdlist[0] = 0; // stdin
    rc = tcgetattr(0, &orig_terminfo);
    sact.sa_handler = signal_handler;
    memset(&sact.sa_mask, 0, sizeof(sact.sa_mask));
    sact.sa_flags = 0;
    rc = sigaction(SIGHUP, &sact, NULL);
    rc |= sigaction(SIGINT, &sact, NULL);
    rc |= sigaction(SIGQUIT, &sact, NULL);
    rc |= sigaction(SIGTERM, &sact, NULL);
    if (rc == -1) {
        printf("[%s:%d] sigaction err %d\n", __FUNCTION__, __LINE__, errno);
        exit(-1);
    }
    rc = tcgetattr(0, &terminfo);
    terminfo.c_lflag &= ~(ICANON | ECHO | ISIG);
    rc = tcsetattr(0, TCSANOW, &terminfo);

    printf("consolable: To exit program, type ctrl-Z\n\n");
    printf("consolable: Waiting for USB device\n");
    while (1) {
        if (fd == -1) {
            struct dirent *direntp;
            DIR *dirptr = opendir("/dev/");
            if (dirptr) {
                while ((direntp = readdir(dirptr))) {
                    if (!strncmp(direntp->d_name, TTYCLASS, strlen(TTYCLASS))) {
                        sprintf(buf, "/dev/%s", direntp->d_name);
                        fprintf(stderr, "consolable: opening %s\n", buf);
                        fd = open(buf, O_RDWR | O_NONBLOCK);
                        fprintf(stderr, "consolable: fd %d\n", fd);
                        break;
                    }
                }
                closedir(dirptr); 
            }
            if (fd >= 0) {
                number_fds = 2;
                printf("consolable: USB device '%s' opened fd=%d\n", buf, fd);
                fdlist[1] = fd;
                maxfd = fd+1;
                rc = tcgetattr(fd, &terminfo);
                terminfo.c_ispeed = B115200;
                terminfo.c_ospeed = B115200;
                rc = tcsetattr(fd, TCSANOW, &terminfo);
            }
        }
        FD_ZERO(&fdset); 
        FD_SET(0, &fdset);
        if (fd != -1)
            FD_SET(fd, &fdset);
        timeout.tv_sec = 0;
        timeout.tv_usec = 300000;
        rc = select(maxfd, &fdset, NULL, NULL, &timeout);
        if (rc > 0) {
            for (fdsindex = 0; fdsindex < number_fds; fdsindex++) {
                if (FD_ISSET(fdlist[fdsindex], &fdset)) {
                    int len = read(fdlist[fdsindex], buf, sizeof(buf));
                    if (len == -1) {
                        if (errno == EWOULDBLOCK)
                            continue;
                        if (fdlist[fdsindex] != 0 && (errno == ENXIO || errno == EBADF)) {
                            printf("consolable: USB device closed\n");
                            number_fds = 1;
                            close(fdlist[fdsindex]);
                            maxfd = 1;
                            fd = -1;
                            fdlist[fdsindex] = -1;
                            continue;
                        }
                        signal_handler(999);
                        exit(-1);
                    }
                    int outfd = 1; // stdout
                    if (fdsindex == 0) {
                        char *p = buf;
                        while (p < &buf[len])
                            if (*p++ == 0x1a) // exit program with ctrl-Z
                                signal_handler(999);
                        if (number_fds > 1)
                            outfd = fdlist[1];
                    }
                    write(outfd, buf, len);
                }
            }
        }
    }
    signal_handler(999);
    return 0;
}
