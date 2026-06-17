#==============================================================================
# Makefile for the APB protocol project.
#
# Targets:
#   make            - compile and run (random stimulus)
#   make linear     - compile and run with fixed test data
#   make wave       - open the resulting VCD in GTKWave
#   make clean      - remove all build artifacts
#
# Requires: iverilog, vvp, (optional) gtkwave
#==============================================================================

RTL    := rtl/apb_master.v rtl/apb_slave.v rtl/apb_top.v
TB     := tb/tb_apb_top.v
SIM    := build/sim.vvp
VCD    := build/apb.vcd
IVOPTS := -g2012

.PHONY: all linear wave clean

all: $(SIM)
	@cd build && vvp sim.vvp

linear:
	@mkdir -p build
	iverilog $(IVOPTS) -DLINEAR_TB -o $(SIM) $(RTL) $(TB)
	@cd build && vvp sim.vvp

$(SIM): $(RTL) $(TB)
	@mkdir -p build
	iverilog $(IVOPTS) -o $(SIM) $(RTL) $(TB)

wave: $(VCD)
	gtkwave $(VCD) &

$(VCD): all

clean:
	rm -rf build
