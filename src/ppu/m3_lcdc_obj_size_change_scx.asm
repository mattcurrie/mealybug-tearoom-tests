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

; Toggles bit 2 of LCDC register (sprite size) during mode 3 while changing
; SCX value on based on the row's LY value to affect timing
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

    ; 12 + 8 + 8 + 12 = 40 cycles
    ld a, [rLY]
    swap a
    and 7
    ld [rSCX], a

    REPT 6
    nop
    ENDR    

    ; set 8*8 sprites
    ld a, d
    ld [c], a

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

    DB $10, $0c, $4c, 0
    DB $20, $0c, $4c, 0
    DB $30, $0c, $4c, 0
    DB $40, $0c, $4c, 0
    DB $50, $0c, $4c, 0
    DB $60, $0c, $4c, 0
    DB $70, $0c, $4c, 0
    DB $80, $0c, $4c, 0
    DB $90, $0c, $4c, 0

    ; flipped vertically

    DB $10, $20, $4c, $40
    DB $20, $20, $4c, $40
    DB $30, $20, $4c, $40
    DB $40, $20, $4c, $40
    DB $50, $20, $4c, $40
    DB $60, $20, $4c, $40
    DB $70, $20, $4c, $40
    DB $80, $20, $4c, $40
    DB $90, $20, $4c, $40

sprite_data_end::

INCLUDE "inc/utils.asm"
