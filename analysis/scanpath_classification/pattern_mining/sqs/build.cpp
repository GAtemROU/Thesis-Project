#include "search.h"
#include <algorithm>



struct candidate {
	bool operator < (const candidate & b) {return cost < b.cost;}

	double cost;
	uint32_t first, second;
};

struct symwrap {
	symwrap(uint32_t i, uint32_t d, std::vector<pattern *> & p) : ind(i), dim(d), patterns(p) {}
	uint32_t ind;
	uint32_t dim;
	std::vector<pattern *> & patterns;

	uint32_t size() const {return ind < dim ? 1 : patterns[ind - dim]->size();}
	uint32_t operator [] (uint32_t i) const {return ind < dim ? ind : patterns[ind - dim]->at(i);}
};


typedef std::vector<candidate> candvector;

static bool
sqs_close(cover & c, const sequence & seq, pattern *p, const params & par, double & optcost)
{
	//p->print(stdout);
	//printf("\n");
	c.add(p);

	double cost = c.optimize();

	if (cost < optcost && p->cur.usage >= par.thresh) {
		c.purgefast();
		printf("adding: ");
		p->print(stdout);
		printf(" (%f %f)\n", cost, optcost - cost);
		optcost = c.cost();
	}
	else {
		c.remove(p);
		delete p;
		return false;
	}


	if (p->cur.cover == index_t(p->cur.usage*(p->size() - 1))) return true;
	intvector counts(seq.dim());
	window *w;
	
	TAILQ_FOREACH(w, &p->opt, optinst) {
		for (const event *e = w->first; e != w->last; e = e->next()) {
			counts[e->symbol]++;
		}
	}	

	for (uint32_t i = 0; i < p->size(); i++) counts[p->at(i)] = 0;

	for (uint32_t i = 0; i < counts.size(); i++) {
		if (counts[i] == 0) continue;
		for (uint32_t j = 1; j < p->size(); j++) {
			pattern *q = new pattern(p->size() + 1);
			for (uint32_t k = 0; k < j; k++) q->at(k) = p->at(k);
			q->at(j)= i;
			for (uint32_t k = j; k < p->size(); k++) q->at(k + 1) = p->at(k);
			sqs_close(c, seq, q, par, optcost);
		}
	}

	return true;
}


void
sqs_slam(cover & c, const sequence & seq, const params & par)
{
	c.optimize();
	double optcost = c.cost();

	std::vector<bool> hope(seq.dim(), true);

	while (true) {
		printf("%d candidates, cost: %f\n", c.patcnt(), c.cost());
		fflush(stdout);

		std::vector<pattern *> patterns(c.patcnt());
		pattern *q;
		uint32_t ind = 0;
		TAILQ_FOREACH (q, c.patterns(), entries) patterns[ind++] = q;
			
		
		candvector cands(seq.dim() + c.patcnt());

#pragma omp parallel for
		for (uint32_t a = 0; a < seq.dim(); a++) {
			printf("%d test of %d\r", a, (uint32_t)cands.size());
			fflush(stdout);

			candidate & cand = cands[a];
			cand.cost = std::numeric_limits<double>::min();
			cand.first = a;
			if (!hope[a] || seq.symcnt(a) < par.thresh) continue;
			cand.cost = c.optimalexpand(a, cand.second);

		}

#pragma omp parallel for
		for (uint32_t i = seq.dim(); i < cands.size(); i++) {
			printf("%d test of %d\r", i, (uint32_t)cands.size());
			fflush(stdout);
			candidate & cand = cands[i];

			cand.first = i;
			cand.cost = c.optimalexpand(patterns[i - seq.dim()], cand.second);
		}

		std::make_heap(cands.begin(), cands.end());
		std::sort_heap(cands.begin(), cands.end());

		bool changed = false;
		for (uint32_t j = 0; j < cands.size(); j++) {
			printf("checking %d\r", j);
			fflush(stdout);
			
			candidate & bc = cands[j];

			if (bc.cost == std::numeric_limits<double>::min()) continue;

			symwrap first(bc.first, seq.dim(), patterns);
			symwrap second(bc.second, seq.dim(), patterns);

			pattern *p = new pattern(first.size() + second.size());

			for (uint32_t i = 0; i < first.size(); i++)
				p->at(i) = first[i];
			for (uint32_t i = 0; i < second.size(); i++)
				p->at(i + first.size()) = second[i];

			if (sqs_close(c, seq, p, par, optcost))
				changed = true;

		}
		c.optimize();

		if (!changed) break;
	}
	c.purge();
}
