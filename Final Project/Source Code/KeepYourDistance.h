#ifndef KEEP_YOUR_DISTANCE_H
#define KEEP_YOUR_DISTANCE_H

typedef nx_struct alert_message {

  nx_uint8_t 	mote_id; 		
} alert_msg_t;

typedef nx_struct logentry_t {

	nx_uint8_t	mote_id;
	
} logentry_t;

enum{
	AM_MSG = 6,
	TIMERMILLIS = 500
};

#endif
