#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char * const *argv)
{
    const char *exename = "../testecho.py";
    char library_path[4096];
    if (argc > 1)
	exename = argv[1];
#if (OS == android)
    strncpy(library_path, "./bin:../lib:.", sizeof(library_path));
    exename = "../bin/python";
#else
    strncpy(library_path, "./bin", sizeof(library_path));
#endif
    if (getenv("LD_LIBRARY_PATH")) {
        strncat(library_path, ":", sizeof(library_path));
        strncat(library_path, getenv("LD_LIBRARY_PATH"), sizeof(library_path));
    }
    fprintf(stderr, "LD_LIBRARY_PATH: %s\n", library_path);
    setenv("LD_LIBRARY_PATH", library_path, 1);
    fprintf(stderr, "%s: execv(%s)\n", argv[0], exename);
    return execv(exename, argv);
}
