#!/usr/bin/env tclsh

########################################
# @proc keyvalue_list_to_array
# Flattens a list with key/value pairs
# and makes sure that every pair produces
# two elements in the resulting list.
# The result can be used to create an array
# with `array set arr [keyvalue_list_to_array [list {key1 value1} {key2]]
# @param list a list with key/value pairs
proc keyvalue_list_to_array {list} {
   return [join [lmap x $list {expr {
      [list [lindex $x 0] [lindex $x 1]]
   }}]]
}

########################################
# @proc keyvalue_list_to_keys
# Extracts the keys from a list with
# key/value pairs
# Example: [keyvalue_list_to_keys {k1 v1} k2 {k3 v3}]
# Result: k1 k2 k3
# @param list a list with key/value pairs
proc keyvalue_list_to_keys {list} {
   return [lmap x $list {expr {
      [lindex $x 0]
   }}]
}


########################################
# @proc function
# @param name name of procedure to create
# @param arguments a list of parameters of the
#        function and their default values
# @param required a list of required parameters
# @param script the code body of the function
proc function {name arguments required script} {
   proc $name args [
      set code ""
      foreach var $arguments {
         append code "set [lindex $var 0] {[lindex $var 1]}\n"
      }
      set parameters [keyvalue_list_to_array $arguments]
      set param_names [lsort [keyvalue_list_to_keys $arguments]]

      append code [string map [list SCRIPT $script PROCNAME $name PARAM_NAMES $param_names REQUIRED $required PARAMS $parameters] {
         array set defaults [list PARAMS]
         foreach {var val} $args {
            set varname [string trim $var -]
	    set found($varname) 1
            #puts "Setting arg $varname = $val"
            #if {![info exists $varname]} 
            if {![info exists defaults($varname)]} {
               error "bad option '$varname', should be one of: PARAM_NAMES"
            }
            set $varname $val
         }

         set missing [lmap varname [list REQUIRED] {expr {
	    [info exists found($varname)] ? [continue] : "'$varname'"
	 }}]

         set missing_count [llength $missing]
	 if { $missing_count > 0 } {
	    error "missing mandatory option[expr {
	       $missing_count > 1 ? {s} : {}
	    }] $missing"
	 }

         #puts "Executing PROCNAME"

         SCRIPT
      }
   ]]
}

if (0) {
   function testproc {text {case "upper"}} {text} {
      switch -- $case {
         upper {set text [string toupper $text]}
         lower {set text [string tolower $text]}
      }
      puts $text
   }

   # Calling "testproc":
   #testproc                         ;# error 'missing mandatory option 'text'
   #testproc -foo bar                ;# error "bad otpion 'foo'
   testproc -text Hello              ;# this prints out 'HELLO'
   testproc -text Hello -case upper  ;# this prints out 'HELLO'
   testproc -text Hello -case lower  ;# this prints out 'hello'
   testproc -text Hello -case none   ;# this prints out 'Hello'
}
