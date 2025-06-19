.PHONY: all clean eeprom
.SUFFIXES: .bin .lbl .lst .map .o .s .sym

IMAGE=ipl.bin
EEPROM_PART=AT28C256
LD_CONFIG=ipl.cfg

INCLUDES=$(LD_CONFIG) \
	loader.h.s \
	forth.h.s \
	monitor.h.s \
	registers.h.s \
	../include/acia.h.s \
    ../include/ascii.h.s \
	../include/conf.h.s \
	../include/hex.h.s \
	../include/ports.h.s \
	../include/prog.h.s

MODULES=ipl.o \
        fill.o \
	loader.o \
	monitor.o \
	acia.o \
	hex.o \
	peek.o \
	poke.o \
	quit.o \
	stdio.o \
	registers.o \
	vectors.o

AS=ca65
LD=ld65
PU=minipro

ASFLAGS=--cpu 65c02 -I ../include -DACIA_ISR_INCLUDED=1
LDFLAGS=--config $(LD_CONFIG)
PUFLAGS=-p $(EEPROM_PART)

all: $(IMAGE)

clean:
	-rm -f *.bin *.lbl *.lst *.map *.o *.sym

eeprom:	ipl.bin
	$(PU) $(PUFLAGS) -uP -w $<

acia.o: ../lib/acia.s $(INCLUDES)
fill.o: fill.s $(INCLUDES)
hex.o: ../lib/hex.s $(INCLUDES)
ipl.o: ipl.s $(INCLUDES)
loader.o: loader.s $(INCLUDES)
monitor.o: monitor.s $(INCLUDES)
peek.o: peek.s $(INCLUDES)
poke.o: poke.s $(INCLUDES)
quit.o: quit.s $(INCLUDES)
registers.o: registers.s $(INCLUDES)
stdio.o: ../lib/stdio.s $(INCLUDES)
vectors.o: vectors.s $(INCLUDES)

$(IMAGE): $(MODULES)
	$(LD) $(LDFLAGS) $^ -o $@ -m $*.map -Ln $*.lbl

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@ -l $*.lst

%.o: ../lib/%.s
	$(AS) $(ASFLAGS) $< -o $@ -l $*.lst

	
