#include <stdlib.h>
#include <unistd.h>

int main(int argc, char * const *argv)
{
    setenv("LD_LIBRARY_PATH", "./bin", 1);
    return execv("../testecho.py", argv);
}
