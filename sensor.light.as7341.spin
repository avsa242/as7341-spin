{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.light.as7341.spin
    Description:    Driver for the ams AS7341 multi-spectral sensor
    Author:         Jesse Burt
    Started:        May 20, 2024
    Updated:        May 20, 2024
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


PUB reset()
' Reset the device


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
        $80..$ff:
            banksel(REGBANK_HIGH)
        other:                                  ' invalid reg_nr
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start()
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.start()
    i2c.wr_byte(SLAVE_RD)
    i2c.rdblock_msbf(ptr_buff, nr_bytes, i2c.NAK)
    i2c.stop()


PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes to the device from ptr_buff
    case reg_nr
        $60..$74:
            banksel(REGBANK_LOW)
        $80..$ff:
            banksel(REGBANK_HIGH)
        other:
            return

    cmd_pkt.byte[0] := SLAVE_WR
    cmd_pkt.byte[1] := reg_nr
    i2c.start()
    i2c.wrblock_lsbf(@cmd_pkt, 2)
    i2c.wrblock_msbf(ptr_buff, nr_bytes)
    i2c.stop()

DAT
{
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

