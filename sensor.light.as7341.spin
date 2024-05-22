{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.light.as7341.spin
    Description:    Driver for the ams AS7341 multi-spectral sensor
    Author:         Jesse Burt
    Started:        May 20, 2024
    Updated:        May 22, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    { default I/O configuration - these can be overridden by the parent object }
    SCL             = 28
    SDA             = 29
    I2C_FREQ        = 100_000


    SLAVE_WR        = core.SLAVE_ADDR
    SLAVE_RD        = core.SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core.I2C_MAX_FREQ

VAR


OBJ

{ decide: Bytecode I2C engine, or PASM? Default is PASM if BC isn't specified }
#ifdef AS7341_I2C_BC
    i2c:    "com.i2c.nocog"                     ' BC I2C engine
#else
    i2c:    "com.i2c"                           ' PASM I2C engine
#endif
    core:   "core.con.as7341.spin"              ' AS7341-specific constants
    time:   "time"                              ' basic timing functions


PUB null()
' This is not a top-level object


PUB start(): status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(SCL, SDA, I2C_FREQ)


PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom IO pins and I2C bus frequency
    if ( lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) )
        if ( status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ) )
            time.usleep(core.T_POR)             ' wait for device startup
            if ( dev_id() == core.DEVID_RESP )  ' validate device 
                return
    ' if this point is reached, something above failed
    ' Re-check I/O pin assignments, bus speed, connections, power
    ' Lastly - make sure you have at least one free core/cog 
    return FALSE


PUB stop()
' Stop the driver
    i2c.deinit()


PUB defaults()
' Set factory defaults


PUB dev_id(): id
' Read device identification
    id := 0
    readreg(core.ID, 1, @id)


PUB flicker_detection_enabled(en=-2): c
' Enable flicker detection
'   en:
'       TRUE (non-zero values): enabled
'       FALSE (0): disabled
'   Returns:
'       current setting, if called with other values
    c := 0
    readreg(core.ENABLE, 1, @c)
    if ( en )
        en := (c & core.FDEN_MASK) | ( ((en <> 0) & 1) << core.FDEN )
        writereg(core.ENABLE, 1, @en)
    else
        return ( ((en >> core.FDEN) & 1) == 1 )


CON

    { sensor operating modes }
    SP_MEASURE_DIS  = 0                         ' measurements disabled
    SP_MEASURE_EN   = 1                         ' measurements enabled

PUB opmode(md=-2): c
' Set device operating mode
'   md:
'       SP_MEASURE_DIS (0): disable spectral measurements
'       SP_MEASURE_EN (1): enable spectral measurements
'   Returns:
'       current setting, if called with other values
    c := 0
    readreg(core.ENABLE, 1, @c)
    if ( md )
        md := (c & core.SP_EN_MASK) | ( ((md <> 0) & 1) << core.SP_EN )
        writereg(core.ENABLE, 1, @md)
    else
        return ( ((c >> core.SP_EN) & 1) == 1 )

PUB powered(p=-2): c
' Power up the sensor
'   p:
'       TRUE (non-zero values) or FALSE (0)
'   Returns:
'       current setting, if called with other values
    c := 0
    readreg(core.ENABLE, 1, @c)
    if ( p )
        p := (c & core.PON_MASK) | ((p <> 0) & 1)
        writereg(core.ENABLE, 1, @p)
    else
        return ( (c & 1) == 1 )


PUB reset()
' Reset the device


VAR

    word _light_data[6]

PUB rgbw_data(ptr_d=0)
' Get sensor data
'   ptr_d (optional):
'       pointer to 6-word buffer to copy data to
'   Data format:
'       TBD
'   NOTE: This buffer must be at least 6 words in length
    readreg(core.CH0_DATA, 12, @_light_data)
    if ( ptr_d )
        wordmove(ptr_d, @_light_data, 6)


PUB rgbw_data_rdy(): f
' Flag indicating new sensor data ready
'   Returns: TRUE (-1) or FALSE (0)
    f := 0
    readreg(core.STAT, 1, @f)
    return ( (f & core.READY_BIT) == 1 )



con

    REGBANK_LOW     = 0
    REGBANK_HIGH    = 1

PRI banksel(b) | tmp
' Select register bank
'   REGBANK_LOW (0): access registers $60..$74
'   REGBANK_HIGH (1): access registers $80..$ff
    tmp := 0
    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(core.CFG0)
    i2c.start()
    i2c.write(SLAVE_RD)
    tmp := i2c.read(i2c.NAK)
    i2c.stop()

    if ( b == REGBANK_HIGH )
        tmp &= core.REG_BANK_MASK
    elseif ( b == REGBANK_LOW )
        tmp |= core.REG_BANK_LO

    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(core.CFG0)
    i2c.write(tmp)
    i2c.stop()


PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    case reg_nr                                 ' validate register num
        $60..$74:
            banksel(REGBANK_LOW)
        $80, $81, $83..$87, $90..$a0, $a3, $a4, $a6, $a7, $a9, $aa, $ac, $af, $b1..$b3, ...
        $b5, $bd, $be, $ca, $cb, $cf, $d6..$d8, $da, $db, $f9, $fa, $fc, $fd..$ff:
            banksel(REGBANK_HIGH)
        other:                                  ' invalid reg_nr
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start()
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start()
    i2c.wr_byte(SLAVE_RD)
    i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c.NAK)
    i2c.stop()


PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        $60..$62, $66..$70, $72..$74:
            banksel(REGBANK_LOW)
        $80, $81, $83..$87, $93, $94, $a9, $aa, $ac, $af, $b1..$b3, ...
        $b5, $bd, $be, $ca, $cb, $cf, $d6..$d8, $da, $f9, $fa, $fc, $fe, $ff:
            banksel(REGBANK_HIGH)
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start()
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.wrblock_lsbf(ptr_buff, nr_bytes)
    i2c.stop()

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

