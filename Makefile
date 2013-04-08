all: de
	@echo "To benchmark, try\n\n > time luajit de.lua\n\nor\n\n > time ./de\n"

de: de.c
	gcc -O3 de.c -o de
