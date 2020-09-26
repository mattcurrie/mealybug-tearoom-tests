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

; Turns bit 5 (WIN_EN) of LCDC register on and off multiple times 
; during mode 3. 
; If WX is set to activate at a pixel that has not been drawn yet, and WIN_EN
; is toggled then the window can be turned on and off multiple times on a single
; row, with background tiles displaying in between.
; The current row of the window is incremented each time the window is activated,
; so the second time the window is activated on the row, the next row of window
; pixels are displayed.
; When the window is disabled during mode 3, the tile fetcher will read from the
; background tiles instead of the window tiles at the start of the next tile 
; fetcher cycle.  This means that when the window is turned on and off it will
; always display a multiple of 8 pixels, except when the window begins off the
; left edge of the screen.
; Initiated by STAT mode 2 LCDC interrupt in a field of NOPs.


INCLUDE "inc/hardware.inc"
INCLUDE "inc/utils.asm"

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

    call copy_font

    ; background is filled with 'B'
    ld a, $42
    call fill_vram_9800

    ; window is filled with 'ABC...' on each row
    ld hl, $9c00

.row:
    ld c, 32
    ld a, 65     ; 'A'

.inner:   
    ld [hl+], a
    inc a
    dec c
    jr nz, .inner

    bit 5, h       ; bit 5 will be set when value of h register is $a0
    jr z, .row


    ; turn the screen on, $9C00-$9FFF window tile map, window on, bg tile data $8000-$8FFF, 
    ; bg tile map $9800-$9BFF, obj size 8*8, obj display on, bg display on
    ld b, $f3

    ; c has the same value, but with bit 5 reset
    ld c, b
    res 5, c

    ld a, 7
    ldh [rWX], a

    ld a, 0
    ldh [rWY], a

    ld a, $e4
    ldh [rOBP0], a

    ld a, $e4
    ldh [rBGP], a

    ; load hl with address of LCDC register
    ld hl, rLCDC

    ; set initial value
    ld [hl], b

    ; enable interrupts
    ei


nop_slide:
    REPT 1200
    nop
    ENDR

    jp nop_slide

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

    ; 20 cycles interrupt dispatch + 12 cycles to jump here: 32

    line_0_fix 

    ld a, 24
    nop

    ; 12 cycles
    ldh [rWX], a


    REPT 5
    nop
    ENDR    

    ; set new WX value
    ld a, 120
    ldh [rWX], a

    nop
    nop
    nop
    nop

    ; set the new value: 8 cycles - window off  - background is visible
    ld [hl], c

    nop
    nop

    ; restore old value  - window on again
    ld [hl], b


    ; reset the return address to the top of the nops loop
    pop de
    ld de, nop_slide
    push de

    reti
