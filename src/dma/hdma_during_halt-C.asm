; Copyright (C) 2020 Matt Currie <me@mattcurrie.com>
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

; Tests whether HDMA runs during halt - it does not. The HDMA transfer occurs
; after exiting from halt.

; Verified results:
;   pass: CGB 0/B/C/D/E, AGB 0/B
;   fail: DMG, MGB, SGB, SGB2
;   untested: CGB A, AGB A/BE

TITLE equs "hdma_during_halt-C"
REQUIRES_CGB = 1
INCLUDE "inc/base.asm"

SECTION "correct-results", ROMX
CorrectResults::
    ; testing with di + halt
    DB $03, $04, $05, $06   ; LY
    DB $c6, $c2, $c2, $c2   ; STAT
    DB $01, $00, $ff, $ff   ; HDMA5
    DB $11, $be, $be, $be   ; $980f
    DB $22, $22, $ef, $ef   ; $981f

    ; testing with ei + halt
    DB $03, $04, $05, $06   ; LY
    DB $c6, $c2, $c2, $c2   ; STAT
    DB $01, $00, $ff, $ff   ; HDMA5
    DB $11, $be, $be, $ff   ; $980f
    DB $22, $22, $ef, $ff   ; $981f


SECTION "source-data", WRAM0, ALIGN[8]
SourceData::
    DS 32


SECTION "lcdc-stat", ROM0[$48]
    jp hl


; @param \1 delay1 number of nops to delay before initialising HDMA transfer
; @param \2 address address to read after halt
sub_test_di: MACRO
    ; reset the results
    ld a, $11
    ld [$980f], a
    ld a, $22
    ld [$981f], a

    ; populate the source data
    ld a, $be
    ld [SourceData + $0f], a
    ld a, $ef
    ld [SourceData + $1f], a

    ld a, 3
    ldh [rLYC], a
    ld a, STATF_LYC
    ldh [rSTAT], a
    ld a, IEF_LCDC
    ldh [rIE], a
    xor a
    ldh [rIF], a

    lcd_on

    ld a, high(SourceData)
    ldh [rHDMA1], a
    ld a, low(SourceData)
    ldh [rHDMA2], a
    ld a, $98
    ldh [rHDMA3], a
    ld a, $00
    ldh [rHDMA4], a

    nops \1
    ld a, $81               ; copy 32 bytes using H-blank DMA
    ldh [rHDMA5], a

    halt

    ld a, [\2]
    store_result

    nops 101 - 9
    ld a, [\2]
    store_result

    nops 101 - 9
    ld a, [\2]
    store_result

    nops 101
    ld a, [\2]
    store_result

    call LcdOffSafe

    xor a
    ldh [rLYC], a
    ldh [rSTAT], a
    ldh [rIF], a
    ldh [rIE], a
ENDM

; @param \1 delay1 number of nops to delay before initialising HDMA transfer
; @param \2 address address to read after halt
sub_test_ei: MACRO
    ; reset the results
    ld a, $11
    ld [$980f], a
    ld a, $22
    ld [$981f], a

    ; populate the source data
    ld a, $be
    ld [SourceData + $0f], a
    ld a, $ef
    ld [SourceData + $1f], a

    ld a, 3
    ldh [rLYC], a
    ld a, STATF_LYC
    ldh [rSTAT], a
    ld a, IEF_LCDC
    ldh [rIE], a

    lcd_on

    ld a, high(SourceData)
    ldh [rHDMA1], a
    ld a, low(SourceData)
    ldh [rHDMA2], a
    ld a, $98
    ldh [rHDMA3], a
    ld a, $00
    ldh [rHDMA4], a

    nops \1
    ld a, $81               ; copy 32 bytes using H-blank DMA
    ldh [rHDMA5], a

    xor a
    ldh [rIF], a
    ld hl, intr_handler\@
    ei
    nop
    halt

intr_handler\@::
    ld a, [\2]
    store_result

    nops 101 - 9
    ld a, [\2]
    store_result

    nops 101 - 9
    ld a, [\2]
    store_result

    nops 101
    ld a, [\2]
    store_result

    ; pop off the interrupt handler return address
    pop af

    call LcdOffSafe

    xor a
    ldh [rLYC], a
    ldh [rSTAT], a
    ldh [rIF], a
    ldh [rIE], a
ENDM

SECTION "run-test", ROM0
RunTest::
    di
    sub_test_di 104, rLY
    sub_test_di 104, rSTAT
    sub_test_di 104, rHDMA5
    sub_test_di 104, $980f
    sub_test_di 104, $981f

    sub_test_ei 104, rLY
    sub_test_ei 104, rSTAT
    sub_test_ei 104, rHDMA5
    sub_test_ei 104, $980f
    sub_test_ei 104, $981f
    ret
