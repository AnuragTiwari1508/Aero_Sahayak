##############################################################################
#  MASTER_FIX_AND_SIMULATE.tcl
#
#  YE EK HI SCRIPT SAB KUCH KARTI HAI:
#   [FIX-1] design_fft_voice conflict resolve
#   [FIX-2] Correct top module set (design_1_wrapper)
#   [FIX-3] impl_1 properly reset + bitstream generate
#   [FIX-4] Simulation setup with your WAV data
#   [FIX-5] sim_files folder + hex files check
#
#  HOW TO RUN — Vivado Tcl Console mein:
#    source C:/Users/HP/AVC_Project/MASTER_FIX_AND_SIMULATE.tcl
##############################################################################

set proj_dir "C:/Users/HP/AVC_Project"
set sim_dir  "$proj_dir/sim_files"

puts "INFO: =========================================="
puts "INFO: MASTER FIX + SIMULATE Script Starting"
puts "INFO: =========================================="

##############################################################################
# FIX-1: design_fft_voice conflict
# Agar koi aur BD design conflict kar raha hai to use close karo
##############################################################################
puts "INFO: FIX1 — Closing any conflicting block designs..."

foreach bd [get_bd_designs] {
    if {$bd ne "design_1"} {
        puts "INFO: Closing BD: $bd"
        close_bd_design $bd
    }
}

# Agar design_1 open nahi hai to open karo
if {[llength [get_bd_designs design_1]] == 0} {
    catch {open_bd_design [get_files design_1.bd]}
}
puts "INFO: FIX1 done"

##############################################################################
# FIX-2: Correct top module — MUST be design_1_wrapper, not AVC_DataPath
##############################################################################
puts "INFO: FIX2 — Setting correct top module..."

set current_top [get_property top [current_fileset]]
puts "INFO: Current top = $current_top"

if {$current_top ne "design_1_wrapper"} {
    set_property top design_1_wrapper [current_fileset]
    puts "INFO: Top changed to design_1_wrapper"
} else {
    puts "INFO: Top already correct"
}

update_compile_order -fileset sources_1
puts "INFO: FIX2 done — top = [get_property top [current_fileset]]"

##############################################################################
# FIX-3: Reset ALL runs properly then launch bitstream
##############################################################################
puts "INFO: FIX3 — Resetting runs for clean bitstream generation..."

# Reset both synth and impl cleanly
reset_run synth_1
puts "INFO: synth_1 reset done"

# Launch synthesis first
puts "INFO: Launching synthesis (takes 5-10 min)..."
launch_runs synth_1 -jobs 2
wait_on_run synth_1

set synth_status [get_property STATUS [get_runs synth_1]]
puts "INFO: Synthesis status = $synth_status"

if {[get_property PROGRESS [get_runs synth_1]] ne "100%"} {
    puts "ERROR: Synthesis failed — check Messages panel"
} else {
    puts "INFO: Synthesis OK — launching implementation + bitstream..."

    reset_run impl_1
    launch_runs impl_1 -to_step write_bitstream -jobs 2
    wait_on_run impl_1

    set impl_status [get_property STATUS [get_runs impl_1]]
    set impl_prog   [get_property PROGRESS [get_runs impl_1]]
    puts "INFO: Implementation status   = $impl_status"
    puts "INFO: Implementation progress = $impl_prog"

    if {$impl_prog eq "100%"} {
        # Copy output files
        file mkdir "$proj_dir/PYNQ_FILES"

        set bit_src [glob -nocomplain \
            "$proj_dir/AdaptiveVoiceCancellation.runs/impl_1/*.bit"]
        if {[llength $bit_src] > 0} {
            file copy -force [lindex $bit_src 0] \
                "$proj_dir/PYNQ_FILES/design_1.bit"
            puts "INFO: .bit copied to PYNQ_FILES/design_1.bit"
        }

        set hwh_src [glob -nocomplain \
            "$proj_dir/AdaptiveVoiceCancellation.srcs/sources_1/bd/design_1/hw_handoff/*.hwh"]
        if {[llength $hwh_src] > 0} {
            file copy -force [lindex $hwh_src 0] \
                "$proj_dir/PYNQ_FILES/design_1.hwh"
            puts "INFO: .hwh copied to PYNQ_FILES/design_1.hwh"
        }

        puts "INFO: FIX3 done — BITSTREAM GENERATED!"
        puts "INFO: Files at: $proj_dir/PYNQ_FILES/"
    } else {
        puts "ERROR: Implementation did not complete"
        puts "ERROR: Check impl_1 logs in Vivado"
    }
}

##############################################################################
# FIX-4: Simulation setup with WAV hex data
##############################################################################
puts "INFO: FIX4 — Setting up simulation..."

file mkdir $sim_dir

# Check if hex files exist
set noise_hex "$sim_dir/noise_samples.hex"
set voice_hex "$sim_dir/voice_samples.hex"

if {![file exists $noise_hex]} {
    puts "WARNING: $noise_hex not found"
    puts "WARNING: Download noise_samples.hex and put it in $sim_dir"
} else {
    puts "INFO: noise_samples.hex found OK"
}

if {![file exists $voice_hex]} {
    puts "WARNING: $voice_hex not found"
    puts "WARNING: Download voice_samples.hex and put it in $sim_dir"
} else {
    puts "INFO: voice_samples.hex found OK"
}

# Add testbench to sim_1
set tb_file "$proj_dir/tb_LMS_Filter.v"
if {[file exists $tb_file]} {
    add_files -fileset sim_1 -norecurse $tb_file
    set_property top tb_LMS_Filter [get_filesets sim_1]
    update_compile_order -fileset sim_1
    puts "INFO: Testbench added to sim_1"
} else {
    puts "WARNING: tb_LMS_Filter.v not found at $tb_file"
    puts "WARNING: Download it and place at $tb_file"
}

# Add LMS_Filter RTL
set lms_file "$proj_dir/ip_repo/LMS_Filter_1_0/hdl/LMS_Filter.v"
if {[file exists $lms_file]} {
    catch {add_files -norecurse $lms_file}
    puts "INFO: LMS_Filter.v confirmed in sources"
}

puts "INFO: FIX4 done"

##############################################################################
# SUMMARY
##############################################################################
puts ""
puts "=========================================="
puts "SUMMARY:"
puts "  Top module : [get_property top [current_fileset]]"
puts "  Sim top    : [get_property top [get_filesets sim_1]]"
puts ""
puts "NEXT STEPS:"
puts "  BITSTREAM: Check $proj_dir/PYNQ_FILES/ for .bit and .hwh"
puts "  SIMULATE : Flow Navigator -> Simulation -> Run Behavioral Simulation"
puts "             Ya Tcl Console: launch_simulation"
puts "=========================================="
