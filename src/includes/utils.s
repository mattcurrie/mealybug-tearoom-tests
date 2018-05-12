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

SECTION "utils", ROMX, BANK[1]

INCLUDE "src/includes/old_skool_outline_thick.s"


wait_vblank::
    ldh a, [rLY]
    cp $90
    jr nz, wait_vblank

    ret


reset_oam::
    ld hl, $fe00
    ld a, $ff
    ld c, 160

.loop:
    ld [hl+], a
    dec c
    jr nz, .loop

    ret


reset_registers::
    call wait_vblank

    xor a
    ldh [rLCDC], a
    ldh [rIF], a
    ldh [rSCX], a
    ldh [rSCY], a

    ; position the window off screen
    ld a, 150
    ldh [rWY], a

    ret


reset_vram::
    ld hl, $9800
    xor a

.loop:   
    ld [hl+], a
    bit 2, h       ; bit 2 will be set when value of h register is $9c
    jr z, .loop

    ret


oam_copy::
    ld de, $fe00

.loop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec c
    jr nz, .loop

    ret


copy_font::
    ld hl, oldskooloutlinethick_tile_data
    ld de, $8000

.loop:
    ld a, [hl+]
    ld [de], a
    inc de

    bit 4, d     ; bit 4 will be set when value of d register is $90
    jr z, .loop

    ret


fill_vram_9800::
    ld hl, $9800

.loop:   
    ld [hl+], a
    bit 2, h       ; bit 2 will be set when value of h register is $9c
    jr z, .loop

    ret


fill_vram_9c00::
    ld hl, $9c00

.loop:   
    ld [hl+], a
    bit 5, h       ; bit 5 will be set when value of h register is $a0
    jr z, .loop

    ret    


fill_vram_8000::
    ld hl, $8000

.loop:   
    ld [hl+], a
    bit 5, h       ; bit 5 will be set when value of h register is $90
    jr z, .loop

    ret    


; line 0 timing is different by 4 cycles, so jump only 
; when on line 0
; 24 cycles (or 28 cycles when LY = 0)
line_0_fix: MACRO
    ldh a, [rLY]
    and a
    jr nz, .target\@
.target\@
    ENDM