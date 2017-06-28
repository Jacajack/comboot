all: clean force
	cd asm && nasm comboot.asm -o ../bin/comboot.bin

force:
	-mkdir bin

clean:
	-rm -r bin

run:
	qemu-system-i386 -boot a -fda bin/comboot.bin -serial stdio
