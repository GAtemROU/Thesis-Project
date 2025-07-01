/*	$Id$	*/
#ifndef SEQUENCE_H
#define SEQUENCE_H

#include <stdio.h>
#include <stdint.h>
#include "event.h"
#include "params.h"

#include <vector>



class sequence {
	public:
		sequence(const params & par);
		void read(FILE *f) {if (m_params.sparse) read_sparse(f); else read_full(f);}

		uint32_t dim() const {return m_events.size();}
		uint32_t size() const {return m_data.size();}

		uint32_t symcnt(uint32_t s) const {const event *e = last(s); return e ? e->simid + 1: 0;}

		const event *first(uint32_t symbol) const {return TAILQ_FIRST(&m_events[symbol]);}
		const event *last(uint32_t symbol) const {return TAILQ_LAST(&m_events[symbol], eventlist);}
		event *first(uint32_t symbol) {return TAILQ_FIRST(&m_events[symbol]);}
		event *last(uint32_t symbol) {return TAILQ_LAST(&m_events[symbol], eventlist);}

		const uintvector & seqsizes() const {return m_seqsizes;}

		void filter(uint32_t thresh);


	protected:
		void read_full(FILE *f);
		void read_sparse(FILE *f);


		const params & m_params;

		eventlist m_sequence;

		std::vector<eventlist> m_events;
		std::vector<event> m_data;
		
		uintvector m_seqsizes;
};

#endif
