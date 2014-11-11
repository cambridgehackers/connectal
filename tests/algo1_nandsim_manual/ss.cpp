#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h> 
#include <errno.h>
#include <dirent.h>
#include <fcntl.h>
#include <linux/limits.h>
#include <linux/hdreg.h>
#include <linux/fs.h>
#include <sys/stat.h>
#include <sys/ioctl.h> 
#include <blkid/blkid.h>

#include "ss.h"

#include "StdDmaIndication.h"
#include "MMURequest.h"
#include "GeneratedTypes.h" 
#include "NandSimIndication.h"
#include "NandSimRequest.h"
#include "StrstrIndication.h"
#include "StrstrRequest.h"

uint32_t io_time = 0;
uint32_t comp_time = 0;

static int trace_memory = 0;

uint8_t* blk_buf = NULL;

int __get_dev_start_ofs (char* devname)
{
	int fd;
	struct hd_geometry geo;

	if ((fd = open (devname, O_RDONLY | O_NONBLOCK)) < 0) {
		return -1;
	}

	if ((ioctl (fd, HDIO_GETGEO, &geo)) < 0) {
		close (fd);
		return -1;
	}

	close (fd);

	return geo.start;
}

void __fibmap_display_file (const char* fname) 
{
	struct stat st;
	int fd, nr_blks, blksz, i, ret;

	char* devname = NULL;
	int dev_start_blk = 0;

	int spb = 0;
	int start_blk = -1;
	int len = 1;

#define TOLBA(spb, blk_no) (spb * blk_no)

	if ((fd = open (fname, O_RDONLY | O_DIRECT | O_SYNC)) < 0) {
		fprintf (stderr, "Cannot open %s: %s\n", fname, strerror (errno));
		return;
	}

	/* get the block size */
	if ((ret = ioctl (fd, FIGETBSZ, &blksz)) < 0) {
		fprintf (stderr, "Cannot get block size of %s: %s\n", fname, strerror (errno));
		close (fd);
		return;
	}

	/* get fstat */
	if ((ret = fstat (fd, &st)) < 0) {
		fprintf (stderr, "Cannot fstat %s: %s\n", fname, strerror (errno));
		close(fd);
		return;
	}

	/* get the device name */
	devname = blkid_devno_to_devname (st.st_dev);

	/* get the start offset of the device */
	dev_start_blk = __get_dev_start_ofs (devname);

	printf ("\n");
	printf ("%s:\n", devname);
	printf ("start LBA = %d\n", dev_start_blk);
	printf ("\n");

	/* get # of blks for a file */
	nr_blks = (st.st_size + blksz - 1) / blksz;
	spb = blksz / SECSZ;

	printf ("%s:\n", fname);
	printf ("# of blocks(4KB)/sectors(512B): %d/%d\n", nr_blks, nr_blks * spb);
	printf ("\n");

	printf ("-----------------------------------------------\n");
	printf ("%15s\t%15s\t%15s\n", "begin_LBA", "end_LBA", "sectors");

	for (i = 0; i < nr_blks; i++) {
		int lba = i;

		if ((ret = ioctl (fd, FIBMAP, &lba)) < 0) {
			fprintf (stderr, "ioctl on %s failed: %s\n", fname, strerror (errno));
			close (fd);
			return;
		}

		if (start_blk == -1) {
			start_blk = lba;
			len = 1;
		} else if (len == MAX_FIBBLKS) {
			printf ("%15d\t%15d\t%15d\n", 
				TOLBA(spb, start_blk) + dev_start_blk,
				TOLBA(spb, start_blk) + TOLBA(spb, len) + dev_start_blk - 1,
				TOLBA(spb, len));
			start_blk = lba;
			len = 1;
		} else if (lba == start_blk + len) {
			len++;
		} else {
			printf ("%15d\t%15d\t%15d\n", 
				TOLBA(spb, start_blk) + dev_start_blk,
				TOLBA(spb, start_blk) + TOLBA(spb, len) + dev_start_blk - 1,
				TOLBA(spb, len));
			start_blk = lba;
			len = 1;
		}
	}

	printf ("%15d\t%15d\t%15d\n", 
		TOLBA(spb, start_blk) + dev_start_blk,
		TOLBA(spb, start_blk) + TOLBA(spb, len) + dev_start_blk - 1,
		TOLBA(spb, len));

	close (fd);
}

int __fibmap_search_file (const char* pattern, const char* fname, compr_func fp_comp)
{
	struct stat st;
	int fd, fd_dev, nr_blks, blksz, i, ret;
	char* devname = NULL;
	int start_blk = -1;
	int len = 1;
	int match = 0;

	if ((fd = open (fname, O_RDONLY)) < 0) {
		fprintf (stderr, "Cannot open %s: %s\n", fname, strerror (errno));
		return -1;
	}

	/* get the block size */
	if ((ret = ioctl (fd, FIGETBSZ, &blksz)) < 0) {
		fprintf (stderr, "Cannot get block size of %s: %s\n", fname, strerror (errno));
		close (fd);
		return -1;
	}

	/* get fstat */
	if ((ret = fstat (fd, &st)) < 0) {
		fprintf (stderr, "Cannot fstat %s: %s\n", fname, strerror (errno));
		close (fd);
		return -1;
	}

	/* get the device name */
	devname = blkid_devno_to_devname (st.st_dev);

	if ((fd_dev = open64 (devname, O_RDONLY | O_DIRECT)) < 0) {
		fprintf (stderr, "Cannot open %s: %s\n", devname, strerror (errno));
		close (fd);
		return -1;
	}

	/* get # of blks for a file */
	nr_blks = (st.st_size + blksz - 1) / blksz;

	/* if 'nr_blks' is 0, return 0 */
	if (nr_blks == 0) {
		close (fd);
		close (fd_dev);
		return 0;
	}

	for (i = 0; i < nr_blks; i++) {
		int lba = i;

		if ((ret = ioctl (fd, FIBMAP, &lba)) < 0) {
			fprintf (stderr, "ioctl on %s failed: %s\n", fname, strerror (errno));
			close (fd);
			close (fd_dev);
			return -1;
		}

		if (start_blk == -1) {
			start_blk = lba;
			len = 1;
		} else if (len == 32768) {
			if ((ret = fp_comp (fd_dev, pattern, start_blk, len)) < 0) {
				printf ("fp_comp failed: %s %s %s %d %d\n", fname, devname, pattern, start_blk, len);
				ret = 0;
			}
			match += ret;
			start_blk = lba;
			len = 1;
		} else if (lba == start_blk + len) {
			len++;
		} else {
			if ((ret = fp_comp (fd_dev, pattern, start_blk, len)) < 0) {
				printf ("fp_comp failed: %s %s %s %d %d\n", fname, devname, pattern, start_blk, len);
				ret = 0;
			}
			match += ret;
			start_blk = lba;
			len = 1;
		}
	}

	if ((ret = fp_comp (fd_dev, pattern, start_blk, len)) < 0) {
		printf ("fp_comp failed: %s %s %s %d %d\n", fname, devname, pattern, start_blk, len);
		ret = 0;
	}
	match += ret;

	close (fd);
	close (fd_dev);

	return match;
}

/* search the pattern in a single file */
int __fs_search_file (const char* pattern, const char* fname) 
{
	FILE* fp = NULL;
	uint8_t* buf = NULL;
	struct stat st;
	off_t len;
	int match = 0;

	if ((fp = fopen (fname, "r")) == NULL) {
		printf ("errors occur while opening a file (%s) (errno=%s)\n", fname, strerror (errno));
		return -1;
	}

	if (fstat (fp->_fileno, &st)) {
		printf ("errors occur while getting the size of a file (errno=%d)\n", errno);
		fclose (fp);
		return -1;
	}

	if ((off_t)strlen (pattern) > st.st_size) {
		fclose (fp);
		return 0;
	}

	/* time taken to read a file */
	if ((buf = (uint8_t*)malloc (sizeof (uint8_t) * st.st_size)) == NULL) {
		fclose (fp);
		return -1;
	}

	for (len = 0; len < st.st_size; ) {
		len += fread (buf + len, 1, st.st_size - len, fp);
	}

	/* time taken to find a pattern */
	for (len = 0; len <= st.st_size - (off_t)strlen (pattern); len++) {
		if (bcmp (buf + len, pattern, strlen (pattern)) == 0) {
			match++;
		}
	}

	if (buf)
		free (buf);

	if (fp)
		fclose (fp);

	return match;
}

#define DISPLAY_FILE

/* NOTE: options
 * - __fibmap_display_file: it is the same as hdparam --fibmap 
 * - __fibmap_search_file: search patterns using FIBMAP by SW or HW
 * - __fs_search_file: search patterns using FS
 */
int search_pattern_file (const char* pattern, const char* fname) 
{
	int match = 0;
	
#ifdef DISPLAY_FILE
	printf ("%s\n", fname);
#endif

	/*__fibmap_display_file (fname); *//* same as hdparam --fibmap */
	//match = __fibmap_search_file (pattern, fname, sw_comp);
	match = __fibmap_search_file (pattern, fname, hw_comp);
	//match = __fs_search_file (pattern, fname);

	return match;
}

int search_pattern_directory (const char* pattern, const char* fname, int lvl)
{
	DIR* d_fh = NULL;
	struct dirent* entry = NULL;
	char longest_name[PATH_MAX+1];
	int match = 0;
	int ret;

#ifdef DISPLAY_FILE
	printf ("%s\n", fname);
#endif

	if ((d_fh = opendir (fname)) == NULL) {
		if (errno == ENOTDIR) {
			/* if 'fname' is a normal file, then we run search_pattern_file */
			if ((ret = search_pattern_file (pattern, fname)) == -1) {
				fprintf (stderr, "Couldn't search a file %s: %s\n", longest_name, strerror (errno));
				exit (-1);
			} 
			match += ret;
			return match;
		} else {
			fprintf (stderr, "Couldn't open directory: %s (%d)\n", fname, errno);
			exit (-1);
		}
	}

	while ((entry = readdir (d_fh)) != NULL) {
		/* exclude a current directory & a previous directory */
		if (strlen (entry->d_name) == 2 && strncmp (entry->d_name, "..", 2) == 0)
			continue;

		if (strlen (entry->d_name) == 1 && strncmp (entry->d_name, ".", 1) == 0)
			continue;

		/* make a full name */
		strncpy (longest_name, fname, PATH_MAX);
		if (longest_name[strlen(longest_name)-1] != '/')
			strncat (longest_name, "/", PATH_MAX);
		strncat (longest_name, entry->d_name, PATH_MAX);

		if (entry->d_type == DT_DIR) {
			if ((ret = search_pattern_directory (pattern, longest_name, lvl + 1)) == -1) {
				fprintf (stderr, "Couldn't search a directory %s: %s\n", longest_name, strerror (errno));
				exit (-1);
			}
			match += ret;
		} else {
			if ((ret = search_pattern_file (pattern, longest_name)) == -1) {
				fprintf (stderr, "Couldn't search a file %s: %s\n", longest_name, strerror (errno));
				exit (-1);
			} 
			match += ret;
		}
	}

	closedir (d_fh);

	return match;
}

/* parse input arguments */
int parse_args (int argc, char** argv, char** pattern, char** fname)
{
	if (argc == 3) {
		*pattern = argv[1];
		*fname = argv[2];
		return 0;
	}
	return 1;
}

/* entry point */
int main (int argc, char** argv)
{
	char* pattern = NULL;
	char* fname = NULL;
	int ret = 0;

	if (parse_args (argc, argv, &pattern, &fname)) {
		fprintf (stderr, "Usage: ss PATTERN FILE\n");
		exit (-1);
	}

	if ((blk_buf = (uint8_t*)malloc (MAX_FIBBLKS * BLKSZ)) == NULL) {
		fprintf (stderr, "Cannot allocate memory for reading files: %s\n", strerror (errno));
		exit (-1);
	}

	hw_init (pattern);

	ret = search_pattern_directory (pattern, fname, 0);

	printf ("%d (%u) (%u)\n", ret, io_time, comp_time);

	hw_destroy ();

	if (blk_buf) {
		free (blk_buf);
	}

	return ret;
}

