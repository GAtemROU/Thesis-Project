Program for discovering significant episodes.

Compile: make

Run: ./sqs

Help with parameters: ./sqs -h

Input formats:
Data file:

space-separated sequence of ids, unsigned integers.
-1 acts as a separator between two sequences.

Pattern file:
Each pattern, a sequence of ids (unsigned integers), on a separate line.  If
the line contains non-numerical symbols, reading the events from the line is
aborted and the read events are used as a pattern. Each line can be only 1024
symbols.
