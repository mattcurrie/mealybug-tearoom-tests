; Copyright (C) 2019 Eldred Habert (eldredhabert0@gmail.com)
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

; Tests enabling LCDC bit 6 but not bit 0


INCLUDE "inc/hardware.inc"


SECTION "vblank", ROM0[$40]

    reti


SECTION "stat", ROM0[$48]

    jr hstat_handler


SECTION "boot", ROM0[$100]

    di
    jp main

    ds $150 - $104


SECTION "main", ROM0

main::
    ld sp, $e000


    call reset_registers
    call reset_oam

    call copy_font
    ; write tile using color 2 to tile $80
    ld sp, $8810
    ld hl, $ff00
REPT 8
    push hl
ENDR
    ld sp, $e000
    call reset_vram
    ld a, $80
    call fill_vram_9c00

    ; copy hram code to hram
    ld hl, hram_code
    ld bc, (hram_code_end - hram_code) << 8 | low(hhram_code)
.copy_hram
    ld a, [hli]
    ldh [c], a
    inc c
    dec b
    jr nz, .copy_hram

    ; select mode 0 and mode 2 interrupts
    ; actually, due to STAT IRQ blocking, a mode 2 interrupt cannot trigger
    ; if mode 0 is also selected. LYC, however, can.
    ; so, we select LYC and will update that register accordingly
    ; it's possible to overwrite the STAT register to select different interrupt sources,
    ld a, STATF_MODE00 | STATF_LYC
    ldh [rSTAT], a

    ; set window to partially cover screen
    ld a, $30
    ldh [rWX], a
    ldh [rWY], a

    ld a, %11000100
    ldh [rBGP], a
    ldh [rOBP0], a

    ld a, LCDCF_ON | LCDCF_WINON | LCDCF_WIN9C00 | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJON | LCDCF_OBJ8 | LCDCF_BGOFF
    ldh [rLCDC], a


    ; clear pending interrupts
    xor a
    ldh [rIE], a

    ; enable vblank interrupt
    ld a, IEF_VBLANK
    ldh [rIE], a

    ei


    ; first frame is weird, wait until it ends
    ; only vblank can trigger this
    halt

    ; disable interrupts, as we don't want them except on certain scanlines
    di

    ; the next section of the test only relies on the STAT interrupt
    ld a, IEF_LCDC
    ldh [rIE], a


    ld a, $10
    call test_hblank_len

    ldh a, [hcounter]
    ldh [hfirstcounter], a

    ld a, $80
    call test_hblank_len


    ld hl, sprites
    ld de, woam
    ld c, $A0
.copy_oam
    ld a, [hli]
    ld [de], a
    inc e
    dec c
    jr nz, .copy_oam
    ld c, low(hfirstcounter)
    ld hl, woam + 2
    call print_value
    inc c ; hcounter
    call print_value
    call hoamdma

    ; source code breakpoint - good time to take a screenshot to compare
    ld b,b

.done
    jr .done

print_value::
    ldh a, [c]
    and $f0
    swap a
    call .print
    ldh a, [c]
    and $0f
.print
    cp $A
    jr c, .digit
    add a, "A" - "0" - $A
.digit
    add a, "0"
    ld [hli], a
    inc l
    inc l
    inc l
    ret


test_hblank_len::
    ; wait until given scanline
    ld hl, rLY
.wait
    cp [hl]
    jr nz, .wait

    inc a
    ldh [rLYC], a

    ; we must be in mode 2 or 3, so the next interrupt that will occur should be Mode 0

    ; clear pending interrupts
    xor a
    ei ; enable interrupts, doesn't take effect until *after the next instruction*
    ldh [rIF], a

    halt ; wait for the Mode 0 interrupt (during which Mode 2 will occur)
    ret


SECTION "stat handlers", ROM0[$68]

mode2_handler::
    ldh [hcounter], a

    ld a, low(($10000 - hstat_handler.jump) + mode0_handler)
    ldh [hstat_handler + 1], a
    ret ; return with ints disabled

mode0_handler::
    ei ; allow mode 2 int to trigger
    ld a, low(($10000 - hstat_handler.jump) + mode2_handler)
    ldh [hstat_handler + 1], a

    xor a
REPT 100
    inc a
ENDR
    ret



SECTION "hram code", ROM0

hram_code::

oamdma::
    ld a, high(woam)
    ldh [rDMA], a
    ld a, 40
.wait
    dec a
    jr nz, .wait
    ret
.end

stat_handler::
    db $18 ; jr
    db low(($10000 - hstat_handler.jump) + mode0_handler)

hram_code_end::


SECTION "hram", HRAM[$fff0]

hhram_code::

hoamdma::
    ds oamdma.end - oamdma

hstat_handler::
    ds 2
.jump

hfirstcounter::
    db
hcounter::
    db



SECTION "oam", ROM0

dspr: MACRO
    db \1 + 16, \2 + 8, \3, \4
ENDM

sprites::
    dspr 60, 76, "?", 0
    dspr 60, 84, "?", 0
    dspr 68, 76, "?", 0
    dspr 68, 84, "?", 0

    dspr 50, 50, "N", OAMF_PRI
    dspr 50, 58, "O", OAMF_PRI
    dspr 50, 68, "W", 0
    dspr 50, 76, "I", 0
    dspr 50, 84, "N", 0

    dspr 60, 50, "1", 0
    dspr 60, 58, "0", 0
    dspr 60, 68, "$", 0

    dspr 68, 50, "8", 0
    dspr 68, 58, "0", 0
    dspr 68, 68, "$", 0
.end
REPT $a0 - (.end - sprites)
    db $ff
ENDR


SECTION "wram", WRAM0,ALIGN[8]

woam::
    ds $a0



INCLUDE "inc/utils.s"
