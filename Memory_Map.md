# Memory Map

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

	0x00003000  Output record header parameters, read-write, bits 25 to 6, bits 5 to 0 are read only, 26 bits defined as:

			bits 25..22 = slot_id(3..0), default "0010"
			bits 21..12 = crate_id(9..0), default is "0000000001"
			bits 11..6  = detector_id(5..0), default is "000010"
			bits 5..0   = version_id(5..0), default is "000010"
				
	0x00003001  Output link control byte. used to select streaming or self triggered mode sender, 
			or idle. This register defaults to 0, all output links idle. When an output link 
			is disabled it sends FELIX style idle words (D0.0 & D0.0 & D0.0 & K28.5)

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

	The following registers are used to determine which physical input channels 
	    (which are numbered decimal 0-7, 10-17, 20-27, 30-37, and 40-47)
	are connected to which core STREAMING sender inputs. These registers are read/write.
	Each register must contain a valid input number (as listed above) otherwise it will 
	set the corresponding mux output bus to all zeros. Applies only to STREAMING senders

	0x00005000  StreamSender0 input0 channel select, default = 0  (AFE0 ch0)
	0x00005001  StreamSender0 input1 channel select, default = 1  (AFE0 ch1)
	0x00005002  StreamSender0 input2 channel select, default = 2  (AFE0 ch2)
	0x00005003  StreamSender0 input3 channel select, default = 3  (AFE0 ch3)

	0x00005004  StreamSender1 input0 channel select, default = 10 (AFE1 ch0)
	0x00005005  StreamSender1 input1 channel select, default = 11 (AFE1 ch1)
	0x00005006  StreamSender1 input2 channel select, default = 12 (AFE1 ch2)
	0x00005007  StreamSender1 input3 channel select, default = 13 (AFE1 ch3)

	0x00005008  StreamSender2 input0 channel select, default = 20 (AFE2 ch0)
	0x00005009  StreamSender2 input1 channel select, default = 21 (AFE2 ch1)
	0x0000500A  StreamSender2 input2 channel select, default = 22 (AFE2 ch2)
	0x0000500B  StreamSender2 input3 channel select, default = 23 (AFE2 ch3)

	0x0000500C  StreamSender3 input0 channel select, default = 30 (AFE3 ch0)
	0x0000500D  StreamSender3 input1 channel select, default = 31 (AFE3 ch1)
	0x0000500E  StreamSender3 input2 channel select, default = 32 (AFE3 ch2)
	0x0000500F  StreamSender3 input3 channel select, default = 33 (AFE3 ch3)

	Specify the threshold value to be used for all self-triggered mode senders.
	Note this value is relative to the automatic baseline value calculated 
	for each input channel. Default is 256. This register is read/write.

	0x00006000  Trigger threshold for self triggered senders, 14 bits R/W

	There is only one self triggered sender module and it connects to all forty
	input channels. Use this register to enable which channels you want the self
	triggered sender to see. The default value is for this register is all inputs DISABLED

	0x00006001  Self Trigger sender input enables, 40 bits R/W

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

	0x90000000   Micocontroller Access via SPI FIFO, 2k x 8, read-write (8-bit ASCII strings )

	0xFFFFFFFF   Reserved for OEI internal settings

## Memory Map Notes:

* Address space is 32 bits, Data width is 64-bits (A32D64)
* AFE Spy Buffers are 14 bits wide and are read-only
* When properly aligned, every word in the frame marker spy buffers should read "11111110000000"  (0x3F80)
