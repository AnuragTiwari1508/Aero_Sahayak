##############################################################
## timing_constraints.xdc
## PYNQ-Z2 / xc7z020clg400-1
## Primary clock constraint for FCLK_CLK0 (100 MHz from PS)
##############################################################

# PS7 FCLK0 = 100 MHz (10 ns period)
# This is the source clock going into clk_wiz_0
create_clock -period 10.000 -name clk_fclk0  [get_pins ps7/inst/PS7_i/FCLKCLK[0]]

# False path on async reset inputs (safe to ignore CDC on reset)
set_false_path -from [get_pins ps7/inst/PS7_i/FCLKRESETN[0]]

# Max delay on AXI interface crossing (protocol converter)
set_max_delay -datapath_only 5.0  -from [get_cells -hierarchical -filter {NAME =~ *axi_pc*}]  -to   [get_cells -hierarchical -filter {NAME =~ *ps7*}]

