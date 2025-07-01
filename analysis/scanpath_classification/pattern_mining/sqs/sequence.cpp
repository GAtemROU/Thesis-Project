#include <algorithm>
#include "sequence.h"

#include <limits>
#include <algorithm>
#include <map>


sequence::sequence(const params & par) : m_params(par)
{
	TAILQ_INIT(&m_sequence);
}

bool
event_comp(event *a, event *b)
{
	return a->symbol < b->symbol;
}

void
sequence::read_full(FILE *f)
{
	uint32_t cnt = 0;
	uint32_t scnt = 1;
	int32_t a;
	int32_t m = 0;

	while (fscanf(f, "%d", &a) == 1) {
		if (a >= 0) cnt++; else scnt++;
		if (a > m) m = a;
	}

	m_data.resize(cnt);
	m_events.resize(m + 1);
	m_seqsizes.resize(scnt);

	for (uint32_t i = 0; i < m_events.size(); i++)
		TAILQ_INIT(&m_events[i]);

	rewind(f);

	uint32_t i = 0;
	uint32_t sid = 0;
	while (fscanf(f, "%d", &a) == 1) {
		if (a == -1) {
			sid++;
			continue;
		}
		event *e = &m_data[i];
		e->symbol = a;
		e->index = i;
		e->id = i;
		e->seqid = sid;
		if (TAILQ_EMPTY(&(m_events[a])))
			e->simid = 0;
		else
			e->simid = last(a)->simid + 1;

		TAILQ_INSERT_TAIL(&m_sequence, e, entries);
		TAILQ_INSERT_TAIL(&(m_events[a]), e, similar);
		i++;
		m_seqsizes[sid]++;
	}
}


void
sequence::read_sparse(FILE *f)
{
	uint32_t cnt = 0;
	uint32_t a;
	int32_t ind;
	uint32_t m = 0;
	while (fscanf(f, "%d%u", &ind, &a) == 2) {
		cnt++;
		if (a > m) m = a;
	}

	m_data.resize(cnt);
	m_events.resize(m + 1);

	for (uint32_t i = 0; i < m_events.size(); i++)
		TAILQ_INIT(&m_events[i]);

	rewind(f);

	uint32_t i = 0;
	while (fscanf(f, "%d%u", &ind, &a) == 2) {
		if (i > 0 && ind < m_data[i - 1].index)  {
			fprintf(stderr, "Input file doesn't have monotonic indices: %u (line %u) vs. %u (line %u)\n", ind, i, m_data[i - 1].index, i - 1);
			exit(1);
		}
			
		event *e = &m_data[i];
		e->symbol = a;
		e->index = ind;
		e->id = i;
		if (TAILQ_EMPTY(&(m_events[a])))
			e->simid = 0;
		else
			e->simid =  last(a)->simid + 1;

		TAILQ_INSERT_TAIL(&m_sequence, e, entries);
		TAILQ_INSERT_TAIL(&(m_events[a]), e, similar);
		i++;
	}
}

void
sequence::filter(uint32_t t) {
	for (uint32_t i = 0; i < dim(); i++) {
		if (symcnt(i) < t) {
			for (event *e = first(i); e; e = e->sim())
				TAILQ_REMOVE(&m_sequence, e, entries);
		}
	}
}
