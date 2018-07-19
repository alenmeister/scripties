# rt.tcl [12 December 2012] 
# Copyright (C) 2011-2012 Alen Mistric <anigma@purehype.no>
#
# Latest version can be found on https://www.purehype.no/lang/tcl/
# 
# If you have any suggestions, questions or you want to report 
# bugs, please feel free to send me an email: anigma (at) purehype (dot) no
# 
#
# Tested on eggdrop1.6.21 with TCL 8.4.19


### SETTINGS ###

# WHAT COMMAND PREFIX DO YOU WANT TO USE FOR CHANNEL COMMANDS?
set rt_cmdpfix "."

# WHAT USERS CAN CHANGE THE TOPIC?
set rt_flag "o|o"

# WHAT FILE DO YOU WANT TO USE FOR STORING TOPICS?
set rt_file "topics.dat"


### BINDINGS ###

bind pub $rt_flag ${rt_cmdpfix}rt pub:rt_rt

### PROCEDURES ###

proc pub:rt_rt {nick uhost hand chan arg} {
global rt_file rt_cmdpfix
if {[lindex [split $arg] 0] != ""} { set chan [lindex [split $arg] 0] }
	if {(![file exists $rt_file]) || (![file readable $rt_file])} { 
		putserv "NOTICE $nick :Unable to read from file $rt_file."
	} else {
		if {![rt_botonchan $chan]} {
			putserv "NOTICE $nick :I'm not on $chan."
		} else {
			set topic [rt_gettopic]
			if {($topic != "") && (([botisop $chan]) || (![string match "*t*" [lindex [getchanmode $chan] 0]]))} {
				putserv "TOPIC $chan :$topic" 
			} else {
				putserv "NOTICE $nick :Unable to change topic of $chan."
			}
		}
	}
return 1
}

proc rt_botonchan {chan} {
global botnick numversion
	if {$numversion < 1032400} {
		if {([validchan $chan]) && ([onchan $botnick $chan])} {
			return 1
		} else {
			return 0
		}
	} else {
		if {([validchan $chan]) && ([botonchan $chan])} {
			return 1
		} else {
			return 0
		}
	}
}

proc rt_gettopic { } {
global rt_file
set topics ""
	set fd [open $rt_file r]
	while {![eof $fd]} { 
		gets $fd text
		if {$text != ""} {
			lappend topics $text
		}
	}
	close $fd
	return [lindex $topics [rand [llength $topics]]]
}


### End ###

if {![info exists rt_loaded]} {
	set rt_loaded 1
}

putlog "Loaded rt.tcl by Alen Mistric"
