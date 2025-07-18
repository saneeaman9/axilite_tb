
catch {namespace delete ::run_simulation}

source setsim_temp.do
source set_lib_paths_ms.do

set currentTime [clock seconds]
set formattedTime [clock format $currentTime]

puts "***************************************************************"
puts "* Simulation started @ $formattedTime"
puts "* MODULE name  : $MODULE"
puts "* TESTCASE     : $TESTCASE"
puts "* NOCOVERAGE   : $NOCOVERAGE"
puts "* NOWLF        : $NOWLF"
puts "* NORTLCOMPILE : $NORTLCOMPILE"
puts "***************************************************************"

set random_seed [clock seconds]
puts "RANDOM_SEED : $random_seed"
set formatted_time [clock format $random_seed -format {+define+RANDOM_SEED=%s+DAY=%d+MONTH=%m+YEAR=%y+HOUR=%H+MIN=%M+SEC=%S}]
set OPT_TIME $formatted_time

namespace eval ::run_simulation {

  onerror { quit }
  
  # variable python_script "parse_yaml.py"
  # variable result [exec python $python_script $TESTCASE]
  # puts $result
  

  # variable script_dir [file dirname [info script]]
  variable script_dir [pwd]
  variable rundir_dir [file join $script_dir ".." "rundir"]
  cd $rundir_dir
  variable BASEDIR [file join [file dirname $rundir_dir] ".."]
  variable CODEDIR [file join $BASEDIR "code"]

  
  proc read_compile_order {filename} {
    variable f [open $filename]
    variable content [read $f]
    close $f
    return [split $content "\n"]
  }
  
  proc compile_files {compile_order custom_options} {
    variable CODEDIR
  
    variable include_dirs [list]
    variable source_files [list]
    
    foreach item $compile_order {
      set item [string map [list \$CODEDIR $CODEDIR] $item]
      set item [string trimright $item] ;# Trim spaces at the end of the file path
      
      set comment_pos [string first "#" $item]
      if {$comment_pos != -1} {
        set item [string range $item 0 [expr {$comment_pos - 1}]]
        set item [string trimright $item] ;# Trim spaces again after removing the comment
      }
      
      if {$item eq ""} {
        # Skip empty lines
        continue
      } elseif {[string match "+incdir+*" $item]} {
        lappend include_dirs [string range $item 8 end]
      } else {
        lappend source_files $item
      }
    }
  
    variable incdir_options ""
    foreach incdir $include_dirs {
      append incdir_options "+incdir+$incdir "
    }
    variable custom_options_str [join $custom_options " "]
  
    foreach file $source_files {
      switch -glob -- [file extension $file] {
        .v -
        .sv {eval vlog -sv $custom_options_str $incdir_options $file}
        .vhd -
        .vhdl {eval vcom $custom_options_str $file}
        default {puts "Error: Unknown file type $file"}
      }
    }
  }
  
  proc sim_run {} {
  
    global XIL_GLBL_FILE XLIB_UNISIMS TESTCASE MODULE NOWLF NOCOVERAGE NORTLCOMPILE OPT_TIME
    
    variable start_sim_time [clock milliseconds]
  
    variable compile_order_rtl [read_compile_order "../scripts/flists/rtl.flist"]
    variable compile_order_tb [read_compile_order "../scripts/flists/tb.flist"]
    
    if {$NORTLCOMPILE == "False" || $NORTLCOMPILE == 0} {
      set rtl_work_lib "work_rtl"
      if {[file exists $rtl_work_lib]} {
        vdel -lib $rtl_work_lib -all
      }
      vlib $rtl_work_lib
      
      variable custom_options [list "-permissive" "-timescale 1ns/1ps" "-quiet" "-work $rtl_work_lib"]
      if ($NOCOVERAGE==0) {
        lappend custom_options "-coverAll"
      }
      
      echo "Compiling RTL......"
      compile_files $compile_order_rtl $custom_options
      vlog -work $rtl_work_lib $XIL_GLBL_FILE
    }
    
    set tb_work_lib "work_tb"
    if {[file exists $tb_work_lib]} {
      vdel -lib $tb_work_lib -all
    }
    vlib $tb_work_lib
    
    variable OPT1 "+define+testfile=`include\"../testlib/$TESTCASE/$TESTCASE.sv\""
    variable custom_options [list "-permissive" "-timescale 1ns/1ps" "-work $tb_work_lib" $OPT1 $OPT_TIME]
    echo "Compiling TB......."
    compile_files $compile_order_tb $custom_options

    variable top_module_name "$tb_work_lib.$MODULE"
    
    variable SIMOPT "-L $rtl_work_lib ${rtl_work_lib}.glbl"
    
    if {$NOWLF == "False" || $NOWLF == 0} {
      variable SIMOPT [concat $SIMOPT "-wlf waveform.wlf"]
    }
    
    if {$NOCOVERAGE == "False" || $NOCOVERAGE == 0} {
      variable SIMOPT [concat $SIMOPT "-coverage"]
    }
    
    eval vsim -c $SIMOPT $top_module_name -voptargs=+acc
    
    set NoQuitOnFinish 1
    onbreak {resume}
    
    if {$NOWLF == "False" || $NOWLF == 0} {
      add log -r /*
    }
    
    run -all
    
    if {$NOCOVERAGE == "False" || $NOCOVERAGE == 0} {
      coverage report -byinstance -file coverage_rpt.txt
      coverage report -byinstance -totals -append -file coverage_rpt.txt
      coverage save $TESTCASE.ucdb
    }
    
    variable end_sim_time [clock milliseconds]
    variable total_time [expr $end_sim_time - $start_sim_time]
    
    set currentTime [clock seconds]
    set formattedTime [clock format $currentTime]
    
    puts "***************************************************************"
    puts "* Simulation completed @ $formattedTime"
    puts "* Total simulation time: $total_time in ms"
    puts "***************************************************************"
    
    quit
    
  }

  sim_run
  
}