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

INCLUDE "inc/old_skool_outline_thick.s"


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

    bit 3, d     ; bit 3 will be set when value of d register is $88
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


reset_tile_maps::
    ; select vram bank 1
    ld a, 1
    ldh [rVBK], a

    ; set palette 0 by default
    ld a, 0
    call fill_vram_9800
    call fill_vram_9c00

    ; select vram bank 0
    xor a
    ldh [rVBK], a

    ; background defaults to " "
    ld a, " "
    call fill_vram_9800
    call fill_vram_9c00
    ret


; Input:
;   A = value
;   HL = destination
;   BC = length in bytes
; Preserved:
;   none
memset::
    ld e, a
.loop:
    ld a, e
    ld [hl+], a
    dec bc
    ld a, b
    cp c
    jr nz, .loop
    ret


; Input:
;   HL = source
;   DE = destination
;   BC = length in bytes
; Preserved:
;   none
memcpy::
.loop:
    ld a, [hl+]
    ld [de], a
    inc de
    dec bc
    ld a, b
    or c
    jr nz, .loop
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


; Output specified number of nops
; @param \1 Number of nops to output
nops: MACRO
    REPT \1
    nop
    ENDR
    ENDM    


cgb_mode: MACRO
    SECTION "cgb-mode", ROM0[$143]
        db $80
    ENDM


switch_speed:
    xor a
    ldh [rIE], a
    ld a, $30
    ldh [rP1], a
    ld a, $01
    ldh [rKEY1], a
    stop
    ret


; Delay for a specified number of M-cycles
; @param \1 Number of M-cycles to wait for
delay: MACRO
DELAY = (\1)

IF DELAY >= 100000
    REPT DELAY / 100000
    call Delay100000MCycles
    ENDR
DELAY = DELAY % 100000
ENDC

IF DELAY >= 10000
    call Delay10000MCycles - (3 * ((DELAY / 10000) - 1))
DELAY = DELAY % 10000
ENDC

IF DELAY >= 1000
    call Delay1000MCycles - (3 * ((DELAY / 1000) - 1))
DELAY = DELAY % 1000
ENDC

IF DELAY >= 100
    call Delay100MCycles - (3 * ((DELAY / 100) - 1))
DELAY = DELAY % 100
ENDC

IF DELAY >= 10
    call Delay10MCycles - (3 * ((DELAY / 10) - 1))
DELAY = DELAY % 10
ENDC

IF DELAY > 0
    nops DELAY
ENDC
    ENDM


Delay100000MCycles::
    call Delay10000MCycles
Delay90000MCycles::
    call Delay10000MCycles
Delay80000MCycles::
    call Delay10000MCycles
Delay70000MCycles::
    call Delay10000MCycles
Delay60000MCycles::
    call Delay10000MCycles
Delay50000MCycles::
    call Delay10000MCycles
Delay40000MCycles::
    call Delay10000MCycles
Delay30000MCycles::
    call Delay10000MCycles
Delay20000MCycles::
    call Delay10000MCycles

Delay10000MCycles::
    call Delay1000MCycles
Delay9000MCycles::
    call Delay1000MCycles
Delay8000MCycles::
    call Delay1000MCycles
Delay7000MCycles::
    call Delay1000MCycles
Delay6000MCycles::
    call Delay1000MCycles
Delay5000MCycles::
    call Delay1000MCycles
Delay4000MCycles::
    call Delay1000MCycles
Delay3000MCycles::
    call Delay1000MCycles
Delay2000MCycles::
    call Delay1000MCycles
    
Delay1000MCycles::
    call Delay100MCycles
Delay900MCycles::
    call Delay100MCycles
Delay800MCycles::
    call Delay100MCycles
Delay700MCycles::
    call Delay100MCycles
Delay600MCycles::
    call Delay100MCycles
Delay500MCycles::
    call Delay100MCycles
Delay400MCycles::
    call Delay100MCycles
Delay300MCycles::
    call Delay100MCycles
Delay200MCycles::
    call Delay100MCycles

Delay100MCycles::
    call Delay10MCycles
Delay90MCycles::
    call Delay10MCycles
Delay80MCycles::
    call Delay10MCycles
Delay70MCycles::
    call Delay10MCycles
Delay60MCycles::
    call Delay10MCycles
Delay50MCycles::
    call Delay10MCycles
Delay40MCycles::
    call Delay10MCycles
Delay30MCycles::
    call Delay10MCycles
Delay20MCycles::
    call Delay10MCycles

Delay10MCycles::
    ret


rgb_low_byte: MACRO
    db low(\1 + (\2 << 5) + \3 << 10)
    ENDM


rgb_high_byte: MACRO
    db high(\1 + (\2 << 5) + \3 << 10)
    ENDM


cgb_color: MACRO
    rgb_low_byte \1, \2, \3
    rgb_high_byte \1, \2, \3
    ENDM


copy_obj_color_palette_data::
    ld c, low(rOCPD)
    jr copy_bg_color_palette_data.loop

copy_bg_color_palette_data::
    ld c, low(rBCPD)
.loop:
    ld a, [hl+]
    ld [c], a
    dec b
    jr nz, .loop
    ret
