----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement
--  Stored Filename: $Id: Measurement.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               Package containing the operations required to capture the
--  *            measurement data and to initialise the analysis of the data
--  </description>
----------------------------------------------------------------------

--# inherit ADC,
--#         Calibration,
--#         Calibration_Peak,
--#         Channel_Types,
--#         Count_Types,
--#         Measurement_Peaks,
--#         Measurement_Peaks.Curve_Fit,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Timeouts,
--#         Timer,
--#         Toolbox.Currie,
--#         Toolbox.FWHM,
--#         Toolbox.Maths,
--#         Toolbox.Peak_Net_Area,
--#         Toolbox.Peak_Search,
--#         Usart_Types,
--#         Usart1;

package Measurement
--# own Data_Store : Data_Store_Type;
is

   --# type Data_Store_Type is abstract;

   -------------------------------------------------------------------
   --  Proof Functions
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Is_Empty_PF </name>
   --  <description>
   --     Proof function stating that the data store has been cleared
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns">
   --     Boolean flag stating whether the data store has been cleared
   --  </Returns>
   -------------------------------------------------------------------
   --# function Is_Empty_PF(Data_Store :  Data_Store_Type) return Boolean;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Perform_Measurement </name>
   --  <description>
   --     Capture the data required for analysis of Pu239 and the Pu240:Pu239 ratio
   --  *  and perform analysis on that data
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Is_Present">
   --     Boolean flag stating whether Pu239 has been determined to be present and
   --  *  whether the isotopic ratio test has been passed
   --  </output>
   -------------------------------------------------------------------
   procedure Perform_Measurement (Is_Present : out Boolean);
   --# global in     Calibration.State;
   --#        in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out Measurement_Peaks.State;
   --#           out Data_Store;
   --#           out Timer.Setup;
   --# derives ADC.State               from *,
   --#                                      Timer.Timeout &
   --#         Data_Store,
   --#         Timer.Setup             from  &
   --#         Is_Present,
   --#         Measurement_Peaks.State from ADC.State,
   --#                                      Calibration.State,
   --#                                      Measurement_Peaks.State,
   --#                                      Timer.Timeout;
   pragma Inline (Perform_Measurement);

   -------------------------------------------------------------------
   --  <name> Clear_Store </name>
   --  <description>
   --     Set the data store for both the isotopic ROI and the identification ROI
   --  *  to zero
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Clear_Store;
   --# global out Data_Store;
   --# derives Data_Store from ;
   --# post Is_Empty_PF(Data_Store);
   pragma Inline (Clear_Store);

private

   -------------------------------------------------------------------
   --  <name> Measurement_Calculations </name>
   --  <description>
   --     Perform analysis on the isotopic and identification ROI data to
   --  *  determine the presence of Pu239 and the Pu240:Pu239 ratio
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Is_Present">
   --     Boolean flag stating whether Pu239 has been determined to be present and
   --  *  whether the isotopic ratio test has been passed
   --  </output>
   -------------------------------------------------------------------
   procedure Measurement_Calculations (Is_Present : out Boolean);
   --# global in     Data_Store;
   --#        in out Measurement_Peaks.State;
   --# derives Is_Present,
   --#         Measurement_Peaks.State from Data_Store,
   --#                                      Measurement_Peaks.State;

   -------------------------------------------------------------------
   --  <name> Gather_Data </name>
   --  <description>
   --     Capture the data required for analysis of Pu239 and the Pu240:Pu239 ratio
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Target_Counts_Reached">
   --     Boolean flag stating that sufficient counts had been captured in the
   --  *  413 keV peak
   --  </output>
   -------------------------------------------------------------------
   procedure Gather_Data (Target_Counts_Reached : out Boolean);
   --# global in     Calibration.State;
   --#        in     Timer.Timeout;
   --#        in out ADC.State;
   --#           out Data_Store;
   --#           out Timer.Setup;
   --# derives ADC.State             from *,
   --#                                    Timer.Timeout &
   --#         Data_Store,
   --#         Target_Counts_Reached from ADC.State,
   --#                                    Calibration.State,
   --#                                    Timer.Timeout &
   --#         Timer.Setup           from ;

   -------------------------------------------------------------------
   --  <name> Dump_Measurement_Data </name>
   --  <description>
   --     Engineering use subprogramme sending measurement information to the
   --  *  debug port
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Dump_Measurement_Data;
   --# derives;

end Measurement;
