Tcl FogBugz XML API Package
===========================

This package provides a Tcl native interface to the FogBugz XMP API as 
documented at http://fogbugz.stackexchange.com/fogbugz-xml-api

Currently this package only supports login and the various list methods of
the API.

Requirements
------------

* A [FogBugz](http://www.fogcreek.com/fogbugz/) server or FogBugz On Demand account
* Tcl 8.4 or newer
* [tDOM](https://github.com/tDOM/tdom)

Other Stuff that's Included
---------------------------

* fogbugz-git-hook is a script which can be used to auto-populate a BUGZID
  reference in git commits based on the user's "Currently Working On" setting
  on the FogBugz server.
