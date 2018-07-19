# topic.tcl [12 March 2014]
# Copyright (C) 2013 Alen Mistric <anigma@purehype.no>
#
# Latest version can be found on https://www.purehype.no/lang/tcl/
#
# If you have any suggestions, questions or you want to report 
# bugs, please feel free to send me an email: anigma (at) purehype (dot) no
#
# Tested on eggdrop1.6.21 with TCL 8.6.1


### BINDINGS ###

bind pub o|o .topic public:topic
bind pub o|o .append public:append

### PROCEDURES ###

proc public:topic {nickname hostname handle channel arguments} {
if {![botisop $channel]} {
	puthelp "NOTICE $nickname :Sorry, I'm not an OP on $channel!"
return 0
}

set arguments [split $arguments]

	if {![llength $arguments] > 0} {
		puthelp "NOTICE $nickname :Syntax: .topic \[text\]"
	return 0
	} else {
		putserv "TOPIC $channel :[join [lrange $arguments 0 end]] ($handle)" 
	}
}

proc public:append {nickname hostname handle channel arguments} {
if {![botisop $channel]} {
	puthelp "NOTICE $nickname :Sorry, I'm not an OP on $channel!"
return 0
}

set arguments [split $arguments]
	
	if {![$llength $arguments] > 0} {
		puthelp "NOTICE $nickname :Syntax: .append \[text\]"
	return 0
	} else {
	set topic [topic $channel]
		putserv "TOPIC $channel :$topic [join [lrange $arguments 0 end]] ($handle)"
	}
}

### END ###  

putlog "Loaded topic.tcl by Alen Mistric"
