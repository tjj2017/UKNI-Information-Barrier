  This software is made available under the Open Government License v3.0.

  Please attribute to
     United Kingdom - Norway Initiative, http://ukni.info (2016)

**********************************************************************
                          Introduction
**********************************************************************

This readme is intended as a quick introduction into how to build, run
and analyse the Ada UKNI IB.  More details on the code and the  
compilation and analysis setup can be found in the IB Software 
Development Report.  Note: The build and analysis processes have
been changed for ASVAT and may not be the same as documented in
the report.

The following topics are presented
* building the code from the command line
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
* open up a terminal
* change directory into the build folder
   (where UKNI-Information-Barrier/IB_Phase3_Build
    is an existing folder to build into)
   > cd UKNI-Information-Barrier/IB_Phase3_Build
* type the following into the prompt
   (where UKNI-Information-Barrier/UKNI contains the source code)
    > gprbuild -d -P../UKNI/ukni.gpr Main.adb -s

**********************************************************************
               Analysing the code from the command line
**********************************************************************
To analyse the code from the command line, perform the following steps
(where > is used to denote the command prompt)
* open up a command prompt
* change the current directory to the folder containing the source code
   > cd UKNI-Information-Barrier/UKNI
* clean the old analysis files
   > sparkclean
* use the SPARK examiner to examine the files
   > spark -pl -flow_analysis=information -html -index_file=main.idx -vcg -config=config.cfg -error_explanations=first -dpc -language=2005 -statistics -warning_file=warnings.wrn -output_directory=SPARK_Output -casing -rules=keen @main.smf
* change directory to the SPARK output folder
    > cd SPARK_Output 
* run the Spark simplifier
   > sparksimp -p=4 -victor -vargs "-solver=z3"
   (-p=4 indicates the number of processor cores available to use)
* change directory to where all the output files are stored
   > cd UKNI-Information-Barrier/UKNI/SPARK_Output
*  run the Proof ObliGation Summariser tool to collate the results
   > pogs -i
   

**********************************************************************
                          Toolsets used
**********************************************************************
The following toolsets were used:
* GPS 2016 (20160515)
* GNAT GPL 2016 (20160515-49)
* SPARK-GPL-2012
