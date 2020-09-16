puts {
  ModelSim general compile script version 1.2
  Copyright (c) Doulos June 2017, SD
}

# Simply change the project settings in this section
# for each new project. There should be no need to
# modify the rest of the script.
set workDir [pwd]
set workLevel 0

# Placeholder file which confirms the existence of temp folder
set placeholderFile "placeholder.dat"

# Path to script for recursion
set scriptDir $workDir/../compile.tcl

# Recursive compile and generated garbage files into a temp folder
if { [file exists $placeholderFile] == 0 } {
  puts "Creating the temp folder"
  file mkdir $workDir/temp
  cd temp
  set fp [open $placeholderFile w]
  puts $fp "keep this file"
  close $fp
  set script $workDir/compile.tcl
  set workLevel 1
}

# Pathing (with logic for recursion)
if { $workLevel == 1 } {
  set rootDir $workDir/../..
  puts "rootDir set to $rootDir"
} else {
  set rootDir $workDir/../../..
  puts "rootDir set to $rootDir"
}

set library_file_list {
  
  icePU   { $rootDir/src/icePU/reg32_8_rtl.vhdl }
  
  test    { $rootDir/test/src/reg32_8_tb.vhdl }  
} 

set top_level              test.reg32_8_tb
set wave_patterns {
                           /*
}
set wave_radices {
                           hexadecimal {data q}
}


# After sourcing the script from ModelSim for the
# first time use these commands to recompile.

proc r  {} {
  global script
  uplevel #0 source $script
}
proc rr {} {
  global last_compile_time
  set last_compile_time 0
  r                            
}
proc q  {} {
  quit -force                  
}

#Does this installation support Tk?
set tk_ok 0
if [catch {package require Tk}] {set tk_ok 0}

# Prefer a fixed point font for the transcript
set PrefMain(font) {Courier 10 roman normal}

# Compile out of date files
set time_now [clock seconds]
if [catch {set last_compile_time}] {
  set last_compile_time 0
}

foreach {name file_list} $library_file_list {
  puts "Compiling files for libraray $name"
  vlib $name
  foreach path $file_list {
    set file [subst -nocommands $path]
    puts "Compiling library $file"
    if { $last_compile_time < [file mtime $file] } {
      if [regexp {.vhdl?$} $file] {
        vcom -2008 -work $name $file
      } else { 
        vlog -work $name $file
      }
    }
    set last_compile_time 0
  }
}

set last_compile_time $time_now

# Load the simulation
eval vsim -voptargs=+acc $top_level

# If waves are required
if [llength $wave_patterns] {
  noview wave
  foreach pattern $wave_patterns {
    add wave $pattern
  }
  configure wave -signalnamewidth 1
  foreach {radix signals} $wave_radices {
    foreach signal $signals {
      catch {property wave -radix $radix $signal}
    }
  }
}

# Run the simulation (disabled by default)
# run -all

# If waves are required
if [llength $wave_patterns] {
  if $tk_ok {wave zoomfull}
}

puts {
  Script commands are:

  r = Recompile changed and dependent files
 rr = Recompile everything
  q = Quit without confirmation
}

# How long since project began?
if {[file isfile start_time.txt] == 0} {
  set f [open start_time.txt w]
  puts $f "Start time was [clock seconds]"
  close $f
} else {
  set f [open start_time.txt r]
  set line [gets $f]
  close $f
  regexp {\d+} $line start_time
  set total_time [expr ([clock seconds]-$start_time)/60]
  puts "Project time is $total_time minutes"
}