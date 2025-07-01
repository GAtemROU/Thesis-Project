#include "cover.h"
#include <algorithm>

struct pc {
	double cost;
	pattern *p;

	bool operator < (const pc & b) const {return cost < b.cost;}
};

void
sqs_order(cover & c, const sequence & seq, const mathutil & mu, const patternlist & p, const params & par)
{
	std::vector<pc> order(p.size());

	printf("Sorting %u patterns\n", uint32_t(p.size()));

	uint32_t i = 0;
	for (patternlist::const_iterator it = p.begin(); it != p.end(); ++it, i++) {
		cover test(seq, mu);
		test.add(*it);
		order[i].cost = test.optimize();
		order[i].p = *it;
		printf("%d\r", i);
		fflush(stdout);
	}

	printf("Testing\n");

	std::make_heap(order.begin(), order.end());
	std::sort_heap(order.begin(), order.end());

	double cost = c.optimize();

	for (i = 0; i < order.size(); i++) {
		c.add(order[i].p);
		if (c.optimize() < cost && order[i].p->cur.usage >= par.thresh) {
			c.purgefast();
			cost = c.cost();
		}
		else
			c.remove(order[i].p);
		printf("%d %d %f\r", i, c.patcnt(), c.cost());
		fflush(stdout);
	}
	printf("\nDone\n");

	c.purge();
}
