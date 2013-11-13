BASEDIR = ../../
UTILDIR = ../../cpp/

testpa:
	g++ -I$(BASEDIR) testpa.cpp $(UTILDIR)/portal.cpp $(UTILDIR)/sock_fd.cxx $(UTILDIR)/sock_utils.cxx -pthread

clean:
	rm a.out