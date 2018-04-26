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



