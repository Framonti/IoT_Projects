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

  message_t packet; 

  bool busy_sending;
  uint16_t counter = 0; 	
  
  event void Boot.booted() {
    call AMControl.start();	// starts the radio
  }
	// this event is triggered by AMContro.start()
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    	if(TOS_NODE_ID == 1){
      		call MilliTimer.startPeriodic(TIMERMILLISNODE1); // 1 Hz
      	}
      	else if (TOS_NODE_ID == 2){
      		call MilliTimer.startPeriodic(TIMERMILLISNODE2); // 3 Hz
      	}			
      	else {
      		call MilliTimer.startPeriodic(TIMERMILLISNODE3); // 5 Hz	
      	}	
    }
    else {
      call AMControl.start();	 // restart the radio, if unsuccesful the first time
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }

	// Time to send the message  
  event void MilliTimer.fired() {

  //  dbg("RadioCountToLedsC", "RadioCountToLedsC: timer fired, counter is %hu.\n", counter);
    if (!busy_sending) {
    	// creating the message
    	radio_sender_msg_t* rsm = (radio_sender_msg_t*)call Packet.getPayload(&packet, sizeof(radio_sender_msg_t));
    	if (rsm == NULL) {
			return;
		}

  		rsm->counter 		= counter;
 		rsm->sender_id 	= TOS_NODE_ID;
  		// send the messagge in broadcast
  		if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_sender_msg_t)) == SUCCESS) {
			busy_sending = TRUE;
    	}
  	}
 }
 //messagge has been correctly sent
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
   	if (&packet == bufPtr) {
      busy_sending = FALSE;
    }
  }

// Logic of messagge arrival
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (len == sizeof(radio_sender_msg_t)) {

      radio_sender_msg_t* rsm = (radio_sender_msg_t*)payload;
      counter++;
      
      if((rsm-> counter % 10) == 0){
      	call Leds.led0Off();
      	call Leds.led1Off();
      	call Leds.led2Off();
      	return bufPtr;
      }
      else {
      	if (rsm-> sender_id == 1) {
			call Leds.led0Toggle();
		}
      	else if (rsm -> sender_id == 2){
			call Leds.led1Toggle();
      	}
      	else {
			call Leds.led2Toggle();
      	}
     }
   } 
   return bufPtr;
  }
}
