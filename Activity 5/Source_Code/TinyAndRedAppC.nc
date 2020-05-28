#include "TinyAndRed.h"
#include "printf.h"

configuration TinyAndRedAppC {}
implementation {
  components MainC, TinyAndRedC as App;
  components new AMSenderC(AM_RADIO_SENDER_MSG);
  components new AMReceiverC(AM_RADIO_SENDER_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  components RandomC;
  components PrintfC;
  components SerialStartC;
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
  App.Random -> RandomC;
}
