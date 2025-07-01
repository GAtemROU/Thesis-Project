/*	$Id$	*/
#ifndef EVENT_H
#define EVENT_H

#include <vector>
#include <assert.h>
#include <stdint.h>
#include "queue.h"
#include "defines.h"



struct event;
TAILQ_HEAD(eventlist, event);

struct event {
	uint32_t symbol;
	index_t index;
	uint32_t id;
	uint32_t simid;
	uint32_t seqid;

	event * next() {return TAILQ_NEXT(this, entries);}
	event * sim() {return TAILQ_NEXT(this, similar);}

	const event * next() const {return TAILQ_NEXT(this, entries);}
	const event * sim() const {return TAILQ_NEXT(this, similar);}

	const event * simprev() const {return TAILQ_PREV(this, eventlist, similar);}

	TAILQ_ENTRY(event) entries;
	TAILQ_ENTRY(event) similar;
};

typedef std::vector<const event *> eventvector;



#endif
