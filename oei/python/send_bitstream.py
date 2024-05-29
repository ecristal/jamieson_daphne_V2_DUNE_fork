#!/bin/env python3
# send_bitstream.py -- send a bitstream to a DAPHNE2A through repeated write commands

import argparse
from time import sleep,time
import io, os
import encode_bin
import serial
from oei import *
from time import sleep


class OEICommandWrapper(object):
    def __init__(self,ip_address):
        self.connection = 'fpga'
        self.default_outstanding = 4
        self.cmd_ending = 3
        self.oei = OEI(ip_address)
    def read(self):
        reply = self.oei.readf(0x90000000,50)[2:]
        reply = bytes([r for r in reply if r != 255])
        return reply
    def write(self,cmd):
        cmdbin = [ch for ch in cmd]
        for i in range((len(cmdbin)+49)//50):
            self.oei.writef(0x90000000, cmdbin[i*50:(i+1)*50])
        return len(cmdbin)

class SerialCommandWrapper(object):
    def __init__(self,tty = '/dev/ttyUSB0'):
        self.connection = 'serial'
        self.default_outstanding = 0
        self.cmd_ending = b"DAPHNE>"
        if not (os.path.exists(tty) and tty.startswith('/dev/ttyUSB')):
            raise ValueError(tty)
        self.path = tty
        #os.system('stty 921600 -F /dev/ttyUSB0 raw -echo time 0 min 0')
        self.tty = serial.Serial(self.path,921600,timeout=0)
        #io.FileIO(os.open(self.path, os.O_NOCTTY | os.O_RDWR), "r+")
    def read(self):
        return self.tty.read(256)
    def write(self,cmd):
        for i in range((len(cmd)+49)//50):
            self.tty.write(cmd[i*50:(i+1)*50])
            sleep(0.001)
        return 


class command_sender(object):
    def __init__(self, cmd_generator, cmd_interface, outstanding=0):
        self.cmdgen = cmd_generator
        self.cmd_interface = cmd_interface
        self.max_outstanding = outstanding
        self.sent = []
        self.pending = []
        self.returned = []
        self.replybuf = b""
        self.cmd_interface.write(b"clear_line\rclear_line\r")
        sleep(0.5)
        # clear read buffer
        while (len(self.cmd_interface.read())):
            pass
        self.get_reply()
        self.returned = [] # re-initialize to clear out previous entries
        self.replybuf = b"" # same
        print("ready")

    def send_header(self):
        cmd = self.cmdgen.HeaderWriteCmd().encode('ascii')
        cmd += b'\n'
        self.pending.append(cmd)
        self.cmd_interface.write(cmd)


    def send_next(self):
        cmd = self.cmdgen.next().encode('ascii')
        cmd += b'\n'
        self.pending.append(cmd)
        self.cmd_interface.write(cmd)

    def get_reply(self):
        more = True
        replylen = 0
        while(more):
            reply = self.cmd_interface.read()
            if len(reply):
                self.replybuf += reply
                replylen += len(reply)
                self.lastbyte = time()
            else:
                more = False
        return replylen
    
    def parse_replybuf(self):
        parsed = 0
        # Don't actually check for full replies now, for testing
        endindex = self.replybuf.find(self.cmd_interface.cmd_ending)
        while endindex > -1:
            self.returned.append(self.replybuf[:endindex+1])
            for i in reversed(range(len(self.pending))):
                if self.pending[i].strip() in self.replybuf[:endindex+1]:
                    self.sent.append(self.pending[i])
                    self.pending.pop(i)
                    break
            self.replybuf = self.replybuf[endindex+1:]
            parsed += 1
            endindex = self.replybuf.find(self.cmd_interface.cmd_ending)
        return parsed
    
    def count_outstanding(self):
        return len(self.pending)

    def go(self):
        start = time()
        self.lastbyte = time()
        self.send_header()
        while self.count_outstanding() > self.max_outstanding:
            sleep(0.01)
            self.get_reply()
            self.parse_replybuf()
            if time()-self.lastbyte > 1:
                return
        while len(self.returned) < len(self.cmdgen):
            if self.cmdgen.more():
                self.send_next()
                if len(self.sent)%1 == 0:
                    print(f"Sent {len(self.sent)+len(self.pending)} of {len(self.cmdgen)} in {time()-start:0.1f}")
            self.get_reply()
            self.parse_replybuf()
            while self.count_outstanding() > self.max_outstanding:
                sleep(0.01)
                self.get_reply()
                self.parse_replybuf()
                if time()-self.lastbyte > 1:
                    return
            if time()-self.lastbyte > 1:
                return



if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-f', '--file', type=str, required=True, help='Path to bitstream file.')
    parser.add_argument('--ip-address', type=str, required=False, help='IP address.')
    parser.add_argument('--serial-port', type=str, required=False, help='Serial device /dev/ttyUSB0')
    parser.add_argument('--pageoffset', type=int, default=0, help='Starting page offset, must be multiple of 16.')
    parser.add_argument('--header',type=bool, default=True, help='Include header')
    # should add a testing switch.
    args = parser.parse_args()
    print(args)
    bf =encode_bin.binfile(args.file,page_offset=args.pageoffset,header=args.header)
    if args.ip_address:  # if IP
        CMDInterface = OEICommandWrapper(args.ip_address)
    elif args.serial_port:
        CMDInterface = SerialCommandWrapper(args.serial_port)
    else:
        raise Exception("Must set either IP address or Serial port")

    print('sending a bitfile with default options')
    cs = command_sender(bf,CMDInterface,CMDInterface.default_outstanding)
    cs.go()
