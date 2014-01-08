// kind of like Server, only with notFull and notEmpty

// users must import GetPut

interface ServerF#(type requestType, type responseType);
   method action Put#(requestType);
   method Bool notFull(Empty);
   method ActionValue responseType Get(Empty);
   method Value notEmpty(Empty);
endinterface

