#include "Timer.h"
#include "TinyAndRed.h"
#include "printf.h"

 
module TinyAndRedC @safe() {
  uses {
    interface Boot;
    interface Receive; 	// receiving message
    interface AMSend;	// sending the messages
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl; 	// starting the radio
    interface Packet; 	//managing the packets
    interface Random; 	// Random values generation
  }
}
implementation {

  message_t packet; 

  bool busy_sending;
  uint16_t rand_val = 0; 	
  
  event void Boot.booted() {
    call AMControl.start();	// starts the radio
  }
	// this event is triggered by AMControl.start()
  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    	if(TOS_NODE_ID == 2 || TOS_NODE_ID == 3){
      		call MilliTimer.startPeriodic(TIMERMILLIS); 
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

  		rsm->random_value 	= (call Random.rand16()) % MAX_VALUE;
 		rsm->topic_id 		= TOS_NODE_ID - 1;
  		// send the messagge to node 1
  		if (call AMSend.send(1, &packet, sizeof(radio_sender_msg_t)) == SUCCESS) {
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
      
      // encode as JSON
      printf("{\"Value\": %u, \"TopicID\": %u}\n", rsm -> random_value, rsm->topic_id);      	
      printfflush();  
   } 
   return bufPtr;
  }
}
