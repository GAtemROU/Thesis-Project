#ifndef MATHUTIL_H
#define MATHUTIL_H

#include "defines.h"
#include <math.h>
#include "queue.h"

class mathutil {
	public:
		mathutil(uint32_t N);

		double choose(uint32_t n, uint32_t  k) const {return m_fact[n] - m_fact[k] - m_fact[n - k];}
		double fact(uint32_t n) const {return m_fact[n];}
		double stirling(uint32_t n, uint32_t  k) const;

	protected:
		doublevector m_fact;
};

extern const double logbase;
#define lg2(x) (log(x) / logbase)

#endif
