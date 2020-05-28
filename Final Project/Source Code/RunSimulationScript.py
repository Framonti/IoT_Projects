import sys
import time

from TOSSIM import *

t = Tossim([])

modelfile = "meyer-heavy.txt"

print ("Initializing mac...")
mac = t.mac()
print ("Initializing radio channels...")
radio = t.radio()
print ("using noise file: " + modelfile)
print ("Initializing simulator....")
t.init()

for i in range(1, 7):
    print "Creating node ", i
    node = t.getNode(i)
    time = 0*t.ticksPerSecond() #instant at which each node should be turned on
    node.bootAtTime(time)
    print ">>>Will boot at time",  time/t.ticksPerSecond(), "[sec]"


#creation of channel model
print "Initializing Closest Pattern Matching (CPM)..."
noise = open(modelfile, "r")
lines = noise.readlines()
curr_lines = 0
max_lines = 20000

print ("Reading noise model data file:", modelfile)

for line in lines:
    str_line = line.strip()
    if str_line != "":
        val = int(str_line)
        for i in range(1, 7):
            t.getNode(i).addNoiseTraceReading(val)
        curr_lines += 1 
    if curr_lines > max_lines:
        break

print ("Done!")


for i in range(1, 7):
    print ">>>Creating noise model for node: ", i
    t.getNode(i).createNoiseModel()

for i in range(1, 7):
    simulation_file = "simulation_results/simulation" + str(i) + ".txt"
    outfile = open(simulation_file, "w") 

    #Add debug channel
    print ("Activate debug message on channel boot")
    t.addChannel("boot",outfile)
    print ("Activate debug message on channel radio_status")
    t.addChannel("radio_status",outfile)
    print ("Activate debug message on channel radio_send")
    t.addChannel("radio_send",outfile)
    print ("Activate debug message on channel radio_rcv")
    t.addChannel("radio_rcv",outfile)

    topofile = "topologies/topology" + str(i) + ".txt"
    print "Using topology number", i
    f = open(topofile, "r")
    lines = f.readlines()
    for line in lines:
      s = line.split()
      if (len(s) > 0):
        print ">>>Setting radio channel from node ", s[0], " to node ", s[1], " with gain ", s[2], " dBm"
        radio.add(int(s[0]), int(s[1]), float(s[2]))

    print "Start simulation with TOSSIM! \n\n\n"

    for i in range(0,2500):
        t.runNextEvent()
    
print "\n\n\nSimulation finished!"

