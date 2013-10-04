#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>


extern "C" {

  bool writeReq(){
    return false;
  }
  
  unsigned int writeAddr(){
    return 0;
  }
  
  unsigned int writeData(){
    return 0;
  }
  
  bool readReq(){
    return false;
  }
  
  unsigned int readAddr(){
    return 0;
  }
  
  void readData(unsigned int x){
    ;
  }

}
