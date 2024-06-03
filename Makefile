AS = ca65
CC = cc65
LD = ld65

HLT_NUM=$(shell printf '%d' 0x${HLT_INSTRUCTION})

.PHONY: clean

build: all

%.o: %.s
	$(AS) -D HLT_INSTRUCTION=${HLT_NUM} -g --create-dep "$@.dep" --debug-info $< -o $@

HLT_${HLT_INSTRUCTION}.nes: layout main.o
	$(LD) --dbgfile $@.dbg -C $^ -o $@

all:
	HLT_INSTRUCTION=02 make HLT_02.nes
	make clean
	HLT_INSTRUCTION=12 make HLT_12.nes
	make clean
	HLT_INSTRUCTION=22 make HLT_22.nes
	make clean
	HLT_INSTRUCTION=32 make HLT_32.nes
	make clean
	HLT_INSTRUCTION=42 make HLT_42.nes
	make clean
	HLT_INSTRUCTION=52 make HLT_52.nes
	make clean
	HLT_INSTRUCTION=62 make HLT_62.nes
	make clean
	HLT_INSTRUCTION=72 make HLT_72.nes
	make clean
	HLT_INSTRUCTION=92 make HLT_92.nes
	make clean
	HLT_INSTRUCTION=B2 make HLT_B2.nes
	make clean
	HLT_INSTRUCTION=D2 make HLT_D2.nes
	make clean
	HLT_INSTRUCTION=F2 make HLT_F2.nes
	make clean

clean:
	rm -f *.dep *.o *.dbg

include $(wildcard *.dep)
