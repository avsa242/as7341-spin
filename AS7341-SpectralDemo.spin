{
----------------------------------------------------------------------------------------------------
    Filename:       AS7341-Demo.spin
    Description:    Demo of the AS7341 driver
    Author:         Jesse Burt
    Started:        May 31, 2024
    Updated:        May 31, 2024
    Copyright (c) 2024 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    _clkmode    = cfg._clkmode
    _xinfreq    = cfg._xinfreq


OBJ

    cfg:    "boardcfg.flip"
    time:   "time"
    ser:    "com.serial.terminal.ansi" | SER_BAUD=115_200
    sensor: "sensor.light.as7341" | SCL=28, SDA=29, I2C_FREQ=400_000


PUB main()

    setup()

    sensor.als_integr_time(2_777)               ' 2..182_184 (microseconds)
    sensor.atime_multiplier(100)                ' 1..256
    sensor.gain(256)                            ' 0, 1..512 (powers of 2; 0=0.5)
    sensor.preset_f1f4_clear_nir()
    repeat
        repeat until sensor.rgbw_data_rdy()
        sensor.rgbw_data_all()
        ser.pos_xy(0, 4)
        ser.printf1(@"415nm: %5.5d\n\r", sensor._light_data[1])
        ser.printf1(@"445nm: %5.5d\n\r", sensor._light_data[2])
        ser.printf1(@"480nm: %5.5d\n\r", sensor._light_data[3])
        ser.printf1(@"515nm: %5.5d\n\r", sensor._light_data[4])
        ser.printf1(@"555nm: %5.5d\n\r", sensor._light_data[7])
        ser.printf1(@"590nm: %5.5d\n\r", sensor._light_data[8])
        ser.printf1(@"630nm: %5.5d\n\r", sensor._light_data[9])
        ser.printf1(@"680nm: %5.5d\n\r", sensor._light_data[10])
        ser.printf1(@"Clear: %5.5d\n\r", sensor._light_data[11])
        ser.printf1(@"NIR: %5.5d\n\r", sensor._light_data[12])


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

