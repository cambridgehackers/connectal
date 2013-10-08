#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <pthread.h>
#include <assert.h>
#include <portal.h>


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

static void* init_socket(void* _xx)
{
  int msg = (int)_xx;
  int id  = msg & 0x7FFFFFFF;
  int rr  = msg & 0x80000000;
  assert(id < 16);

  char str[100];
  struct channel* c = rr ? &(portals[id].read) : &(portals[id].write); 

  printf("(%08x) init_socket\n",msg);
  if ((c->s1 = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "(%08x) socket error", msg);
    exit(1);
  }
  
  sprintf(str,"/tmp/fpga%d%s", id, rr ? "_rc" : "_wc");
  c->local.sun_family = AF_UNIX;
  strcpy(c->local.sun_path, str);
  unlink(c->local.sun_path);
  int len = strlen(c->local.sun_path) + sizeof(c->local.sun_family);
  if (bind(c->s1, (struct sockaddr *)&c->local, len) == -1) {
    fprintf(stderr, "(%08x) bind error", msg);
    exit(1);
  }
  
  if (listen(c->s1, 5) == -1) {
    fprintf(stderr, "(%08x) listen error", msg);
    exit(1);
  }
  
  fprintf(stderr, "(%08x) waiting for a connection...\n", msg);
  if ((c->s2 = accept(c->s1, NULL, NULL)) == -1) {
    fprintf(stderr, "(%08x) accept error", msg);
    exit(1);
  }
  
  fprintf(stderr, "(%08x) connected\n",msg);
  c->connected = true;
  return _xx;
}


extern "C" {
  void initPortal(int id){
    pthread_t tid;
    if(pthread_create(&tid, NULL,  init_socket, (void*)(id|0x80000000))){
      fprintf(stderr, "error creating init thread\n");
      exit(1);
    }
    if(pthread_create(&tid, NULL,  init_socket, (void*)id)){
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
