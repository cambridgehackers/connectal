#include "portal.h"

#include "DirectoryResponseWrapper.h"
#include "DirectoryRequestProxy.h"

class DirectoryResponse : public DirectoryResponseWrapper
{
public:
  
  unsigned long offset;
  unsigned long long type;
  unsigned long addrbits;
  unsigned long long timestamp;
  unsigned long numportals;
  
  DirectoryResponse(const char* devname, unsigned int addrbits) : DirectoryResponseWrapper(devname, addrbits) {
  }

  void timeStamp ( const unsigned long long t ){
    timestamp = t;
  }

  void numPortals ( const unsigned long n ) {
    numportals = n;
  }

  void portalAddrBits ( const unsigned long n ){
    addrbits = n;
  }

  void idOffset ( const unsigned long id, const unsigned long o ){
    offset = o;
  }

  void idType ( const unsigned long id, const unsigned long long t ){
    type = t;
  }
};

