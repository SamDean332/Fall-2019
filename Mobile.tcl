#list clustering 

#Wireless Sensor Network 

#This is a proximity-based wireless sensor network for NS2

#Sam Dean - 2019

#Define WSN Options 
set val(chan)           Channel/WirelessChannel    ;# Channel Type
set val(prop)           Propagation/TwoRayGround   ;# radio-propagation model
set val(netif)          Phy/WirelessPhy/802_15_4   ;#802.15 is low level	
set val(mac)            Mac/802_15_4			   ;#802.15
set val(ifq)            Queue/DropTail/PriQueue    ;# interface queue type
set val(ll)             LL                         ;# link layer type
set val(ant)            Antenna/OmniAntenna        ;# antenna model
set val(ifqlen)         100000                         ;# max packet in ifq
set val(nn)             30                         ;# number of nodes
set val(rp)             DumbAgent                       ;#AODV low power low data; similar to 802.15
set val(x)  70
set val(y)  70


#Physical Layer Options - need to know more about Freq & bandwidth
Phy/WirelessPhy set freq_ 2.4e+9 ;# The working band is 2.4GHz 802.15.4 standard 
Phy/WirelessPhy set L_ 1.00   ;#Define teh system loss in TwoRayGround (default)
Phy/WirelessPhy set  bandwidth_  250.0*10e3   ;#250 kbps - 802.15.4 standard (0.25Mb) 

# For model 'TwoRayGround' - Look at indep-utils/propagation/threshold.cc 
# The received signals strenghts  in different distances
#set dist(5m)  7.69113e-06
#set dist(9m)  2.37381e-06
#set dist(10m) 1.92278e-06
#set dist(11m) 1.58908e-06
#set dist(12m) 1.33527e-06
#set dist(13m) 1.13774e-06
#set dist(14m) 9.81011e-07
#set dist(15m) 8.54570e-07
#set dist(16m) 7.51087e-07
#set dist(20m) 4.80696e-07
#set dist(25m) 3.07645e-07
#set dist(30m) 2.13643e-07
#set dist(35m) 1.56962e-07
#set dist(40m) 1.20174e-07
Phy/WirelessPhy set CPThresh_ 10.0; #Capture threshold - signal level at which a new packet can disrupt ongoing reception
Phy/WirelessPhy set CSThresh_ 1.5848931925e-12     ;#Carrier Sense Power   -88dBm 
Phy/WirelessPhy set RXThresh_ 3.1622776602e-12; #Receiver sensitivity - Min recieved signal power that is necessary to attempt decoding a packet 
Phy/WirelessPhy set Pt_ 0.00050118723363            ;#in W for Transmit Power -3dBm IEEE 802.15.4 standard

#Specified Parameters for 802.15.4 MAC
Mac/802_15_4 wpanCmd verbose on   ;# to work in verbose mode
Mac/802_15_4 wpanNam namStatus on  ;# default = off (should be turned on before other 'wpanNam' commands can work)

#new Sim
global ns
set ns [new Simulator]
#tracing
$ns use-newtrace
set ProxOut [open ProxOut.tr w]
$ns trace-all $ProxOut


#NAM
set ProxNam [open ProxNam.nam w]
$ns namtrace-all-wireless $ProxNam $val(x) $val(y)
$ns puts-nam-traceall {# nam4wpan #}  ;# inform nam that this is a trace file for wpan (special handling needed)

proc finish {} {
	global ns ProxNam
	$ns flush-trace
	close $ProxNam
	exec ./nam ProxNam.nam &
	exit 0
}

#Topography
set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)

#GOD
set god [create-god $val(nn)]
set chan_1 [new $val(chan)]

# configure nodes
$ns node-config -adhocRouting $val(rp) \
	-llType $val(ll) \
	-macType $val(mac) \
	-ifqType $val(ifq) \
	-ifqLen $val(ifqlen) \
	-antType $val(ant) \
	-propType $val(prop) \
	-phyType $val(netif) \
	-topoInstance $topo \
	-agentTrace OFF \
	-routerTrace OFF \
	-macTrace ON \
	-movementTrace ON \
	-energyModel "EnergyModel"\
	-initialEnergy 1.0\
	-rxPower 0.395\
	-txPower 0.660\
	-channel $chan_1


#Create god 
for {set i 0} {$i < $val(nn) } {incr i} {
	set node($i) [$ns node]
	$node($i) random-motion 1  ;# disable random motion
	$god new_node $node($i)
}


# Define the nodes positions
for {set i 0} {$i < $val(nn)} { incr i} {
	set xx [expr rand()*$val(x)]
	set yy [expr rand()*$val(y)]
	$node($i) set X_ $xx
	$node($i) set Y_ $yy
	$node($i) set Z_ 0.0
}

#Node size on Nam 
for {set i 0} {$i < $val(nn)} {incr i} {
	$ns initial_node_pos $node($i) 3
}

#Traffic setup and generation
for {set i 0} {$i < $val(nn)} {incr i} {
	set udp($i) [new Agent/UDP]
	$ns attach-agent $node($i) $udp($i)
}

#CBR generation
for {set i 0} {$i < $val(nn)} {incr i} {
	set cbr($i) [new Application/Traffic/CBR]
	$cbr($i) set packetSize_ 64
	#64 is good pckt size AND 5
	$cbr($i) set random_ false
	$cbr($i) set interval_ 0.2
	#0.02 is good interval AND 1.0
	$cbr($i) attach-agent $udp($i)
}

#Set Nulls 
for {set i 0} {$i < $val(nn)} {incr i} {
	set null($i) [new Agent/Null]
	$ns attach-agent $node($i) $null($i)
}


#LSET Change________________________________ 
rename lset _tcl_lset

proc lpop {varname} {
    upvar 1 $varname var
    set value [lindex $var end]
    set var [lrange $var 0 end-1]
    return $value
}

proc lset {varname args} {
    upvar 1 $varname var
    set value [lpop args]
    set indices $args

    if {[lindex $indices end] == "end+1"} {
        lpop indices
        set sublist [lindex $var {*}$indices]
        lappend sublist $value
        set args [list {*}$indices $sublist]
    }

    _tcl_lset var {*}$args
}

#_________________________LSET END________________

#LMAP CHANGE_______________________________________ 

proc lmap args {
    set body [lindex $args end]
    set args [lrange $args 0 end-1]
    set n 0
    set pairs [list]
    foreach {varnames listval} $args {
        set varlist [list]
        foreach varname $varnames {
            upvar 1 $varname var$n
            lappend varlist var$n
            incr n
        }
        lappend pairs $varlist $listval
    }
    set temp [list]
    foreach {*}$pairs {
        lappend temp [uplevel 1 $body]
    }
    set temp
}

#_____________________NODE CREATE____________________

set allNodes [list]
set subClusters [list]
for {set i 0} {$i < $val(nn)} {incr i} {
    lappend subClusters [list]
}
lappend allNodes $subClusters

#_________________________________________________________

puts "All node count: [llength $subClusters]"
set heads {}
set members {}

#____________________COUNT OF NEIGHBORS__________________________

proc memberCount {n1 nd1} {
global node allClusters subClusters count countList node2

set count($nd1) 0
set countList [list]

for {set i 0} {$i < [llength $subClusters]} {incr i} {
	set node2 $node($i)
	set nd2 $i
	set x1 [expr int([$n1 set X_])]
	set y1 [expr int([$n1 set Y_])]
	set x2 [expr int([$node2 set X_])]
	set y2 [expr int([$node2 set Y_])]
	set d [expr int(sqrt(pow(($x2-$x1),2)+pow(($y2-$y1),2)))]
	#puts "Testing $n1 $nd1 --- $n2 $nd2"
		if {$d<=10 && $nd1!=$nd2} {
			incr count($nd1)
			#puts "Member count $nd1: $count($nd1)"
			} elseif {$d>10} {
				#puts "Range issue Distance: $d | ND1: $nd1 | ND2: $nd2" 
			}
			
		}
	#puts "Member count $nd1: $count($nd1)"
	return $count($nd1)
	return $node($i)
}

#__________________________________________________________________________________

for {set i 0} {$i < [llength $subClusters]} {incr i} {
	memberCount $node($i) $i
}


set sortedList [list]
set nodeList [list]
set nodeID [list]


for {set i 0} {$i < [llength $subClusters]} {incr i} {
	puts "Member count of $i -- Memory Location: $node($i) -- Count: $count($i)"
	lappend countList "$node($i) $count($i) $i"
	lappend nodeList $node($i)
	lappend nodeID $i
	set mappedUnsorted [lmap a $nodeList b $nodeID {list $a $b}]		
}
	
puts $countList
puts $mappedUnsorted
#puts "Manual Sort: [lsort -integer -decreasing -index 1 $countList]"
set sortedList [lsort -integer -decreasing -index 1 $countList]

puts "Sort check: $sortedList"



set stime 0.0

proc headSet {n1 nd1} {
global heads members allNodes currentHead currentHeadID node subClusters ns stime
	if {([lsearch -exact $heads $nd1] == -1) && ([lsearch -exact $members $nd1] == -1) } { 
		lappend heads $nd1
		set currentHead $n1
		$ns at $stime "$currentHead color magenta"
		$currentHead color pink 
		$ns at $stime "$currentHead label \"HEAD\""
		set currentHeadID $nd1
		lset subClusters $currentHeadID end+1 "$nd1"
		puts "Current Head: $currentHead | N1: $n1 | ND1: $nd1"
	} else {
		#puts "..... Do nothing .... "
	}
	for {set j 0} {$j < [llength $subClusters]} {incr j} {
		addMembers $currentHead $node($j) $j
	}
#puts "Heads: $heads"
#puts "Members: $members" 
}

proc addMembers {currentHead n2 nd2} {
global heads members allNodes n1 nd1 currentHeadID subClusters ns stime
if {([lsearch -exact $members $nd2] == -1 && [lsearch -exact $heads $nd2] == -1)} {
	puts "Add $nd2 as a member ... "
			set x1 [expr int([$currentHead set X_])]
			set y1 [expr int([$currentHead set Y_])]
			set x2 [expr int([$n2 set X_])]
			set y2 [expr int([$n2 set Y_])]
			set d [expr int(sqrt(pow(($x2-$x1),2)+pow(($y2-$y1),2)))]
			#puts "Testing $currentHead $currentHeadID --- $n2 $nd2"
			if {$d<=10 && $currentHeadID!=$nd2} {
				lappend members $nd2
				$ns at $stime "$n2 color dodgerblue"
				$n2 color dodgerblue
				$ns at $stime "$n2 label \"Target: $currentHeadID\""
				lset subClusters $currentHeadID end+1 "$nd2"
				#puts "Members: $members" 
			} elseif {$d>10} {
				#puts "Range issue Distance: $d | ND1: $currentHeadID | ND2: $nd2" 
			}
	
	} else {
			#puts "$currentHeadID $nd2 did not pass | Memeber/Head issue" 
	}
	#puts "All Nodes: $allNodes"
}


for {set i 0} {$i < [llength $subClusters]} {incr i} {
	headSet [lindex $sortedList $i 0] [lindex $sortedList $i 2]
}

puts "Heads: $heads"
puts "Members: $members" 
puts "All Nodes: $subClusters"


#TRAFFIC____________________________________________________________

set udpIndex [list]
set nullIndex [list]

foreach i $subClusters {
	if {([llength $i] != 0)} {
		set currentNull $null([lindex $i 0])
		puts "Current Null $currentNull"
	}
	if {([llength $i] != 0)} {
	for {set x 0} {$x < [llength $i]} {incr x} {
		if {($x > 0)} {
			set currentUDP $udp([lindex $i $x])
			puts "Connecting $currentUDP to $currentNull"
			$ns connect $currentUDP $currentNull
			}
		}
	}
}


foreach i $members {
	$ns at 1.$i "$cbr($i) start"
	set xr [expr rand()*$val(x)]
    set yr [expr rand()*$val(y)]
    $ns at 2.0 "$node($i) setdest $xr $yr 50"
	$ns at 20.0 "$cbr($i) stop"
}


$ns at 21.0 "finish"



$ns run
