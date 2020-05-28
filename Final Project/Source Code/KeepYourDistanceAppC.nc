#include "KeepYourDistance.h"
#include "printf.h"
#include "StorageVolumes.h"

configuration KeepYourDistanceAppC {}
implementation {
  components MainC, KeepYourDistanceC as App;
  components new AMSenderC(AM_MSG);
  components new AMReceiverC(AM_MSG);
  components new TimerMilliC();
  components ActiveMessageC;
  components PrintfC;
  components SerialStartC;
  components new LogStorageC(VOLUME_IDLOG, TRUE);
  
  App.Boot -> MainC.Boot;
  
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.MilliTimer -> TimerMilliC;
  App.Packet -> AMSenderC;
  App.LogRead -> LogStorageC;
  App.LogWrite -> LogStorageC;
}
