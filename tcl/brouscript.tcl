# brouscript.tcl [29 October 2013]
# Copyright (C) 2013 Alen Mistric <anigma@purehype.no>
#
# Latest version can be found on https://www.purehype.no/lang/tcl/
#
# If you have any suggestions, questions or you want to report 
# bugs, please feel free to send me an email: anigma (at) purehype (dot) no
#
# Tested on eggdrop1.6.21 with TCL 8.5.11

### SETTINGS ###

# HOW DO YOU WANT TO BAN THE USER? DEFAULT 1
#  0 - *!*user@*.domain
#  1 - *!*@host.domain
set brou(bantype) 1

# SET THE CHARACTER THAT WILL BE USED BEFORE PUBLIC QUERIES
set brou(cmdchar) "."

# ENABLE (1) OR DISABLE (0) PROTECTION AGAINST BANS MADE 
# BY LOWER USERS AGAINST HIGHER USERS. IF THE BAN IS SET BY A CHAN MASTER, 
# ONLY A WARNING IS DISPLAYED. IF NOT, THE FLAG OF THE USER AND OF 
# THE VICTIM(S) ARE COMPARED. IF THE VICTIM HAS THE HIGHEST FLAG, 
# THE BAN IS REMOVED BY THE BOT. THE BOT ALSO REMOVES BANS THAT MATCH ITSELF.
set brou(ban_protect) 1

# SET THE FLAGS FOR USERS THAT YOU DO NOT WANT KICKED IN THE EVENT OF
# A !BAN <HOSTMASK>, THE OPED OR VOICED USERS AT THE MOMENT OF THE KICK 
# ARE NOT KICKED, THIS SETTING ONLY AFFECTS THE OTHER USERS IN THE CHAN. 
set brou(no_ban_flags) "nmov"

### BINDINGS ###

bind pub o|o [string trim $brou(cmdchar)]ban pub_ban
bind pub o|o [string trim $brou(cmdchar)]unban pub_unban
bind pub o|o [string trim $brou(cmdchar)]banlist pub_banlist
bind pub o|o [string trim $brou(cmdchar)]help pub_help

### PROCEDURES ###

proc pub_banlist {nick host hand chan arg} {
	set arg [charfilter $arg]
	global brou botnick
	set num 1
      puthelp "NOTICE $nick :Channel bans for $chan:"
	foreach bans [banlist $chan] {
		set victim [lindex $bans 0]
		set why [lindex $bans 1]
		set expire [lindex $bans 2]
		set who [lindex $bans 5]
		set remain [expr $expire - [unixtime]]
		if {$remain > 0} {
			set remain "expire in [time_diff2 $expire]."
		} {
			set remain "PermBan"
		}
		puthelp "NOTICE $nick :\002BAN $num:\002 $victim, $remain"
		puthelp "NOTICE $nick :$who: $why"
		incr num
	}
      if {$num == 1} {puthelp "NOTICE $nick :There are no bans, permanent or otherwise."}
	return 0
}

proc pub_ban {nick host hand chan arg} {
	set arg [charfilter $arg]
	global brou botnick
	if {[llength $arg] < 1} {
		puthelp "NOTICE $nick :Syntax: [string trim $brou(cmdchar)]ban <nickname> \[time\] \[reason\]"
		return 0
	}
	set who [lindex $arg 0]
	if {[strlwr $who] == [strlwr $botnick]} {
		puthelp "NOTICE $nick :Yeah right, like I'm going to let you ban ME!"
		return 0
	}
	
	set ti [lindex $arg 1]
	if {[isnumber $ti]} {
		set reason [lrange $arg 2 end]
	} {
		set ti ""
		set reason [lrange $arg 1 end]
	}

	if {$reason == ""} { set reason "requested" }
	
	if {[onchan $who $chan]} {
		if { $brou(bantype) == 0 } { 
			set ipmask [lindex [split [maskhost $who![getchanhost $who $chan]] "@"] 1]
			set usermask [lindex [split [getchanhost $who $chan] "@"] 0]		
			set banmask *!*$usermask@$ipmask
		} else { 
			set banmask [getchanhost $who $chan]
     	      	set banmask "*!*[string range $banmask [string first @ $banmask] e]" 
		}	
	} else {  		
		set banmask [lindex $arg 0]
		if {[string first "!" $banmask] == -1 && [string first "@" $banmask] == -1} {
			if {[isnumber [string index $banmask 0]]} { 
				set banmask *!*@$banmask 
			} else {
				 set banmask $banmask*!*@* 
			}
		}
		if {[string first "!" $banmask] == -1} { set banmask *!*$banmask }
		if {[string first "@" $banmask] == -1} { set banmask $banmask*@* }
	}
			   		
	if {![botisop $chan]} { return 0 }
	putserv "MODE $chan +b $banmask"

  	foreach chanuser [chanlist $chan] {
      	if {[string match [strlwr $banmask] [strlwr "$chanuser![getchanhost $chanuser $chan]"]] && $chanuser != $botnick } { 
			if {[nick2hand $chanuser $chan] != "*"} {
				if {$hand != [nick2hand $chanuser $chan]} {
					if {[matchattr [nick2hand $chanuser $chan] o|o $chan] && ![matchattr $hand o|o $chan]} {
                  	            puthelp "NOTICE $nick :Sorry, you must be an operator to ban an operator."
						return 0
					}
					if {([matchattr [nick2hand $chanuser $chan] m|m $chan] || [matchattr [nick2hand $who $chan] b]) && ![matchattr $hand m|m $chan]} {
            	                  puthelp "NOTICE $nick :Sorry, you must be a master to ban a master or a bot."
						return 0
					}
				}
			}
	    	   	putkick $chan $chanuser $reason
		}
       }	 

	switch $ti {
		""
		{
			newchanban $chan $banmask $nick $reason
			puthelp "NOTICE $nick :New mask added : $banmask"
		}
		0
		{
			newchanban $chan $banmask $nick $reason $ti
			puthelp "NOTICE $nick :New mask added permanently : $banmask"
		}
		default
		{
			newchanban $chan $banmask $nick $reason $ti
			puthelp "NOTICE $nick :New mask added for $ti minutes : $banmask"
		}
	}
	return 0
}

proc pub_unban {nick host hand chan arg} {
	set arg [charfilter $arg]
	global brou botnick
	if {[llength $arg] != 1} {
		puthelp "NOTICE $nick :Syntax: [string trim $brou(cmdchar)]unban <hostmask or number>"
		return 0
	}
	set find 0
	set mask [lindex $arg 0]

	if {[isnumber $mask]} {
		foreach bans [banlist $chan] {
			incr find
			if {$find == $mask} { set mask [lindex $bans 0] ; break }
		}
		if {[isnumber $mask]} {
			puthelp "NOTICE $nick :There is no ban number $mask in this chan, type .bans."
			return 0
		} 
	} else {	if {[string first "!" $mask] == -1 && [string first "@" $mask] == -1} {
				if {[isnumber [string index $mask 0]]} { set mask *!*@$mask 
				} else { set mask $mask*!*@* }
			}
			if {[string first "!" $mask] == -1} {set mask *!*$mask}
			if {[string first "@" $mask] == -1} {set mask $mask*@*}
	}
	
	if {[isban $mask $chan]} { 
		killchanban $chan $mask
		killban $mask
		puthelp "NOTICE $nick :Ban successfully removed on $chan."
		return 0
	} 

	foreach bans [chanbans $chan] {
		set victim [lindex $bans 0]
		if {[strlwr $victim] == [strlwr $mask]} {set find 1}
	}

	if {[botisop $chan] && $find == 1} {
		pushmode $chan -b $mask
            puthelp "NOTICE $nick :Ban successfully removed."
		return 0
	}
		
	puthelp "NOTICE $nick :No such ban on $chan."
	return 0
}

proc pub_help {nick host hand chan arg} {
	set arg [charfilter $arg]
	global brou botnick
	if {![validuser $hand]} {return 0}
	puthelp "NOTICE $nick :\002\[BrouScript\]\002:"
	if {[matchattr $hand o|o $chan]} {
		puthelp "NOTICE $nick :[string trim $brou(cmdchar)]BANLIST - Current bans in channel."  
		puthelp "NOTICE $nick :[string trim $brou(cmdchar)]BAN <nickname> \[time\] \[reason\]"
		puthelp "NOTICE $nick :[string trim $brou(cmdchar)]UNBAN <hostmask or number>"
	}
}

### MISCELLANEOUS ###

proc ban_warn {nick hand ban chan victims} {
	global brou
	if {![botisop $chan] || [strlwr $hand] == [string trimright [strlwr $victims] " "] || $brou(ban_protect) == 0} {return 0}
	if {$hand == "*"} {
		if {[string first +userbans [channel info $chan]] != -1} {
                  puthelp "NOTICE $nick :Your ban matches my users ! Be careful !"
			putserv "MODE $chan -b $ban"
		}
	return 0
	}
	set remove 0
	foreach user $victims {
		if {([matchattr $user m|m $chan] || [matchattr $user b]) && !([matchattr $hand m|m $chan] || ([matchattr $hand o|o $chan] && [matchattr $hand b]))} {
			set remove 1
			break
		}
		if {([matchattr $user o|o $chan] || [matchattr $user v|v $chan]) && ![matchattr $hand o|o $chan]} {
			set remove 1
			break
		}
	}
	if {$remove == 1} {putserv "MODE $chan -b $ban"}
	if {![matchattr $hand b]} {
		if {[llength $victims] > 1} {
            	puthelp "NOTICE $nick :Your ban in $chan ($ban), matches my users: $victims"
		} {
                  puthelp "NOTICE $nick :Your ban in $chan ($ban), matches one of my users: $victims"
		}
	}
	return 0
}

proc time_diff2 {time} {
	set ltime [expr $time - [unixtime]]
	set seconds [expr $ltime % 60]
	set ltime [expr ($ltime - $seconds) / 60]
	set minutes [expr $ltime % 60]
	set ltime [expr ($ltime - $minutes) / 60]
	set hours [expr $ltime % 24]
	set days [expr ($ltime - $hours) / 24]
	set result ""
	if {$days} {
		append result "$days "
		if {$days} {
			append result "day "
		} {
			append result "days "
		}
	}
	if {$hours} {
		append result "$hours "
		if {$hours} {
			append result "hour "
		} {
			append result "hours "
		}
	}
	if {$minutes} {
		append result "$minutes "
		if {$minutes} {
			append result "minute"
		} {
			append result "minutes"
		}
	}
	if {$seconds} {
		append result " $seconds "
		if {$seconds} {
			append result "second"
		} {
			append result "seconds"
		}
	}
	return $result
}

proc time_diff {time} {
	set ltime [expr [unixtime] - $time]
	set seconds [expr $ltime % 60]
	set ltime [expr ($ltime - $seconds) / 60]
	set minutes [expr $ltime % 60]
	set ltime [expr ($ltime - $minutes) / 60]
	set hours [expr $ltime % 24]
	set days [expr ($ltime - $hours) / 24]
	set result ""
	if {$days} {
		append result "$days "
		if {$days} {
			append result "day "
		} {
			append result "days "
		}
	}
	if {$hours} {
		append result "$hours "
		if {$hours} {
			append result "hour "
		} {
			append result "hours "
		}
	}
	if {$minutes} {
		append result "$minutes "
		if {$minutes} {
			append result "minute"
		} {
			append result "minutes"
		}
	}
	if {$seconds} {
		append result " $seconds "
		if {$seconds} {
			append result "second"
		} {
			append result "seconds"
		}
	}
	return $result
}

proc charfilter {x {y ""} } {
	for {set i 0} {$i < [string length $x]} {incr i} {
		switch -- [string index $x $i] {
			"\"" {append y "\\\""}
			"\\" {append y "\\\\"}
			"\[" {append y "\\\["}
			"\]" {append y "\\\]"}
			"\} " {append y "\\\} "}
			"\{" {append y "\\\{"}
			default {append y [string index $x $i]}
		}
	}
	return $y
}

### END ###

putlog "Loaded brouscript.tcl by Alen Mistric"
