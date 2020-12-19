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

TITLE equs "mbc3_rtc"
INCLUDE "inc/base.asm"

SECTION "correct-results", ROMX
CorrectResults::
    DB $01, $00
    DB $01, $00
    DB $00, $3B
    DB $40, $00, $00, $00, $3B
    DB $00, $00, $00, $01, $00
    DB $00, $00, $01, $00, $00
    DB $00, $01, $00, $00, $00
    DB $01, $00, $00, $00, $00
    DB $80, $00, $00, $00, $00
    DB $01, $00, $00, $3B
    DB $01, $00, $01, $00  
    DB $10, $20
    DB $00, $00
    DB $C1, $1F, $3F, $3F


SECTION "header-mbc-type", ROM0[$147]
MBCType::
    DB $10, $00, $03


RTC_SECONDS EQU $08
RTC_MINUTES EQU $09
RTC_HOURS EQU $0A
RTC_DAYS_LOW EQU $0B
RTC_DAYS_HIGH EQU $0C

ONE_SECOND EQU 1048576
HALF_SECOND EQU 524288
TOLERANCE EQU 128


latch_rtc_data: MACRO
    xor a
    ld [$6000], a
    inc a
    ld [$6000], a
    ENDM

set_rtc_register: MACRO
    ld a, \1
    ld [$4000], a   
    ld a, \2
    ld [$a000], a
    ENDM

read_rtc_register_and_store_result: MACRO
    ld a, \1
    ld [$4000], a   
    ld a, [$a000]
    store_result
    ENDM


subtest_seconds: MACRO
    set_rtc_register RTC_SECONDS, 0
    delay \1
    latch_rtc_data
    read_rtc_register_and_store_result RTC_SECONDS
    ENDM


subtest_minutes_write_does_not_reset_counter: MACRO
    set_rtc_register RTC_SECONDS, 59
    delay HALF_SECOND
    set_rtc_register RTC_MINUTES, 0
    delay \1
    latch_rtc_data
    read_rtc_register_and_store_result RTC_MINUTES
    read_rtc_register_and_store_result RTC_SECONDS
    ENDM


subtest_overflow: MACRO
    set_rtc_register RTC_SECONDS, 0
    set_rtc_register RTC_MINUTES, \5
    set_rtc_register RTC_HOURS, \4
    set_rtc_register RTC_DAYS_LOW, \3
    set_rtc_register RTC_DAYS_HIGH, \2
    set_rtc_register RTC_SECONDS, 59
    delay \1
    latch_rtc_data
    read_rtc_register_and_store_result RTC_DAYS_HIGH
    read_rtc_register_and_store_result RTC_DAYS_LOW
    read_rtc_register_and_store_result RTC_HOURS
    read_rtc_register_and_store_result RTC_MINUTES
    read_rtc_register_and_store_result RTC_SECONDS
    ENDM


subtest_latching_does_not_reset_counter: MACRO
    set_rtc_register RTC_SECONDS, 59
    set_rtc_register RTC_MINUTES, 0
    delay HALF_SECOND
    latch_rtc_data
    delay \1
    latch_rtc_data
    read_rtc_register_and_store_result RTC_MINUTES
    read_rtc_register_and_store_result RTC_SECONDS
    ENDM


subtest_disabling_timer_does_not_reset_counter: MACRO
    set_rtc_register RTC_SECONDS, 0
    delay HALF_SECOND
    set_rtc_register RTC_DAYS_HIGH, $40 ; disable
    delay ONE_SECOND
    set_rtc_register RTC_DAYS_HIGH, $00 ; enable
    delay \1        ; wait another half second +/- tolerance
    latch_rtc_data
    ; total elapsed time is 2 seconds, but seconds should read back as 1
    ; because the timer was delayed for 1 second of that.
    read_rtc_register_and_store_result RTC_SECONDS
    ENDM


subtest_write_and_read: MACRO
    set_rtc_register RTC_DAYS_HIGH, $40
    set_rtc_register \1, \2
    latch_rtc_data
    read_rtc_register_and_store_result \1
    set_rtc_register RTC_DAYS_HIGH, $00
    ENDM


SECTION "run-test", ROM0
RunTest::
    ld a, $0a
    ld [$0000], a

    set_rtc_register RTC_DAYS_HIGH, $00

TestSecondsIncrement::
    subtest_seconds (ONE_SECOND + TOLERANCE)
    subtest_seconds (ONE_SECOND - TOLERANCE)


TestMinutesWriteDoesNotResetCounter::
    subtest_minutes_write_does_not_reset_counter (HALF_SECOND + TOLERANCE)
    subtest_minutes_write_does_not_reset_counter (HALF_SECOND - TOLERANCE)


TestRegisterOverflows::
    subtest_overflow (ONE_SECOND + TOLERANCE), $40, 0, 0, 0
    subtest_overflow (ONE_SECOND + TOLERANCE), 0, 0, 0, 0
    subtest_overflow (ONE_SECOND + TOLERANCE), 0, 0, 0, 59
    subtest_overflow (ONE_SECOND + TOLERANCE), 0, 0, 23, 59
    subtest_overflow (ONE_SECOND + TOLERANCE), 0, 255, 23, 59
    subtest_overflow (ONE_SECOND + TOLERANCE), 1, 255, 23, 59


TestLatchingDoesNotResetCounter::
    subtest_latching_does_not_reset_counter (HALF_SECOND + TOLERANCE)
    subtest_latching_does_not_reset_counter (HALF_SECOND - TOLERANCE)


TestDisablingTimerDoesNotResetCounter::
    subtest_disabling_timer_does_not_reset_counter (HALF_SECOND + TOLERANCE)
    subtest_disabling_timer_does_not_reset_counter (HALF_SECOND - TOLERANCE)

    
TestSecondsWriteDoesNotDiscardElapsedTime::
    set_rtc_register RTC_SECONDS, 59
    set_rtc_register RTC_MINUTES, 0
    delay ((ONE_SECOND * 2) + TOLERANCE)
    set_rtc_register RTC_SECONDS, 0
    latch_rtc_data
    read_rtc_register_and_store_result RTC_MINUTES
    read_rtc_register_and_store_result RTC_SECONDS


TestWrittenValueIsNotReadableUntilLatched::
    set_rtc_register RTC_DAYS_HIGH, $40
    set_rtc_register RTC_MINUTES, $10
    latch_rtc_data
    set_rtc_register RTC_MINUTES, $20
    read_rtc_register_and_store_result RTC_MINUTES
    latch_rtc_data
    read_rtc_register_and_store_result RTC_MINUTES
    set_rtc_register RTC_DAYS_HIGH, $00
   

TestOutOfBoundsWriteAndIncrement::
    set_rtc_register RTC_DAYS_HIGH, $40
    set_rtc_register RTC_HOURS, $00
    set_rtc_register RTC_MINUTES, $3F
    set_rtc_register RTC_SECONDS, 59
    set_rtc_register RTC_DAYS_HIGH, $00
    delay ONE_SECOND + TOLERANCE
    latch_rtc_data
    read_rtc_register_and_store_result RTC_HOURS
    read_rtc_register_and_store_result RTC_MINUTES


TestRegisterSizes::
    subtest_write_and_read RTC_DAYS_HIGH, $FF
    subtest_write_and_read RTC_HOURS, $FF
    subtest_write_and_read RTC_MINUTES, $FF
    subtest_write_and_read RTC_SECONDS, $FF
    

    xor a
    ld [$0000], a

    ret