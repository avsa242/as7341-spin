{
----------------------------------------------------------------------------------------------------
    Filename:       AS7341-Demo.spin
    Description:    Demo of the AS7341 driver
    Author:         Jesse Burt
    Started:        May 20, 2024
    Updated:        May 21, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq


OBJ

    cfg:    "boardcfg.flip"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    time:   "time"
    sensor: "sensor.light.as7341" | SCL=28, SDA=29, I2C_FREQ=400_000


PUB main() | id, i

    setup()

    sensor.powered(true)
    sensor.opmode(sensor.SP_MEASURE_EN)
    repeat


PUB setup()

    ser.start()
    time.msleep(30)
    ser.clear()
    ser.strln(@"Serial terminal started")

    if ( sensor.start() )
        ser.strln(@"AS7341 driver started")
    else
        ser.strln(@"AS7341 driver failed to start - halting")


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

