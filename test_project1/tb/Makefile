TOPLEVEL_LANG = verilog
VERILOG_SOURCE = ../rtl/async_fifo.v
SIM ?= icarus
WAVES ?= 1
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps
DUT      = async_fifo
TOPLEVEL = $(DUT)
MODULE   = $(DUT)_tb
include $(shell cocotb-config --makefiles)/Makefile.sim
