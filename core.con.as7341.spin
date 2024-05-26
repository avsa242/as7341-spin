{
----------------------------------------------------------------------------------------------------
    Filename:       core.con.as7341.spin
    Description:    AS7341-specific constants
    Author:         Jesse Burt
    Started:        May 20, 2024
    Updated:        May 26, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

' I2C Configuration
    I2C_MAX_FREQ                = 400_000       ' device max I2C bus freq
    SLAVE_ADDR                  = $39 << 1      ' 7-bit format slave address
    T_POR                       = 0             ' startup time (usecs)

    DEVID_RESP                  = $24           ' device ID expected response

' Register definitions
    { low bank: CFG0 | REG_BANK }
    ASTATUS0                    = $60
        ASAT_STATUS             = 7
        AGAIN_STATUS            = 0
        AGAIN_STATUS_BITS       = %1111

    CH0_DATA_A                  = $61
    ITIME                       = $63'..$65
    CH1_DATA_A                  = $66
    CH2_DATA_A                  = $68
    CH3_DATA_A                  = $6a
    CH4_DATA_A                  = $6c
    CH5_DATA_A                  = $6e

    CONFIG                      = $70
    CONFIG_MASK                 = $0f
        LED_SEL                 = 3
        LED_SEL_MASK            = (1 << LED_SEL) ^ CONFIG_MASK
        INT_SEL                 = 2
        INT_SEL_MASK            = (1 << INT_SEL) ^ CONFIG_MASK
        INT_MODE                = 0
        INT_MODE_BITS           = %11
        INT_MODE_MASK           = (INT_MODE_BITS << INT_MODE) ^ CONFIG_MASK

    STAT                        = $71
    STAT_MASK                   = $03
        WAIT_SYNC               = 1
        READY                   = 0
        READY_BIT               = (1 << READY)

    EDGE                        = $72

    GPIO                        = $73
    GPIO_MASK                   = $03
        PD_GPIO                 = 1
        PD_GPIO_MASK            = (1 << PD_GPIO) ^ GPIO_MASK
        PD_INT                  = 0
        PD_INT_MASK             = (1 << PD_INT) ^ GPIO_MASK

    LED                         = $74
    LED_MASK                    = $ff
        LED_ACT                 = 7
        LED_ACT_MASK            = (1 << LED_ACT) ^ LED_MASK
        LED_DRIVE               = 0
        LED_DRIVE_BITS          = %1111111
        LED_DRIVE_MASK          = (LED_DRIVE_BITS << LED_DRIVE) ^ LED_MASK

    { high bank: CFG0 & !REG_BANK }
    ENABLE                      = $80
    ENABLE_MASK                 = $5b
        FDEN                    = 6
        FDEN_MASK               = (1 << FDEN) ^ ENABLE_MASK
        SMUXEN                  = 4
        SMUXEN_MASK             = (1 << SMUXEN) ^ ENABLE_MASK
        WEN                     = 3
        WEN_MASK                = (1 << WEN) ^ ENABLE_MASK
        SP_EN                   = 1
        SP_EN_MASK              = (1 << SP_EN) ^ ENABLE_MASK
        PON                     = 0
        PON_MASK                = (1 << PON) ^ ENABLE_MASK

    ATIME                       = $81
    WTIME                       = $83
    SP_TH_L                     = $84
    SP_TH_H                     = $86

    AUXID                       = $90
    REVID                       = $91
    ID                          = $92

    STATUS                      = $93
    STATUS_MASK                 = $8f
        ASAT                    = 7
        ASAT_MASK               = (1 << ASAT) ^ STATUS_MASK
        AINT                    = 3
        AINT_MASK               = (1 << AINT) ^ STATUS_MASK
        FINT                    = 2
        FINT_MASK               = (1 << FINT) ^ STATUS_MASK
        C_INT                   = 1
        C_INT_MASK              = (1 << C_INT) ^ STATUS_MASK
        SINT                    = 0
        SINT_MASK               = (1 << SINT) ^ STATUS_MASK

    ASTATUS1                    = $94
    ASTATUS_MASK                = $8f
        ASAT_STATUS             = 7
        AGAIN_STATUS            = 0
        AGAIN_STATUS_BITS       = %1111

    CH0_DATA                    = $95
    CH1_DATA                    = $97
    CH2_DATA                    = $99
    CH3_DATA                    = $9b
    CH4_DATA                    = $9d
    CH5_DATA                    = $9f

    STATUS2                     = $a3           ' r/o
        AVALID                  = 6
        ASAT_DIG                = 4
        ASAT_ANA                = 3
        FDSAT_ANA               = 1
        FDSAT_DIG               = 0
        SAT_BITS                = %11011

    STATUS3                     = $a4           ' r/o
        INT_SP_H                = 5
        INT_SP_L                = 4

    STATUS5                     = $a6           ' r/o
        SINT_FD                 = 3

    STATUS6                     = $a7           ' r/o
        FIFO_OV                 = 7
        OVTEMP                  = 5
        FD_TRIG                 = 4
        SP_TRIG                 = 2
        SAI_ACT                 = 1
        INT_BUSY                = 0

    CFG0                        = $a9
    CFG0_MASK                   = $34
        LOW_POWER               = 5
        LOW_POWER_MASK          = (1 << LOW_POWER) ^ CFG0_MASK
        REG_BANK                = 4
        REG_BANK_MASK           = (1 << REG_BANK) ^ CFG0_MASK
        REG_BANK_LO             = (1 << REG_BANK)
        REG_BANK_HI             = (0 << REG_BANK)
        WLONG                   = 2
        WLONG_MASK              = (1 << WLONG) ^ CFG0_MASK

    CFG1                        = $aa
    CFG1_MASK                   = $1f
        AGAIN                   = 0
        AGAIN_BITS              = %11111
        AGAIN_MASK              = (AGAIN_BITS << AGAIN) ^ CFG1_MASK

    CFG3                        = $ac
    CFG3_MASK                   = $20
        SAI                     = 5
        SAI_MASK                = (1 << SAI) ^ CFG3_MASK

    CFG6                        = $af
    CFG6_MASK                   = $38
        SMUX_CMD                = 3
        SMUX_CMD_BITS           = %11
        SMUX_CMD_MASK           = (SMUX_CMD_BITS << SMUX_CMD) ^ CFG6_MASK

    CFG8                        = $b1
    CFG8_MASK                   = $8c
        FIFO_TH                 = 6
        FIFO_TH_BITS            = %11
        FIFO_TH_MASK            = (FIFO_TH_BITS << FIFO_TH) ^ CFG8_MASK
        FD_AGC                  = 3
        FD_AGC_MASK             = (1 << FD_AGC) ^ CFG8_MASK
        SP_AGC                  = 2
        SP_AGC_MASK             = (1 << SP_AGC) ^ CFG8_MASK

    CFG9                        = $b2
    CFG9_MASK                   = $50
        SIEN_FD                 = 6
        SIEN_FD_MASK            = (1 << SIEN_FD) ^ CFG9_MASK
        SIEN_SMUX               = 4
        SIEN_SMUX_MASK          = (1 << SIEN_SMUX) ^ CFG9_MASK
        SIEN_MASK               = CFG9_MASK ^ $ff

    CFG10                       = $b3
    CFG10_MASK                  = $f7
        AGC_H                   = 6
        AGC_H_BITS              = %11
        AGC_H_MASK              = (AGC_H_BITS << AGC_H) ^ CFG10_MASK
        AGC_L                   = 4
        AGC_L_BITS              = %11
        AGC_L_MASK              = (AGC_L_BITS << AGC_L) ^ CFG10_MASK
        FD_PERS                 = 0
        FD_PERS_BITS            = %111
        FD_PERS_MASK            = (FD_PERS_BITS << FD_PERS) ^ CFG10_MASK

    CFG12                       = $b5
    CFG12_MASK                  = $07
        SP_TH_CH                = 0
        SP_TH_CH_BITS           = %111
        SP_TH_CH_MASK           = (SP_TH_CH_BITS << SP_TH_CH) ^ CFG12_MASK

    PERS                        = $bd
    PERS_MASK                   = $0f
        APERS                   = 0
        APERS_BITS              = %1111
        APERS_MASK              = (APERS_BITS << APERS) ^ PERS_MASK

    GPIO2                       = $be
    GPIO2_MASK                  = $0f
        GPIO_INV                = 3
        GPIO_INV_MASK           = (1 << GPIO_INV) ^ GPIO2_MASK
        GPIO_IN                 = 2
        GPIO_IN_MASK            = (1 << GPIO_IN) ^ GPIO2_MASK
        GPIO_OUT                = 1
        GPIO_OUT_MASK           = (1 << GPIO_OUT) ^ GPIO2_MASK
        GPIO_IN0                = 0
        GPIO_IN0_MASK           = (1 << GPIO_IN0) ^ GPIO2_MASK

    ASTEP                       = $ca'..$cb

    AGC_GAIN_MAX                = $cf
    AGC_GAIN_MAX_MASK           = $ff
        AGC_FD_GAIN_MAX         = 4
        AGC_FD_GAIN_MAX_BITS    = %1111
        AGC_FD_GAIN_MAX_MASK    = (AGC_FD_GAIN_MAX_BITS << AGC_FD_GAIN_MAX) ^ AGC_GAIN_MAX_MASK
        AGC_AGAIN_MAX           = 0
        AGC_AGAIN_MAX_BITS      = %1111
        AGC_AGAIN_MAX_MASK      = (AGC_AGAIN_MAX_BITS << AGC_AGAIN_MAX) ^ AGC_GAIN_MAX_MASK

    AZ_CONFIG                   = $d6

    FD_TIME1                    = $d8
    FD_TIME1_MASK               = $ff
        FD_TIME_LBITS           = %11111111
    FD_TIME2                    = $da
    FD_TIME2_MASK               = $ff
        FD_GAIN                 = 3
        FD_GAIN_BITS            = %11111
        FD_GAIN_MASK            = (FD_GAIN_BITS << FD_GAIN) ^ FD_TIME2_MASK
        FD_TIME_M               = 8
        FD_TIME_MBITS           = %111          ' bits 10..8 of FD_TIME
    FD_TIME_BITS                = (FD_TIME_MBITS << FD_TIME_M) | FD_TIME_LBITS
    FD_TIME_MASK                = FD_TIME_BITS ^ ( (FD_TIME2_MASK << 8) | FD_TIME1_MASK )

    FD_CFG0                     = $d7
    FD_CFG0_MASK                = $80
        FD_FIFO                 = 7

    FD_STATUS                   = $db           ' r/o
    FD_STATUS_MASK              = $3f
        FD_VALID                = 5
        FD_VALID_MASK           = (1 << FD_VALID) ^ FD_STATUS_MASK
        FD_VALID_CLEAR          = (1 << FD_VALID)
        FD_SAT                  = 4
        FD_SAT_MASK             = (1 << FD_SAT) ^ FD_STATUS_MASK
        FD_120HZ_VALID          = 3
        FD_120HZ_VALID_MASK     = (1 << FD_120HZ_VALID) ^ FD_STATUS_MASK
        FD_100HZ_VALID          = 2
        FD_100HZ_VALID_MASK     = (1 << FD_100HZ_VALID) ^ FD_STATUS_MASK
        FD_120HZ                = 1
        FD_120HZ_MASK           = (1 << FD_120HZ) ^ FD_STATUS_MASK
        FD_100HZ                = 0
        FD_100HZ_MASK           = (1 << FD_100HZ) ^ FD_STATUS_MASK

    INTENAB                     = $f9
    INTENAB_MASK                = $8d
        ASIEN                   = 7
        SP_IEN                  = 3
        FIEN                    = 2
        CIEN                    = 1
        SIEN                    = 0

    CONTROL                     = $fa
    CONTROL_MASK                = $07
        AZ_SP_MAN               = 2
        FIFO_CLR                = 1
        CLEAR_SAI_ACT           = 0
        CLEAR_SAI_ACT_BIT       = (1 << CLEAR_SAI_ACT)
        AZ_SP_MAN_MASK          = (1 << AZ_SP_MAN) ^ CONTROL_MASK
        FIFO_CLR_MASK           = (1 << FIFO_CLR) ^ CONTROL_MASK
        CLEAR_SAI_ACT_MASK      = (1 << CLEAR_SAI_ACT) ^ CONTROL_MASK

    FIFO_MAP                    = $fc
    FIFO_MAP_MASK               = $7f
        FIFO_WRITE_CH_DATA      = 1
        ASTATUS                 = 0

    FIFO_LVL                    = $fd
    FDATA                       = $fe'..$ff


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

