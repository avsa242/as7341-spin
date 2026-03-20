{
----------------------------------------------------------------------------------------------------
    Filename:       sensor.light.as7341.spin
    Description:    Driver for the ams AS7341 multi-spectral sensor
    Author:         Jesse Burt
    Started:        May 20, 2024
    Updated:        Mar 20, 2026
    Copyright (c) 2026 - See end of file for terms of use.
----------------------------------------------------------------------------------------------------
}

CON

    { default I/O configuration - these can be overridden by the parent object }
    SCL             = 28
    SDA             = 29
    I2C_FREQ        = 100_000


    SLAVE_WR        = core.SLAVE_ADDR
    SLAVE_RD        = core.SLAVE_ADDR|1


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
            _bank := -1                         ' init reg bank
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


PUB preset_flicker_detection()
' Preset settings: set up sensor for flicker detection
    flicker_detect_enabled(false)
    opmode(SP_MEASURE_DIS)
    powered(false)

    powered(true)

    smux_command(SMUX_CMD_WRITE)
    flicker_detect_smux_config()
    smux_execute_cmd()

    opmode(SP_MEASURE_EN)
    flicker_detect_enabled(true)
    time.msleep(500)


PUB preset_f1f4_clear_nir() | n
' Preset settings: photodiodes F1..F4, clear, NIR
    powered(false)
    powered(true)
    smux_cfg_f1f4_clear_nir()
    time.msleep(500)


PUB preset_f5f8_clear_nir()
' Preset settings: photodiodes F5..F8, clear, NIR
    powered(false)
    powered(true)
    smux_cfg_f5f8_clear_nir()
    time.msleep(500)


PUB agc_gain(): g
' Get the gain level currently set by the AGC
'   Returns: gain factor
    g := ( _light_data.byte[1] & core.AGC_AGAIN_MAX_BITS )
    if ( g )
        return (1 << (g-1))             ' map bitfield 1..10 to 1..512x
    else
        return 0


PUB agc_gain_max(g=-2): c
' Set automatic gain control maximum level
'   g:
'       0, 1..512, in powers of 2 (0 = 0.5; default: 256)
'   Returns:
'       current setting, if called with other values
    c := readreg(core.AGC_GAIN_MAX)
    case g
        0..512:
            if ( g )
                g := >|(g)                      ' map 1..512x to bitfield 1..10 (log2(g)+1)
            else
                g := 0
            g := (c & core.AGC_AGAIN_MAX_MASK) | g
            writereg(core.AGC_GAIN_MAX, g)
        other:
            c := ( c & core.AGC_AGAIN_MAX_BITS )
            if ( c )
                return (1 << (c-1))             ' map bitfield 1..10 to 1..512x
            else
                return 0


PUB agc_high_hysteresis(h=-2): c
' Set automatic gain control high hysteresis, as a percentage
'   h:
'       50, 62 (62.5%), 75, 87 (87.5%)
'   Returns:
'       current setting, if called with other values
    c := readreg(core.CFG10)
    case h
        50, 62, 75, 87:
            h := lookdownz(h: 50, 62, 75, 87)   ' map 50..87 to 0..3
            h := (c & core.AGC_H_MASK) | (h << core.AGC_H)
            writereg(core.CFG10, h)
        other:
            c := ( (c >> core.AGC_H) & core.AGC_H_BITS )
            return lookupz(c: 50, 62, 75, 87)   ' map 0..3 to 50..87


PUB agc_low_hysteresis(h=-2): c
' Set automatic gain control low hysteresis, as a percentage
'   h:
'       12 (12.5%), 25, 37 (37.5%), 50
'   Returns:
'       current setting, if called with other values
    c := readreg(core.CFG10)
    case h
        12, 25, 37, 50:
            h := lookdownz(h: 12, 25, 37, 50)   ' map 12..50 to 0..3
            h := (c & core.AGC_L_MASK) | (h << core.AGC_L)
            writereg(core.CFG10, h)
        other:
            c := ( (c >> core.AGC_L) & core.AGC_L_BITS )
            return lookupz(c: 12, 25, 37, 50)   ' map 0..3 to 12..50


PUB als_integr_time(t=-2): c
' Set sensor ADC integration time/time step size, in microseconds
'   t:
'       2..182184:
'   Returns:
'       current setting, if called with other values
'   NOTE: The actual integration time is the current value of this setting multiplied by
'       atime_multiplier()
    case t
        2..182_184:
            t := ( (t * 1_00) / 2_78 )
            writereg(core.ASTEP, t, 2)
        other:
            c := readreg(core.ASTEP, 2)
            return ( (c * 2_78) / 1_00 )


PUB atime_multiplier(m=-2): c
' Set integration time multiplier
'   m:
'       1..256
'   Returns:
'       current setting, if called with other values
    case m
        1..256:
            m--
            writereg(core.ATIME, m)
        other:
            c := readreg(core.ATIME)
            return ( c + 1 )


PUB autozero_freq(f=-2): c
' Set how often the device performs auto-zero of the spectral engines
'   f:
'       0:      never (not recommended)
'       1:      every integration cycle
'       2..254: every f'th integration cycle
'       255:    only before the first measurement cycle (default)
'   Returns:
'       current setting, if called with other values
    case f
        0..255:
            writereg(core.AZ_CONFIG, f)
        other:
            c := readreg(core.AZ_CONFIG)


PUB dev_id(): id
' Read device identification
    return readreg(core.ID)


PUB fifo_data_overrun(): f
' Flag indicating FIFO data has overrun (data was lost)
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.STATUS6)
    return ( ((f >> core.FIFO_OV) & 1) == 1 )


PUB fifo_flush() | tmp
' Flush FIFO, clear interrupt, overflow status and level
    tmp := readreg(core.CONTROL)
    tmp |= (1 << core.FIFO_CLR)
    writereg(core.CONTROL, tmp)


PUB fifo_nr_unread(): n
' Number of unread samples stored in FIFO
'   Returns: number of entries, 0..128 (each sample is 2 bytes)
    return readreg(core.FIFO_LVL)


PUB fifo_read(n, p_buff)
' Read FIFO data
'   n:      number of samples/entries to read
'   p_buff: pointer to buffer to copy data to
'   Returns: none
    readreg(core.FDATA, n*2, p_buff)


PUB fifo_src(msk=-2): c | tmp
' Set FIFO source data
'   msk: bitmask
'       bit     description
'       7       write flicker detection data (ignored if flicker detection is disabled)
'       6       write CH5 data (ignored if flicker detection is enabled)
'       5       write CH4 data
'       4       write CH3 data
'       3       write CH2 data
'       2       write CH1 data
'       1       write CH0 data
'       0       write ASTATUS (one byte per sample)
'   Returns:
'       current setting, if called with other values
    if ( msk => 0 )
        if ( msk & core.FIFO_WRITE_FD_SET )
            tmp := readreg(core.FIFO_CFG0)      ' ensure the reserved bits are kept
            tmp |= core.FIFO_WRITE_FD_SET
            writereg(core.FIFO_CFG0, tmp)
        msk &= core.FIFO_MAP_MASK
        writereg(core.FIFO_MAP, msk)
    else
        c := readreg(core.FIFO_MAP)
        tmp := readreg(core.FIFO_CFG0)
        return c | (tmp & core.FIFO_WRITE_FD_SET)


PUB fifo_thresh(t): c
' Set FIFO interrupt threshold
'   t:
'       1, 4, 8, 16
'   Returns:
'       current setting, if called with other values
    c := readreg(core.CFG8)
    case t
        1, 4, 8, 16:
            t := lookdownz(t: 1, 4, 8, 16)      ' map 1, 4, 8, 16 to 0..3
            t := (c & core.FIFO_TH_MASK) | (t << core.FIFO_TH)
            writereg(core.CFG8, t)
        other:
            c := ( (c >> core.FIFO_TH) & core.FIFO_TH_BITS )
            return lookupz(c: 1, 4, 8, 16)      ' map 0..3 to 1, 4, 8, 16


PUB flicker_detected_100hz(): f
' Flag indicating flicker detected at 100Hz
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.FD_STATUS)
    return ( (f & 1) == 1 )


PUB flicker_detected_120hz(): f
' Flag indicating flicker detected at 120Hz
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.FD_STATUS)
    return ( ((f >> core.FD_120HZ) & 1) == 1 )


PUB flicker_detect_agc_enabled(en): c
' Use automatic gain control for the flicker detection engine
'   en:
'       TRUE (-1 or positive values): enabled
'       FALSE (0): disabled
'   Returns:
'       current setting, if called with other values
    c := readreg(core.CFG8)
    if ( en => true )
        en := (c & core.FD_AGC_MASK) | ( ((en <> 0) & 1) << core.FD_AGC )
        writereg(core.CFG8, en)
    else
        return ( ((c >> core.FD_AGC) & 1) == 1 )


PUB flicker_detect_agc_max(g=-2): c
' Set flicker detection AGC maximum level
'   g:
'       0, 1..512, in powers of 2 (0 = 0.5; default: 256)
'   Returns:
'       current setting, if called with other values
    c := readreg(core.AGC_GAIN_MAX)
    case g
        0..512:
            if ( g )
                g := >|(g)                      ' map 1..512x to bitfield 1..10 (log2(g)+1)
            else
                g := 0
            g := (c & core.AGC_FD_GAIN_MAX_MASK) | (g << core.AGC_FD_GAIN_MAX)
            writereg(core.AGC_GAIN_MAX, g)
        other:
            c := ( (c >> core.AGC_FD_GAIN_MAX) & core.AGC_FD_GAIN_MAX_BITS )
            if ( c )
                return (1 << (c-1))             ' map bitfield 1..10 to 1..512x
            else
                return 0


PUB flicker_detect_clear() | tmp
' Clear the flicker detect ready status bit
    tmp := core.FD_VALID_CLEAR
    writereg(core.FD_STATUS, tmp)


PUB flicker_detect_gain(g=-2): c
' Set flicker detection gain
'   g:
'       0, 1..512, in powers of 2 (0 = 0.5; default: 256)
'   Returns:
'       current setting, if called with other values
    c := readreg(core.FD_TIME2)
    case g
        0..512:
            if ( g )
                g := >|(g)                      ' map 1..512x to bitfield 1..10 (log2(g)+1)
            else
                g := 0
            g := (c & core.FD_GAIN_MASK) | (g << core.FD_GAIN)
            writereg(core.FD_TIME2, g)
        other:
            c := ( (c >> core.FD_GAIN) & core.FD_GAIN_BITS )
            if ( c )
                return (1 << (c-1))             ' map bitfield 1..10 to 1..512x
            else
                return 0


PUB flicker_detect_persistence(n=-2): c
' Set the number of consecutive flicker detect results that must be different before
'   flicker detection status changes
    c := readreg(core.CFG10)
    case n
        1..128:
            n := >|(n)-1
            n := (c & core.FD_PERS_MASK) | n
            writereg(core.CFG10, n)
        other:
            return ( 1 << ((c & core.FD_PERS_BITS)+1) )


PUB flicker_detect_ready(): f
' Flag indicating flicker detection measurement is complete
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.FD_STATUS)
    return ( ((f >> core.FD_VALID) & 1) == 1 )


PUB flicker_detect_100hz_ready(): f
' Flag indicating flicker detection 100Hz measurement is valid
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.FD_STATUS)
    return ( ((f >> core.FD_100HZ_VALID) & 1) == 1 )


PUB flicker_detect_120hz_ready(): f
' Flag indicating flicker detection 120Hz measurement is valid
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.FD_STATUS)
    return ( ((f >> core.FD_120HZ_VALID) & 1) == 1 )


PUB flicker_detect_saturated(): f
' Flag indicating flicker detection measurement is saturated
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.FD_STATUS)
    return ( ((f >> core.FD_SAT) & 1) == 1 )


PUB flicker_detect_smux_config() | r
' Configure SMUX chain registers for flicker detection
    repeat r from $00 to $12
        smux_reg_write(r, $00)
    smux_reg_write($13, $60)


CON

    { flicker detection status }
    FD_MEAS_VALID       = (1 << 5)
    FL_SATURATED        = (1 << 4)
    FD_120HZ_VALID      = (1 << 3)
    FD_100HZ_VALID      = (1 << 2)
    FL_DETECTED_120HZ   = (1 << 1)
    FL_DETECTED_100HZ   = (1 << 0)

PUB flicker_detect_status(): f
' Get flicker detection overall status
'   Returns: bitmask
'       bit     description
'       5       flicker detection measurement valid
'       4       flicker saturation detected
'       3       flicker detection 120Hz flicker valid
'       2       flicker detection 100Hz flicker valid
'       1       flicker detected at 120Hz
'       0       flicker detected at 100Hz
    return readreg(core.FD_STATUS)


PUB flicker_detect_time(t=-2): c
' Set flicker detection integration time, in microseconds
'   t:
'       2_780..5_690660
'   Returns:
'       current setting, if called with other values
    c.byte[0] := readreg(core.FD_TIME1)         ' discrete reads: regs aren't sequential
    c.byte[1] := readreg(core.FD_TIME2)
    case t
        2_780..5_690660:
            t /= 2_780
            t := (c & core.FD_TIME_MASK) | t
            writereg(core.FD_TIME1, t)
            writereg(core.FD_TIME1, t.byte[1])
        other:
            return ( (c & core.FD_TIME_BITS) * 2_780 )


PUB flicker_detect_trig_err(): f
' Flag indicating there is a timing error that prevents flicker detection from working correctly
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.STATUS6)
    return ( ((f >> core.FD_TRIG) & 1) == 1 )


PUB flicker_detect_enabled(en=-2): c
' Enable flicker detection
'   en:
'       TRUE (-1 or positive values): enabled
'       FALSE (0): disabled
'   Returns:
'       current setting, if called with other values
    c := readreg(core.ENABLE)
    if ( en => true )
        en := (c & core.FDEN_MASK) | ( ((en <> 0) & 1) << core.FDEN )
        writereg(core.ENABLE, en)
    else
        return ( ((c >> core.FDEN) & 1) == 1 )


PUB gain(g=-2): c
' Set spectral engines gain/sensitivity
'   g:
'       0, 1..512, in powers of 2 (0 = 0.5; default: 256)
'   Returns:
'       current setting, if called with other values
    c := readreg(core.CFG1)
    case g
        0..512:
            if ( g )
                g := >|(g)                      ' map 1..512x to bitfield 1..10 (log2(g)+1)
            else
                g := 0
            g := (c & core.AGAIN_MASK) | g
            writereg(core.CFG1, g)
        other:
            c := ( c & core.AGAIN_BITS )
            if ( c )
                return (1 << (c-1))             ' map bitfield 1..10 to 1..512x
            else
                return 0


PUB init_busy(): f
' Flag indicating the device is initializing
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.STATUS6)
    return ( (f & 1) == 1 )


CON

    { interrupts }
    INT_SAI     = (1 << 8)                      ' pseudo int: sleep after interrupt
    INT_ASAT    = (1 << 7)
    INT_SP_THR  = (1 << 3)
    INT_FIFO_THR= (1 << 2)
    INT_CAL     = (1 << 1)
    INT_SYS     = 1


PUB int_clear(m=-2) | tmp
' Clear interrupt(s)
'   m:  bitmask (set bits will clear the corresponding interrupt)
'       bit     interrupt
'       7       spectral/flicker detection saturation interrupt
'       3       spectral threshold interrupt
'       2       FIFO threshold interrupt
'       1       calibration interrupt
'       0       system interrupt
'   Returns: none
    if ( m & INT_SAI )
        tmp := readreg(core.CONTROL)
        tmp |= core.CLEAR_SAI_ACT_BIT           ' clear SAI_ACTIVE, end sleep, restart operation
        writereg(core.CONTROL, tmp)
        m &= !INT_SAI                           ' strip off the SAI bit

    m &= core.STATUS_MASK                       '   and RESERVED bits
    writereg(core.STATUS, m)


PUB int_mask(m=-2): c
' Set interrupt mask
'   m:
'       symbol          bit     description
'       INT_ASAT        7       Spectral/flicker saturation interrupt
'       INT_SP_THR      3       Spectral interrupt (threshold)
'       INT_FIFO_THR    2       FIFO buffer interrupt (FIFO level threshold)
'       INT_SYS         0       System interrupt (flicker detection status change or SMUX finished)
'   Returns: current setting, if called with other values
    if ( m => 0 )
        m &= core.INTENAB_MASK
        writereg(core.INTENAB, m)
    else
        c := readreg(core.INTENAB)
        return (c & core.INTENAB_MASK)


PUB interrupt(): src
' Interrupt source(s)
'   Returns: bitmask
'       bit     symbol          meaning
'       9       INT_SP_H        spectral interrupt high (n/a unless bit 3 is set)
'       8       INT_SP_L        spectral interrupt low (n/a unless bit 3 is set)
'       7       INT_ASAT        spectral/flicker detect saturation
'       3       INT_SP_THR      spectral threshold interrupt
'       2       INT_FIFO_THR    FIFO level threshold interrupt
'       1       INT_CAL         calibration interrupt
'       0       INT_SYS         system interrupt
    src := readreg(core.STATUS)
    if ( src & INT_SP_THR )                     ' if there was a spectral threshold interrupt,
        src.byte[1] := readreg(core.STATUS3)    '   report which one it actually was in bits 8..9
        src.byte[1] := (src.byte[1] >> core.INT_SP_L)


PUB is_sleeping(): f
' Flag indicating sleep-after-interrupt is active
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.STATUS6)
    return ( ((f >> core.SAI_ACT) & 1) == 1 )


PUB led_current(lc=-2): c
' Set LED drive strength, in milliamperes
'   lc:
'       4..258 (default: 12)
'   Returns:
'       current setting, if called with other values
    c := readreg(core.LED)
    case lc
        4..258:
            lc := (c & core.LED_DRIVE_MASK) | ( ((lc/2)-2) << core.LED_DRIVE )
            writereg(core.LED, lc)
        other:
            return ( ((c & core.LED_DRIVE_BITS) + 2) * 2 )


PUB led_enabled(en=-2): c
' Enable control of external LED
'   en:
'       TRUE (-1 or positive values): enabled
'       FALSE (0): disabled
'   Returns:
'       current setting, if called with other values
    c := readreg(core.CONFIG)
    if ( en => true )
        en := (c & core.LED_SEL_MASK) | ( ((en <> 0) & 1) << core.LED_SEL )
        writereg(core.CONFIG, en)
    else
        return ( ((c >> core.LED_SEL) & 1) == 1 )


PUB led_powered(p=-2): c
' Power on external LED
'   en:
'       TRUE (-1 or positive values): power on
'       FALSE (0): power off
'   Returns:
'       current setting, if called with other values
    readreg(core.LED)
    if ( p => true )
        p := (c & core.LED_ACT_MASK) | ( ((p <> 0) & 1) << core.LED_ACT )
        writereg(core.LED, p)
    else
        return ( ((c >> core.LED_ACT) & 1) == 1 )


CON

    { sensor operating modes }
    SP_MEASURE_DIS  = 0                         ' measurements disabled
    SP_MEASURE_EN   = 1                         ' measurements enabled

    LOW_POWER       = 1 << 1

PUB opmode(md=-2): c | lp
' Set device operating mode
'   md: bitmask
'       bit     description
'       0       disable/enable spectral measurements (SP_MEASURE_DIS, SP_MEASURE_EN)
'       1       normal/low power mode (if set; LOW_POWER)
'   Returns:
'       current setting, if called with other values
    c := readreg(core.ENABLE)
    lp := readreg(core.CFG0)
    if ( md => true )
        lp := (lp & core.LOW_POWER_MASK) | (md.[1] << core.LOW_POWER)
        md := (c & core.SP_EN_MASK) | ( md.[0] << core.SP_EN )
        writereg(core.ENABLE, md)
        writereg(core.CFG0, lp)
    else
        c := c.[core.SP_EN]                     ' extract only the SP_EN bit
        c.[1] := lp.[core.LOW_POWER]            ' add the LOW_POWER bit to bit 1 of the return val
        return c


PUB over_temperature(): f
' Flag indicating the sensor's temperature is too high
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.STATUS6)
    return ( ((f >> core.OVTEMP) & 1) == 1 )


PUB powered(p=-2): c
' Power up the sensor
'   p:
'       TRUE (-1, or positive values): power on
'       FALSE (0): power off
'   Returns:
'       current setting, if called with other values
    c := readreg(core.ENABLE)
    if ( p => true )
        p := (c & core.PON_MASK) | ((p <> 0) & 1)
        writereg(core.ENABLE, p)
    else
        return ( (c & 1) == 1 )


PUB reset()
' Reset the device


VAR

    { spectral data }
    { structure:
        _light_data.byte[0]: undefined
        _light_data.byte[1]: ASTATUS1

        _light_data.word[1]: CH1_DATA
        _light_data.word[2]: CH2_DATA
        _light_data.word[3]: CH3_DATA
        _light_data.word[4]: CH4_DATA

        _light_data.word[5]: CH5_DATA
        _light_data.word[6]: CH6_DATA
        _light_data.word[7]: CH7_DATA
        _light_data.word[8]: CH8_DATA

        _light_data.word[9]: CLEAR_DATA
        _light_data.word[10]: NIR_DATA

    }
    word _light_data[13]


PUB rgbw_data_all()
' Read all spectral data
    smux_cfg_f1f4_clear_nir()
    bytefill(@_light_data+1, 0, 13)
    readreg(core.ASTATUS1, 13, @_light_data+1)

    smux_cfg_f5f8_clear_nir()
    bytefill(@_light_data+14, 0, 12)
    readreg(core.CH0_DATA, 12, @_light_data+14)


PUB rgbw_data(ptr_d=0)
' Get sensor data
'   ptr_d (optional):
'       pointer to 6-word buffer to copy data to
'   Data format:
'       TBD
'   NOTE: This buffer must be at least 6 words in length
    bytefill(@_light_data+1, 0, 13)
    readreg(core.ASTATUS1, 13, @_light_data+1)
    if ( ptr_d )
        wordmove(ptr_d, @_light_data+2, 6)


PUB rgbw_data_rdy(): f
' Flag indicating new sensor data ready
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.STATUS2)
    _sat_status := f                            ' cache reg in RAM for use by saturation()
    return ( ((f >> core.AVALID) & 1) == 1)


VAR byte _sat_status
PUB saturation(): st
' Sensor saturation status
'   Returns: bitmask
'       bit     symbol          description
'       4       ASAT_DIGITAL    ADC max value has been reached
'       3       ASAT_ANALOG     ambient light intensity exceeds max integration level for spectral
'                                   analog circuit
'       1       FDSAT_ANALOG    ambient light intensity exceeds max integration level for flicker
'                                   detection analog circuit
'       0       FDSAT_DIGITAL   ADC max value has been reached during flicker detection
'   NOTE: rgbw_data_rdy() must be called first to update this status
    return ( _sat_status & core.SAT_BITS )


PUB sleep_after_int(en): c
' Sleep after interrupts are asserted
'   en:
'       TRUE (-1 or positive values): enabled
'       FALSE (0): disabled
'   Returns:
'       current setting, if called with other values
    c := readreg(core.CFG3)
    if ( en => true )
        en := (c & core.SAI_MASK) | ( ((en <> 0) & 1) << core.SAI )
        writereg(core.CFG3, en)
    else
        return ( ((c >> core.SAI) & 1) == 1 )


DAT

    { SMUX configuration binary blobs - 20 bytes starting at register $00 }
    _smux_cfg_f1f4_clear_nir
    byte $30, $01, $00, $00, $00, $42, $00, $00, $50, $00, $00, $00, $20, $04, $00, $30
    byte $01, $50, $00, $06

    _smux_cfg_f5f8_clear_nir
    byte $00, $00, $00, $40, $02, $00, $10, $03, $50, $10, $03, $00, $00, $00, $24, $00
    byte $00, $50, $00, $06


PUB smux_cfg_f1f4_clear_nir()
' Configure SMUX for photodiodes F1..F4, clear, NIR channels
    opmode(SP_MEASURE_DIS)
    smux_command(SMUX_CMD_WRITE)
        smux_wr_block(@_smux_cfg_f1f4_clear_nir)
    smux_execute_cmd()
    opmode(SP_MEASURE_EN)
    time.msleep(300)


PUB smux_cfg_f5f8_clear_nir()
' Configure SMUX for photodiodes F5..F8, clear, NIR channels
    opmode(SP_MEASURE_DIS)
    smux_command(SMUX_CMD_WRITE)
        smux_wr_block(@_smux_cfg_f5f8_clear_nir)
    smux_execute_cmd()
    opmode(SP_MEASURE_EN)
    time.msleep(300)


CON

    { SMUX commands }
    SMUX_CMD_ROM_INIT   = 0
    SMUX_CMD_READ       = 1
    SMUX_CMD_WRITE      = 2


VAR

    byte _smux_state

PUB smux_command(cmd): c
' Send SMUX command to device
'   cmd:
'       0: ROM code init of SMUX
'       1: read current SMUX config
'       2: write SMUX config
    c := readreg(core.CFG6)
    case cmd
        0..2:
            _smux_state := SMUX_CMD_WRITE       ' track the set command
            cmd := (c & core.SMUX_CMD_MASK) | (cmd << core.SMUX_CMD)
            writereg(core.CFG6, cmd)
        other:
            return ((c >> core.SMUX_CMD) & core.SMUX_CMD_BITS)


PUB smux_execute_cmd() | tmp
' Executes the currently set SMUX command
    tmp := readreg(core.ENABLE)
    tmp |= (1 << core.SMUXEN)
    writereg(core.ENABLE, tmp)                  ' execute the SMUX command

    repeat                                      ' wait for the command to finish
        tmp := readreg(core.ENABLE)
    while ( tmp & core.SMUXEN_SET )


PUB smux_reg_write(r_nr, val)
' Write to SMUX chain registers
'   r_nr:   register number
'   val:    value to write
'   Returns: none
    if ( _smux_state == SMUX_CMD_WRITE )        ' one layer of protection to make sure we're not
        i2c.start()                             '   writing to the general registers
        i2c.write(SLAVE_WR)
        i2c.write(r_nr)
        i2c.write(val)
        i2c.stop()


PUB smux_wr_block(p_cfgblk)
' Write a configuration block to the SMUX chain registers
'   p_cfgblk: pointer to 20-byte block of data to write
'   Returns: none
    smux_command(SMUX_CMD_WRITE)                ' prep the sensor for writing to the SMUX regs
        i2c.start()
        i2c.write(SLAVE_WR)
        i2c.write($00)                          ' starting with register $00,
        i2c.wrblock_lsbf(p_cfgblk, 20)          '   write the block
        i2c.stop()
    smux_execute_cmd()


PUB spectral_agc_enabled(en): c
' Use automatic gain control for the spectral engines
'   en:
'       TRUE (-1 or positive values): enabled
'       FALSE (0): disabled
'   Returns:
'       current setting, if called with other values
    c := readreg(core.CFG8)
    if ( en => true )
        en := (c & core.SP_AGC_MASK) | ( ((en <> 0) & 1) << core.SP_AGC )
        writereg(core.CFG8, en)
    else
        return ( ((c >> core.SP_AGC) & 1) == 1 )


PUB spectral_autozero(en): c
' Start manual autozero of the spectral engines
'   en:
'       TRUE (-1, or positive values): start autozero
'       FALSE (0): TBD
'   Returns:
'       current setting, if called with other values
'   NOTE: opmode(SP_MEASURE_DIS) should be called before calling this method.
    c := readreg(core.CONTROL)
    if ( en => true )
        en := (c & core.AZ_SP_MAN_MASK) | ( ((en <> 0) & 1) << core.AZ_SP_MAN )
        writereg(core.CONTROL, en)
    else
        return ( ((c >> core.AZ_SP_MAN) & 1) == 1 )


PUB spectral_int_duration(cyc=-2): c
' Set number of consecutive cycles necessary to generate a spectral interrupt
'   cyc:
'       0..3, 5..60 in multiples of 5 (default: 0)
'   Returns:
'       current setting, if called with other values
    c := readreg(core.PERS)
    case cyc
        0..3, 5..60:
            if ( cyc => 5 )
                cyc := (cyc / 5) + 3
            cyc := (c & core.APERS_MASK) | cyc
            writereg(core.PERS, cyc)
        other:
            c &= core.APERS_BITS
            if ( c => 4 )
                c := 5 * (c-3)
            return c


PUB spectral_int_hi_thresh(): th
' Get spectral interrupt high threshold
'   Returns:
'       currently set threshold
    th := readreg(core.SP_TH_H, 2)


PUB spectral_int_lo_thresh(): th
' Get spectral interrupt low threshold
'   Returns:
'       currently set threshold
    th := readreg(core.SP_TH_L, 2)


PUB spectral_int_set_hi_thresh(th)
' Set spectral interrupt high threshold
'   th:
'       0..65535 (clamped to range; default: 0)
'   Returns:
'       none
    th := 0 #> th <# 65535
    writereg(core.SP_TH_H, th, 2)


PUB spectral_int_set_lo_thresh(th)
' Set spectral interrupt low threshold
'   th:
'       0..65535 (clamped to range; default: 0)
'   Returns:
'       none
    th := 0 #> th <# 65535
    writereg(core.SP_TH_L, th, 2)


PUB spectral_thresh_channel(ch=-2): c
' Set channel used for spectral engine-related interrupts (interrupts, persistence, AGC)
'   ch:
'       0..4
'   Returns:
'       current setting, if called with other values
    c := readreg(core.CFG12)
    case ch
        0..4:
            ch := (c & core.SP_TH_CH_MASK) | ch
            writereg(core.CFG12, ch)
        other:
            return (c & core.SP_TH_CH_BITS)


PUB spectral_trig_err(): f
' Flag indicating wait_time() is set too short for the selected als_integr_time()
'   Returns: TRUE (-1) or FALSE (0)
    f := readreg(core.STATUS6)
    return ( ((f >> core.SP_TRIG) & 1) == 1 )


CON

    { system interrupts }
    SIEN_FD     = (1 << core.SIEN_FD)
    SIEN_SMUX   = (1 << core.SIEN_SMUX)

PUB system_int_ena(msk=-2): c
' Enable system interrupt(s)
'   msk: bitmask
'       bit     symbol      description
'       6       SIEN_FD     enable system interrupt when flicker detection status has changed
'       4       SIEN_SMUX   enable system interrupt when SMUX command has finished
'       (other bits ignored)

    c := readreg(core.CFG9)
    if ( msk => 0 )
        msk &= core.CFG9_MASK
        msk := (c & core.SIEN_MASK) | msk
        writereg(core.CFG9, msk)
    else
        return (c & core.CFG9_MASK)


PUB wait_time(w=-2): c
' Set the delay between consecutive spectral measurements, in microseconds
'   w:
'       2_780..711_000:
'   Returns:
'       current setting, if called with other values
'   NOTE: This setting should be longer than the currently set integration time
    case w
        2_780..711_000:
            w := ( w / 2_780 )-1
            writereg(core.WTIME, w)
        other:
            return readreg(core.WTIME)


con

    { register bank }
    REGBANK_LOW     = 0
    REGBANK_HIGH    = 1

VAR

    { Track the last set bank. When the driver is started, this is initialized to a value that
        doesn't match either setting, so it always gets set to a known state the first time around
        when it's checked }
    byte _bank

PRI banksel(b) | tmp
' Select register bank
'   REGBANK_LOW (0): access registers $60..$74
'   REGBANK_HIGH (1): access registers $80..$ff
    if ( b == _bank )
        return                                  ' already set to the same bank; do nothing

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
    _bank := b                                  ' update last used bank

    i2c.start()
    i2c.write(SLAVE_WR)
    i2c.write(core.CFG0)
    i2c.write(tmp)
    i2c.stop()


PRI readreg(reg_nr, len=1, p_dest=0): v | cmd_pkt
' Read nr_bytes from the device into ptr_buff
    v := 0

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
    if ( len =< 4 )
        p_dest := @v
    i2c.rdblock_lsbf(p_dest, len, i2c.NAK)
    i2c.stop()


PRI writereg(reg_nr, val, len=1) | cmd_pkt
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
    i2c.wrblock_lsbf(@val, len)
    i2c.stop()

DAT
{
Copyright 2026 Jesse Burt

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

