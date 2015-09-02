CONNECTALDIR?=../..

run: floatTestBench
	./floatTestBench

ctest:
	gcc -o ftest ftest.c
	./ftest
	rm -f ftest

floatTestBench: FloatTest.bsv
	mkdir -p obj
	bsc --show-schedule -sim -info-dir obj -bdir obj -p +:$(CONNECTALDIR)/lib/bsv -g mkFloatTestBench -u $<
	bsc --show-schedule -sim -info-dir obj -bdir obj -e mkFloatTestBench -o floatTestBench

clean:
	rm -rf floatTestBench* mkFloatTestBench.* model_mkFloatTestBench.* dump.vcd obj
