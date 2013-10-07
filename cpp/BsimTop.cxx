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

static int s1[16];
static int s2[16];
static struct sockaddr_un local[16];
static bool connected[16] = {false,false,false,false,false,false,false,false,
			 false,false,false,false,false,false,false,false};


struct memrequest{
  bool write;
  unsigned int addr;
  unsigned int data;
};

struct queuestatus{
  struct memrequest req;
  unsigned int portal;
  bool valid;
  bool inflight;
};

static struct queuestatus head = 
  { 
    {false,0,0},
    0,
    false,
    false,
  };


static void recv_request(void)
{
  if (!head.valid){
    for(int i = 0; i < 16; i++){
      if(connected[i]){
	if(recv(s2[i], &head.req, sizeof(memrequest), MSG_DONTWAIT)){
	  head.portal = i;
	  head.valid = true;
	  head.inflight = false;
	  head.req.addr |= i << 16;
	}
      }
    }
  }
}

static void* init_socket(void* _xx)
{
  int id = (int)_xx;
  assert(id < 16);
  char str[100];

  printf("(%d) init_socket\n",id);
  if ((s1[id] = socket(AF_UNIX, SOCK_STREAM, 0)) == -1) {
    fprintf(stderr, "(%d) socket error", id);
    exit(1);
  }
  
  sprintf(str,"/tmp/fpga%d", id);
  local[id].sun_family = AF_UNIX;
  strcpy(local[id].sun_path, str);
  unlink(local[id].sun_path);
  int len = strlen(local[id].sun_path) + sizeof(local[id].sun_family);
  if (bind(s1[id], (struct sockaddr *)&local[id], len) == -1) {
    fprintf(stderr, "(%d) bind error", id);
    exit(1);
  }
  
  if (listen(s1[id], 5) == -1) {
    fprintf(stderr, "(%d) listen error", id);
    exit(1);
  }
  
  printf("(%d) waiting for a connection...\n", id);
  if ((s2[id] = accept(s1[id], NULL, NULL)) == -1) {
    fprintf(stderr, "(%d) accept error", id);
    exit(1);
  }
  
  printf("(%d) connected\n",id);
  connected[id] = true;
  return _xx;
}


extern "C" {

  void initPortal(int id){
    pthread_t tid;
    if(pthread_create(&tid, NULL,  init_socket, (void*)id)){
      fprintf(stderr, "error creating init thread\n");
      exit(1);
    }
  }

  bool writeReq(){
    recv_request();
    return (head.req.write && head.valid && !head.inflight);
  }
  
  unsigned int writeAddr(){
    return head.req.addr;
  }
  
  unsigned int writeData(){
    head.valid = false;
    head.inflight = false;
    return head.req.data;
  }
  
  bool readReq(){
    recv_request();
    return (!head.req.write && head.valid && !head.inflight);
  }
  
  unsigned int readAddr(){
    head.inflight = true;
    return head.req.addr;
  }
  
  void readData(unsigned int x){
    head.valid = false;
    head.inflight = false;
    if(send(s2[head.portal], &x, sizeof(x), 0) < 0){
      fprintf(stderr, "(%d) send failure", head.portal);
      exit(1);
    }
  }

}
