#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/utsname.h>

int main(int argc, char * const *argv)
{
    const char *exename = "../testecho.py";
    char library_path[4096];
    struct utsname utsname;

    if (argc > 1)
	exename = argv[1];
    uname(&utsname);
    if (strcmp(utsname.machine, "armv7l") == 0) {
	strncpy(library_path, "./bin:../lib:.", sizeof(library_path));
	exename = "../bin/python";
    } else {
	strncpy(library_path, "./bin", sizeof(library_path));
    }
    
    if (getenv("LD_LIBRARY_PATH") != 0) {
        strncat(library_path, ":", sizeof(library_path)-strlen(library_path)-1);
        strncat(library_path, getenv("LD_LIBRARY_PATH"), sizeof(library_path)-strlen(library_path)-1);
    }
    fprintf(stderr, "LD_LIBRARY_PATH: %s\n", library_path);
    setenv("LD_LIBRARY_PATH", library_path, 1);
    fprintf(stderr, "%s: execv(%s)\n", argv[0], exename);
    return execv(exename, argv);
}
