#ifndef TINY_AND_RED_H
#define TINY_AND_RED_H

typedef nx_struct radio_sender_msg {

  nx_uint16_t random_value; 
  nx_uint16_t topic_id;  
} radio_sender_msg_t;


enum {
  AM_RADIO_SENDER_MSG 	= 6,
  MAX_VALUE 	= 100,
  TIMERMILLIS	= 5000	// 0.2 Hz
};

#endif
