#include "cover.h"
#include "pattern.h"
#include <assert.h>
#include <math.h>
#include <algorithm>



void
cover::add(pattern *p)
{
	TAILQ_INSERT_TAIL(&m_patterns, p, entries);
	p->index = m_patcnt;
	m_patcnt++;
	p->active = true;
	assert(TAILQ_EMPTY(&p->windows));

	build(p);

	window *w1, *w2;


	w2 = TAILQ_FIRST(&m_head);
	TAILQ_FOREACH(w1, &p->windows, inst) {
		while (w2 && w2->first->index < w1->first->index)
			w2 = TAILQ_NEXT(w2, head);
		if (w2 == NULL)
			TAILQ_INSERT_TAIL(&m_head, w1, head);
		else
			TAILQ_INSERT_BEFORE(w2, w1, head);
	}

	w2 = TAILQ_FIRST(&m_tail);
	TAILQ_FOREACH(w1, &p->windows, inst) {
		//printf("1 %d %d\n", w1->first->index, w1->last->index);

		while (w2 && w2->last->index < w1->last->index)
			w2 = TAILQ_NEXT(w2, tail);
		if (w2 == NULL)
			TAILQ_INSERT_TAIL(&m_tail, w1, tail);
		else {
			//printf("2 %d %d\n", w2->first->index, w2->last->index);
			TAILQ_INSERT_BEFORE(w2, w1, tail);
		}
	}

	w2 = TAILQ_FIRST(&p->windows);
	TAILQ_FOREACH(w1, &p->windows, inst) {
		if (w2->first->index <= w1->first->index)
			w2 = w1;
		while (w2 && w2->first->index <= w1->last->index)
			w2 = TAILQ_NEXT(w2, head);
		if (w2 == NULL) break;
		assert(w1->first->index < w2->first->index);
		w1->next = w2;
	}

	w2 = TAILQ_LAST(&p->windows, windowhead);
	TAILQ_FOREACH_REVERSE(w1, &p->windows, windowhead, inst) {
		if (w2 && w2->last->index >= w1->last->index)
			w2 = w1;

		while (w2 && w2->last->index >= w1->first->index)
			w2 = TAILQ_PREV(w2, windowhead, tail);
		if (w2 == NULL) break;

		window *s = TAILQ_PREV(w1, windowhead, inst);

		//printf("1 %d %d\n", w1->first->index, w1->last->index);

		while (w2 && (s == NULL || w2->last->index >= s->first->index) && (w2->next == NULL || w2->next->first->index >= w1->first->index)) {
			w2->next = w1;
			//printf("2 %d %d\n", w2->first->index, w2->last->index);
			assert(w2->first->index < w1->first->index);
			w2 = TAILQ_PREV(w2, windowhead, tail);
		}
	}


}

cover::~cover()
{
	while (!TAILQ_EMPTY(&m_patterns))
		remove(TAILQ_FIRST(&m_patterns));
}



void
cover::remove(pattern *p)
{
	window *w1, *w2;

	w2 = TAILQ_LAST(&p->windows, windowhead);

	TAILQ_FOREACH_REVERSE(w1, &p->windows, windowhead, inst) {
		if (w2 && w2->last->index >= w1->last->index)
			w2 = w1;

		while (w2 && w2->last->index >= w1->first->index)
			w2 = TAILQ_PREV(w2, windowhead, tail);

		while (w2 && w2->next == w1) {
			w2->next = TAILQ_NEXT(w1, head);
			w2 = TAILQ_PREV(w2, windowhead, tail);
		}

		TAILQ_REMOVE(&m_head, w1, head);
		TAILQ_REMOVE(&m_tail, w1, tail);
	}

	while (!TAILQ_EMPTY(&p->windows)) {
		w1 = TAILQ_FIRST(&p->windows);
		TAILQ_REMOVE(&p->windows, w1, inst);
		delete w1;
	}
	TAILQ_INIT(&p->opt);
	p->win.usage = p->win.cover = 0;

	for (pattern *q = TAILQ_NEXT(p, entries); q; q = TAILQ_NEXT(q, entries)) q->index--;


	TAILQ_REMOVE(&m_patterns, p, entries);
	m_patcnt--;
}

double
cover::optimize()
{
	init();
	do {
		//printf("%f\n", cost());
		align();
		//printf("infer\n");
	} while (infer());

	//printf("done\n");
	computecode();

	return cost();
}


void
cover::build(pattern *p) const
{
	eventvector ev(p->size());
	const event *front = NULL, *back = NULL;

	for (uint32_t i = 0; i < p->size(); i++)
		ev[i] = m_seq.first(p->symbols[i]);

	while (ev[0]) {
		bool ok = true;

		for (uint32_t i = 1; i < p->size(); i++) {
			while (ev[i] && ev[i]->index <= ev[i - 1]->index)
				ev[i] = ev[i]->sim();
			if (ev[i] == NULL) {
				ok = false;
				break;
			}
		}
		if (!ok) break;

		if (back != NULL && back->index < ev.back()->index && front->seqid == back->seqid) {
			p->add(new window(front, back, p));
		}

		front = ev.front();
		back = ev.back();

		ev[0] = ev[0]->sim();
	}
	if (back != NULL && front->seqid == back->seqid) 
		p->add(new window(front, back, p));
}

void
cover::align()
{
	window *w = TAILQ_LAST(&m_head, windowhead);

	if (w == NULL) return;

	if (w->cost > 0 && w->pat->active) {
		w->optcost = w->cost;
		w->opt = w;
	}
	else {
		w->optcost = 0;
		w->opt = NULL;
	}


	window *n = w;

	for (w = TAILQ_PREV(w, windowhead, head); w != NULL; w = TAILQ_PREV(w, windowhead, head)) {
		double c = w->cost;

		if (w->next != NULL)
			c += w->next->optcost;

		if (!w->pat->active || n->optcost > c) {
			w->opt = n->opt;
			assert(w->first->index <= n->first->index);
			assert(w->opt == NULL || w->first->index <= w->opt->first->index);
			w->optcost = n->optcost;
		}
		else {
			w->opt = w;
			w->optcost = c;
		}
		
		n = w;
	}
}

const double cover::laplace = 1e-100;

bool
cover::infer()
{
	bool changed = false;

	m_usage = m_seq.size();
	m_ctcnt = 0;
	m_patusage = 0;

	for (uint32_t i = 0; i < m_seq.dim(); i++)
		m_usages[i] = m_seq.symcnt(i);

	pattern *p;
	TAILQ_FOREACH(p, &m_patterns, entries) {
		if (!p->active) continue;
		p->cur.usage = p->cur.cover = 0;
		p->gain = 0;
		TAILQ_INIT(&p->opt);
	}


	window *w = TAILQ_FIRST(&m_head);

	while (w) {
		assert(w->opt == NULL || w->opt->first->index >= w->first->index);


		w = w->opt;

		if (w == NULL)  break;

		//if (m_patcnt > 1) printf("%d %d\n", w->first->index, w->last->index);

		p = w->pat;

		assert(p->active);

		m_patusage++;
		m_usage++;
		m_usage -= p->size();

		TAILQ_INSERT_TAIL(&p->opt, w, optinst);
		p->cur.usage++;
		p->cur.cover += w->cover() - 1;
		p->gain += w->cost;


		for (uint32_t i = 0; i < p->size(); i++)
			m_usages[p->at(i)]--;

		w = w->next;
	}


	TAILQ_FOREACH(p, &m_patterns, entries) {
		if (!p->active) continue;

		if (p->prev.usage != p->cur.usage || p->prev.cover != p->cur.cover)
			changed = true;

		if (p->cur.usage > 0) m_ctcnt++;

		p->prev = p->cur;

		//printf("u: %d %d\n", p->cur.usage, p->cur.cover);

		setcost(p);
	}

	return changed;
}

void
cover::computecode()
{
	m_cost = codetable();
	//printf("ct %f\n", m_cost);
	for (uint32_t i = 0; i < m_seq.dim(); i++)
		m_cost += m_seq.symcnt(i) * codeusage(i);

	window *w = TAILQ_FIRST(&m_head);
	if (w) m_cost -= w->optcost;
}

void
cover::setcost(pattern *p) const
{
	double cost = -codeusage(p->cur.usage, m_usage);
	if (p->cur.usage > 0)
		cost += (p->size() - 1)*(lg2(p->cur.usage*(p->size() - 1)) - lg2(p->cur.cover));
	else
		cost -= p->size() - 1;

	for (uint32_t i = 0; i < p->size(); i++) cost += codeusage(p->at(i));

	double gap = -1;
	if (p->cur.usage > 0)
		gap = lg2(p->cur.cover - p->cur.usage*(p->size() - 1)) - lg2(p->cur.cover);

	window *w;
	TAILQ_FOREACH(w, &p->windows, inst) {
		w->cost = cost; 
		if (w->cover() > (index_t)p->size()) w->cost += (w->cover() - p->size())*gap;
	}
}


void
cover::init()
{
	uintvector probs(m_seq.dim());

	uint32_t cnt = 0;

	for (uint32_t i = 0; i < m_seq.dim(); i++) {
		probs[i] = m_seq.symcnt(i);
		cnt += m_seq.symcnt(i);
	}

	pattern *p;
	TAILQ_FOREACH(p, &m_patterns, entries) {
		if (!p->active) continue;
		p->cur = p->win;
		cnt += p->win.usage;
		// Force the algorithm to run at least once completely
		p->prev.cover = 1; p->prev.usage = 0;
	}

	TAILQ_FOREACH(p, &m_patterns, entries) {
		if (!p->active) continue;
		double cost = lg2(p->cur.usage) - lg2(cnt) + lg2(p->cur.usage*(p->size() - 1)) - lg2(p->cur.cover);

		for (uint32_t i = 0; i < p->size(); i++)
			cost -= lg2(probs[(*p)[i]]) - lg2(cnt);
			
		double gap = lg2(p->cur.cover - p->cur.usage*(p->size() - 1)) - lg2(p->cur.cover);

		window *w;
		TAILQ_FOREACH(w, &p->windows, inst) {
			w->cost = cost;
			if (w->cover() > index_t(p->size())) w->cost += (w->cover() - p->size())*gap;
		}
	}
}


double
cover::codetable()
{
	double cost = intcost(m_seq.seqsizes().size()) + intcost(m_seq.dim()) + m_util.choose(m_seq.size() - 1, m_seq.dim() - 1) ;

	for (uint32_t i = 0; i < m_seq.seqsizes().size(); i++)
		cost += intcost(m_seq.seqsizes()[i]);

	//printf("c: %f\n", cost);

	//printf("%d %d %f\n", m_patusage, m_ctcnt, code(m_patusage, m_ctcnt));
	cost += code(m_patusage, m_ctcnt);  

	pattern *p;
	TAILQ_FOREACH(p, &m_patterns, entries) {
		if (p->active && p->cur.usage > 0) 
			cost += code(p);
	}
	//cost += m_singcnt*(intcost(1) + lg2(m_seq.dim()));
	//printf("c: %f %d\n", cost, m_usage);

	return cost;
}

double
cover::code(const pattern *p) const
{
	double cost = intcost(p->size()) + intcost(1 + p->cur.cover - p->cur.usage*(p->size() - 1));
	for (uint32_t i = 0; i < p->size(); i++) cost += code((*p)[i]);
	return cost;
}

double
cover::code(uint32_t usage, uint32_t ctcnt) const
{
	double c = intcost(1 + ctcnt) + intcost(1 + usage);
	if (ctcnt > 0)
		c += m_util.choose(usage - 1, ctcnt - 1);
	return c;
}

double
cover::codegap(uint32_t cover, uint32_t usage, uint32_t symcnt) const
{
	if (cover == 0) return 0;
	uint32_t s = usage*(symcnt - 1);
	double c = s*(-lg2(s) + lg2(cover));

	if (s < cover) c += (cover - s)*(-lg2(cover - s) + lg2(cover));

	return c;
}


double
cover::code(const estimate & est) const
{
	double cost = est.bias + code(est.p1) + code(est.p2) + code(est.pnew);

	//printf("est %f\n", cost);

	cost += (m_usage - est.pnew.usage)*(lg2(m_usage - est.pnew.usage) - lg2(m_usage));
	
	//printf("est %f %d\n", cost, m_usage - est.pnew.usage);
	//return cost;

	int32_t shift = 0;
	if (est.p1.usage == 0 && est.p1.symcnt > 1) shift--;
	if (est.p2.usage == 0 && est.p2.symcnt > 1) shift--;
	if (est.pnew.usage > 0) shift++;

	uint32_t patusage = m_seq.size() - m_usage + est.pnew.usage;

	if (est.p1.symcnt > 1) patusage -= est.pnew.usage;
	if (est.p2.symcnt > 1) patusage -= est.pnew.usage;

	//printf("%d %d %f\n", patusage, m_ctcnt + shift, code(patusage, m_ctcnt + shift));

	return cost + code(patusage, m_ctcnt + shift); 
}

double
cover::code(const patcost & pc) const
{
	double cost = pc.usage*codeusage(pc.usage, m_usage);

	//printf("u %d\n", pc.usage);
	//return cost;

	if (pc.symcnt > 1 && pc.usage > 0) {
		cost += codegap(pc.cover, pc.usage, pc.symcnt);
		cost += intcost(1 + pc.cover - pc.usage*(pc.symcnt - 1));
		cost += pc.stcost;
	}

	//printf("%f\n", cost - c);

	return cost;
}



void
cover::purgefast()
{
	pattern *p, *pnext;

	while (true) {
		for (p = TAILQ_FIRST(&m_patterns); p != NULL; p = pnext) {
			pnext = TAILQ_NEXT(p, entries);
			if (p->cur.usage == 0) remove(p);
		}

		if (m_ctcnt == 0) return;

		uint32_t cnt = m_ctcnt;
		uint32_t usage = m_patusage;
		double thresh = code(usage, cnt);
		
		for (p = TAILQ_FIRST(&m_patterns); p != NULL; p = pnext) {
			pnext = TAILQ_NEXT(p, entries);

			double cost = thresh + code(p);

			cost -= code(usage - p->cur.usage, cnt - 1);

			if (p->gain <= cost)  {
				remove(p);
				cnt--;
				usage -= p->cur.usage;
				thresh = code(usage, cnt);
			}
		}

		if (cnt == m_ctcnt) break;
		optimize();
	}
}

void
cover::purge()
{
	pattern *p, *pnext;
	double c = cost();
	for (p = TAILQ_FIRST(&m_patterns); p != NULL; p = pnext) {
		pnext = TAILQ_NEXT(p, entries);

		p->active = false;
		if (optimize() < c) {
			remove(p);
			c = cost();
		}
		else
			p->active = true;
	}
	optimize();
}

void
cover::rank()
{
	pattern *p;
	double c = cost();
	TAILQ_FOREACH(p, &m_patterns, entries) {
		p->active = false;
		p->worth = optimize() - c;
		p->active = true;
	}
	optimize();
}




double
cover::intcost(uint32_t u) const
{
	double c = lg2(2.865064);
	double z = lg2(u);
	
	while (z > 0) {
		c += z;
		z = lg2(z);
	}

	return c;
}

struct patrankcmp
{
	bool operator () (const pattern *a, const pattern *b) const {return a->worth > b->worth;}
};

void
cover::print(FILE *out)
{
	std::vector<pattern *> pats(m_patcnt);

	pattern *p;
	uint32_t i = 0;
	TAILQ_FOREACH(p, &m_patterns, entries)
		pats[i++] = p;
	
	std::sort(pats.begin(), pats.end(), patrankcmp());

	for (i = 0; i < pats.size(); i++) {
		pats[i]->print(out);
		fprintf(out, "\n");
	}
}
