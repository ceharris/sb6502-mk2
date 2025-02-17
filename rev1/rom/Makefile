
EEPROM_PART=AT28C256
IMAGE=sbmk2.bin
BASIC=msbasic
MODULES=dispatch.o monitor.o acia.o keypad.o registers.o sound.o stdio.o vectors.o $(BASIC)/msbasic.o

.PHONY: all clean eeprom
.SUFFIXES: .lst .bin .map .lbl

AS=ca65
LD=ld65
PU=minipro
ASFLAGS=-Dsbmk2 --cpu 65c02
LDFLAGS=--config sbmk2.cfg
PUFLAGS=-p $(EEPROM_PART)

all: $(IMAGE)

clean:
	-rm -f *.o *.lst *.map *.lbl *.bin $(IMAGE)
	-(cd $(BASIC); rm -f *.o *.lst *.map *.lbl *.bin)

acia.o: ascii.h.s acia.h.s registers.h.s

keypad.o: keypad.h.s registers.h.s

monitor.o: ansi.h.s ascii.h.s keypad.h.s registers.h.s stdio.h.s

sound.o: sound.h.s sound.s

stdio.o: ascii.h.s stdio.h.s

$(BASIC)/msbasic.o: \
	$(BASIC)/array.s \
	$(BASIC)/chrget.s \
	$(BASIC)/defines.s \
	$(BASIC)/error.s \
	$(BASIC)/eval.s \
	$(BASIC)/extra.s \
	$(BASIC)/float.s \
	$(BASIC)/flow1.s \
	$(BASIC)/flow2.s \
	$(BASIC)/init.s \
	$(BASIC)/inline.s \
	$(BASIC)/input.s \
	$(BASIC)/iscntc.s \
	$(BASIC)/loadsave.s \
	$(BASIC)/macros.s \
	$(BASIC)/memory.s \
	$(BASIC)/message.s \
	$(BASIC)/misc1.s \
	$(BASIC)/misc2.s \
	$(BASIC)/msbasic.s \
	$(BASIC)/poke.s \
	$(BASIC)/print.s \
	$(BASIC)/program.s \
	$(BASIC)/rnd.s \
	$(BASIC)/sound.s \
	$(BASIC)/string.s \
	$(BASIC)/token.s \
	$(BASIC)/trig.s \
	$(BASIC)/var.s \
	$(BASIC)/zeropage.s \
	$(BASIC)/defines_sbmk2.s \
	$(BASIC)/sbmk2_extra.s \
	$(BASIC)/sbmk2_iscntc.s \
	$(BASIC)/sbmk2.cfg

eeprom: $(IMAGE)
	$(PU) $(PUFLAGS) -uP -w $<

$(IMAGE): $(MODULES)
	$(LD) $(LDFLAGS) $^ -o $@ -m $*.map -Ln $*.lbl

%.o: %.s
	$(AS) $(ASFLAGS) $< -o $@ -l $*.lst

