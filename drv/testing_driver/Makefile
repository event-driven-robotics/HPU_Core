all: readwrite readtest

readwrite: readwrite.c
	gcc -Wall -O2 -g readwrite.c -o readwrite

readtest: readtest.c
	gcc -Wall -O2 -g readtest.c -o readtest

clean:
	rm readtest readwrite
