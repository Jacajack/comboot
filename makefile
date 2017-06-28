all: clean force
	cd asm && nasm bootsec.asm -o ../bin/000-bootsec.bin
	cd asm && nasm comboot.asm -o ../bin/001-comboot.bin
	cat bin/*.bin | sponge > bin/comboot.bin

force:
	-mkdir bin

clean:
	-rm -r bin

run:
	qemu-system-i386 -boot a -fda bin/comboot.bin -serial stdio
