
#include <linux/ioctl.h>
#include <sys/ioctl.h>

#include "portal.h"

class Directory : public Portal
{
public:
  Directory(const char* devname, unsigned int addrbits) : Portal(devname,addrbits){}
  int print(){
    fprintf(stderr, "Directory::print(%s)\n", name);
    int rc = ioctl(this->fd, PORTAL_PRINT_DIRECTORY, (long)NULL);
    return rc;
  }
};
