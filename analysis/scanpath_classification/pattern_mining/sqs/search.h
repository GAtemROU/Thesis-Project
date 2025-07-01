#ifndef SEARCH_H
#define SEARCH_H

#include "cover.h"

void sqs_order(cover & c, const sequence & seq, const mathutil & mu, const patternlist & p, const params & par);

void sqs_slam(cover & c, const sequence & seq, const params & par);


#endif
