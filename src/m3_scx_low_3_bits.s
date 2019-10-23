; Copyright (C) 2018 Matt Currie <me@mattcurrie.com>
;
; Permission is hereby granted, free of charge, to any person obtaining a copy
; of this software and associated documentation files (the "Software"), to deal
; in the Software without restriction, including without limitation the rights
; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
; copies of the Software, and to permit persons to whom the Software is
; furnished to do so, subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
; SOFTWARE.

; Tests how late SCX can be written to and have the lowest 3 bits of SCX still
; affect the rendering. The lowest 3 bits appear to be read at the start of
; the "B" of the first "B01s" read cycle.
; Initiated by STAT mode 2 LCDC interrupt in a field of NOPs.

INCLUDE "src/includes/hardware.inc"
INCLUDE "src/includes/utils.s"


SECTION "wram", WRAM0

counter::
    ds 1


SECTION "vblank", ROM0[$40]

    jp vblank_handler     


SECTION "lcdc", ROM0[$48]

    jp hl     


SECTION "boot", ROM0[$100]

    nop                                       
    jp main                          


SECTION "main", ROM0[$150]

main::

    di
    ld sp, $fffe

    xor a
    ld [counter], a

    call reset_registers
    call reset_oam

    ; select mode 2 lcdc interrupt
    ld a, $20
    ldh [rSTAT], a

    ; enable vblank and lcdc interrupts
    ld a, $03
    ldh [rIE], a

    ; background is filled with spaces
    ld a, 0
    call fill_vram_9800

    ; fill the last column of the background with (R) tiles
    ld hl, $9800 + 19
    ld de, 32
    ld a, $19
    ld c, 18

.loop:
    ld [hl], a
    add hl, de
    dec c
    jr nz, .loop

    ld a, LCDCF_ON | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_BGON
    ldh [rLCDC], a

    ld a, $fc
    ldh [rBGP], a

    ; set hl so we can jump to it later
    ld hl, lcdc_handler

    ld c, LOW(rSCX)

    ; enable interrupts
    ei


nop_slide:
    REPT 1200
    nop
    ENDR

    jp nop_slide

vblank_handler::

    xor a
    ldh [rSCX], a

    ; let it run for 10 frames
    ld a, [counter]
    inc a

    cp 10
    jp nz, .continue

    ; source code breakpoint - good time to take a screenshot to compare
    ld b,b

.continue:

    ld [counter], a
    reti


lcdc_handler::
    ; 20 cycles interrupt dispatch + 4 cycles to jump here: 24
    
    ; set SCX to 0
    xor a
    ld [c], a

    ; delay 4 t-cycles on the first 72 rows of the screen,
    ; causing the SCX = 2 write to fail.
    ldh a, [rLY]
    cp $48
    jr c, .delay
.delay:    

    nop
    nop

    ; set SCX to 2
    ld a, 2
    ld [c], a

    ; reset the return address to the top of the nops loop
    pop de
    ei
    jp nop_slide

