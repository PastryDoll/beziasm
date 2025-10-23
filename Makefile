run:
	./fasm/fasm hello.asm
	ld -m elf_x86_64 hello.o -dynamic-linker /lib64/ld-linux-x86-64.so.2 -L./raylib/lib -lc -lraylib -lm -o hello
	./hello
