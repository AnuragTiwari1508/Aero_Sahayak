##############################################################################
#  setup_simulation.tcl
#  Vivado Tcl Console mein paste karo:
#    source C:/Users/HP/AVC_Project/setup_simulation.tcl
##############################################################################

puts "INFO: Setting up AVC Simulation..."

# Step 1: sim_files folder banao
file mkdir "C:/Users/HP/AVC_Project/sim_files"

# Step 2: Hex data files copy karo (tumne pehle download kiye the)
# Agar files already hain to skip hoga
foreach src_name {noise_samples.hex voice_samples.hex} {
    set dst "C:/Users/HP/AVC_Project/sim_files/$src_name"
    if {![file exists $dst]} {
        puts "WARNING: $dst not found — manually copy the .hex files here"
    } else {
        puts "INFO: Found $dst OK"
    }
}

# Step 3: Testbench add karo simulation fileset mein
add_files -fileset sim_1 -norecurse \
    "C:/Users/HP/AVC_Project/tb_LMS_Filter.v"

# Step 4: LMS_Filter.v bhi add karo (agar nahi hai)
add_files -norecurse \
    "C:/Users/HP/AVC_Project/ip_repo/LMS_Filter_1_0/hdl/LMS_Filter.v"

# Step 5: Simulation top set karo
set_property top tb_LMS_Filter [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

update_compile_order -fileset sim_1

puts "INFO: Simulation setup complete!"
puts "INFO: Ab Flow Navigator → Simulation → Run Behavioral Simulation"
puts "INFO: Ya Tcl Console mein: launch_simulation"
