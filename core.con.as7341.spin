{
----------------------------------------------------------------------------------------------------
    Filename:       core.con.as7341.spin
    Description:    AS7341-specific constants
    Author:         Jesse Burt
    Started:        May 20, 2024
    Updated:        May 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

' I2C Configuration
    I2C_MAX_FREQ        = 400_000               ' device max I2C bus freq
    SLAVE_ADDR          = $39 << 1              ' 7-bit format slave address
    T_POR               = 0                     ' startup time (usecs)

    DEVID_RESP          = $24                   ' device ID expected response

' Register definitions
    STAT                = $71
    STAT_MASK           = $03
        WAIT_SYNC       = 1
        READY           = 0
        READY_BIT       = (1 << READY)

    ENABLE              = $80
    ENABLE_MASK         = $5b
        FDEN            = 6
        FDEN_MASK       = (1 << FDEN) ^ ENABLE_MASK
        SMUXEN          = 4
        SMUXEN_MASK     = (1 << SMUXEN) ^ ENABLE_MASK
        WEN             = 3
        WEN_MASK        = (1 << WEN) ^ ENABLE_MASK
        SP_EN           = 1
        SP_EN_MASK      = (1 << SP_EN) ^ ENABLE_MASK
        PON             = 0
        PON_MASK        = (1 << PON) ^ ENABLE_MASK

    ID                  = $92

    CH0_DATA            = $95
    CH1_DATA            = $97
    CH2_DATA            = $99
    CH3_DATA            = $9b
    CH4_DATA            = $9d
    CH5_DATA            = $9f

    CFG0                = $a9
    CFG0_MASK           = $34
        LOW_POWER       = 5
        LOW_POWER_MASK  = (1 << LOW_POWER) ^ CFG0_MASK
        REG_BANK        = 4
        REG_BANK_MASK   = (1 << REG_BANK) ^ CFG0_MASK
        REG_BANK_LO     = (1 << REG_BANK)
        REG_BANK_HI     = (0 << REG_BANK)
        WLONG           = 2
        WLONG_MASK      = (1 << WLONG) ^ CFG0_MASK


PUB null()
' This is not a top-level object

DAT
{
Copyright 2024 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}

