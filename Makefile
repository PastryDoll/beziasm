run: link build
	./beziasm

link: build
	ld -m elf_x86_64 beziasm.o -dynamic-linker /lib64/ld-linux-x86-64.so.2 -L./raylib/lib -lc -lraylib -lm -o beziasm

build: 
	./fasm/fasm beziasm.asm
