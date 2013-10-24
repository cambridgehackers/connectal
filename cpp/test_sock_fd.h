#include "sock_fd_test.h"

void
child(int sock)
{
    int fd;
    char    buf[16];
    ssize_t size;

    sleep(1);
    for (;;) {
        size = sock_fd_read(sock, buf, sizeof(buf), &fd);
        if (size <= 0)
            break;
        printf ("read %d\n", size);
        if (fd != -1) {
            write(fd, "hello, world\n", 13);
            close(fd);
        }
    }
}

void
parent(int sock)
{
    ssize_t size;
    int i;
    int fd;

    fd = 1;
    char buf[] = "1";
    size = sock_fd_write(sock, (void*)buf, 1, fd);
    printf ("wrote %d\n", size);
}

int
main(int argc, char **argv)
{
    int sv[2];
    int pid;

    if (socketpair(AF_LOCAL, SOCK_STREAM, 0, sv) < 0) {
        perror("socketpair");
        exit(1);
    }
    switch ((pid = fork())) {
    case 0:
        close(sv[0]);
        child(sv[1]);
        break;
    case -1:
        perror("fork");
        exit(1);
    default:
        close(sv[1]);
        parent(sv[0]);
        break;
    }
    return 0;
}
