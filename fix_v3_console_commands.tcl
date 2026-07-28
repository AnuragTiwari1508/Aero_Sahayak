##############################################################################
#  fix_v3_console_commands.tcl
#  Vivado Tcl Console mein paste karo:
#    source C:/Users/HP/AVC_Project/fix_v3_console_commands.tcl
#
#  Ye script sirf PROPERTY FIXES karti hai — naye cells NAHI banati.
#  Cells pehle se exist karte hain (previous script ne banaye).
##############################################################################

puts "INFO: Applying property fixes to existing cells..."

# ── FIX-1: Protocol Converter DATA_WIDTH 32→64 ──────────────────────────────
# PS7 S_AXI_HP ports are 64-bit wide — converter must match
set_property -dict [list \
    CONFIG.MI_PROTOCOL {AXI3} \
    CONFIG.SI_PROTOCOL {AXI4} \
    CONFIG.DATA_WIDTH  {64}   \
] [get_bd_cells axi_pc_noise]

set_property -dict [list \
    CONFIG.MI_PROTOCOL {AXI3} \
    CONFIG.SI_PROTOCOL {AXI4} \
    CONFIG.DATA_WIDTH  {64}   \
] [get_bd_cells axi_pc_voice]

puts "INFO: FIX1 done — Protocol Converter DATA_WIDTH set to 64"

# ── FIX-2: INTC interrupt mode Bus→Single ───────────────────────────────────
# When IRQ_F2P is used directly, INTC output must be Single not Bus
set_property -dict [list \
    CONFIG.C_HAS_FAST   {0}      \
    CONFIG.C_IRQ_IS_LEVEL {1}    \
    CONFIG.C_IRQ_CONNECTION {0}  \
] [get_bd_cells axi_intc_0]

puts "INFO: FIX2 done — INTC set to Single output mode"

# ── FIX-3: DMA data width must also be 64-bit to match HP port ──────────────
# AXI DMA memory-mapped ports must be 64-bit to connect through 64-bit chain
set_property -dict [list \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_m_axis_mm2s_tdata_width {32} \
] [get_bd_cells axi_dma_noise]

set_property -dict [list \
    CONFIG.c_m_axi_mm2s_data_width  {64} \
    CONFIG.c_m_axis_mm2s_tdata_width {32} \
    CONFIG.c_m_axi_s2mm_data_width  {64} \
    CONFIG.c_s_axis_s2mm_tdata_width {32} \
] [get_bd_cells axi_dma_voice]

puts "INFO: FIX3 done — DMA AXI memory ports set to 64-bit"

# ── Reassign addresses (needed after property changes) ───────────────────────
puts "INFO: Reassigning addresses..."
assign_bd_address

# ── Validate ─────────────────────────────────────────────────────────────────
puts "INFO: Validating design..."
validate_bd_design

puts "INFO: Saving..."
save_bd_design

puts "----------------------------------------------"
puts "INFO: DONE. Check for any remaining warnings."
puts "----------------------------------------------"
