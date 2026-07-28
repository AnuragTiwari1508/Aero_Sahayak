##############################################################################
#  fix_existing_design.tcl  —  FIXED VERSION (Tcl bracket escape fixed)
#  Vivado Tcl Console mein run karo:
#    source C:/Users/HP/AVC_Project/fix_existing_design.tcl
##############################################################################

set bd_name "design_1"
if {[llength [get_bd_designs $bd_name]] == 0} {
    open_bd_design [get_files ${bd_name}.bd]
}

puts "INFO: AVC Design Fix Script Starting..."

# Convenience vars (already exist in design)
set clk100 [get_bd_pins clk_wiz_0/clk_out1]
set rst100  [get_bd_pins psr_100/peripheral_aresetn]

##############################################################################
# FIX-A: AXI Protocol Converter
# DMA M_AXI is AXI4, PS7 HP ports are AXI3 — need converter in between
##############################################################################
puts "INFO: FIXA — Adding AXI Protocol Converters..."

create_bd_cell -type ip \
    -vlnv xilinx.com:ip:axi_protocol_converter:2.1 \
    axi_pc_noise

set_property -dict [list \
    CONFIG.MI_PROTOCOL          {AXI3} \
    CONFIG.SI_PROTOCOL          {AXI4} \
    CONFIG.DATA_WIDTH           {32}   \
    CONFIG.SUPPORT_NARROW_BURST {0}    \
] [get_bd_cells axi_pc_noise]

connect_bd_net $clk100 [get_bd_pins axi_pc_noise/aclk]
connect_bd_net $rst100 [get_bd_pins axi_pc_noise/aresetn]

# Voice channel needs a 2-to-1 SmartConnect (MM2S + S2MM share one HP port)
create_bd_cell -type ip \
    -vlnv xilinx.com:ip:smartconnect:1.0 \
    axi_smc_voice

set_property -dict [list \
    CONFIG.NUM_SI {2} \
    CONFIG.NUM_MI {1} \
] [get_bd_cells axi_smc_voice]

connect_bd_net $clk100 [get_bd_pins axi_smc_voice/aclk]
connect_bd_net $rst100 [get_bd_pins axi_smc_voice/aresetn]

create_bd_cell -type ip \
    -vlnv xilinx.com:ip:axi_protocol_converter:2.1 \
    axi_pc_voice

set_property -dict [list \
    CONFIG.MI_PROTOCOL          {AXI3} \
    CONFIG.SI_PROTOCOL          {AXI4} \
    CONFIG.DATA_WIDTH           {32}   \
    CONFIG.SUPPORT_NARROW_BURST {0}    \
] [get_bd_cells axi_pc_voice]

connect_bd_net $clk100 [get_bd_pins axi_pc_voice/aclk]
connect_bd_net $rst100 [get_bd_pins axi_pc_voice/aresetn]

# Wire: DMA Noise MM2S → pc_noise → PS7 HP0
connect_bd_intf_net \
    [get_bd_intf_pins axi_dma_noise/M_AXI_MM2S] \
    [get_bd_intf_pins axi_pc_noise/S_AXI]

connect_bd_intf_net \
    [get_bd_intf_pins axi_pc_noise/M_AXI] \
    [get_bd_intf_pins ps7/S_AXI_HP0]

# Wire: DMA Voice MM2S + S2MM → smc_voice → pc_voice → PS7 HP1
connect_bd_intf_net \
    [get_bd_intf_pins axi_dma_voice/M_AXI_MM2S] \
    [get_bd_intf_pins axi_smc_voice/S00_AXI]

connect_bd_intf_net \
    [get_bd_intf_pins axi_dma_voice/M_AXI_S2MM] \
    [get_bd_intf_pins axi_smc_voice/S01_AXI]

connect_bd_intf_net \
    [get_bd_intf_pins axi_smc_voice/M00_AXI] \
    [get_bd_intf_pins axi_pc_voice/S_AXI]

connect_bd_intf_net \
    [get_bd_intf_pins axi_pc_voice/M_AXI] \
    [get_bd_intf_pins ps7/S_AXI_HP1]

puts "INFO: FIXA done — Protocol Converters connected"

##############################################################################
# FIX-B: S_AXIS_S2MM unconnected
# AXIS FIFO: DMA Noise M_AXIS_MM2S → FIFO → DMA Voice S_AXIS_S2MM
##############################################################################
puts "INFO: FIXB — Connecting S_AXIS_S2MM via AXIS FIFO..."

create_bd_cell -type ip \
    -vlnv xilinx.com:ip:axis_data_fifo:2.0 \
    axis_fifo_lms

set_property -dict [list \
    CONFIG.TDATA_NUM_BYTES {4}   \
    CONFIG.FIFO_DEPTH      {512} \
    CONFIG.HAS_TLAST       {1}   \
] [get_bd_cells axis_fifo_lms]

connect_bd_net $clk100 [get_bd_pins axis_fifo_lms/s_axis_aclk]
connect_bd_net $rst100 [get_bd_pins axis_fifo_lms/s_axis_aresetn]

connect_bd_intf_net \
    [get_bd_intf_pins axi_dma_noise/M_AXIS_MM2S] \
    [get_bd_intf_pins axis_fifo_lms/S_AXIS]

connect_bd_intf_net \
    [get_bd_intf_pins axis_fifo_lms/M_AXIS] \
    [get_bd_intf_pins axi_dma_voice/S_AXIS_S2MM]

puts "INFO: FIXB done — S_AXIS_S2MM now connected"

##############################################################################
# FIX-C: axi_intc_0/intr unconnected  +  irq not wired to PS7
##############################################################################
puts "INFO: FIXC — Wiring interrupt chain..."

connect_bd_net \
    [get_bd_pins axi_dma_noise/mm2s_introut] \
    [get_bd_pins xlconcat_irq/In0]

connect_bd_net \
    [get_bd_pins axi_dma_voice/mm2s_introut] \
    [get_bd_pins xlconcat_irq/In1]

connect_bd_net \
    [get_bd_pins axi_dma_voice/s2mm_introut] \
    [get_bd_pins xlconcat_irq/In2]

connect_bd_net \
    [get_bd_pins xlconcat_irq/dout] \
    [get_bd_pins axi_intc_0/intr]

connect_bd_net \
    [get_bd_pins axi_intc_0/irq] \
    [get_bd_pins ps7/IRQ_F2P]

puts "INFO: FIXC done — IRQ chain connected"

##############################################################################
# Assign addresses for new cells, then validate and save
##############################################################################
puts "INFO: Assigning addresses..."
assign_bd_address

puts "INFO: Validating design..."
validate_bd_design

puts "INFO: Saving design..."
save_bd_design

puts "----------------------------------------------"
puts "INFO: ALL FIXES DONE. Now run:"
puts "  Flow Navigator -> Generate Block Design"
puts "  Flow Navigator -> Run Synthesis"
puts "----------------------------------------------"
