#include "pattern.h"
#include <stdlib.h>

void
read(patternlist & patterns, FILE *f)
{

	while (!feof(f)) {
		char line[1024];
		fgets(line, 1024, f);
		uintlist syms;

		char *p = line;
		while (true) {
			char *q;
			uint32_t s = uint32_t(strtol(p, &q, 10));
			if (p == q) break;
			syms.push_back(s);

			p = q;
		}

		if (syms.size() > 1) {
			pattern *p = new pattern(syms.size());
			std::copy(syms.begin(), syms.end(), p->symbols.begin());
			patterns.push_back(p);
		}
	}
}

void
pattern::print(FILE *out) const
{
	for (uint32_t i = 0; i < size(); i++)
		fprintf(out, "%d ", symbols[i]);
	fprintf(out, " (%f %f %d)", (cur.cover - cur.usage*(size() - 1)) / double(cur.cover), worth, cur.usage);
}
