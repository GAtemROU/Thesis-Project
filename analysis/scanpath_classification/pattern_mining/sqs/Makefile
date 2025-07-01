SRCS = sqs.cpp cover.cpp sequence.cpp mathutil.cpp order.cpp pattern.cpp build.cpp estimate.cpp
OBJS = $(SRCS:.cpp=.o)


CC = g++
LDFLAGS= -lm -O3 #-fopenmp
CFLAGS= -g -O3 -Wall -Wextra #-fopenmp

all : sqs 

sqs: $(OBJS)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)


%.o : %.cpp
	 $(CC) $(CFLAGS) -c $*.cpp

clean:
	-rm *.o sqs

zip:
	zip sqs.zip *.cpp *.h Makefile readme.txt \
	experiments/address.dat experiments/address.lab \
	experiments/jmlr.dat experiments/jmlr.lab \
	experiments/moby.dat experiments/moby.lab \
	experiments/ind.dat experiments/plant2.dat experiments/plant3.dat

depend:
	makedepend -Y -- $(CFLAGS) -- $(SRCS)
# DO NOT DELETE

sqs.o: sequence.h event.h queue.h defines.h params.h cover.h pattern.h
sqs.o: mathutil.h search.h
cover.o: cover.h event.h queue.h defines.h sequence.h params.h pattern.h
cover.o: mathutil.h
sequence.o: sequence.h event.h queue.h defines.h params.h
mathutil.o: mathutil.h defines.h queue.h
order.o: cover.h event.h queue.h defines.h sequence.h params.h pattern.h
order.o: mathutil.h
pattern.o: pattern.h defines.h event.h queue.h
build.o: search.h cover.h event.h queue.h defines.h sequence.h params.h
build.o: pattern.h mathutil.h
estimate.o: cover.h event.h queue.h defines.h sequence.h params.h pattern.h
estimate.o: mathutil.h
