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

; Toggles bit 2 of LCDC register (sprite size) during mode 3 with sprites
; at different X coordinates
; Initiated by STAT mode 2 LCDC interrupt in a field of NOPs.


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

    call copy_font

    ; copy sprite data
    ld hl, sprite_data 
    ld c, (sprite_data_end-sprite_data)
    call oam_copy

    ; turn the screen on, $9800-$9BFF window tile map, window off, bg tile data $8800-$97FF, 
    ; bg tile map $9800-$9BFF, obj size 8*16, obj display on, bg display on
    ld a, $87
    ld b, a
    ldh [rLCDC], a

    ld a, $e4
    ldh [rOBP0], a

    ld a, $00
    ldh [rBGP], a

    ; load c with address of LCDC register
    ld c, LOW(rLCDC)

    ; d contains lcdc value with obj size 8*8
    ld d, $83


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

    REPT 14
    nop
    ENDR    

    ; set 8*8 sprites
    ld a, d
    ld [c], a

    nop
    nop
    nop

    ; set 8*16 sprites
    ld a, b
    ld [c], a

    ; set 8*8 sprites
    ld a, d
    ld [c], a

    ; set 8*16 sprites
    ld a, b
    ld [c], a

    ; reset the return address to the top of the nops loop
    pop hl
    ld hl, nop_slide
    push hl

    reti


sprite_data::

    DB $10, 00, $4c, 0
    DB $20, 01, $4c, 0
    DB $30, 02, $4c, 0
    DB $40, 03, $4c, 0
    DB $50, 04, $4c, 0
    DB $60, 05, $4c, 0
    DB $70, 06, $4c, 0
    DB $80, 07, $4c, 0
    DB $90, 08, $4c, 0

    DB $10, $10, $4c, 0
    DB $20, $11, $4c, 0
    DB $30, $12, $4c, 0
    DB $40, $13, $4c, 0
    DB $50, $14, $4c, 0
    DB $60, $15, $4c, 0
    DB $70, $16, $4c, 0
    DB $80, $17, $4c, 0
    DB $90, $18, $4c, 0

    ; flipped vertically

    DB $10, $20, $4c, $40
    DB $20, $21, $4c, $40
    DB $30, $22, $4c, $40
    DB $40, $23, $4c, $40
    DB $50, $24, $4c, $40
    DB $60, $25, $4c, $40
    DB $70, $26, $4c, $40
    DB $80, $27, $4c, $40
    DB $90, $28, $4c, $40

sprite_data_end::

INCLUDE "inc/utils.s"
