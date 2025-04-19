# Change to your simulator’s bin directory if needed
VLOG = vlog
VSIM = vsim
INCDIR   = +incdir+./src/include
SRCS     = src/modules/*.sv src/testbench/systolic_array_tb.sv

all: sim

sim:
	$(VLOG) -sv $(INCDIR) $(SRCS)
	$(VSIM) -c -voptargs="+acc"  -do dump.do work.systolic_array_tb