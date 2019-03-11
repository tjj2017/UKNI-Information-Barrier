  This software is made available under the Open Government License v3.0.

  Please attribute to
     United Kingdom - Norway Initiative, http://ukni.info (2016)

**********************************************************************
                          Introduction
**********************************************************************

This readme is intended as a quick introduction into how to build, run
and analyse the Ada UKNI IB.  More details on the code and the  
compilation and analysis setup can be found in the IB Software 
Development Report.

The following topics are presented
* building the code from the command line
* editing the ihex file to insert CRC
* downloading the code
* analysing the code from the command line
* toolsets used

Building and analysing the code can also be done via GPS.  For more
information on how to perform these operations, see the GPS user 
guides.

Make sure that all the tools listed in the "toolsets used" section
are installed and in the path.

**********************************************************************
                  Building the code from the command line
**********************************************************************
To build the code base from the command line, perform the following 
steps (where > is used to denote the command prompt):
* extract the zipped source code files into a new folder (e.g. c:\MYPATH\ib)
* create a build folder to build the source into (e.g. 
C:\MYPATH\IB_Phase3_Build)
* open up a command prompt
* change directory into the build folder (where C:\MYPATH\IB_Phase3_Build
is an existing folder to build into)
   > cd C:\MYPATH\IB_Phase3_Build
* type the following into the prompt (where c:\MYPATH\ib contains the 
source code)
    > gprbuild --target=avr -d -PC:\MYPATH\ib\ib.gpr Main.adb -s
* convert the produced file into an ihex file
    > avr-objcopy -O ihex main main.ihex
* fill the rest of the ihex file with zeros
    > srec_cat main.ihex -intel --crop 0 0x3FFFF --fill 0x00 0x0000 0x40000 -output main.ihex -intel --address_length=2 --line_length=44


**********************************************************************
                   Editing the ihex file to insert CRC
**********************************************************************
The generated file will not have the correct CRC at the end of the 
file. The CRC check is part of the IB start-up integrity checks.
* open the main.ihex file (from C:\MYPATH\IB_Phase3_Build contains the 
main.ihex file)
* edit the last line of the ihex file (starting :10FFF0) to contain 
the CRC (calculated as per application note AVR236).  For the provided 
code this is CEB3
* calculate the checksum (required to ensure the ihex is in valid intel
hex file format) as the twos complement of the entire line 
(including the CRC bytes added). For the provided code this is 80
* the last line of the code is:
    :10FFF0000000000000000000000000000000CEB380


**********************************************************************
                         Downloading the code
**********************************************************************
To use a JTAGICE mkII in JTAG mode to download the code onto the AVR
using AVR Studio 4.0
* on the main Tab select
    Device = ATmega2560
    Programming Mode and Target Settings = JTAG mode
* on the Fuses Tab set
    EXTENDED= 0xFF
    HIGH = 0x99
    LOW = 0xFF7
* on the LockBits tab set
    LOCKBIT = 0xFF
* on the Program Tab select
    Flash Input HEX File = C:\MYPATH\IB_Phase3_Build\main.ihex
    Press the "Program" button in the Flash section
* If the code has successfully downloaded and the CRC correctly 
calculated, the IB will illuminate the LEDS as per the IB start-up 
routine

**********************************************************************
               Analysing the code from the command line
**********************************************************************
To analyse the code from the command line, perform the following steps
(where > is used to denote the command prompt)
* open up a command prompt
* change the current directory to the folder containing the source code
   > cd c:\MYPATH\ib
* clean the old analysis files
   > sparkclean
* use the SPARK examiner to examine the files
   > spark -pl -flow_analysis=information -html -index_file=C:\MYPATH\ib\Main.idx -vcg -config=C:\MYPATH\ib\config.cfg -error_explanations=first -dpc -language=2005 -statistics -warning_file=C:\MYPATH\ib\warnings.wrn -output_directory=C:\MYPATH\ib\SPARK_Output -casing -rules=keen @main.smf
* change directory to the SPARK output folder
    > cd SPARK_Output 
* run the Spark simplifier
   > sparksimp -p=1 -nz -l -sargs "-plain"
* the proof checker is used to discharge the undischarged verification 
conditions.  Change directory to enable the checker to be run on this 
file
   > cd c:\MYPATH\ib\SPARK_Output\toolbox_\peak_net_area\
* run the proof checker
   > checker -exec=roi_02 roi_area.siv
* change directory to where all the output files are stored
   > cd c:\MYPATH\ib\SPARK_Output
*  run the Proof ObliGation Summariser tool to collate the results
   > pogs -i
   

**********************************************************************
                          Toolsets used
**********************************************************************
The following toolsets were used:
* GPS 6.0.0 (20131030)
* GNAT Pro 7.0.1 (20120104-45)
* SPARK 11.1.0 (26142)
* srec_cat 1.42.D001
* AVR Studio 4 (4, 19, 0, 730)
