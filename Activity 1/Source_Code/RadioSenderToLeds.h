#ifndef RADIO_SENDER_TO_LEDS_H
#define RADIO_SENDER_TO_LEDS_H

typedef nx_struct radio_sender_msg {

  nx_uint16_t counter; 
  nx_uint16_t sender_id;  
} radio_sender_msg_t;


enum {
  AM_RADIO_SENDER_MSG 	= 6,
  TIMERMILLISNODE1		= 1000,	// 1 Hz
  TIMERMILLISNODE2 		= 333, 	// 3 Hz
  TIMERMILLISNODE3		= 200 	// 5 Hz
};

#endif
