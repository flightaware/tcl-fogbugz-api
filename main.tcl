#!/usr/bin/env tclsh8.5

package require http
package require tdom
package require tls

namespace eval ::fogbugz {

proc load_globals {} {
	set ::fogbugz::fields(ixPerson) [list ixPerson sFullName sEmail sPhone fAdministrator fCommunity fVirtual fDeleted fNotify sHomepage sLocale sLanguage sTimeZoneKey fExpert]
	set ::fogbugz::fields(interval) [list ixBug ixInterval dtStart dtEnd sTitle ixPerson]

	set ::fogbugz::objType(People) ixPerson
}

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

proc login {{api_url ""} {email ""} {password ""}} {
	::http::register https 443 ::tls::socket
	load_globals

	if {$api_url != ""} {
		set ::fogbugz::config(api_url)	$api_url
		set ::fogbugz::config(email)	$email
		set ::fogbugz::config(password)	$password
	}

	if {![info exists ::fogbugz::config(api_url)]} {
		return [list 0 "No FogBugz API URL is configured"]
	}

	set qs	[::http::formatQuery cmd logon email $::fogbugz::config(email) password $::fogbugz::config(password)]
	lassign [get_xml $::fogbugz::config(api_url) $qs] success xml error

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
	foreach field $::fogbugz::fields($type) {
		# debug "Parsing $element :: $field"
		set value [[$element getElementsByTagName $field] asText]
		dict set retdict $field $value
	}

	return $retdict
}

proc getList {object dict} {
	set object [string totitle $object]
	set qs [::http::formatQuery cmd "list$object" token [dict get $dict token]]
	# puts "qs ::${qs}::"
	lassign [get_xml $::fogbugz::config(api_url) $qs] success xml error

	if {!$success} {
		return [list 0 $error $xml]
	}

	# puts "-- \n$xml\n-- "
	set dom [dom parse $xml]
	set doc [$dom documentElement]
	set nodeList [$doc selectNodes {/response/people/person}]
	# puts "== \n$nodeList\n== "

	set returnList [list]

	foreach obj $nodeList {
		lappend returnList [parse_element $obj $::fogbugz::objType($object)]
	}

	$dom delete

	return $returnList
}

proc whoami {dict} {
	set peopleList [getList People $dict]

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

}

package provide fogbugz 1.0
