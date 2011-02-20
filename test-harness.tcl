#!/usr/bin/env tclsh8.5

source main.tcl
if {[catch {source config.tcl} err]} {
	puts "No configuration found: $err"
	exit -1
}

proc rule {} {
	puts "-- "
}

proc main {} {
	set verbose 0

	parray ::fogbugz::config
	lassign [::fogbugz::login] logged_in token
	if {!$logged_in} {
		puts "Unable to log in: $token"
		exit -1
	}
	puts "Logged in with token $token"

	rule

	if {0} {
		foreach listType [array names ::fogbugz::listResult] {
			set result [::fogbugz::getList $listType [dict create token $token]]
			puts "list$listType returned [llength $result] items"
			if {$verbose} {
				foreach item $result {
					puts "- $item"
				}
			}
		}
		rule
	}

	if {1} {
		# puts [::fogbugz::raw_cmd viewPerson [dict create token $token ixPerson 2]]
		puts [::fogbugz::view Person [dict create token $token ixPerson 2]]
		rule
		puts [::fogbugz::view Status [dict create token $token ixStatus 2]]
		rule
	}


	::fogbugz::logoff $token
}

if !$tcl_interactive main
