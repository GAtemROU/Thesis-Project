#include "mathutil.h"
#include "math.h"

const double logbase = log(2);

#define pw2(x) exp((x) * logbase)

double inline
plus(double a, double b) {
	double c = a > b ? a : b;
	return lg2(pw2(a - c) + pw2(b - c)) + c;
}

double inline
diff(double a, double b) {
	double c = a > b ? a : b;
	return lg2(pw2(a - c) - pw2(b - c)) + c;
}


mathutil::mathutil(uint32_t N) : m_fact(N + 1)
{
	for (uint32_t i = 2; i <= N; i++)
		m_fact[i] = m_fact[i - 1] + log2(i);
}

double
mathutil::stirling(uint32_t n, uint32_t  k) const
{
	double s, ns;

	ns = s = std::numeric_limits<double>::min();

	for (uint32_t i = 1; i <= k; i++) {
		double term = choose(k, k - i) + n * lg2(i);

		if ((k - i) % 2 == 1)
			ns = plus(ns, term);
		else
			s = plus(s, term);

		if (s > ns && ns >= 0) {
			s = diff(s, ns);
			ns = std::numeric_limits<double>::min();
		}
	}

	return s - fact(k);
}
