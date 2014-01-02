# examples/echo

gen_echo:
	cd ../..; ./genxpsprojfrombsv -B$(BOARD) -p test-echo -x mkZynqTop -s2h Swallow -s2h EchoRequest -h2s EchoIndication \
	-s examples/echo/testecho.cpp -t examples/echo/Topz.bsv -V verilog examples/echo/Echo.bsv examples/echo/Swallow.bsv

#################################################################################################

