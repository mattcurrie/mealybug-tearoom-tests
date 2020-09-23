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

; Tests changing the sprite palette in OBP0 during mode 3 with sprites
; at different X coordinates


INCLUDE "inc/hardware.inc"


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

    ; use the (r) logo as a sprite
    ld hl, sprite_data 
    ld c, 76 ; 19 sprites * 4
    call oam_copy

    ; turn the screen on, $9800-$9BFF window tile map, window off, bg tile data $8800-$97FF, 
    ; bg tile map $9800-$9BFF, obj size 8*8, obj display on, bg display on
    ld a, $83
    ldh [rLCDC], a

    ld a, $ff
    ldh [rOBP0], a

    ld a, $e4
    ldh [rBGP], a

    ; load c with address of OBP0 register
    ld c, $48

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


    ; set default palette and save into b: 20 cycles
    ld a, $04
    ld b, a
    ld [c], a

    ; new palette value in a: 8 cycles
    ld a, $0c

    REPT 10
    nop
    ENDR    

    ; set the new palette: 8 cycles
    ld [c], a

    ; reset the return address to the top of the nops loop
    pop hl
    ld hl, nop_slide
    push hl

    reti


sprite_data::

    DB $08, 00, $19, 0 ; this is offscreen
    DB $10, 01, $19, 0
    DB $18, 02, $19, 0
    DB $20, 03, $19, 0
    DB $28, 04, $19, 0
    DB $30, 05, $19, 0
    DB $38, 06, $19, 0
    DB $40, 07, $19, 0
    DB $48, 08, $19, 0
    DB $50, 09, $19, 0
    DB $58, 10, $19, 0
    DB $60, 11, $19, 0
    DB $68, 12, $19, 0
    DB $70, 13, $19, 0
    DB $78, 14, $19, 0
    DB $80, 15, $19, 0
    DB $88, 16, $19, 0
    DB $90, 17, $19, 0
    DB $98, 18, $19, 0


INCLUDE "inc/utils.s"
