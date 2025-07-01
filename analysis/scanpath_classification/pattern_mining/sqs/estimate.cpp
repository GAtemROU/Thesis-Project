#include "cover.h"
#include "pattern.h"
#include <assert.h>
#include <math.h>
#include <algorithm>


bool
cover::update(estimate & est, index_t l1, index_t l2, index_t lnew, double bias) const
{

	assert(est.p1.usage > 0);
	est.p1.usage--;
	est.p1.cover -= l1;
	if (est.selfref) {
		est.p1.usage--;
		est.p1.cover -= l2;
	}
	else {
		est.p2.usage--;
		est.p2.cover -= l2;
	}

	est.pnew.usage++;
	est.pnew.cover += lnew;

	double cand = code(est) + bias;


	if (cand < est.cost) {
		est.cost = cand;
		est.use = est.pnew.usage;
	}

	return true;

}

void
cover::tracker::step()
{
	cur = cur->next();

	if (cur == NULL) return;

	while (opt && opt->first->index < cur->index) {
		opt = opt->next;
		if (opt) opt = opt->opt;
	}

	if (opt && opt->first == cur) cur = opt->last;
}


void
cover::scan(std::vector<estimate> & estimates, tracker *t) const
{
	// tracker has a pattern of form A A but is overlapping
	if (t->cur == t->stop && !t->selfact)
		return;

	bool change = false;

	if (t->opt && t->cur == t->opt->last) {
		window *w = t->opt->simprev();
		if (w == NULL || w->first->index <= t->start->index + t->startlen) {
			estimate & est = estimates[t->opt->pat->index + m_seq.dim()];
			change = update(est, t->startlen, t->opt->cover() - 1, t->opt->last->index - t->start->index, t->bias);
		}
		t->bias += t->opt->cost;
	}
	else {
		const event *e = t->cur->simprev();
		if (e == NULL || e->index <= t->start->index + t->startlen) {
			estimate & est = estimates[t->cur->symbol];
			change = update(est, t->startlen, 0, t->cur->index - t->start->index, t->bias);
		}
	}

	// tracker has a pattern of form A A. make sure that surrounding trackers will not overlap
	if (change && t->cur == t->stop) {
		tracker *u = TAILQ_NEXT(t, entries);
		if (u) u->selfact = false;
		u = TAILQ_PREV(t, trackerhead, entries);
		if (u) u->selfact = false;
	}
}

void
cover::optimize(std::vector<estimate> & estimates, trackerhead *trackers) const
{
	index_t ml = 1;
	window *w = TAILQ_FIRST(&m_head);

	while (w) {
		w = w->opt;
		if (w == NULL) break;

		ml = std::max(w->cover(),  ml);

		w = w->next;
	}

	std::vector<trackerhead> th(ml + 1);

	for (uint32_t i = 0; i < th.size(); i++) TAILQ_INIT(&th[i]);

	uint32_t cnt = 0;
	tracker *t;
	TAILQ_FOREACH(t, trackers, entries) {
		t->step();
		if (!t->done()) {
			TAILQ_INSERT_TAIL(&th[(t->cur->index - t->start->index) % th.size()], t, queue);
			cnt++;
		}
	}

	uint32_t ind = 1;
	while (cnt > 0) {
		while (!TAILQ_EMPTY(&th[ind])) {
			t = TAILQ_FIRST(&th[ind]);
			TAILQ_REMOVE(&th[ind], t, queue);

			scan(estimates, t);
			t->step();

			if (!t->done())
				TAILQ_INSERT_TAIL(&th[(t->cur->index - t->start->index) % th.size()], t, queue);
			else
				cnt--;
		}
		//printf("next\n");
		ind = (ind + 1) % th.size();
	}
}

double
cover::optimalexpand(uint32_t s, uint32_t & best) const
{
	std::vector<estimate> estimates(m_seq.dim() + m_patcnt);

	patcost p1 = {m_usages[s], 0, 1, 0};

	for (uint32_t i = 0; i < m_seq.dim(); i++) {
		estimates[i].p1 = p1;
		estimates[i].p2.usage = m_usages[i];
		estimates[i].p2.symcnt = 1;

		estimates[i].pnew.symcnt = 2;
		estimates[i].pnew.stcost = intcost(2) + code(s) + code(i);

		estimates[i].selfref = i == s;
		estimates[i].bias = -code(estimates[i]); 
		//printf("bias %f\n", estimates[i].bias);
	}

	pattern *p = TAILQ_FIRST(&m_patterns);
	for (uint32_t i = 0; i < m_patcnt; i++) {
		double c = 0;
		for (uint32_t j = 0; j < p->size(); j++) c += code(p->at(j));

		estimate & est = estimates[m_seq.dim() + i];
		est.p1 = p1;
		est.p2.usage = p->cur.usage;
		est.p2.cover = p->cur.cover;
		est.p2.symcnt = p->size();
		est.p2.stcost = intcost(p->size()) + c;
		est.pnew.symcnt = p->size() + 1;
		est.pnew.stcost = intcost(1 + p->size()) + code(s) + c;

		est.bias = -code(est);

		p = TAILQ_NEXT(p, entries);
	}


	std::vector<tracker> trackers(m_seq.symcnt(s));

	uint32_t cnt = 0;
	window *w = TAILQ_FIRST(&m_head);
	if (w) w = w->opt;

	trackerhead th;
	TAILQ_INIT(&th);

	for (const event *e = m_seq.first(s); e; e = e->sim()) {
		while (w && w->last->index < e->index) {
			w = w->next;
			if (w) w = w->opt;
		}
		if (w == NULL || e->index < w->first->index) {
			tracker *t = &trackers[cnt++];
			t->start = t->cur = e;
			t->stop = NULL;
			t->selfact = true;
			t->startlen = 0;
			t->opt = w;
			t->bias = 0;
			TAILQ_INSERT_TAIL(&th, t, entries);
		}
	}

	for (uint32_t i = 1; i < cnt; i++) {
		trackers[i - 1].stop = trackers[i].start;
	}

	optimize(estimates, &th);

	best = 0;
	for (uint32_t i = 1; i < estimates.size(); i++)
		if (estimates[best].cost > estimates[i].cost)
			best = i;
	//printf("%f %d\n", estimates[best].cost, estimates[best].use);
	return estimates[best].cost;
}

double
cover::optimalexpand(const pattern *t, uint32_t & best) const
{
	std::vector<estimate> estimates(m_seq.dim() + m_patcnt);

	double c1 = 0;
	for (uint32_t j = 0; j < t->size(); j++) c1 += code(t->at(j));


	patcost p1 = {t->cur.usage, t->cur.cover, t->size(), c1 + intcost(t->size())};

	for (uint32_t i = 0; i < m_seq.dim(); i++) {
		estimates[i].p1 = p1;
		estimates[i].p2.usage = m_usages[i];
		estimates[i].p2.symcnt = 1;

		estimates[i].pnew.symcnt = t->size() + 1;
		estimates[i].pnew.stcost = intcost(t->size() + 1) + c1 + code(i);

		estimates[i].bias = -code(estimates[i]); 
		//printf("bias %f\n", estimates[i].bias);
	}

	pattern *p = TAILQ_FIRST(&m_patterns);
	for (uint32_t i = 0; i < m_patcnt; i++) {
		double c = 0;
		for (uint32_t j = 0; j < p->size(); j++) c += code(p->at(j));

		estimate & est = estimates[m_seq.dim() + i];
		est.p1 = p1;
		est.p2.usage = p->cur.usage;
		est.p2.cover = p->cur.cover;
		est.p2.symcnt = p->size();
		est.p2.stcost = intcost(p->size()) + c;
		est.pnew.symcnt = p->size() + t->size();
		est.pnew.stcost = intcost(t->size() + p->size()) + c1 + c;

		est.selfref = p == t;

		est.bias = -code(est);

		p = TAILQ_NEXT(p, entries);
	}


	std::vector<tracker> trackers(t->cur.usage);

	uint32_t cnt = 0;
	window *w = TAILQ_FIRST(&m_head);
	if (w) w = w->opt;

	trackerhead th;
	TAILQ_INIT(&th);

	TAILQ_FOREACH(w, &t->opt, optinst) {
		tracker *t = &trackers[cnt++];
		t->start = w->first;
		t->cur = w->last;
		window *s = TAILQ_NEXT(w, optinst);
		t->stop = s ? s->last : NULL;
		t->selfact = true;
		t->startlen = w->cover() - 1;
		t->opt = w->next;
		if (t->opt) t->opt = t->opt->opt;
		t->bias = 0;
		TAILQ_INSERT_TAIL(&th, t, entries);
	}

	optimize(estimates, &th);

	best = 0;
	for (uint32_t i = 1; i < estimates.size(); i++)
		if (estimates[best].cost > estimates[i].cost)
			best = i;
	//printf("%f %d\n", estimates[best].cost, estimates[best].use);
	return estimates[best].cost;
}

