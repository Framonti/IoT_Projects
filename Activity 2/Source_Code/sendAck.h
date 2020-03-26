/**
 *  @author Luca Pietro Borsani
 */

#ifndef SENDACK_H
#define SENDACK_H

//payload of the msg
typedef nx_struct my_msg {
  nx_uint8_t 	msg_type; 		// REQ or RESP
  nx_uint16_t 	msg_counter;
  nx_uint16_t 	value;
} msg_t;

#define REQ 	1
#define RESP 	2 

enum{
AM_MSG = 6,
TIMERMILLIS = 1000,
NO_DATA = 0 		// Used in REQ messages for the value field
};

#endif
