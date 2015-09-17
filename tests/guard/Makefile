CONNECTALDIR?=../..

run: guardTestBench
	#./guardTestBench

guardTestBench: GuardTest.bsv
	mkdir -p obj
	bsc --show-schedule -aggressive-conditions \
	   -sim -info-dir obj -bdir obj -p +:$(CONNECTALDIR)/lib/bsv -g mkGuardTestBench -u $<
	bsc --show-schedule -sim -info-dir obj -bdir obj -e mkGuardTestBench -o guardTestBench

clean:
	rm -rf guardTestBench* mkGuardTestBench.* model_mkGuardTestBench.* dump.vcd obj
