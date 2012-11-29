
all:
	./run_test.sh

syntax.py: syntax.g
	python yapps/yapps2.py syntax.g 
