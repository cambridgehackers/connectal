// Copyright (c) 2016 Bluespec, Inc.  All Rights Reserved.

// This is a boilerplate 'main' to drive a Bluesim executable without
// using the BlueTcl top-level that bsc normally generates.

// Example:
// Suppose your top-level BSV file is Foo.bsv, with top-level module mkFoo
// Compile and link the top-level BSV as usual, e.g.,:
//    bsc -sim -u Foo.bsv
//    bsc -sim -e mkFoo
// This will produce the usual Bluetcl-based executable (a.out and a.out.so)
// but it will also produce:
//    mkFoo.{h,cxx,o}
//    model_mkFoo.{h,cxx,o}
//    (and of course similar files for any other imported BSV modules)
// Then, compile and link this file with those .o's, like this Makefile target
//
//     CXXFAMILY=g++4                // for 32-bit platforms
//     CXXFAMILY=g++4_64             // for 64-bit platforms
//
//     $(EXE): model_$(TOPMOD).o $(TOPMOD).o
//             c++ -O3                                \
//                 bluesim_main.cxx                        \    // This file
//                 -o $@                                   \    // Your final executable
//                 -I.                                     \    // bsc-generated .h files, project .h files
//                 -I$(BLUESPECDIR)/Bluesim                \    // Dir for Bluespec release .h files
//                 -L$(BLUESPECDIR)/Bluesim/$(CXXFAMILY)   \    // Dir Bluespec release libs
//                 $^                                      \    // all your .o's
//                 -lbskernel -lbsprim -lpthread                // libs

#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include "bluesim_kernel_api.h"

// #include MODEL_MKFOO_H
#include "model_mkXsimTop.h"

// ================================================================
// Process command line args

static char default_vcd_filename [] = "dump.vcd";
static char *vcd_filename = NULL;    // Valid if not NULL

static tUInt64  count = 0;           // Valid if positive

static
void process_command_line_args (int argc, char *argv [])
{
    // Check for -h (help)
    for (int j = 0; j < argc; j++) {
	if (strcmp (argv [j], "-h") == 0) {
	    fprintf (stderr, "Usage: %s [opts]\n", argv [0]);
	    fprintf (stderr, "Options:\n");
	    fprintf (stderr, "  -h            = print help and exit\n");
	    fprintf (stderr, "  -m <N>        = execute for N cycles\n");
	    fprintf (stderr, "  -V [<file>]   = dump waveforms to VCD file (default: dump.vcd)\n");
	    fprintf (stderr, "\n");
	    fprintf (stderr, "Examples:\n");
	    fprintf (stderr, "  %s\n", argv [0]);
	    fprintf (stderr, "  %s -m 3000\n", argv [0]);
	    fprintf (stderr, "  %s -V sim.vcd\n", argv [0]);
	    exit (1);
	}
    }

    // Check for -V or -V vcd_filename in command-line args
    for (int j = 0; j < argc; j++) {
	if (strcmp (argv [j], "-V") == 0) {
	    if (j == (argc - 1))
		vcd_filename = & (default_vcd_filename [0]);
	    else if (argv [j+1][0] != '-')
		vcd_filename = argv [j+1];
	    break;
	}
    }

    // Check for -m <N> flag (execute for N cycles)
    long int n = -1;
    for (int j = 0; j < argc; j++) {
	if (strcmp (argv [j], "-m") == 0) {
	    if (j == (argc - 1)) {
		fprintf (stderr, "Command-line error: -m flag must be followed by a positive integer\n");
		exit (1);
	    }
	    errno = 0;
	    n = strtol (argv [j+1], NULL, 0);
	    if ((errno != 0) || (n < 1)) {
		fprintf (stderr, "Command-line error: -m flag must be followed by a positive integer\n");
		exit (1);
	    }
	    count = n;
	    break;
	}
    }
}

// ================================================================

int main (int argc, char *argv[])
{
    process_command_line_args (argc, argv);

    // tModel model = NEW_MODEL_MKFOO ();
    tModel model = new_MODEL_mkXsimTop();

#ifdef BSC_OBSOLETE
    tSimStateHdl sim = bk_init (model, true, false);
#else
    tSimStateHdl sim = bk_init (model, true);
#endif

    if (vcd_filename != NULL) {
	tStatus status = bk_set_VCD_file (sim, vcd_filename);
	if (status == BK_ERROR) {
	    fprintf (stderr, "Error: Could not open file for VCD output: %s\n", vcd_filename);
	    exit (1);
	}
	tBool b = bk_enable_VCD_dumping (sim);
	if (b == 0) {
	    fprintf (stderr, "Error: Could not enable VCD dumping in file: %s\n", vcd_filename);
	    exit (1);
	}
	fprintf (stdout, "Enabled VCD dumping to file %s\n", vcd_filename);
    }

    if (count > 0) {
	tClock clk = 0;
	tEdgeDirection dir = POSEDGE;
	bk_quit_after_edge (sim, clk, dir, count);
	fprintf (stdout, "Will stop after %0lld clocks\n", count);
    }

    bk_advance (sim, false);

    bk_shutdown (sim);

    if (count > 0) {
	fprintf (stdout, "Stopped after %0lld clocks\n", count);
    }
}
