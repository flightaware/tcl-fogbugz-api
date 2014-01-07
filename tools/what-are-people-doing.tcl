#!/usr/bin/env tclsh8.6
#
# Reference code for the FogBugz API Tcl package
#
# Lists all active users and the state of their "Working on" bug (interval)
#

package require fogbugz

proc main {} {
	lassign [::fogbugz::login] logged_in token
	if {!$logged_in} {
		puts "Unable to log in: $token"
		exit -1
	}

	#
	# We only want to look back a couple days, not at every interval since the beginning of time
	#
	set dtStart [clock format [expr [clock seconds] - (86400 * 2)] -format "%Y-%m-%dT00:00:00Z"]

	#
	# Iterate through each user using the listPeople method
	#
	foreach person [::fogbugz::getList People [dict create token $token]] {
		set ixPerson	[dict get $person ixPerson]
		set sFullName	[dict get $person sFullName]

		unset -nocomplain ixBug sTitle

		#
		# Iterate through each of this user's recent intervals looking for an open-ended one
		#
		foreach interval [::fogbugz::getList Intervals [dict create token $token ixPerson $ixPerson dtStart $dtStart]] {
			# puts $interval

			if {![dict exists $interval dtEnd]} {
				#
				# No dtEnd means the interval is in progress.
				#
				set ixBug	[dict get $interval ixBug]
				set sTitle	[dict get $interval sTitle]
				set since	[dict get $interval dtStart_epoch]
			}
		}

		if {[info exists ixBug]} {
			set hours [format "%4.2f" [expr ([clock seconds].00 - $since.00) / 60.00 / 60.00]]
			set working_on "$sTitle ($ixBug) for $hours hours"
		} else {
			set working_on "?"
		}
		puts "[format "%-20s" $sFullName]: $working_on"
	}

	::fogbugz::logoff $token
}

if !$tcl_interactive main
