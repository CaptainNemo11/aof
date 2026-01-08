SIM ?= Questa
SIM_ARGS += -voptargs=+acc -onfinish stop
TOPLEVEL_LANG ?= verilog
TOPLEVEL = day10
MODULE = tb
VERILOG_SOURCES += $(PWD)/10.sv
include $(shell cocotb-config --makefiles)/Makefile.sim
