#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "portal.h"
#include "dmaManager.h"
#include "NandCfgRequest.h"
#include "NandCfgIndication.h"

class NandCfgIndication : public NandCfgIndicationWrapper
{
public:
  unsigned int rDataCnt;
  virtual void readDone(uint32_t v){
    fprintf(stderr, "NandSim::readDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void writeDone(uint32_t v){
    fprintf(stderr, "NandSim::writeDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void eraseDone(uint32_t v){
    fprintf(stderr, "NandSim::eraseDone v=%x\n", v);
    sem_post(&sem);
  }
  virtual void configureNandDone(){
    fprintf(stderr, "NandSim::configureNandDone\n");
    sem_post(&sem);
  }

  NandCfgIndication(int id) : NandCfgIndicationWrapper(id) {
    sem_init(&sem, 0, 0);
  }
  void wait() {
    fprintf(stderr, "NandSim::wait for semaphore\n");
    sem_wait(&sem);
  }
private:
  sem_t sem;
};

int initNandSim(DmaManager *hostDma)
{
    NandCfgRequestProxy *nandcfgRequest = new NandCfgRequestProxy(IfcNames_NandCfgRequestS2H);
    NandCfgIndication *nandcfgIndication = new NandCfgIndication(IfcNames_NandCfgIndicationH2S);

    int nandBytes = 1 << 12;
    int nandAlloc = portalAlloc(nandBytes, 0);
    fprintf(stderr, "testnandsim::nandAlloc=%d\n", nandAlloc);
    int ref_nandAlloc = hostDma->reference(nandAlloc);
    fprintf(stderr, "ref_nandAlloc=%d\n", ref_nandAlloc);
    fprintf(stderr, "testnandsim::NAND alloc fd=%d ref=%d\n", nandAlloc, ref_nandAlloc);
    nandcfgRequest->configureNand(ref_nandAlloc, nandBytes);
    nandcfgIndication->wait();

    const char *filename = "../test.bin";
    fprintf(stderr, "testnandsim::opening %s\n", filename);
    // open up the text file and read it into an allocated memory buffer
    int data_fd = open(filename, O_RDONLY);
    if (data_fd < 0) {
	fprintf(stderr, "%s:%d failed to open file %s errno=%d:%s\n", __FUNCTION__, __LINE__, filename, errno, strerror(errno));
	return 0;
    }
    off_t data_len = lseek(data_fd, 0, SEEK_END);
    fprintf(stderr, "%s:%d fd=%d data_len=%ld\n", __FUNCTION__, __LINE__, data_fd, data_len);
    data_len = data_len & ~15; // because we are using a burst length of 16
    lseek(data_fd, 0, SEEK_SET);

    int dataAlloc = portalAlloc(data_len, 0);
    char *data = (char *)portalMmap(dataAlloc, data_len);
    ssize_t read_len = read(data_fd, data, data_len); 
    if(read_len != data_len) {
	fprintf(stderr, "%s:%d::error reading %s %ld %ld\n", __FUNCTION__, __LINE__, filename, (long)data_len, (long) read_len);
	exit(-1);
    }
    int ref_dataAlloc = hostDma->reference(dataAlloc);

    // write the contents of data into "flash" memory
    portalCacheFlush(ref_dataAlloc, data, data_len, 1);
    fprintf(stderr, "testnandsim::invoking write %08x %08lx\n", ref_dataAlloc, (long)data_len);
    nandcfgRequest->startWrite(ref_dataAlloc, 0, 0, data_len, 16);
    nandcfgIndication->wait();

    fprintf(stderr, "%s:%d finished -- data_len=%ld\n", __FUNCTION__, __LINE__, data_len);
    return data_len;
}
