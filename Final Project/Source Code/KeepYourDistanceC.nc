#include "Timer.h"
#include "KeepYourDistance.h"
#include "printf.h"

 
module KeepYourDistanceC @safe() {
  uses {
    interface Boot;
    interface Receive;    // receiving messages
    interface AMSend;   // sending messages
    interface Timer<TMilli> as MilliTimer;  // Timer
    interface SplitControl as AMControl;  // Starting the radio
    interface Packet;     //managing the packets
    interface LogRead;    // Reads logs
    interface LogWrite;   // Saves logs
  }
}
implementation {

  message_t packet; 
  bool busy_sending;
  
  event void Boot.booted() {
    dbg("boot","Application booted on node %u.\n", TOS_NODE_ID);
    call AMControl.start(); // starts the radio
  }


  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      dbg("radio_status","Successfully started the radio\n");
    call MilliTimer.startPeriodic(TIMERMILLIS);  // Starts the timer    
    }
    else {
      dbgerror("radio_status", "Something went wrong while starting the radio; retrying...\n");
      call AMControl.start();  // restart the radio, if unsuccesful the first time
    }
  }  

 // Pings the device id in broadcast  
 event void MilliTimer.fired() {

    if (!busy_sending) {
      // creating the message
      alert_msg_t* alert_msg = (alert_msg_t*)call Packet.getPayload(&packet, sizeof(alert_msg_t));
      if (alert_msg == NULL) {
        dbgerror("radio_send", "Couldn't create the message...\n");
      return;
    }
    
      alert_msg->mote_id  = TOS_NODE_ID;
      // send the messagge in broadcast
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(alert_msg_t)) == SUCCESS) {
        dbg("radio_send", "Created message to inform of my presence, with ID %u\n", alert_msg->mote_id);
      busy_sending = TRUE;
      }
    }
 }
 
 //messagge has been sent
  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      dbg("radio_send", "I succesfully sent the messagge\n");
      busy_sending = FALSE;

    }
    else{
      dbgerror("radio_send", "Something went wrong while sending the message...\n");
      }
  }

// New Message Arrives
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (len == sizeof(alert_msg_t)) {
      
      alert_msg_t* alert_msg = (alert_msg_t*)payload;
      logentry_t* log_entry;     
      //1) saves ID   
      log_entry->mote_id = alert_msg->mote_id;  // dbg of loggin in LogWrite.appendDone
      if(call LogWrite.append(&log_entry, sizeof(logentry_t)) == FAIL)
        call LogWrite.append(&log_entry, sizeof(logentry_t));  // If it fails to save the record, try again
        
      //2) Sends alarm 
      dbg("radio_rcv", "A Device with ID %u is near me!\n", alert_msg->mote_id);
        printf("A Device with ID %u is near me!\n", alert_msg->mote_id);     
      }
   else{
    dbgerror("radio_rcv", "I received a message, but I couldn't process it...\n");
    }
   return bufPtr;
  }
  
  event void LogWrite.appendDone(void* buf, storage_len_t len, 
                                 bool recordsLost, error_t err) { 
      if(err == SUCCESS)
        dbg("log_write", "Successfully saved the log\n");
      else
        dbgerror("log_write", "I couldn't save the log...\n");      
  }
  
  event void LogWrite.eraseDone(error_t err) {
    if (err == SUCCESS) {
    }
    else {
      call LogWrite.erase(); // Try to erase again
    }
  }
   
 event void LogRead.readDone(void* buf, storage_len_t len, error_t err) {
  }

  event void LogRead.seekDone(error_t err) {
  }

  event void LogWrite.syncDone(error_t err) {
  }
  
  event void AMControl.stopDone(error_t err) {
  }
}
