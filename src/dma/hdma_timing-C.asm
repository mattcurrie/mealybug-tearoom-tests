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

; Tests HDMA timing in single speed and double speed mode to see when HDMA
; should start/finish relative to STAT mode. Also tests HDMA duration
; using DIV.

; Verified results:
;   pass: CGB 0/B/C/D/E, AGB 0/B
;   fail: DMG, MGB, SGB, SGB2
;   untested: CGB A, AGB A/BE

TITLE equs "hdma_timing-C"
REQUIRES_CGB = 1
INCLUDE "inc/base.asm"

SECTION "correct-results", ROMX
CorrectResults::
    ; testing with SCX = 1
    DB $83, $80, $80, $82
    DB $00, $ff, $ff, $ff

    ; testing with SCX = 2. HDMA is delayed due to longer mode 3.
    DB $83, $80, $80, $82
    DB $00, $00, $ff, $ff

    ; test the duration of HDMA using DIV
    DB $01, $02, $01, $02
    DB $03, $04, $03, $04

    ; testing with SCX = 1 in 2x speed mode
    DB $83, $80, $80, $82
    DB $00, $ff, $ff, $ff

    ; testing with SCX = 2 in 2x speed mode
    DB $83, $80, $80, $82
    DB $00, $00, $ff, $ff

    ; test the duration of HDMA using DIV in 2x speed mode
    DB $03, $04, $03, $04
    DB $07, $08, $07, $08


; @param \1 number of nops to delay before initialising HDMA transfer
; @param \2 number of nops to delay before reading of register \3
; @param \3 register to read after delaying
sub_test: MACRO
    lcd_on
    ld a, $c0
    ldh [rHDMA1], a
    ld a, $00
    ldh [rHDMA2], a
    ld a, $98
    ldh [rHDMA3], a
    ld a, $00
    ldh [rHDMA4], a
    nops \1
    ld a, $80               ; copy 16 bytes using H-blank DMA
    ldh [rHDMA5], a
    nops \2
    ldh a, [low(\3)]
    store_result
    call LcdOffSafe
ENDM


sub_test_group: MACRO
    sub_test 104, 44, rSTAT
    sub_test 104, 45, rSTAT
    sub_test 104, 86, rSTAT
    sub_test 104, 87, rSTAT

    sub_test 104, 46, rHDMA5
    sub_test 104, 47, rHDMA5
    sub_test 104, 48, rHDMA5
    sub_test 104, 49, rHDMA5
ENDM


sub_test_group2x: MACRO
    sub_test 218, 107, rSTAT
    sub_test 218, 108, rSTAT
    sub_test 218, 191, rSTAT
    sub_test 218, 192, rSTAT

    sub_test 218, 109, rHDMA5
    sub_test 218, 110, rHDMA5
    sub_test 218, 111, rHDMA5
    sub_test 218, 112, rHDMA5
ENDM


; @param \1 number of nops to delay before resetting DIV
; @param \2 number of nops to delay before initialising HDMA transfer
; @param \3 number of nops to delay before reading of register \4
; @param \4 register to read after delay \3
; @param \5 length in bytes
sub_test2: MACRO
    lcd_on
    nops \1
    xor a
    ldh [rDIV], a
    ld a, $c0
    ldh [rHDMA1], a
    ld a, $00
    ldh [rHDMA2], a
    ld a, $98
    ldh [rHDMA3], a
    ld a, $00
    ldh [rHDMA4], a
    nops \2
    ld a, $80 | ((\5 / 16) - 1)
    ldh [rHDMA5], a
    nops \3
    ldh a, [low(\4)]
    store_result
    call LcdOffSafe
ENDM


SECTION "run-test", ROM0
RunTest::
    ld a, 1
    ldh [rSCX], a
    sub_test_group

    ld a, 2
    ldh [rSCX], a
    sub_test_group

    ld a, 1
    ldh [rSCX], a
    sub_test2 70, 30, 60, rDIV, 16
    sub_test2 70, 30, 61, rDIV, 16

    ld a, 2
    ldh [rSCX], a
    sub_test2 70, 30, 60, rDIV, 16
    sub_test2 70, 30, 61, rDIV, 16

    ld a, 1
    ldh [rSCX], a
    sub_test2 70, 30, 179, rDIV, 32
    sub_test2 70, 30, 180, rDIV, 32

    ld a, 2
    ldh [rSCX], a
    sub_test2 70, 30, 179, rDIV, 32
    sub_test2 70, 30, 180, rDIV, 32

    call SwitchSpeed

    ld a, 1
    ldh [rSCX], a
    sub_test_group2x

    ld a, 2
    ldh [rSCX], a
    sub_test_group2x

    ld a, 1
    ldh [rSCX], a
    sub_test2 140, 65, 145, rDIV, 16
    sub_test2 140, 65, 146, rDIV, 16

    ld a, 2
    ldh [rSCX], a
    sub_test2 140, 65, 145, rDIV, 16
    sub_test2 140, 65, 146, rDIV, 16

    ld a, 1
    ldh [rSCX], a
    sub_test2 140, 65, 384, rDIV, 32
    sub_test2 140, 65, 385, rDIV, 32

    ld a, 2
    ldh [rSCX], a
    sub_test2 140, 65, 384, rDIV, 32
    sub_test2 140, 65, 385, rDIV, 32

    ret
