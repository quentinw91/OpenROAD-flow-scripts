if {![info exists standalone] || $standalone} {
  # Read lef
  read_lef $::env(TECH_LEF)
  read_lef $::env(SC_LEF)
  if {[info exist ::env(ADDITIONAL_LEFS)]} {
    foreach lef $::env(ADDITIONAL_LEFS) {
      read_lef $lef
    }
  }

  # Read liberty files
  foreach libFile $::env(LIB_FILES) {
    read_liberty $libFile
  }

  # Read def and sdc
  # Use -order_wires to build wire graph
  # for antenna checker read_def -order_wires $::env(RESULTS_DIR)/6_1_fill.def
  read_def $::env(RESULTS_DIR)/6_1_fill.def
  read_sdc $::env(RESULTS_DIR)/6_1_fill.sdc
  if [file exists $::env(PLATFORM_DIR)/derate_final.tcl] {
    source $::env(PLATFORM_DIR)/derate_final.tcl
    puts "derate_final.tcl sourced"
  }
}

# Set res and cap
if [file exists $::env(PLATFORM_DIR)/setRC.tcl] {
  source $::env(PLATFORM_DIR)/setRC.tcl
}

set_propagated_clock [all_clocks]
estimate_parasitics -placement

log_begin $::env(REPORTS_DIR)/6_final_report.rpt

puts "\n=========================================================================="
puts "report_checks -path_delay min"
puts "--------------------------------------------------------------------------"
report_checks -path_delay min -fields {slew cap input nets fanout} -format full_clock_expanded

puts "\n=========================================================================="
puts "report_checks -path_delay max"
puts "--------------------------------------------------------------------------"
report_checks -path_delay max -fields {slew cap input nets fanout} -format full_clock_expanded

puts "\n=========================================================================="
puts "report_checks -unconstrained"
puts "--------------------------------------------------------------------------"
report_checks -unconstrained -fields {slew cap input nets fanout} -format full_clock_expanded

puts "\n=========================================================================="
puts "report_tns"
puts "--------------------------------------------------------------------------"
report_tns

puts "\n=========================================================================="
puts "report_wns"
puts "--------------------------------------------------------------------------"
report_wns

puts "\n=========================================================================="
puts "report_check_types -max_slew -violators"
puts "--------------------------------------------------------------------------"
report_check_types -max_slew -max_capacitance -max_fanout -violators

puts "\n=========================================================================="
puts "report_clock_skew"
puts "--------------------------------------------------------------------------"
report_clock_skew

puts "\n=========================================================================="
puts "report_power"
puts "--------------------------------------------------------------------------"
report_power

puts "\n=========================================================================="
puts "report_design_area"
puts "--------------------------------------------------------------------------"
report_design_area

puts "\n=========================================================================="
puts "instance_count"
puts "--------------------------------------------------------------------------"
puts "[sta::network_leaf_instance_count]"

puts "\n=========================================================================="
puts "pin_count"
puts "--------------------------------------------------------------------------"
puts "[sta::network_leaf_pin_count]"

#puts "\n=========================================================================="
#puts "check_antennas"
#puts "--------------------------------------------------------------------------"
#check_antennas -path $::env(REPORTS_DIR) 

log_end

# Delete routing obstructions for final DEF
source scripts/deleteRoutingObstructions.tcl
deleteRoutingObstructions

if {![info exists standalone] || $standalone} {
  write_def $::env(RESULTS_DIR)/6_final.def
  write_verilog $::env(RESULTS_DIR)/6_final.v
  exit
}
