#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/utsname.h>
#include <libgen.h>

#include <ConnectalProjectConfig.h>

#define STR_VALUE_(arg)      #arg
#define STR_VALUE(arg)      STR_VALUE_(arg)

int main(int argc, char * const *argv)
{
    const char *exename = "../test.py";
    char library_path[4096];
    struct utsname utsname;
    struct stat statbuf;
    const char *libdir = "./bin";
    int statok = 0;

    fprintf(stderr, "runpython args: ");
    for (int i = 0; i < argc; i++)
      fprintf(stderr, " %s", argv[i]);
    fprintf(stderr, "\n");
    if (argc > 1) {
	exename = argv[1];
	// What? dirname modifies its argument?
	libdir = dirname(strdup(argv[1]));
    }
    statok = stat("/usr/bin/python", &statbuf);
    uname(&utsname);

    if ((statok != 0)
	&& strcmp(utsname.machine, "armv7l") == 0) {
	strncpy(library_path, "./bin:../lib:.", sizeof(library_path));
	exename = "../bin/python";
    } else {
	strncpy(library_path, libdir, sizeof(library_path));
        strncat(library_path, ":./bin", sizeof(library_path)-strlen(":./bin")-1);
    }
    
    if (getenv("LD_LIBRARY_PATH") != 0) {
        strncat(library_path, ":", sizeof(library_path)-strlen(library_path)-1);
        strncat(library_path, getenv("LD_LIBRARY_PATH"), sizeof(library_path)-strlen(library_path)-1);
    }
    fprintf(stderr, "LD_LIBRARY_PATH: %s\n", library_path);
    setenv("LD_LIBRARY_PATH", library_path, 1);
#ifdef PYTHONPATH
    fprintf(stderr, "PYTHONPATH=%s\n", PYTHONPATH);
    fprintf(stderr, "CONNECTALDIR=%s\n", CONNECTALDIR);
    static char pythonpath[1024];
    snprintf(pythonpath, sizeof(pythonpath), "%s:%s/scripts", PYTHONPATH, CONNECTALDIR);
    fprintf(stderr, "using PYTHONPATH=%s\n", pythonpath);
    setenv("PYTHONPATH", pythonpath, 1);
#endif
    fprintf(stderr, "%s: execv(%s)\n", argv[0], exename);
    return execv(exename, argv);
}
