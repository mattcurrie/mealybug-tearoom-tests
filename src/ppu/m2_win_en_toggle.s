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

; Toggles bit 5 (WIN_EN) of LCDC register on each row of the screen during 
; STAT mode 2. 
; The current window line is only incremented when the window is actually 
; activated, so on rows when the window is off, the window line should not
; be incremented.
; Initiated by STAT mode 2 LCDC interrupt in a field of NOPs.


INCLUDE "inc/hardware.inc"
INCLUDE "inc/utils.s"

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


    ; background is filled with ' '
    ld a, $20
    call fill_vram_9c00


    ; window is filled with 'ABC...', advancing by one letter per row
    ld hl, $9800

    ld b, 65    ; 'A'

.row:
    ld c, 32
    ld a, b

.inner:   
    ld [hl+], a
    inc a
    dec c
    jr nz, .inner

    inc b

    bit 2, h       ; bit 2 will be set when value of h register is $9c
    jr z, .row

    ; default window to being off. it will be then turned on during mode 2 of line 0
    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_WIN9800 | LCDCF_BG9C00 | LCDCF_BG8000 | LCDCF_BGON | LCDCF_OBJOFF | LCDCF_OBJ8
    ldh [rLCDC], a

    ld a, 7
    ldh [rWX], a

    ld a, 0
    ldh [rWY], a

    ld a, $e4
    ldh [rBGP], a

    ; enable interrupts
    ei


nop_slide:
    REPT 1200
    nop
    ENDR

    jp nop_slide

vblank_handler::

    ; set bit 5
    ldh a, [rLCDC]
    or $20
    ldh [rLCDC], a

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

    ; toggle bit 5
    ldh a, [rLCDC]
    xor $20
    ldh [rLCDC], a

    ; reset the return address to the top of the nops loop
    pop de
    ld de, nop_slide
    push de

    reti


