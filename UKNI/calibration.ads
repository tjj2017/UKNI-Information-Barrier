----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Calibration
--  Stored Filename: $Id: Calibration.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               Calibration routines for IB Phase 3
--  *            Calibrates off a Eu152 Source
--  </description>
----------------------------------------------------------------------

with Calibration_Peak,
     Channel_Types,
     Region_Of_Interest;

use type Channel_Types.Data_Channel_Number;

--# inherit ADC,
--#         Calibration_Peak,
--#         Channel_Types,
--#         Count_Types,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Registers,
--#         Timeouts,
--#         Timer,
--#         Toolbox.Currie,
--#         Toolbox.FWHM,
--#         Toolbox.Peak_Net_Area,
--#         Toolbox.Peak_Search,
--#         Usart_Types,
--#         Usart1;

package Calibration
--# own State : State_Type;
--# initializes State;

is
   --# type State_Type is abstract;
   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  Number of allowable channels below theoretical peak location
   MIN_PEAK_VARIANCE : constant := 64;

   --  Number of allowable channels above theoretical peak location
   MAX_PEAK_VARIANCE : constant := 63;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  Channel range to look for the upper calibration peak
   subtype Eu152_778_ROI_Range is Channel_Types.Data_Channel_Number range
     (Calibration_Peak.EU152_778_CENTRE_CHANNEL - MIN_PEAK_VARIANCE) ..
     (Calibration_Peak.EU152_778_CENTRE_CHANNEL + MAX_PEAK_VARIANCE);

   --  Channel range to look for the lower calibration peak
   subtype Eu152_121_ROI_Range is Channel_Types.Data_Channel_Number range
     (Calibration_Peak.EU152_121_CENTRE_CHANNEL - MIN_PEAK_VARIANCE) ..
     (Calibration_Peak.EU152_121_CENTRE_CHANNEL + MAX_PEAK_VARIANCE);

   --  Define a type for the maximum displacement of the calibration peaks
   subtype Calibration_Offset_Type is Integer range
     -Integer (Channel_Types.Data_Channel_Number'Last) ..
     Integer (Channel_Types.Data_Channel_Number'Last);

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Perform_Calibration</name>
   --  <description>
   --               Perform the calibration on the IB and return whether the
   --               calibration has been successful
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Is_Successful">
   --               True if the calibration has been successful.
   --  </output>
   -------------------------------------------------------------------
   procedure Perform_Calibration (Is_Successful : out Boolean);
   --# global in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out State;
   --#           out Timer.Setup;
   --# derives ADC.State,
   --#         Is_Successful,
   --#         Timer.Setup   from ADC.State,
   --#                            Timer.Timeout &
   --#         State         from *,
   --#                            ADC.State,
   --#                            Timer.Timeout;
   pragma Inline (Perform_Calibration);

   -------------------------------------------------------------------
   --  <name> Verify_Calibration </name>
   --  <description>
   --               Capture the distribution associated with the calibration
   --               Region of Interest (ROI) and check whether the upper and
   --               lower calibration peaks are within agreed tolerance
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Is_Successful">
   --    True if the calibration peaks are within tolerance.
   --  </output>
   -------------------------------------------------------------------
   procedure Verify_Calibration (Is_Successful : out Boolean);
   --# global in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out State;
   --#           out Timer.Setup;
   --# derives ADC.State,
   --#         State         from *,
   --#                            ADC.State,
   --#                            Timer.Timeout &
   --#         Is_Successful from ADC.State,
   --#                            State,
   --#                            Timer.Timeout &
   --#         Timer.Setup   from ;
   pragma Inline (Verify_Calibration);

   -------------------------------------------------------------------
   --  <name> Get_Offset </name>
   --  <description>
   --               Return the currently stored calibration offset value
   --  </description>
   --  <input name="None">
   --  </input>
   --  <returns>
   --               The current stored calibration offset value.
   --  </returns>
   -------------------------------------------------------------------
   function Get_Offset return Calibration_Peak.Offset_Type;
   --# global in State;
   pragma Inline (Get_Offset);

   -------------------------------------------------------------------
   --  <name> Full_Reset </name>
   --  <description> Resets the attenuator values to their default
   --  </description>
   --  <input name="None">
   --  </input>.
   --  <output name="None">
   --  </output>.
   -------------------------------------------------------------------
   procedure Full_Reset;
   --# global in out State;
   --# derives State from *;
   pragma Inline (Full_Reset);

private
   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  Define a type for the region of interest for the upper calibration peaks
   subtype Upper_Peak_Type is
     Region_Of_Interest.Region_Of_Interest_Type (Eu152_778_ROI_Range);

   --  Define a type for the region of interest for the lower calibration peaks
   subtype Lower_Peak_Type is
     Region_Of_Interest.Region_Of_Interest_Type (Eu152_121_ROI_Range);

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  Definition for the lower calibration peak
   --  Provides reference access to the channels describing
   --  the lower, upper and central locations of the peaks.
   EU152_121_PEAK_REFERENCE : constant
     Calibration_Peak.Peak_Record_Type := Calibration_Peak.Peak_Record_Type'
       (Centre_Channel             => Calibration_Peak.EU152_121_CENTRE_CHANNEL,
        Search_Region_Low_Channel  => Calibration_Peak.EU152_121_CENTRE_CHANNEL - MIN_PEAK_VARIANCE,
        Search_Region_High_Channel => Calibration_Peak.EU152_121_CENTRE_CHANNEL + MAX_PEAK_VARIANCE);

   --  Definition for the upper calibration peak
   --  Provides reference access to the channels describing
   --  the lower, upper and central locations of the peaks.
   EU152_778_PEAK_REFERENCE : constant
     Calibration_Peak.Peak_Record_Type := Calibration_Peak.Peak_Record_Type'
       (Centre_Channel             => Calibration_Peak.EU152_778_CENTRE_CHANNEL,
        Search_Region_Low_Channel  => Calibration_Peak.EU152_778_CENTRE_CHANNEL - MIN_PEAK_VARIANCE,
        Search_Region_High_Channel => Calibration_Peak.EU152_778_CENTRE_CHANNEL + MAX_PEAK_VARIANCE);

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Clear_Calibration_ROIs </name>
   --  <description>
   --               Clear the upper and lower calibration ROIs
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Clear_Calibration_ROIs;
   --# global in out State;
   --# derives State from *;

   -------------------------------------------------------------------
   --  <name> Gather_Calibration_Data </name>
   --  <description>
   --               Collects the calibration data
   --  </description>
   --  <input name="Timed_Out">
   --              Flag stating whether the timer has timed out
   --  </input>
   --  <output name="Timed_Out">
   --              Flag stating whether the timer has timed out
   --  </output>
   -------------------------------------------------------------------
   procedure Gather_Calibration_Data (Timed_Out : in out Boolean);
   --# global in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out State;
   --# derives ADC.State,
   --#         State,
   --#         Timed_Out from *,
   --#                        ADC.State,
   --#                        Timed_Out,
   --#                        Timer.Timeout;

   -------------------------------------------------------------------
   --  <name> Find_Calibration_Centroids </name>
   --  <description>
   --               Calculate the centroids of the calibration peaks
   --  </description>
   --  <input name="Upper_Search_Array">
   --              The upper calibration search array
   --  </input><input name="Lower_Search_Array">
   --              The lower calibration search array
   --  </input>
   --  <output name="Upper_Peak_Location">
   --              The location of the upper calibration peak
   --  </output>
   --  <output name="Lower_Peak_Location">
   --              The location of the lower calibration peak
   --  </output>
   -------------------------------------------------------------------
   procedure Find_Calibration_Centroids (Upper_Search_Array   : in  Upper_Peak_Type;
                                         Lower_Search_Array   : in  Lower_Peak_Type;
                                         Upper_Peak_Centroid  : out Channel_Types.Data_Channel_Number;
                                         Lower_Peak_Centroid  : out Channel_Types.Data_Channel_Number;
                                         Upper_Peak_Found     : out Boolean;
                                         Lower_Peak_Found     : out Boolean);
   --# derives Lower_Peak_Centroid,
   --#         Lower_Peak_Found    from Lower_Search_Array &
   --#         Upper_Peak_Centroid,
   --#         Upper_Peak_Found    from Upper_Search_Array;
   --# post Upper_Peak_Centroid <= Upper_Search_Array'Last + 1 and
   --#      Upper_Peak_Centroid >= Upper_Search_Array'First and
   --#      Lower_Peak_Centroid <= Lower_Search_Array'Last + 1 and
   --#      Lower_Peak_Centroid >= Lower_Search_Array'First;
   pragma Inline (Find_Calibration_Centroids);

   -------------------------------------------------------------------
   --  <name> Perform_Two_Point_Calibration </name>
   --  <description>
   --               Performs a two point calibration on the IB
   --  </description>
   --  <input name="Lower_Calibration_Peak">
   --               The details of the lower calibration peak.
   --  </input><input name="Upper_Calibration_Peak">
   --               The details of the upper calibration peak.
   --  </input>
   --  <output name="Is_Successful">
   --               True if the calibration was successful.
   --  </output>
   -------------------------------------------------------------------
   procedure Perform_Two_Point_Calibration (Is_Successful : out Boolean);
   --# global in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out State;
   --#           out Timer.Setup;
   --# derives ADC.State,
   --#         Is_Successful,
   --#         Timer.Setup   from ADC.State,
   --#                            Timer.Timeout &
   --#         State         from *,
   --#                            ADC.State,
   --#                            Timer.Timeout;

end Calibration;
