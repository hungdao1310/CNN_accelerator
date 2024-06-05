all: gen sim compare

gen: 
	python3 testbench_gen.py

sim:
	iverilog -o outputfile *.v
	vvp outputfile

compare:
	python3 compare.py
