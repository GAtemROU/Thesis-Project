#ifndef COVER_H
#define COVER_H

#include <stdio.h>
#include <stdint.h>
#include "event.h"
#include "sequence.h"
#include "pattern.h"
#include "mathutil.h"

#include <vector>



class cover {
	public:
		cover(const sequence & seq, const mathutil & m) : m_seq(seq), m_patcnt(0),  m_usages(seq.dim()), m_util(m) {TAILQ_INIT(&m_head); TAILQ_INIT(&m_tail); TAILQ_INIT(&m_patterns);}
		~cover();


		void add(pattern *p);
		void remove(pattern *p);

		double optimize();

		double cost() const {return m_cost;}

		void purgefast();
		void purge();

		void print(FILE *out);

		uint32_t patcnt() const {return m_patcnt;}
		patternhead *patterns() {return &m_patterns;}


		struct patcost {
			uint32_t usage;
			uint32_t cover;
			uint32_t symcnt;
			double stcost;
		};


		struct estimate {
			patcost p1, p2, pnew;

			bool selfref;

			double cost;
			double bias;
			uint32_t use;

		};

		struct tracker {
			const event *start;
			const event *cur;
			const event *stop;

			bool selfact;

			index_t startlen;
			window *opt;

			void step();
			bool done() const {return cur == NULL || cur->seqid != start->seqid || (stop != NULL && cur->index > stop->index); }
			
			double bias;

			TAILQ_ENTRY(tracker) entries;
			TAILQ_ENTRY(tracker) queue;
		};

		TAILQ_HEAD(trackerhead, tracker);


		void rank();

		double optimalexpand(uint32_t c, uint32_t & ind) const;
		double optimalexpand(const pattern *t, uint32_t & ind) const;

	protected:
		void build(pattern *p) const;

		void init();
		void align();
		bool infer();

		void optimize(std::vector<estimate> & estimates, trackerhead *trackerhead) const;

		void scan(std::vector<estimate> & estimates, tracker *t) const;
		bool update(estimate & est, index_t l1, index_t l2, index_t lnew, double bias) const;

		void setcost(pattern *p) const;


		double intcost(uint32_t u) const ;

		double codeusage(uint32_t v, uint32_t norm) const {return -lg2(v + laplace / (m_seq.dim() + m_patcnt)) + lg2(norm + laplace);}
		double codeusage(uint32_t s) const {return codeusage(m_usages[s], m_usage);}
		double codegap(uint32_t cover, uint32_t usage, uint32_t symcnt) const;
		double code(const patcost & pc) const;

		double code(uint32_t s) const {return -lg2(m_seq.symcnt(s)) + lg2(m_seq.size());}
		double code(const pattern *p) const;
		double code(uint32_t usage, uint32_t ctcnt) const;
		double codetable();

		double code(const estimate & est) const;

		void computecode();


		const sequence & m_seq;

		windowhead m_head, m_tail;

		patternhead m_patterns;
		uint32_t m_patcnt;

		double m_cost;
		uint32_t m_usage; // number of total codes 
		uint32_t m_patusage; // number of pattern codes 
		uint32_t m_ctcnt; // number of patterns used in encoding 

		intvector m_usages;

		const mathutil & m_util;

		const static double laplace;
};

#endif
