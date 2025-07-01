#ifndef PATTERN_H
#define PATTERN_H

#include "defines.h"
#include "event.h"
#include "queue.h"
#include <list>
#include <stdio.h>

struct pattern;

TAILQ_HEAD(windowhead, window);

struct window {
	window(const event *f, const event *l, pattern *p) : first(f), last(l), pat(p), next(0) {}

	const event *first, *last;
	pattern *pat;

	TAILQ_ENTRY(window) inst;
	TAILQ_ENTRY(window) head;
	TAILQ_ENTRY(window) tail;
	TAILQ_ENTRY(window) optinst;
	window *next;

	index_t cover() const {return  last->index - first->index + 1;}

	window * simoptprev() {return TAILQ_PREV(this, windowhead, optinst);}
	window * simopt() {return TAILQ_NEXT(this, optinst);} 
	window * simprev() {return TAILQ_PREV(this, windowhead, inst);}
	window * sim() {return TAILQ_NEXT(this, inst);} 

	double cost;
	double optcost;
	window *opt;
};




struct pattern {
	pattern(uint32_t cnt) : symbols(cnt), worth(0), gain(0) {TAILQ_INIT(&windows); win.usage = win.cover = 0; cur.usage = 0;}

	uintvector symbols;
	double worth;
	uint32_t index;

	struct {
		uint32_t usage;
		index_t cover;
	} cur, prev, win;

	double gain;
	bool active;

	void print(FILE *out) const;

	windowhead windows; 
	windowhead opt; 

	void add(window *w) {TAILQ_INSERT_TAIL(&windows, w, inst); win.usage++; win.cover += w->cover() - 1;}

	uint32_t size() const {return symbols.size();}

	const uint32_t & operator [] (uint32_t i) const {return symbols[i];}
	uint32_t & operator [] (uint32_t i) {return symbols[i];}

	const uint32_t & at(uint32_t i) const {return symbols[i];}
	uint32_t & at(uint32_t i) {return symbols[i];}

	TAILQ_ENTRY(pattern) entries;
};

TAILQ_HEAD(patternhead, pattern);

typedef std::list<pattern *> patternlist;

void read(patternlist & patterns, FILE *f);

#endif
