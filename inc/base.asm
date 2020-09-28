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

SECTION "lib", ROMX
INCLUDE "mgblib/src/hardware.inc"
INCLUDE "mgblib/src/macros.asm"
IF DEF(REQUIRES_CGB)
    enable_cgb_mode
ENDC
INCLUDE "mgblib/src/old_skool_outline_thick.asm"
INCLUDE "mgblib/src/display.asm"
INCLUDE "mgblib/src/print.asm"
INCLUDE "mgblib/src/misc/delay.asm"
INCLUDE "mgblib/src/serial/SerialSendByte.asm"

PUSHS
SECTION "results", WRAM0, ALIGN[8]
Results::
    DS 254
ResultCounter::
    DS 1
TestResult::
    DS 1
POPS


; Writes byte in register `a` to [de] and increases
; the result counter
;
; @param a the value to store
; @param de the address to store the value
; @return de + 1
; @destroys f, hl
store_result: MACRO
    ld [de], a
    inc de
    ld hl, ResultCounter
    inc [hl]
    ENDM


SECTION "boot", ROM0[$100]

    nop
    jp Main


SECTION "main", ROM0[$150]
Main::
    di
    ld sp, $fffe

    push af

    call ResetDisplay
    call ResetCursor

    pop af

IF DEF(REQUIRES_CGB)
    cp $11
    jp nz, NotCGB
ENDC

    xor a
    ld [ResultCounter], a
    ld de, Results

    call RunTest

    call ResetDisplay
    call LoadFont
    call GeneratePaleHexDigits

    ld de, TestTitle
    call PrintString
IF DEF(DISPLAY_RESULTS_ONLY)
    call DisplayResults
ELSE
    call CompareResults
    jp Quit
ENDC


NotCGB::
    call LoadFont
    print_string_literal "CGB Required"
    ld a, "F"
    ld [TestResult], a
    jp Quit


; Displays and compares Results to CorrectResults
;
; @param [Results] results recorded from test
; @param [CorrectResults] the correct results
; @param [ResultCounter] number of results to compare
CompareResults::
    print_string_literal "\\n\\n"

    ld a, "P"
    ld [TestResult], a

    ld hl, Results
    ld de, CorrectResults
    ld a, [ResultCounter]
    ld c, a
 .loop
    ld a, [de]
    ld b, a     ;   b = correct result
    ld a, [hl]  ;   a = result

    push hl
    push de
    push bc

    ; print the result
    push bc
    push af
    call PrintHexU8NoDollar
    pop af
    pop bc

    cp b
    jr z, .matched

    ; record the failure
    ld a, "F"
    ld [TestResult], a

    ; print the correct result and a space
    ld a, b
    call PrintPaleHexU8NoDollar
    ld a, " "
    call PrintCharacter
    jr .continue

.matched:
    print_string_literal "   "

.continue:
    pop bc
    pop de
    pop hl

    inc hl
    inc de
    dec c
    jr nz, .loop

    inc a

    ; print a new line if not already on the first character of the line
    call PrintNewLine
    ld a, [wPrintCursorAddress]
    and 31
    jr z, .noExtraLine
    call PrintNewLine
.noExtraLine::

    ld a, [TestResult]
    cp "P"
    jr nz, .failed
    print_string_literal "Passed"
    ret

.failed
    print_string_literal "Failed"
    ret


; Display the results only without comparing
; to any values
DisplayResults::
    print_string_literal "\\n\\n"

    ld hl, Results
    ld a, [ResultCounter]
    ld c, a
.loop
    ld a, [hl]

    push hl
    push bc
    call PrintHexU8NoDollar
    print_string_literal "   "
    pop bc
    pop hl

    inc hl
    dec c
    jr nz, .loop

    ; turn lcd on and loop forever
    lcd_on
    wait_ly 145
    wait_ly 144
    ld b, b
.forever:
    jr .forever


; Set magic register values, sends result via serial
; output, and loops forever
;
; @param [TestResult] if "P" then reports a passed result, otherwise failed
Quit::
    lcd_on
    wait_ly 145

    ld a, [TestResult]
    cp "P"
    jr nz, .failed

    ld b, 3
    ld c, 5
    ld d, 8
    ld e, 13
    ld h, 21
    ld l, 34
    jr .sendSerialResult

.failed
    ld b, $42
    ld c, b
    ld d, b
    ld e, b
    ld h, b
    ld l, b

.sendSerialResult:
    ld a, b
    call SerialSendByte
    ld a, c
    call SerialSendByte
    ld a, d
    call SerialSendByte
    ld a, e
    call SerialSendByte
    ld a, h
    call SerialSendByte
    ld a, l
    call SerialSendByte

    wait_ly 144
    xor a
    ld b, b

.forever:
    jr .forever


; Print a 8-bit value in hexidecimal with pale colours, 2 digits only
;
; @param a number to print
; @destroys af, bc, hl
PrintPaleHexU8NoDollar::
    push af
    swap a
    call PrintPaleHexNibble
    pop af
    call PrintPaleHexNibble
    ret


; Print a 4-bit value in hexidecimal with pale colours
;
; @param a number to print (low nibble)
; @destroys af, bc, hl
PrintPaleHexNibble::
    and $0f
    add 128     ; pale hex digits start at $9000
    jp PrintCharacter


; Generates pale versions of the hex digits at $8800 based
; on the tile data from the ASCII font located at $9000
;
; @destroys af, c, de, hl
GeneratePaleHexDigits::
    ; generate numbers
    ld hl, $9000 + ("0" * 16)
    ld de, $8800
    ld c, 10 * 8
.numbersLoop::
    ; read bitplane 1
    inc hl
    ld a, [hl-]

    ; write it as bitplane 0
    ld [de], a

    ; zero out bitplane 1
    inc de
    xor a
    ld [de], a

    ; advance to next row
    inc de
    inc hl
    inc hl

    dec c
    jr nz, .numbersLoop

    ; generate letters
    ld hl, $9000 + ("A" * 16)
    ld de, $8800 + 10 * 16
    ld c, 6 * 8
.lettersLoop::
    ; read bitplane 1
    inc hl
    ld a, [hl-]

    ; write it as bitplane 0
    ld [de], a

    ; zero out bitplane 1
    inc de
    xor a
    ld [de], a

    ; advance to next row
    inc de
    inc hl
    inc hl

    dec c
    jr nz, .lettersLoop

    ret


SwitchSpeed:
    xor a
    ldh [rIE], a
    ld a, $30
    ldh [rP1], a
    ld a, $01
    ldh [rKEY1], a
    stop
    ret


PUSHS

SECTION "header_title", ROM0[$134]
IF STRLEN("{TITLE}") > 15
    DB STRUPR(STRSUB("{TITLE}", 0, 15))
ELSE
    DB STRUPR("{TITLE}")
ENDC

SECTION "title", ROM0
TestTitle::
    DB "{TITLE}", $00
POPS


