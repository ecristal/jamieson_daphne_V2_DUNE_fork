# DAPHNE2 Firmware

## Documentation

MOST of the design documentation has been moved out of this README file and is now part of the Wiki pages associated with this repo:

<https://github.com/DUNE/daphne2_fpga/wiki>

The exception to this is the memory map, which is very much tied to the design and therefore belongs IN the committed source files.
See the file Memory_Map.md for details.

## Discussion

The #daphne channel on the DUNE workspace on Slack is where to discuss this firmware.

## How do I build it?

This design is intended to be built in Vivado Non-Project mode. From the command line do this:

    $ cd src/xilinx
    $ vivado -mode tcl -source vivado_batch.tcl

After vivado completes the output reports and bit file should be located in the src/xilinx/output directory.

It is strongly recommended to NOT use the Vivado GUI ("project mode") to build this design; some settings in the tcl script will likely not be applied properly if that design flow is attempted. Also, the Vivado GUI sucks.

## Does it meet timing?

The timing constraints for this design were carefully written to provide complete timing coverage and also address the many different clock domains present in this design. After building the firmware be sure to look at the file 

    src/xilinx/output/post_route_timing_summary.rpt

and look for the text "All user specified timing constraints are met". If the design does not meet timing there will be negative slack in the worst case timing paths that will need to be addressed.

## Where are the binaries?!?

Output files including the BIN and BIT files, along with various reports, are usually ZIPPED up and attached to each commit in the comments section.

<jamieson@fnal.gov>

