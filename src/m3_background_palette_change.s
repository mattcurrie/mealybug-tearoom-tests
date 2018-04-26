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

; Tests changing the background palette in BGP during mode 3


INCLUDE "src/includes/hardware.inc"


SECTION "wram", WRAM0

counter::
    ds 1


SECTION "vblank", ROM0[$40]

    jp vblank_handler     


SECTION "lcdc", ROM0[$48]

    jp lcdc_handler     


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

    ; turn the screen on, $9800-$9BFF window tile map, window off, bg tile data $8800-$97FF, 
    ; bg tile map $9800-$9BFF, obj size 8*8, obj display on, bg display on
    ld a, $83
    ldh [rLCDC], a

    ; load c with address of BGP register
    ld c, $47

    ; enable interrupts
    ei


nops:
    REPT 1200
    nop
    ENDR


vblank_handler::

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
    ; 32 cycles until here (20 interrupt dispatch + 12 for the jump)

    ; line 0 timing is different by 4 cycles, so jump only 
    ; when on line 0
    ; 24 cycles (or 28 cycles when LY = 0)
    ldh a, [rLY]
    and a
    jr nz, .line_0
.line_0:

    ; use bits 4 and 5 for the palette for color 0 so palette will 
    ; change every 16 lines
    ; 24 cycles
    swap a
    ld b, a
    ld [c], a
    inc a

    ; 4 cycles
    nop

    ; set the new palette: 8 cycles
    ld [c], a

    ; set the old palette again: 12 cycles
    ld a, b
    ld [c], a

    ; delay
    REPT 10
    nop
    ENDR

    ; set the new palette: 20 cycles
    ld a, b
    inc a
    inc a
    ld [c], a

    ; set the old palette again: 12 cycles
    ld a, b
    ld [c], a

    ; delay
    REPT 11
    nop
    ENDR

    ; set the new palette: 16 cycles
    ld a, b
    dec a
    ld [c], a

    ; set the old palette again: 12 cycles
    ld a, b
    ld [c], a


    ; set the return address to the top of the nops
    pop hl
    ld hl, nops
    push hl

    reti


INCLUDE "src/includes/utils.s"
