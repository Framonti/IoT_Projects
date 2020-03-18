#include "Timer.h"
#include "RadioSenderToLeds.h"
 
module RadioSenderToLedsC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive; 	// receiving message
    interface AMSend;	// sending the messages
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl; 	// starting the radio
    interface Packet; 	//managing the packets
  }
}
implementation {

  
}
