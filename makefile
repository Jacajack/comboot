all: clean force
	cd asm && nasm bootsec.asm -o ../bin/000-bootsec.bin
	cd asm && nasm comboot.asm -o ../bin/001-comboot.bin
	cat bin/*.bin | sponge > bin/comboot.bin
	cp bin/comboot.bin comboot.img
	dd if=/dev/zero of=comboot.img bs=1 count=0 seek=1474560

force:
	-mkdir bin

clean:
	-rm -r bin

run:
	qemu-system-i386 -boot a -fda comboot.img -serial stdio
