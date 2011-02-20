#!/usr/bin/env tclsh8.5

package require http
package require tdom
package require tls

namespace eval ::fogbugz {

proc debug {buf} {
	if {$::fogbugz::debug} {
		puts $buf
	}
}

proc load_globals {} {
	set ::fogbugz::debug 0

	set ::fogbugz::listResult(Filters)		{filters filter}
	set ::fogbugz::listResult(Intervals)	{intervals interval}
	set ::fogbugz::listResult(People)		{people person}
	set ::fogbugz::listResult(Projects)		{projects project}
	set ::fogbugz::listResult(Areas)		{areas area}
	set ::fogbugz::listResult(Categories)	{categories category}
	set ::fogbugz::listResult(Priorities)	{priorities priority}
	set ::fogbugz::listResult(Statuses)		{statuses status}
	set ::fogbugz::listResult(FixFors)		{fixfors fixfor}
	set ::fogbugz::listResult(Mailboxes)	{mailboxes mailbox}
	set ::fogbugz::listResult(Wikis)		{wikis wiki}
	set ::fogbugz::listResult(Snippets)		{snippets snippet}
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
		set ::fogbugz::config(token) $token
		return [list 1 $token]
	}

	return [list 0 "Unknown Error"]
}

proc raw_cmd {cmd {dict ""}} {
	set qs    [::http::formatQuery cmd $cmd]
	if {[info exists ::fogbugz::config(token)] && (![dict exists $dict token] || [dict get $dict token] == "")} {
		# If no token supplied to the proc, use the variable one if set
		dict set dict token $::fogbugz::config(token)
	}
	foreach arg [dict keys $dict] {
		append qs "&[::http::formatQuery $arg [dict get $dict $arg]]"
	}
	lassign [get_xml $::fogbugz::config(api_url) $qs] success xml error
	if {!$success} {
		debug "raw_cmd $cmd ERROR: $error" $xml]
	}

	return [list $success $xml $error]
}

proc logoff {{token ""}} {
	lassign [raw_cmd logoff [dict create token $token]] success xml error
	return [list $success $xml $error]
}

proc parse_element {element type} {
	foreach domNode [split [$element getElementsByTagName *]] {
		set field [$domNode nodeName]
		set value [$domNode asText]
		debug "$field = $value"
		if {$value != ""} {
			dict set retdict $field $value
		}
	}
	foreach field [split [$element attributes *]] {
		set value [$element getAttribute $field]
		debug "$field = $value *"
		if {$value != ""} {
			dict set retdict $field $value
		}
	}

	foreach attr {data text target} {
		catch {dict set retdict $attr [$element $attr]}
	}

	if {[info exists retdict]} {
		return $retdict
	}

	return
}

proc getList {object dict} {
	lassign [raw_cmd "list$object" $dict] success xml error

	if {!$success} {
		return [list 0 "getList $object ERROR: $error" $xml]
	}

	debug "-- $object xml --\n$xml"
	set dom [dom parse $xml]
	set doc [$dom documentElement]
	set selectPath "/[join [concat "response" $::fogbugz::listResult($object)] "/"]"
	debug "-- $object selectPath: $selectPath --"
	set nodeList [$doc selectNodes $selectPath]
	debug "== $object nodeList ==\n$nodeList"

	set returnList [list]

	foreach obj $nodeList {
		set retbuf [parse_element $obj [lindex $::fogbugz::listResult($object) end]]
		debug $retbuf
		lappend returnList $retbuf
	}

	$dom delete

	#if {[llength $returnList] == 0} {
	#	puts "No elements in $object List"
	#	puts "-- \n$xml\n-- "
	#}

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
