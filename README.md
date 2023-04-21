# DAPHNE2 Firmware

## Overview of Firmware Modules

### Front End Logic

New for this firmware is a fully automatic front end. DAPHNE has 5 AFE chips, each with 8 high speed serial data outputs. This front end logic adjusts the input data streams so that the sample clock is in the optimal center of the eye (IDELAYE2), and then adjusts the serial to parallel shift register logic (ISERDESE2) to properly recover the 14 bit parallel data. Works for all 40 AFE channels and requires no user intervention aside from a soft reset after the FPGA is programmed. 

The output of the front end logic is 40 14-bit data buses synchronized to the master 62.5 MHz clock domain.

### Self Triggered Sender

The core logic contains the sender firmware. The senders take the raw AFE data (after it has been aligned to the master clock) and form output records. Output records are sent downstream to DAQ over high speed serial links. 

#### Automatic Baseline Calculation

The self triggered sender is built upon a modular approach. The STC module monitors a single AFE data stream. Each STC module continuously monitors the data stream from an input channel. It automatically computes the average signal baseline level over 256 samples. The baseline level is reported in the output record header.

#### Trigger Condition

In this example code the user supplies the threshold value, which is relative to the automatic baseline. Thus the trigger condition is defined simply as three consecutive samples over (baseline + threshold). Once a trigger condition is satisfied, the STC module waits for 64 clock cycles, then grabs the next 1024 samples (including 64 pre-trigger samples), forms an output frame around this data, and stores this frame in a FIFO. This FIFO is deep enough to store ~8.9 events. 

#### Re-trigger Capability

Once the STC module is triggered it begins to capture the pre- and post- trigger samples. If during this time another trigger condition occurs, it is currently ignored, as it is assumed that this condition is going to be captured anyway. In a future version we may change this to support overlapping or re-trigger functionality.

#### Backend Logic

On the sender backend, a state machine scans across 10 modules looking to see who has an output record ready to send in the FIFO. In a round robin manner these STC modules are selected to dump data to the output link to FELIX. And the process repeats. The current design has 10 input modules feeding one output: channels 0-9 feed into output 0, channels 10-19 feed into output 1, and so on.

### Streaming Sender 

The streaming sender design takes 4 AFE data streams and packs 64 samples from each stream them into an output frame for transmission to FELIX DAQ. The output link runs at 4.809 Gbps. This design runs continuously and there are a few idle words inserted between output frames. This version of the firmware has four streaming senders instantiated. The DEFAULT inputs to each sender are specified in the memory map section below. The sender input channel selection can be changed at any time by writing to registers via the Gigabit Ethernet interface.

### Timing Endpoint

The timing endpoint firmware block interfaces to the DAPHNE timing input (optical link) and generates the master 62.5 MHz clock and a 64 bit timestamp. The timing endpoint design used here is the NEW style timing protocol based on pulse width modulated clock at 62.5MHz. An external ADN2814 clock and data recovery chip is present, but this new timing scheme no longer requires it. The AD2814 clock output is not used by the new timing endpoint logic, and the DATAOUT signal is the encoded clock. The "pdts" endpoint logic was developed by Dave Newbold and others at Bristol UK and adapted to DAPHNE by Adrian @ UPENN. Through the GbE interface the user can monitor all status bits related to the timing endpoint and control status bits as well. The most important control bit selects either the local clocks (with fake timestamp) or timing endpoint to run the FPGA. 

The default timing endpoint address is a 16 bit unsigned number. It is determined by reading the EFUSE_USER bits [15..8] and adding 0x000F to it.

### Spy Buffers

#### Input Spy Buffers

When triggered, the spy buffers will capture 64 pre-trigger samples followed by 4032 samples on EACH AFE channel. These buffers are memory mapped into the GBE internal address space and then can be read out at any time. The trigger may come from an external input to the DAPHNE2 board or by writing to a particular register in the GbE address space. Note that the Spy Buffer trigger is totally separate from the trigger condition in the self-triggered core logic.

#### Output Spy Buffers

Output spy buffers capture the data that the core is sending on the DAQ0 output link. This spy buffer is 32 bits wide and 4k deep. It is triggered along with the input spy buffers.

### Gigabit Ethernet (GbE)

The GbE interface is a simple way to access FPGA internal registers and memory buffers from a PC. The GbE interface is always active, but is not required for operation. This interface is intended for slow controls and debugging and provides fast access to various spy buffers and registers. This interface is based on the "off the shelf Ethernet Interface" developed at Fermilab by Ryan Rivera and Lorenzo Uplegger. 

The default IP address is 192.168.133.XX and the MAC is 00:80:55:DE:00:XX where XX is EFUSE_USER[15..8] register. This register is one time programmable via the Vivado Hardware Manager. It can also be read via the JTAG cable. Example python code is located in src/oei/python.

The memory map is as follows:

	0x00000000 - 0x00000064 Reserved for OEI internal settings

	0x00001974  Status vector for the Xilinx GbE PCS/PMA IP Core, read-only, 16 bit

	0x00001975  SFP module status bits (all should be zero)

			0:  DAQ0 SFP absent (ABS)
			1:  DAQ0 SFP loss of signal (LOS)
			8:  DAQ1 SFP ABS
			9:  DAQ1 SFP LOS
			16: DAQ2 SFP ABS
			17: DAQ2 SFP LOS
			24: DAQ3 SFP ABS
			25: DAQ3 SFP LOS
			32: GbE SFP ABS
			33: GbE SFP LOS
			40: Timing Endpoint SFP ABS
			41: Timing Endpoint SFP LOS

	0x00002000  Write anything to trigger spy buffers
	0x00002001  Write anything to force front end alignment recalibration
	0x00002002  Read the status of the AFE automatic alignment front end, lower 5 bits should be HIGH
	0x00002010  Number of errors observed for AFE0 frame marker, stops at 255.
	0x00002011  Number of errors observed for AFE1 frame marker, stops at 255.
	0x00002012  Number of errors observed for AFE2 frame marker, stops at 255.
	0x00002013  Number of errors observed for AFE3 frame marker, stops at 255.
	0x00002014  Number of errors observed for AFE4 frame marker, stops at 255.

	0x00003000  Output record header parameters, read-write, 26 bits defined as:

			bits 25..22 = slot_id(3..0), default "0010"
			bits 21..12 = crate_id(9..0), default is "0000000001"
			bits 11..6  = detector_id(5..0), default is "000010"
			bits 5..0   = version_id(5..0), default is "000001"
				
			note: when an output link is disabled it sends FELIX style idle words 
			(D0.0 & D0.0 & D0.0 & K28.5)

	0x00003001  Output link control to select streaming or self triggered mode sender, 
                    or idle. This register defaults to 0, all output links idle.

			bits 1:0: output link0 mode. 
			"0X" = link disabled, send idles
			"10" = streaming mode sender
			"11" = self triggered mode sender

			bits 3:2: output link1 mode. 
			"0X" = link disabled, send idles
			"10" = streaming mode sender
			"11" = self triggered mode sender

			bits 5:4: output link2 mode. 
			"0X" = link disabled, send idles
			"10" = streaming mode sender
			"11" = self triggered mode sender

			bits 7:6: output link0 mode. 
			"0X" = link disabled, send idles
			"10" = streaming mode sender
			"11" = self triggered mode sender






	0x00004000  Master Clock and Timing Endpoint Status Register (read only)

			bit 0: MMCM0 locked status
			bit 1: MMCM1 locked status
			bit 2: reserved, 0
			bit 3: reserved, 0
			bit 4: CDR chip LOS, should be 0
			bit 5: CDR chip LOL, should be 0
			bit 6: Timing SFP LOS, should be 0
			bit 7: Timing SFP ABS, should be 0 if present
			bits 11..8: Timing endpoint state bits, defined as:

				"0000" Starting state after reset
				"0001" Waiting for SFP LOS to go low
				"0010" Waiting for good frequency check
				"0011" Waiting for phase adjustment to complete
				"0100" Waiting for comma alignment, stable 62.5MHz phase
				"0101" Waiting for 8b10 decoder good packet
				"0110" Waiting for phase adjustment command
				"0111" Waiting for time stamp initialization
				"1000" Good to go!!!
				"1100" Error in rx
				"1101" Error in time stamp check
				"1110" Physical layer error after lock

			bit 12: Timing endpoint timestamp valid (Rdy)

	0x00004001  Master Clock and Timing Endpoint Control Register (read write)
			
			bit 0: MMCM1 master clock input select (0=local-default, 1=endpoint)

	0x00004002  Write anything to reset master clock MMCM1
	0x00004003  Write anything to reset timing endpoint

	The following registers are used to determine which physical input channels (numbered 0-39)
	are connected to which streaming core sender inputs. There are four streaming core senders,
	each with 4 inputs. These registers are write only. 

	0x00005000  Sender0 input0 channel select, default = ch0 aka AFE0 input 0
	0x00005001  Sender0 input1 channel select, default = ch1
	0x00005002  Sender0 input2 channel select, default = ch2
	0x00005003  Sender0 input3 channel select, default = ch3

	0x00005010  Sender1 input0 channel select, default = ch8 aka AFE1 input 0
	0x00005011  Sender1 input1 channel select, default = ch9
	0x00005012  Sender1 input2 channel select, default = ch10
	0x00005013  Sender1 input3 channel select, default = ch11

	0x00005020  Sender2 input0 channel select, default = ch16 aka AFE2 input 0
	0x00005021  Sender2 input1 channel select, default = ch17
	0x00005022  Sender2 input2 channel select, default = ch18
	0x00005023  Sender2 input3 channel select, default = ch19

	0x00005030  Sender3 input0 channel select, default = ch24 aka AFE3 input 0
	0x00005031  Sender3 input1 channel select, default = ch25
	0x00005032  Sender3 input2 channel select, default = ch26
	0x00005033  Sender3 input3 channel select, default = ch27

	Specify the threshold value to be used for all self-triggered mode senders.
	Note this value is relative to the automatic baseline value calculated 
	for each input channel. Default is 256. This register is read/write.

	0x00006000  Relative trigger threshold value for self triggered senders

	0x00009000  Read the FW version aka git commit hash ID, read-only, 28 bits

	0x0000AA55  Test register R/O always returns 0xDEADBEEF, read-only, 32 bit

	0x00070000 - 0x703FF  Test BlockRam read-write, 36 bit

	0x12345678 Simple test register, read-write, 64 bit

	0x40000000 - 0x400003FF Spy Buffer AFE0 data0 
	0x40010000 - 0x400103FF Spy Buffer AFE0 data1
	0x40020000 - 0x400203FF Spy Buffer AFE0 data2
	0x40030000 - 0x400303FF Spy Buffer AFE0 data3
	0x40040000 - 0x400403FF Spy Buffer AFE0 data4
	0x40050000 - 0x400503FF Spy Buffer AFE0 data5
	0x40060000 - 0x400603FF Spy Buffer AFE0 data6
	0x40070000 - 0x400703FF Spy Buffer AFE0 data7
	0x40080000 - 0x400803FF Spy Buffer AFE0 frame

	0x40100000 - 0x401003FF Spy Buffer AFE1 data0
	0x40110000 - 0x401103FF Spy Buffer AFE1 data1
	0x40120000 - 0x401203FF Spy Buffer AFE1 data2
	0x40130000 - 0x401303FF Spy Buffer AFE1 data3
	0x40140000 - 0x401403FF Spy Buffer AFE1 data4
	0x40150000 - 0x401503FF Spy Buffer AFE1 data5
	0x40160000 - 0x401603FF Spy Buffer AFE1 data6
	0x40170000 - 0x401703FF Spy Buffer AFE1 data7
	0x40180000 - 0x401803FF Spy Buffer AFE1 frame

	0x40200000 - 0x402003FF Spy Buffer AFE2 data0
	0x40210000 - 0x402103FF Spy Buffer AFE2 data1
	0x40220000 - 0x402203FF Spy Buffer AFE2 data2
	0x40230000 - 0x402303FF Spy Buffer AFE2 data3
	0x40240000 - 0x402403FF Spy Buffer AFE2 data4
	0x40250000 - 0x402503FF Spy Buffer AFE2 data5
	0x40260000 - 0x402603FF Spy Buffer AFE2 data6
	0x40270000 - 0x402703FF Spy Buffer AFE2 data7
	0x40280000 - 0x402803FF Spy Buffer AFE2 frame

	0x40300000 - 0x403003FF Spy Buffer AFE3 data0
	0x40310000 - 0x403103FF Spy Buffer AFE3 data1
	0x40320000 - 0x403203FF Spy Buffer AFE3 data2
	0x40330000 - 0x403303FF Spy Buffer AFE3 data3
	0x40340000 - 0x403403FF Spy Buffer AFE3 data4
	0x40350000 - 0x403503FF Spy Buffer AFE3 data5
	0x40360000 - 0x403603FF Spy Buffer AFE3 data6
	0x40370000 - 0x403703FF Spy Buffer AFE3 data7
	0x40380000 - 0x403803FF Spy Buffer AFE3 frame

	0x40400000 - 0x404003FF Spy Buffer AFE4 data0
	0x40410000 - 0x404103FF Spy Buffer AFE4 data1
	0x40420000 - 0x404203FF Spy Buffer AFE4 data2
	0x40430000 - 0x404303FF Spy Buffer AFE4 data3
	0x40440000 - 0x404403FF Spy Buffer AFE4 data4
	0x40450000 - 0x404503FF Spy Buffer AFE4 data5
	0x40460000 - 0x404603FF Spy Buffer AFE4 data6
	0x40470000 - 0x404703FF Spy Buffer AFE4 data7
	0x40480000 - 0x404803FF Spy Buffer AFE4 frame

	0x40500000 - 0x405003FF Spy Buffer for Timestamp (64 bits)

	0x40600000 - 0x406003FF Spy Buffer for Core Sender0 OUTPUT (32 bits)

	0x80000000   Test FIFO, 512 x 64, read-write (64-bit)

	0x90000000   SPI FIFO, 2k x 8, read-write (8-bit ASCII strings )

	0xFFFFFFFF   Reserved for OEI internal settings

Memory Map Notes:

* Address space is 32 bits, Data width is 64-bits (A32D64)
* AFE Spy Buffers are 14 bits wide and are read-only
* When properly aligned, every word in the frame marker spy buffers should read "11111110000000"  (0x3F80)

### SPI Slave

SPI slave logic is used for communication with the microcontroller. A pair of FIFOs are used to access this SPI slave device from the GbE interface.

## Overview of Hardware Subsystems

### Front Panel Index

The front panel numbers the AFE ports	0 1 2 4 5 (left to right).
The schematic/PCB numbers the AFE buses	0 4 3 2 1 
This firmware now uses the front panel scheme, change made in the constraints file.

### Board Revision

This firmware is designed for the DAPHNE V2A hardware only. It cannot be used on DAPHNE V1 boards.

### Clocks

The programmable clock generator U18 should be configured to output the following clocks: 

* CLK0 = 120.327MHz connects to MGT Quad 216, REFCLK0, pins F11/E11. Used for FELIX DAQ.
* CLK1 = 100MHz connects to bank 33, pins AA4/AB4. General purpose clock.
* CLK2 = 62.5MHz connects to bank 33, pins AA3/AA2. Currently unused.
* CLK3 = 125MHz connects to MGT Quad 213, REFCLK0, pins AA13/AB13. Used for GBE.

This firmware design uses the 100MHz system clock to generate the master clock and other internal clocks used by the firmware design. 

The FPGA outputs a 62.5MHz clock on pins AF5/AF4. This clock goes to clock fanout buffer U20 and then copies of this clock go the 5 AFE chips.

Note that the OEICLK (125MHz for GbE operations) and DAQCLK (120.237MHz for output link sender logic) are generated from their respective GTP reference clock inputs. These clocks are generated by the MMCM/PLL contained in their respective GTP Quad modules. 

If the clock generator U18 is ever re-configured by the microcontroller this can certainly affect the clocks going to the FPGA, and in that case the micro should hard reset the FPGA after the U18 output clocks are stable.

### Reset Sequencing

The front end alignment logic uses a number of different clocks and reset signals, so this sequencing is managed by a new module called clock_reset. The firmware design distinguishes between two different types of resets:

* A HARD RESET is an external signal controlled by the microcontroller. When asserted, the main MMCM/PLL in the FPGA is reset, and this momentarily disrupts all clocks output from this MMCM. After some time the MMCM returns to normal operation (locked=1) and then a state machine generates a sequence of reset pulses which are synchronized to various clock domains in the design.

* A SOFT RESET is generated by the user writing to a specific register in the GbE interface. When a soft reset is issued the main MMCM is not reset and all board clocks continue to run normally, and the reset signals are momentarily pulsed in their respective clock domains.

Normally a hard reset should not be needed. The FPGA should be programmed AFTER the microcontroller has initialized the clock generator U18. A soft reset is recommended after the FPGA is initialized, or any time the automatic front end logic reports bit errors in the framing pattern.

### Timing Interface

The DAPHNE2 board includes the CDR chip ADN2814CPZ U16. This device sends differential clock and data, as well as LOS and LOL indicators, to to FPGA. Currently this interface is unused and we running with the local clocks only.

### Gigabit Ethernet

This firmware uses a Gigabit Ethernet Interface based on the OEI "Off the Shelf Ethernet Interface" developed by Ryan Rivera. This Ethernet interface is fiber and the SFP module connects to Quad 213, channel 0. The default IP address for this interface is determined by the value in EFUSE_USER[15..8].

### High Speed Serial Links

Quad 213 channel 0 is used for GbE. The FPGA can control the TX_DISABLE pin on this SFP. The FPGA can monitor the LOS and ABS signals on the SFP, as well as communicate with the SFP management interface (I2C).

Quad 216 is used for FELIX DAQ links. All four channels in this quad may be used. For FELIX generally only the MGT TX is used and the RX is disabled for each transceiver. The FPGA can control the TX_DISABLE, monitor the LOS and ABS signals, and communicate with the SFP management interface (I2C).

### Microcontroller Interface (Slow Controls)

The FPGA firmware features and SPI slave that is used to communicate with the microcontroller. Two FIFOs are used to attach this slave SPI to the GbE interface. Command strings are written into the CMD FIFO (2k x 8). The command string must be less than 512 bytes ASCII data and terminated with 0x0d (CR) or 0x0a (LF). When the CMD FIFO has some data the SPI slave raises the SPI_IRQ line. The microcontroller then fetches the command string via the SPI interface, does the command, and writes any response string back to the SPI slave, which then stores it into the RES FIFO which can be read by the user through the GbE interface. If the user attempts to read an empty RES FIFO then 0xFF will be returned. This SPI interface between the FPGA and the microcontroller replaces the 100BASE-X Ethernet inteface on the microcontroller.

Also note that the DAPHNE microcontroller can hard reset the FPGA by pulling the RESETn line LOW momentarily. (There is a command to do this!)

### External Trigger

The external interface trigger is now optically isolated. The input is 5-12VDC on an SMB connector (center positive). Note that the optoisolator device used on DAPHNE has an inverted output, so this inversion must be addressed in firmware.

### Status LEDs

There are 5 status LEDs. All are pulse stretched in the firmware so that momentary pulses are visible. The LED closest to the SFP Timing Interface connector is reserved for the microcontroller.

* uC LED: blinks at 1Hz when the microcontroller is programmed
* LED0: ON if the master clock MMCM is LOCKED
* LED1: ON if the automatic front end AFE alignment is done
* LED2: ON if the timing endpoint is locked and timestamp is valid
* LED3: ON if the GbE link is up and the speed is 1000
* LED4: ON if there is activity on the GbE link
* LED5: ON if there if the spy buffers are triggered (externally or internally via GbE)

## Simulation

Many of the firmware modules have separate testbench files, written in VHDL. The simulator I use is Aldec Active-HDL. The Vivado simulator should also work with some modifications.

## Debug

Firmware MAY include a Xilinx "chipscope" Internal Logic Analyzer. See xilinx\output\probes.ltx for details.


## Build Instructions

This design is intended to be built in Vivado Non-Project mode. In a command line window cd to the src/xilinx directory and type: 

	vivado -mode tcl -source vivado_batch.tcl

After vivado completes the output reports and bit file should be located in the src/xilinx/output directory. It is recommended to NOT use the Vivado GUI ("project mode") to build this design; some settings in the tcl script will likely not be applied properly if that design flow is attempted.

The timing constraints for this design were carefully written to provide complete timing coverage and also address the many different clock domains present in this design. After building the firmware be sure to look at the file src/xilinx/output/post_route_timing_summary.rpt and look for the text "All user specified timing constraints are met". If the design does not meet timing there will be negative slack in the worst case timing paths that will need to be addressed.


