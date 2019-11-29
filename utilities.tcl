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
# @proc get_nth_from_list
# Extracts an element from a list with records
# Example: [get_nth_from_list 0 [list {k1 v1} k2 {k3 v3}]]
# Result: k1 k2 k3
# @param list a list with key/value pairs
proc get_nth_from_list {nth list} {
   return [lmap x $list {expr {
      [lindex $x $nth]
   }}]
}

proc strip_from_list {nth list} {
   return [lmap x $list {expr {
      [lreplace $x $nth $nth]
   }}]
}


########################################
# @proc function
# @param name name of procedure to create
# @param arguments a list of parameters of the
#        function and their default values
# @param script the code body of the function
#

# helper function
proc required_arg var {
   switch -glob [lindex $var 0] {
      req* {return [lindex $var 1]}
      opt* {return {}}
      default {error UNKNOWN_FLAG "Unknown flag '[lindex $var 0]' for argument '[lindex $var 1]' - only 'required' or 'optional' are allowed"}
   }
}

proc function {name arguments script} {
   proc $name args [
      set code ""
      set required [lmap x [lmap var $arguments {expr {
         [required_arg $var]
      }}] {expr { $x eq {} ? [continue] : $x }} ]

      foreach arg $arguments {
         append code "set [lindex $var 1] {[lindex $var 2]}\n"
      }
      set parameters [keyvalue_list_to_array [strip_from_list 0 $arguments]]
      set param_names [lsort [get_nth_from_list 1 $arguments]]

      append code [string map [list SCRIPT $script PROCNAME $name PARAM_NAMES $param_names REQUIRED $required PARAMS $parameters] {
         array set defaults [list PARAMS]
         foreach {var val} $args {
            set varname [string trim $var -]
            set found($varname) 1
            #puts "Setting arg $varname = $val"
            #if {![info exists $varname]}
            if {![info exists defaults($varname)]} {
               error NO_SUCH_OPTION "bad option '$varname', should be one of: PARAM_NAMES"
            }
            set $varname $val
         }

         set missing [lmap varname [list REQUIRED] {expr {
            [info exists found($varname)] ? [continue] : "'$varname'"
         }}]

         set missing_count [llength $missing]
         if { $missing_count > 0 } {
            error MISSING_OPTION "missing mandatory option[expr {
               $missing_count > 1 ? {s} : {}
            }] $missing"
         }

         #puts "Executing PROCNAME"

         SCRIPT
      }]
   ]
}

if (0) {
   function testproc {{reqired text} {optional case "upper"}} {
      switch -- $case {
         upper {set text [string toupper $text]}
         lower {set text [string tolower $text]}
      }
      puts $text
   }

   # error: Unknown flag 'foo' for argument 'arg' - only 'required' or 'optional' are allowed
   #
   #function xxx {{foo arg}} {
   #    puts $arg
   #}


   # Calling "testproc":
   #testproc                         ;# error 'missing mandatory option 'text'
   #testproc -foo bar                ;# error "bad otpion 'foo'
   testproc -text Hello              ;# this prints out 'HELLO'
   testproc -text Hello -case upper  ;# this prints out 'HELLO'
   testproc -text Hello -case lower  ;# this prints out 'hello'
   testproc -text Hello -case none   ;# this prints out 'Hello'
}
