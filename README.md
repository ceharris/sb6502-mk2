sb6502-mk2
==========

A single board computer project using the WDC 65C02 microprocessor.

Key hardware features in this design:

* 65C02 microprocessor clocked at 1.8432 MHz
* 32K ROM and 128K RAM with flexible bank switching support
* PLD-based system logic
* Pin sockets for 6502 bus signals to allow easy connection to external
  devices
* On board serial console using MC68B50 ACIA operating at 115 kbps, 
  including hardware flow control, and both TTL and RS-232 terminal 
  connection points
* On board WDC 65C22 Versatile Interface Processor (VIA) with pin sockets
  for all GPIO and control signals
* Switchable interrrupt request configuration for on-board VIA and ACIA
  allowing either wired-OR or use of an external interrupt controller
  to manage the 6502's /IRQ input.

Key software features in this design:

* TailForth 2 in ROM
* Initial program load (IPL) allows system programs to be uploaded 
  in either Motorola SREC or Intel Hex records, directly transferred to
  RAM and executed.
