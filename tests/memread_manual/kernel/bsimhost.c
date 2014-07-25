
#include <stdio.h>
#include <fcntl.h>
#include <sys/select.h>

#include "sock_utils.h"
#include "portal.h"

static void memdump(unsigned char *p, int len, char *title)
{
int i;

    i = 0;
    while (len > 0) {
        if (!(i & 0xf)) {
            if (i > 0)
                printf("\n");
            printf("%s: ",title);
        }
        printf("%02x ", *p++);
        i++;
        len--;
    }
    printf("\n");
}

int main(int argc, char *argv[])
{
struct memrequest req;
int rc;

printf("[%s:%d] start\n", __FUNCTION__, __LINE__);
    int fd = open("/dev/xbsvtest", O_RDWR);
    if (fd == -1) {
        printf("bsimhost: /dev/xbsvtest not found\n");
        return -1;
    }
    while ((rc = read(fd, &req, sizeof(req)))) {
        if (rc == -1) {
            struct timeval timeout;
            timeout.tv_sec = 0;
            timeout.tv_usec = 10000;
            select(0, NULL, NULL, NULL, &timeout);
            continue;
        }
        printf("[%s:%d] rc = %d.\n", __FUNCTION__, __LINE__, rc);
        memdump((unsigned char *)&req, sizeof(req), "RX");
    }
printf("[%s:%d] over\n", __FUNCTION__, __LINE__);
    return 0;
}
