#include "sequence.h"
#include <getopt.h>
#include <stdlib.h>

#include <string>
#include <string.h>
#include <vector>

#include "params.h"
#include "cover.h"
#include "search.h"

void
outofmemory()
{
	fprintf(stderr, "Oh noes! out of memory\n");
	exit(1);
}


int
main(int argc, char ** argv)
{
	static struct option longopts[] = {
		{"out",             required_argument,  NULL, 'o'},
		{"in",              required_argument,  NULL, 'i'},
		{"patterns",        required_argument,  NULL, 'p'},
		{"method",          required_argument,  NULL, 'm'},
		{"thresh",          required_argument,  NULL, 't'},
		{"sparse",          no_argument,        NULL, 's'},
		{"help",            no_argument,        NULL, 'h'},
		{ NULL,             0,                  NULL,  0 }
	};

	char *inname = NULL;
	char *outname = NULL;
	char *patname = NULL;
	char *methname = NULL;

	params par;

	std::set_new_handler(outofmemory);

	int ch;
	while ((ch = getopt_long(argc, argv, "o:i:hp:m:t:", longopts, NULL)) != -1) {
		switch (ch) {
			case 'h':
				printf("Usage: %s -w <window> -i <input file> -o <output file> -m <method> [-p <pattern file>] [-h]\n", argv[0]);
				printf("  -h    print this help\n");
				printf("  -i    input file\n");
				printf("  -o    output file\n");
				printf("  -p    pattern file\n");
				printf("  -t    threshold for usage (default 1)\n");
				printf("  -m    method (either order or search)\n");
				//printf("  -s    input file is in sparse format\n");

				return 0;
				break;
			case 't':
				par.thresh = atoi(optarg);
				break;
			case 'i':
				inname = optarg;
				break;
			case 'm':
				methname = optarg;
				break;
			case 'p':
				patname = optarg;
				break;
			case 'o':
				outname = optarg;
				break;
			case 's':
				//par.sparse = true;
				break;
		}
	}


	if (inname == NULL) {
		fprintf(stderr, "Missing input file\n");
		return 1;
	}
	
	if (outname == NULL) {
		fprintf(stderr, "Missing output file\n");
		return 1;
	}

	if (methname == NULL) {
		fprintf(stderr, "Missing method\n");
		return 1;
	}
	sequence s(par);

	printf("Reading and building sequence\n");
	FILE *f = fopen(inname, "r");
	s.read(f);
	fclose(f);
	s.filter(par.thresh);


	mathutil mu(s.size());
	cover c(s, mu);


	patternlist pats;

	if (patname) {
		f = fopen(patname, "r");
		read(pats, f);
		fclose(f);
	}

	c.optimize();
	printf("dim %d, sequences %d, events %d\n", s.dim(), uint32_t(s.seqsizes().size()), s.size());
	printf("cost %f\n", c.cost());


	if (strcmp(methname, "order") == 0)
		sqs_order(c, s, mu, pats, par);
	else if (strcmp(methname, "search") == 0)
		sqs_slam(c, s, par);

	c.rank();

	f = fopen(outname, "w");
	c.print(f);
	fclose(f);

	printf("cost %f\n", c.cost());

	return 0;
}
