#ifndef _SOCK_UTILS_H_
#define _SOCK_UTILS_H_

struct channel{
  int s1;
  int s2;
  struct sockaddr_un local;
  bool connected;
  char path[100];
};

struct portal{
  struct channel read;
  struct channel write;
};

static struct portal iport = {{0,0,{0,""},false, ""},
			      {0,0,{0,""},false, ""}};

void* init_socket(void* _xx);
void connect_socket(channel *c);
char *get_uid();




#endif //_SOCK_UTILS_H_
