#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/un.h>
#include <pthread.h>
#include <assert.h>
#include <portal.h>

#include "sock_utils.h"

static struct portal iport = {{0,0,{},false},
			      {0,0,{},false}};


static struct portal portals[16] = {iport,iport,iport,iport,iport,iport,
				    iport,iport,iport,iport,iport,iport,
				    iport,iport,iport,iport};

struct queuestatus{
  struct memrequest req;
  unsigned int pnum;
  bool valid;
  bool inflight;
};

static struct queuestatus  read_head = {{},0,false,false,};
static struct queuestatus write_head = {{},0,false,false,};

static void recv_request(bool rr)
{
  struct queuestatus* head = rr ? &read_head : &write_head;
  if (!head->valid && !head->inflight){
    for(int i = 0; i < 16; i++){
      struct channel* chan = rr ? &(portals[i].read) : & (portals[i].write);
      if(chan->connected){
	int rv = recv(chan->s2, &(head->req), sizeof(memrequest), MSG_DONTWAIT);
	if(rv > 0){
	  //fprintf(stderr, "recv size %d\n", rv);
	  assert(rv == sizeof(memrequest));
	  head->pnum = i;
	  head->valid = true;
	  head->inflight = rr ? false : true;
	  head->req.addr |= i << 16;
	  if(0)
	  fprintf(stderr, "recv_request(i=%d,rr=%d) {%d,%08x, %08x}\n", 
		  i, rr, head->req.write, head->req.addr, head->req.data);
	  break;
	}
      }
    }
  }
}


extern "C" {
  void initPortal(unsigned long id){

    pthread_t tid;
    struct channel* rc;
    struct channel* wc;

    assert(id < 16);    

    rc = &(portals[id].read);
    wc = &(portals[id].write);

    snprintf(rc->path, sizeof(rc->path), "/tmp/fpga%ld_rc", id);
    snprintf(wc->path, sizeof(rc->path), "/tmp/fpga%ld_wc", id);

    if(pthread_create(&tid, NULL,  init_socket, (void*)rc)){
      fprintf(stderr, "error creating init thread\n");
      exit(1);
    }

    if(pthread_create(&tid, NULL,  init_socket, (void*)wc)){
      fprintf(stderr, "error creating init thread\n");
      exit(1);
    }
  }

  bool writeReq(){
    recv_request(false);
    return (write_head.req.write && write_head.valid && write_head.inflight);
  }
  
  unsigned int writeAddr(){
    //fprintf(stderr, "writeAddr()\n");
    write_head.inflight = false;
    return write_head.req.addr;
  }
  
  unsigned int writeData(){
    //fprintf(stderr, "writeData()\n");
    write_head.valid = false;
    return write_head.req.data;
  }
  
  bool readReq(){
    recv_request(true);
    return (!read_head.req.write && read_head.valid && !read_head.inflight);
  }
  
  unsigned int readAddr(){
    //fprintf(stderr, "readAddr()\n");
    read_head.inflight = true;
    return read_head.req.addr;
  }
  
  void readData(unsigned int x){
    //fprintf(stderr, "readData()\n");
    read_head.valid = false;
    read_head.inflight = false;
    if(send(portals[read_head.pnum].read.s2, &x, sizeof(x), 0) == -1){
      fprintf(stderr, "(%d) send failure", read_head.pnum);
      exit(1);
    }
  }

}
