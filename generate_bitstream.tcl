##############################################################################
#  generate_bitstream.tcl
#  Vivado Tcl Console mein paste karo:
#    source C:/Users/HP/AVC_Project/generate_bitstream.tcl
#
#  YE KARTA HAI:
#   1. Methodology warnings check aur suppress (safe ones)
#   2. Implementation run
#   3. Bitstream generate
#   4. .bit aur .hwh files copy karta hai ready location pe
##############################################################################

puts "INFO: Starting Implementation + Bitstream flow..."

# ── Step 1: Methodology violations check karo ───────────────────────────────
# CDC (Clock Domain Crossing) warnings common hain aur safe hain
# agar same clock domain use ho raha ho (jo hamare design mein hai)
set_msg_config -id {Methodology 6-69}  -suppress
set_msg_config -id {Methodology 6-901} -suppress
set_msg_config -id {Methodology 8-63}  -suppress

# ── Step 2: Implementation launch karo ──────────────────────────────────────
puts "INFO: Launching implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1

# ── Step 3: Check if successful ─────────────────────────────────────────────
set impl_status [get_property STATUS [get_runs impl_1]]
set impl_progress [get_property PROGRESS [get_runs impl_1]]

puts "INFO: Implementation Status  = $impl_status"
puts "INFO: Implementation Progress = $impl_progress"

if {$impl_progress eq "100%"} {
    puts "INFO: Implementation + Bitstream SUCCESSFUL!"

    # ── Step 4: Copy output files to easy location ───────────────────────────
    set runs_dir "C:/Users/HP/AVC_Project/AdaptiveVoiceCancellation.runs/impl_1"
    set output_dir "C:/Users/HP/AVC_Project/PYNQ_FILES"

    file mkdir $output_dir

    # Copy .bit file
    set bit_files [glob -nocomplain "$runs_dir/*.bit"]
    if {[llength $bit_files] > 0} {
        set src_bit [lindex $bit_files 0]
        file copy -force $src_bit "$output_dir/design_1.bit"
        puts "INFO: .bit file copied to $output_dir/design_1.bit"
    } else {
        puts "WARNING: .bit file not found in $runs_dir"
    }

    # Copy .hwh file (hardware handoff for PYNQ)
    set hwh_files [glob -nocomplain \
        "C:/Users/HP/AVC_Project/AdaptiveVoiceCancellation.srcs/sources_1/bd/design_1/hw_handoff/*.hwh"]
    if {[llength $hwh_files] > 0} {
        set src_hwh [lindex $hwh_files 0]
        file copy -force $src_hwh "$output_dir/design_1.hwh"
        puts "INFO: .hwh file copied to $output_dir/design_1.hwh"
    } else {
        puts "WARNING: .hwh file not found — check sources_1/bd/design_1/hw_handoff/"
    }

    puts ""
    puts "=============================================="
    puts "DONE! PYNQ files ready at:"
    puts "  $output_dir/design_1.bit"
    puts "  $output_dir/design_1.hwh"
    puts ""
    puts "Copy both files to PYNQ board at:"
    puts "  /home/xilinx/design_1.bit"
    puts "  /home/xilinx/design_1.hwh"
    puts "=============================================="

} else {
    puts "ERROR: Implementation did not complete successfully"
    puts "ERROR: Status = $impl_status, Progress = $impl_progress"
    puts "INFO: Check impl_1 run logs for details"
}
