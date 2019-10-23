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

; Changes the SCY register during mode 3, with SCX set to LY on each row.
; Initiated by STAT mode 2 LCDC interrupt in a field of NOPs.


INCLUDE "src/includes/hardware.inc"
INCLUDE "src/includes/utils.s"

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

    ; background is filled with 'ABC...' on each row
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

    ld hl, sprite_data 
    ld c, (sprite_data_end-sprite_data)
    call oam_copy

    ld a, LCDCF_ON | LCDCF_WINOFF | LCDCF_BG9800 | LCDCF_BG8000 | LCDCF_BGON | LCDCF_OBJON | LCDCF_OBJ8
    ldh [rLCDC], a

    ld a, $e4
    ldh [rBGP], a

    ; load hl with address of SCY register
    ld hl, rSCY

    ld bc, $0102

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

    nop
    nop

    xor a

    ld [hl], a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], d
    ld [hl], c
    ld [hl], b
    ld [hl], a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], d
    ld [hl], c
    ld [hl], b
    ld [hl], a
    ld [hl], b
    ld [hl], c
    ld [hl], d
    ld [hl], e
    ld [hl], d
    ld [hl], c
    ld [hl], b


    ; reset the return address to the top of the nops loop
    pop de
    ld de, nop_slide
    push de

    ld de, $0304

    reti


sprite_data::

    DB $10, 00, $00, 0
    DB $18, 01, $00, 0
    DB $20, 02, $00, 0
    DB $28, 03, $00, 0
    DB $30, 04, $00, 0
    DB $38, 05, $00, 0
    DB $40, 06, $00, 0
    DB $48, 07, $00, 0
    DB $50, 08, $00, 0
    DB $58, 09, $00, 0
    DB $60, 10, $00, 0
    DB $68, 11, $00, 0
    DB $70, 12, $00, 0
    DB $78, 13, $00, 0
    DB $80, 14, $00, 0
    DB $88, 15, $00, 0
    DB $90, 16, $00, 0
    DB $98, 17, $00, 0

sprite_data_end::
