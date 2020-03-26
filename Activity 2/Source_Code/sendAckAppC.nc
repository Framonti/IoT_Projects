/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"

configuration sendAckAppC {}

implementation { 


/****** COMPONENTS *****/
  components MainC, sendAckC as App;
  components new AMSenderC(AM_MSG); 		// Send messages
  components new AMReceiverC(AM_MSG); 		// Receive messages
  components new TimerMilliC(); 			// Timer
  components ActiveMessageC; 				// Radio Controls
  //add the other components here
  components new FakeSensorC();

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  
  App.Read -> FakeSensorC; 				  //Fake Sensor read
  App.Receive -> AMReceiverC; 			  //Send interfaces
  App.AMSend -> AMSenderC; 				  //Receive interfaces
  App.AMControl -> ActiveMessageC; 		  //Radio Control
  App.MilliTimer -> TimerMilliC; 		  //Timer interface
  App.Packet -> AMSenderC; 				  //Interfaces to access package fields
  App.PAck -> AMSenderC; 				  //Packet Ack interface 

}

