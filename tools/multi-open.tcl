#!/usr/bin/env tclsh8.6
#
# Reference code for the FogBugz API Tcl package
#
# Example of using FogBugz API to create a meta/sub bug for
# tracking the same issue/feature on all mobile platforms
#

package require fogbugz

proc main {argv} {
	lassign [::fogbugz::login] logged_in token
	if {!$logged_in} {
		puts "Unable to log in: $token"
		exit -1
	}

	#foreach c [::fogbugz::getList People [dict create token $token]] {
	#	puts $c
	#}
	#exit

	#
	# These static IDs were just pulled by hand out of our FogBugz server
	#

	# Areas
	set areas {91 92 37 94}

	# set ixPerson to current user
	lassign [::fogbugz::whoami [dict create token $token]] ixPerson sFullName
	puts "You are $sFullName ($ixPerson)"

	#
	# ixPerson* : 2=nugget 3=dbaker
	# ixCategory: 1=Bug 2=Feature 3=Inquiry 4=Schedule Item 5=Code Review
	# ixPriority: 1-7 (On Fire .. Placard InOp)
	#
	array set master {
		ixProject			11
		ixArea				98
		ixCategory			1
		ixPriority			3
		sTitle				"Test Case"
		sEvent				"This is a test bug, please ignore it"
	}

	set master(ixPersonEditedBy)	$ixPerson

	parray master

	puts "Creating master case"

	lassign [::fogbugz::raw_cmd new [array get master]] success xml error

	if {!$success} {
		puts "Unable to create master bug: $error"
		exit -1
	}

	puts $xml

	if {[regexp {ixBug="(\d+)"} $xml _ ixBug]} {
		puts "Created BUGZID $ixBug: ($master(sTitle))"

		foreach a $areas {
			unset -nocomplain subcase
			set subcase(ixProject)		11
			set subcase(ixArea)			$a
			set subcase(ixBugParent)	$ixBug
			set subcase(ixPriority)		$master(ixPriority)
			set subcase(sTitle)			$master(sTitle)
			set subcase(sEvent)			"This is a platform-specific subcase\n-- \n$master(sEvent)"
			set subcase(ixPersonEditedBy)	$ixPerson

			lassign [::fogbugz::raw_cmd new [array get subcase]] success xml error
			puts " -- Created subase for area $a"
		}
	}

	::fogbugz::logoff $token
}

if !$tcl_interactive {
	main $argv
}
