/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	interface Receive; 	// receiving message
    interface AMSend;	// sending the messages
    interface Timer<TMilli> as MilliTimer;	// Timer
    interface SplitControl as AMControl; 	// starting the radio
    interface Packet; 	//managing the packets

    //other interfaces, if needed
    interface PacketAcknowledgements as PAck;	//packet ack
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {
	
  uint8_t counter=0;
  message_t packet;  

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 	 
	msg_t* message = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
	if (message == NULL) {
		dbgerror("radio_pack", "Message creation failed\n");
		return;
	}
	// Prepare message
	dbg("radio_pack","Preparing the message \n");
	message->msg_type 	 	= REQ;
	message->msg_counter	= counter;
	message->value 			= NO_DATA;
	
	if(call PAck.requestAck(&packet) == SUCCESS){
		dbg("radio_ack", "Ack requested\n");
	}
	else {
		dbgerror("radio_ack", "Error: couldn't create an ack\n");
	}
	
	// send the messagge to node 2
	if (call AMSend.send(2, &packet, sizeof(msg_t)) == SUCCESS) {
  		 dbg("radio_send", "Packet passed to lower layer successfully!\n");
	     dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     dbg_clear("radio_pack","\t Payload Sent\n" );
		 dbg_clear("radio_pack", "\t\t type: %hhu \n ", message->msg_type);
		 dbg_clear("radio_pack", "\t\t counter: %hhu \n", message->msg_counter);
		 dbg_clear("radio_pack", "\t\t data: %hhu \n", message->value);
		 
		 counter++;
	}
 }        

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raise the event read one.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted on node %u.\n", TOS_NODE_ID);
	call AMControl.start(); 				// Start Radio
  }

  //***************** SplitControl interface ********************//
  event void AMControl.startDone(error_t err){
    if(err == SUCCESS){
    	if(TOS_NODE_ID == 1){ 				// Only Node 1 has a timer
    		call MilliTimer.startPeriodic(TIMERMILLIS); // 1 Hz
    	}
    	dbg("radio", "Radio booted\n");
    }
    else{
    	dbgerror("radio", "Starting Radio failed. Rebooting... \n");
    	call AMControl.start();	 // restart the radio, if unsuccesful the first time   	
    }
  }
  
  event void AMControl.stopDone(error_t err){
    	dbg("radio", "Turning off the radio...\n");
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 * Fill this part...
	 */
	 sendReq();
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t error) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 if (&packet == buf && error == SUCCESS) {
      dbg("radio_send", "Packet sent");
      dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }
    else{
      dbgerror("radio_send", "Error: couldn't send the message\n");
    }
    
    if(call PAck.wasAcked(buf)){
    	// stop timer
    	if(TOS_NODE_ID ==1){
    		call MilliTimer.stop();	
    	}
    	dbg("radio_ack", "Ack received\n");  
    }
    else{
    	dbg("radio_ack", "Ack not received; retrasmitting...\n");
    	if(TOS_NODE_ID == 2){			// The Node 1 will automatically send another message after 
    		sendResp(); 				// the timer is fired again
    	}
    }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 if (len == sizeof(msg_t)) {
		  msg_t* message = (msg_t*)payload;
		  
		  dbg("radio_rec", "Received packet at time %s\n", sim_time_string());
		  dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( buf ));
		  dbg("radio_pack", ">>>Pack \n");
		  dbg_clear("radio_pack","\t\t Payload Received\n" );
		  dbg_clear("radio_pack", "\t\t type: %hhu \n ", message->msg_type);
		  dbg_clear("radio_pack", "\t\t counter: %hhu \n", message->msg_counter);
		  dbg_clear("radio_pack", "\t\t data: %hhu \n", message->value);
		  
		  if(message->msg_type == REQ){	//Node 2, we need to respond
		  	counter = message->msg_counter; // Internally saves the counter received
		  	dbg("radio_rec", "Saved received counter\n");
		  	sendResp();
		  }
		  else{	//Node 1
		  	dbg("radio", "Everything received; finishing simulation...\n");
		  }		  
	}
    else {
      dbgerror("radio_rec", "Receiving error \n");      
    }
    return buf;
  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
	msg_t* message = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
	if (message == NULL) {
		dbgerror("radio_pack", "Message creation failed\n");
		return;
	}
	// Prepare message
	dbg("radio_pack","Preparing the message \n");
	message->msg_type 	 	= RESP;
	message->msg_counter	= counter; 		// We saved this value when receiving the message	
	message->value 			= data;
	
	if(call PAck.requestAck(&packet) == SUCCESS){
		dbg("radio_ack", "Ack requested\n");
	}
	else {
		dbgerror("radio_ack", "Error: couldn't create an ack\n");
	}
	
	// send the messagge to node 1
	if (call AMSend.send(1, &packet, sizeof(msg_t)) == SUCCESS) {
  		 dbg("radio_send", "Packet passed to lower layer successfully!\n");
	     dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     dbg_clear("radio_pack","\t Payload Sent\n" );
		 dbg_clear("radio_pack", "\t\t type: %hhu \n ", message->msg_type);
		 dbg_clear("radio_pack", "\t\t counter: %hhu \n", message->msg_counter);
		 dbg_clear("radio_pack", "\t\t data: %hhu \n", message->value);
	}
  }
	 

}

