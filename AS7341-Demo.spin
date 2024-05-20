{
    --------------------------------------------
    Filename: AS7341-Demo.spin
    Author:
    Description:
    Copyright (c) 2024
    Started May 20, 2024
    Updated May 20, 2024
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


OBJ

    cfg   : "boardcfg.flip"
    ser   : "com.serial.terminal.ansi"
    time  : "time"
    i2c:    "com.i2c"
    core:   "core.con.as7341"


con SL = $39 << 1

PUB main() | id

    setup()
    i2c.init_def(400_000)
    time.msleep(30)

    repeat
        i2c.start()
        i2c.write(SL)
        i2c.write($90)
        i2c.start()
        i2c.write(SL|1)
        id := 0
        i2c.rdblock_lsbf(@id, 3, i2c.NAK)
        i2c.stop()
        ser.pos_xy(0, 3)
        ser.hexdump(@id, 0, 4, 3, 1)

PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")


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

