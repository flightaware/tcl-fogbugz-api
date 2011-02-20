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

	::fogbugz::logoff $token
}

if !$tcl_interactive main
