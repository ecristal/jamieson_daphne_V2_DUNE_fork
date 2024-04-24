#!/usr/bin/env python3
# uccmd.py -- send a command to the microcontroller and read the response
# uses the new SPI slave firmware. Python 3.

from oei import *
from time import sleep

thing = OEI("192.168.133.12")

print('DAPHNE Command Interpreter. Type quit to exit.')

# prompt user for command

while True:

	CmdString = input('daphne% ')

	if (CmdString=="quit"):
		break;
		
	# convert string to list of ascii values

	CmdByteList = []

	for ch in CmdString:
		CmdByteList.append(ord(ch))
	
	CmdByteList.append(0x0d) # tack on CR
	#CmdByteList.append(0x0a) # and LF

	# write an ASCII bytes to the SPI command FIFO at 0x9000_0000

	for i in range((len(CmdByteList)+49)//50):
		thing.writef(0x90000000, CmdByteList[i*50:(i+1)*50])
#	thing.writef(0x90000000, CmdByteList)

	# read the SPI slave response FIFO, this is also at address 0x9000_0000
	# if the FIFO is empty it will return zeros when read. this assumes the response will be
	# less than 200 characters


	ResString = ""
	more = 40
	
	while more > 0:
		ResByteList = thing.readf(0x90000000,50) 
		for b in ResByteList[2:]:
			if b==255:
				break
			elif b==1:
				ResString += "[START]"
			elif b==2:
				ResString += "[RESULT]"
			elif b==3:
				ResString += "[END]"	
			elif chr(b).isprintable:
				more = 40
				ResString = ResString + chr(b)
		sleep(0.005)
		more -= 1
	ResString = ResString + chr(0)
	
	print(ResString)

thing.close()





