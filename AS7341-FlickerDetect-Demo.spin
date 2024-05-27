{
----------------------------------------------------------------------------------------------------
    Filename:       AS7341-FlickerDetect-Demo.spin
    Description:    Demo of the AS7341 driver (flicker-detection)
        Locate the sensor within view of household mains-powered lighting.
        The demo should report 100Hz for 50Hz mains frequency, or 120Hz for 60Hz mains frequency.
        'Unknown' will be reported otherwise.
    Author:         Jesse Burt
    Started:        May 27, 2024
    Updated:        May 27, 2024
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


PUB main() | s

    setup()

    sensor.preset_flicker_detection()           ' set up the sensor for flicker detection

    repeat
        s := sensor.flicker_detect_status()
        repeat until (s & sensor.FD_MEAS_VALID) ' wait for a valid measurement flag
        sensor.flicker_detect_clear()           '   and clear it for the next time around
        ser.pos_xy(0, 3)
        ser.str(@"Flicker frequency: ")         ' show the detected frequency, if known
        case (s & %11)
            sensor.FL_DETECTED_120HZ:
                ser.str(@"120Hz")
            sensor.FL_DETECTED_100HZ:
                ser.str(@"100Hz")
            other:
                ser.str(@"Unknown")
        ser.clear_line()


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

