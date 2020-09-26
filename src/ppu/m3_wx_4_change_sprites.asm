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

; Tests changing the value of WX during mode 3
; Initiated by STAT mode 2 LCDC interrupt in a field of NOPs.
; Changes to WX are: WX = 4, WX = LY, WX = 80.
; Window reactivation zero pixels should be present when window is already
; activated and the pixel that the window reactivates on is on the same 
; cycle as the window tile nametable read.
; Sprites with priority bit set should show through window reactivation 
; zero pixels.

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

    ; window is filled with 'B'
    ld a, $42
    call fill_vram_9800

    ; window is filled with 'W'
    ld a, $57
    call fill_vram_9c00

    ; tiles are filled with $ff
    ld a, $ff
    call fill_vram_8000

    ; copy sprite data
    ld hl, sprite_data 
    ld c, (20*4) ; 20 sprites * 4
    call oam_copy

    ; turn the screen on, $9C00-$9FFF window tile map, window on, bg tile data $8000-$8FFF, 
    ; bg tile map $9800-$9BFF, obj size 8*8, obj display on, bg display on
    ld a, $f3
    ldh [rLCDC], a

    ld a, 4
    ldh [rWY], a

    ld a, 80
    ldh [rWX], a 

    ; sprite pixels are all light grey
    ld a, $55
    ldh [rOBP0], a

    ; tile character data is filled with $ff values (= color 3)
    ; so with this palette all window/background pixels should be white
    ld a, $1b
    ldh [rBGP], a

    ; load c with address of WX register
    ld c, LOW(rWX)

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


    ; set default WX and save into b: 20 cycles
    ld a, $04
    ld b, a
    ld [c], a

    ; read LY : 12 cycles
    ldh a, [rLY]

    REPT 5
    nop
    ENDR    

    ; set the new WX: 8 cycles
    ld [c], a

    REPT 20
    nop
    ENDR

    ; position window in middle of the screen
    ld a, 80
    ld [c], a

    ; reset the return address to the top of the nops loop
    pop hl
    ld hl, nop_slide
    push hl

    reti


sprite_data::

    DB $20, $08, $19, 0
    DB $20, $10, $19, 0
    DB $20, $18, $19, 0
    DB $20, $20, $19, 0
    DB $20, $28, $19, 0

    DB $20, $30, $19, 0
    DB $20, $38, $19, 0
    DB $20, $40, $19, 0
    DB $20, $48, $19, 0
    DB $20, $50, $19, 0

    DB $30, $08, $19, $80
    DB $30, $10, $19, $80
    DB $30, $18, $19, $80
    DB $30, $20, $19, $80
    DB $30, $28, $19, $80

    DB $30, $30, $19, $80
    DB $30, $38, $19, $80
    DB $30, $40, $19, $80
    DB $30, $48, $19, $80
    DB $30, $50, $19, $80


INCLUDE "inc/utils.asm"
