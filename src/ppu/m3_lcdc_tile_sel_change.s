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

; Sets and resets bit 4 (TILE_SEL) of LCDC register during mode 3 with sprites
; at different X coordinates
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

    ; map at $9800 is filled with 0
    ld a, $0
    call fill_vram_9800

    ; map at $9c00 is filled with 0
    ld a, $0
    call fill_vram_9c00

    ; white tile at index 0
    xor a
    ld c, 16
    ld hl, $9000
.tile_loop:
    ld [hl+], a
    dec c
    jr nz, .tile_loop

    ; black tile at index 0
    ld a, $ff
    ld c, 16
    ld hl, $8000
.tile_loop2:
    ld [hl+], a
    dec c
    jr nz, .tile_loop2

    ; use the (r) logo as a sprite
    ld hl, sprite_data 
    ld c, 76 ; 19 sprites * 4
    call oam_copy

    ; turn the screen on, $9800-$9BFF window tile map, window off, bg tile data $8800-$97FF, 
    ; bg tile map $9800-$9BFF, obj size 8*8, obj display on, bg display on
    ld b, $83

    ; c has the same value, but with bit 4 set
    ld c, b
    set 4, c

    ld a, $ff
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


    REPT 9
    nop
    ENDR    

    ; set the new value: 8 cycles
    ld [hl], c

    ; restore old value
    ld [hl], b

    ; reset the return address to the top of the nops loop
    pop de
    ld de, nop_slide
    push de

    reti


sprite_data::

    DB $10, 00, $19, 0
    DB $18, 01, $19, 0
    DB $20, 02, $19, 0
    DB $28, 03, $19, 0
    DB $30, 04, $19, 0
    DB $38, 05, $19, 0
    DB $40, 06, $19, 0
    DB $48, 07, $19, 0
    DB $50, 08, $19, 0
    DB $58, 09, $19, 0
    DB $60, 10, $19, 0
    DB $68, 11, $19, 0
    DB $70, 12, $19, 0
    DB $78, 13, $19, 0
    DB $80, 14, $19, 0
    DB $88, 15, $19, 0
    DB $90, 16, $19, 0
    DB $98, 17, $19, 0


