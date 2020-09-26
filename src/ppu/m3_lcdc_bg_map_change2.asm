; Copyright (C) 2019 Matt Currie <me@mattcurrie.com>
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

; Toggles bit 3 (BG_MAP) of LCDC register during mode 3.
; Sprites are positioned to cause the write to occur on different T-cycles of 
; the background tile fetch, showing when the change to the bit takes effect.
; Initiated by LCD STAT mode 2 interrupt in a field of NOPs.

init_lcdc_stat_int_test: MACRO
    call init_bg_maps_alphabetical_9800

    ld b, LCDCF_ON | LCDCF_WIN9C00 | LCDCF_WINOFF | LCDCF_BG8000 | LCDCF_BG9800 | LCDCF_OBJ8 | LCDCF_OBJON | LCDCF_BGON
    ld c, b
    set 3, c

    ld hl, rLCDC
    ld [hl], b
    ENDM


lcdc_stat_int: MACRO
    nops 10
    ld [hl], c
    ld [hl], b
    ENDM


INCLUDE "inc/lcdc_stat_int_base.asm"
