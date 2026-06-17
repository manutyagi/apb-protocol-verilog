#==============================================================================
# run.do - QuestaSim/ModelSim simulation script for the APB protocol project.
#
# Usage (inside QuestaSim Transcript):
#     cd C:/path/to/apb-protocol-verilog/scripts     ; use forward slashes
#     do run.do
#
# Usage (from a shell, headless):
#     cd scripts && vsim -c -do run.do
#
# To use the predictable linear testbench (writes 152 and 1002), change the
# vsim line below to add  +define+LINEAR_TB
#==============================================================================

# 1) Clean previous work library safely
if {[file exists work]} {vdel -all}

# 2) Create a fresh work library
vlib work

# 3) Compile RTL first, then testbench
vlog ../rtl/apb_master.v ../rtl/apb_slave.v ../rtl/apb_top.v
vlog ../tb/tb_apb_top.v

# 4) Elaborate. +acc keeps internal signals visible for debug.
#    Add  +define+LINEAR_TB  for fixed test data instead of random.
vsim -voptargs=+acc -l run.log work.tb_apb_top

# 5) Add waves BEFORE running
add wave -r /*

# 6) Run the simulation
run -all

# 7) Auto-zoom to the full simulation
wave zoom full
