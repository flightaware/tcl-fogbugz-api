#!/usr/bin/env tclsh8.5

package require http
package require tdom
package require tls

namespace eval ::fogbugz {

set ::fields(ixPerson) [list ixPerson sFullName sEmail sPhone fAdministrator fCommunity fVirtual fDeleted fNotify sHomepage sLocale sLanguage sTimeZoneKey fExpert]
set ::fields(interval) [list ixBug ixInterval dtStart dtEnd sTitle ixPerson]

proc get_xml {url qs} {
	while {![info exists dh]} {
		if { [catch {set dh [::http::geturl $url -query $qs]} err] } {
			puts "Retrying http geturl: $err"
			after 2000
		}
	}

	set xml [::http::data $dh]
	set dom [dom parse $xml]
	set doc [$dom documentElement]

	set error [$doc selectNodes {string(/response/error)}]
	set code  [$doc selectNodes {string(/response/error/@code)}]
	$dom delete

	if {$error != ""} {
		return [list 0 $xml "$error ($code)"]
	}

	return [list 1 $xml]
}

proc login {url email password} {
	::http::register https 443 ::tls::socket

	set ::fogbugz::url $url

	set qs	[::http::formatQuery cmd logon email $email password $password]
	lassign [get_xml $::fogbugz::url $qs] success xml error

	if {!$success} {
		return [list 0 $error]
	}

	set dom [dom parse $xml]
	set doc [$dom documentElement]
	set token [$doc selectNodes {string(/response/token)}]
	$dom delete

	if {$token != ""} {
		return [list 1 $token]
	}

	return [list 0 "Unknown Error"]
}

proc parse_element {element type} {
	foreach field $::fields($type) {
		# debug "Parsing $element :: $field"
		set value [[$element getElementsByTagName $field] asText]
		dict set retdict $field $value
	}

	return $retdict
}

proc listPeople {dict} {
	set qs [::http::formatQuery cmd listPeople token [dict get $dict token]]
	lassign [get_xml $::fogbugz::url $qs] success xml error

	if {!$success} {
		return [list 0 $error $xml]
	}

	# puts "-- \n$xml\n-- "
	set dom [dom parse $xml]
	set doc [$dom documentElement]
	set people [$doc selectNodes {/response/people/person}]
	# puts "== \n$people\n== "

	set peopleList [list]

	foreach person $people {
		lappend peopleList [parse_element $person ixPerson]
	}

	$dom delete

	return $peopleList
}

proc whoami {dict} {
	set peopleList [listPeople $dict]

	if {[info exists ::env(fogbugz_ixPerson)]} {
		return $::env(fogbugz_ixPerson)
	}

	foreach person $peopleList {
		set this_id     [dict get $person ixPerson]
		set this_person [dict get $person sFullName]

		if {[info exists ::env(USER)] && [regexp $::env(USER) [dict get $person sEmail]]} {
			# puts "$this_id based on $::env(USER) matching sEmail [dict get $person sEmail]"
			return [list $this_id $this_person]
		}
	}

	return 0
}


proc listIntervals {dict} {
	set qs [::http::formatQuery cmd listIntervals ixPerson [dict get $dict ixPerson] token [dict get $dict token] dtStart [dict get $dict dtStart]]
	lassign [get_xml $::fogbugz::url $qs] success xml error

	if {!$success} {
		return [list 0 $error $xml]
	}

	# puts "-- \n$xml\n-- "
	set dom [dom parse $xml]
	set doc [$dom documentElement]
	set intervals [$doc selectNodes {/response/intervals/interval}]
	# puts "== \n$intervals\n== "

	set intervalsList [list]

	foreach interval $intervals {
		lappend intervalsList [parse_element $interval interval]
	}

	$dom delete

	return $intervalsList
}

}

package provide fogbugz 1.0
