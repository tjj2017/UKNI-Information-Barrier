----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Calibration
--  Stored Filename: $Id: Calibration.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: Calibration routines for IB Phase 3
--               Calibrates off a Eu152 Source
----------------------------------------------------------------------
with ADC,
     Calibration.Gain_Adjustment,
     Count_Types,
     Mod_Types,
     Timeouts,
     Timer,
     Toolbox.Peak_Search,
     Toolbox.Peak_Net_Area,
     Toolbox.FWHM,
     Toolbox.Currie,
     Usart1;

use type Mod_Types.Unsigned_8,
    Mod_Types.Unsigned_32,
    Mod_Types.Unsigned_64;

package body Calibration
--# own State is
--#      Calibration.Gain_Adjustment.State,
--#      Lower_Peak_ROI,
--#      Offset,
--#      Upper_Peak_ROI;
is
   -------------------------------------------------------------------
   --  Variables
   -------------------------------------------------------------------
   Offset : Calibration_Peak.Offset_Type := 0; --  The current calibration offset

   --  Variables to contain the uppper and lower ROIs
   Upper_Peak_ROI                  : Upper_Peak_Type;
   --# accept F, 31, Upper_Peak_ROI, "Initially defined outside of SPARK scope";
   --# accept F, 32, Upper_Peak_ROI, "Initially defined outside of SPARK scope";

   Lower_Peak_ROI                  : Lower_Peak_Type;
   --# accept F, 31, Lower_Peak_ROI, "Initially defined outside of SPARK scope";
   --# accept F, 32, Lower_Peak_ROI, "Initially defined outside of SPARK scope";

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------
   --  The number of channels that the calibration verify centre channel can differ
   --  from the stored offset
   VERIFICATION_TOLERANCE : constant := 1;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Full_Reset
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Full_Reset
   --# global in out Gain_Adjustment.State;
   --# derives Gain_Adjustment.State from *;
   is
   begin
      Gain_Adjustment.Reset;
   end Full_Reset;

   -------------------------------------------------------------------
   --  Name       : Dump_Cal_Data
   --  Description: Engineering use only
   --               Send the calibration distribution to usart1
   --  Inputs     : Peak_Boundaries - the upper, lower and central channels of the calibration peak.
   --               Peak_ROI - the captured region of interest
   --               ROI_Name - the name to be printed to aid understanding of the output
   --  Outputs    : None.
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Dump_Cal_Data (Peak_Boundaries : in Calibration_Peak.Peak_Record_Type;
                            Peak_ROI        : in Region_Of_Interest.Region_Of_Interest_Type;
                            ROI_Name        : in String)
   --# derives null from Peak_Boundaries,
   --#                   Peak_ROI,
   --#                   ROI_Name;
   is
      --  This procedure is hidden because
      --  1. This procedure is for engineering use only and its assurance is
      --     not part of the evidance pack
      --  2. This procedure calls the usart1 package which contains directives
      --     below the SPARK layer of influence
      --  3. All non-usart calls are analysed elsewhere or are not part of normal
      --     execution flow
      --# hide Dump_Cal_Data;

      --  The centre peak of the passed in distribution
      Peak_Centre              : Channel_Types.Data_Channel_Number;
      Centroid                 : Channel_Types.Extended_Channel_Type;

      --  The net peak area of the passed in distribution
      Net_Peak_Area            : Mod_Types.Unsigned_32;

      --  The FWHM of the passed in distribution
      FWHM                     : Mod_Types.Unsigned_32;

      --  Definition of how the peak is seperated into peaks and background
      Peak_ROI_Locations       : Region_Of_Interest.Peak_ROI_Locations_Type;

      --  Flag to determine whether the currie ciritical test has been passed
      Currie_Crit_Limit_Passed : Boolean;

      --  Flag stating whether Find_Centroid successfully located the centroid
      Peak_Found               : Boolean;

   begin

      --  Send the header string
      Usart1.Send_String (Item => "Spectrum in ROI (");
      Usart1.Send_String (Item => ROI_Name);
      Usart1.Send_String (Item => "):");
      Usart1.Send_Message_New_Line;

      --  Send the recorded ROI in csv format
      for I in Channel_Types.Data_Channel_Number range
        Peak_Boundaries.Search_Region_Low_Channel ..
          Peak_Boundaries.Search_Region_High_Channel loop

         Usart1.Send_Message_16 (Data => (I));
         Usart1.Send_String (Item => ",");
         Usart1.Send_Message_16 (Data => (Peak_ROI (I)));
         Usart1.Send_Message_New_Line;

      end loop;
      Usart1.Send_Message_New_Line;

      --  Calculate the peak centre and associated backgrounds
      Toolbox.Peak_Search.Find_Centroid (Search_Array => Peak_ROI,
                                         Centroid       => Centroid,
                                         Is_Successful => Peak_Found);

      if not Peak_Found then
         Usart1.Send_String (Item => "Dump_Cal_Data: Find Centroid Failed");
         Usart1.Send_Message_New_Line;
      end if;

      Peak_Centre := Mod_Types.Unsigned_16 (Centroid / Toolbox.MULT);

      Peak_ROI_Locations := (Ideal_Centre_Channel => Peak_Centre,
                             Background1_LL       => Peak_Centre - 16,
                             Background1_UL       => Peak_Centre - 12,
                             Peak_LL              => Peak_Centre - 9,
                             Peak_UL              => Peak_Centre + 9,
                             Background2_LL       => Peak_Centre + 12,
                             Background2_UL       => Peak_Centre + 16);

      --  Calculate the net peak area of the ROI
      Net_Peak_Area := Toolbox.Peak_Net_Area.Calculate_Peak_Net_Area
        (Peak_ROI_Locations => Peak_ROI_Locations,
         Peak_ROI           => Peak_ROI);

      --  Send the netpeak area of the passed in peak
      Usart1.Send_String (Item => "Net Peak Area: ");
      Usart1.Send_Message_32 (Data => (Net_Peak_Area));
      Usart1.Send_Message_New_Line;
      Usart1.Send_Message_New_Line;

      --  Calculatge the Full Width Half Maximum (FWHM)
      FWHM := Toolbox.FWHM.FWHM_Channels (Peak_ROI_Locations => Peak_ROI_Locations,
                                          Peak_ROI           => Peak_ROI);

      --  Send the FWHM of the passed in peak
      Usart1.Send_String (Item => "FWHM: ");
      Usart1.Send_Message_32 (Data => (FWHM));
      Usart1.Send_Message_New_Line;
      Usart1.Send_Message_New_Line;

      if Peak_ROI_Locations.Background1_UL - Peak_ROI_Locations.Background1_LL + 1 < 64 and then
        Peak_ROI_Locations.Background2_UL - Peak_ROI_Locations.Background2_LL + 1 < 64 and then
        Peak_ROI_Locations.Peak_UL - Peak_ROI_Locations.Peak_LL + 1 < 64 then
         --  Calculate if the peak in the passed in ROI meets the Currie Critical Limit Test
         --  Only one peak in the ROI, therefor the search and peak ROI are the same
         Currie_Crit_Limit_Passed := Toolbox.Currie.Critical_Limit
           (Confidence         => Toolbox.Currie.CONFIDENCE_95_PERCENT,
            Peak_ROI_Locations => Peak_ROI_Locations,
            Peak_ROI           => Peak_ROI);
      else
         Currie_Crit_Limit_Passed := False;
      end if;

      --  Send whether the currie critical limit test has been passed
      if Currie_Crit_Limit_Passed then
         Usart1.Send_String (Item => "Currie CL Passed");
      else
         Usart1.Send_String (Item => "Currie CL Failed");
      end if;
      Usart1.Send_Message_New_Line;
      Usart1.Send_Message_New_Line;

   end Dump_Cal_Data;
   pragma Inline (Dump_Cal_Data);

   -------------------------------------------------------------------
   --  Name       : Clear_Calibration_ROIs
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Clear_Calibration_ROIs
   --# global out Lower_Peak_ROI;
   --#        out Upper_Peak_ROI;
   --# derives Lower_Peak_ROI,
   --#         Upper_Peak_ROI from ;
   --# post (for all I in Eu152_778_ROI_Range => (Upper_Peak_ROI(I) = 0)) and
   --#      (for all I in Eu152_121_ROI_Range => (Lower_Peak_ROI(I) = 0));
   is
      --# hide Clear_Calibration_ROIs;
   begin
      --  hidden body, as array initialisation done via loop
      --  avoiding expensive memory constant array
      for I in Eu152_778_ROI_Range loop
         Upper_Peak_ROI (I) := 0;
      end loop;

      for I in Eu152_121_ROI_Range loop
         Lower_Peak_ROI (I) := 0;
      end loop;

   end Clear_Calibration_ROIs;

   -------------------------------------------------------------------
   --  Name       : Gather_Calibration_Data
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Gather_Calibration_Data (Timed_Out : in out Boolean)
   --# global in     Timer.Timeout;
   --#        in out ADC.State;
   --#           out Lower_Peak_ROI;
   --#           out Upper_Peak_ROI;
   --# derives ADC.State,
   --#         Lower_Peak_ROI,
   --#         Timed_Out,
   --#         Upper_Peak_ROI from ADC.State,
   --#                             Timed_Out,
   --#                             Timer.Timeout;
   is

      --  The number of counts in the ROIs
      Upper_Peak_Counts               : Count_Types.Calibration_Count_Type := 0;
      Lower_Peak_Counts               : Count_Types.Calibration_Count_Type := 0;

      --  The current ADC reading
      ADC_Reading                     : Channel_Types.Data_Channel_Number;
   begin
      Clear_Calibration_ROIs;

      --  Gather the data and if appropriate store in the appropriate ROI
      --  exit loop if timed out or sufficient counts have been stored
      Data_Gathering_Loop          :
      while ((Upper_Peak_Counts < Count_Types.MAX_CALIBRATION_COUNTS) or
               (Lower_Peak_Counts < Count_Types.MAX_CALIBRATION_COUNTS)) and
        not Timed_Out
      loop
         --# assert (Upper_Peak_Counts < Count_Types.MAX_CALIBRATION_COUNTS or
         --#         Lower_Peak_Counts < Count_Types.MAX_CALIBRATION_COUNTS);
         ADC.Get_Reading (Reading           => ADC_Reading);
         if ADC_Reading >= EU152_778_PEAK_REFERENCE.Search_Region_Low_Channel and then
           ADC_Reading <= EU152_778_PEAK_REFERENCE.Search_Region_High_Channel and then
           Upper_Peak_Counts < Count_Types.MAX_CALIBRATION_COUNTS and then
           Upper_Peak_ROI (ADC_Reading) < Count_Types.MAX_CALIBRATION_COUNTS then

            Upper_Peak_ROI (ADC_Reading) := Upper_Peak_ROI (ADC_Reading) + 1;
            Upper_Peak_Counts := Upper_Peak_Counts + 1;

         elsif ADC_Reading >= EU152_121_PEAK_REFERENCE.Search_Region_Low_Channel and then
           ADC_Reading <= EU152_121_PEAK_REFERENCE.Search_Region_High_Channel and then
           Lower_Peak_Counts < Count_Types.MAX_CALIBRATION_COUNTS and then
           Lower_Peak_ROI (ADC_Reading) < Count_Types.MAX_CALIBRATION_COUNTS then

            Lower_Peak_ROI (ADC_Reading) := Lower_Peak_ROI (ADC_Reading) + 1;
            Lower_Peak_Counts := Lower_Peak_Counts + 1;

         end if;
         Timed_Out := Timer.Check_Timeout;

      end loop Data_Gathering_Loop;
   end Gather_Calibration_Data;

   -------------------------------------------------------------------
   --  Name       : Find_Calibration_Centroids
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Find_Calibration_Centroids (Upper_Search_Array   : in  Upper_Peak_Type;
                                         Lower_Search_Array   : in  Lower_Peak_Type;
                                         Upper_Peak_Centroid  : out Channel_Types.Data_Channel_Number;
                                         Lower_Peak_Centroid  : out Channel_Types.Data_Channel_Number;
                                         Upper_Peak_Found     : out Boolean;
                                         Lower_Peak_Found     : out Boolean)
   is
      --  Temporary variable to store the centroid in
      Centroid : Channel_Types.Extended_Channel_Type;
   begin

      --  Calculate the peak locations
      Toolbox.Peak_Search.Find_Centroid (Search_Array   => Upper_Search_Array,
                                         Centroid       => Centroid,
                                         Is_Successful  => Upper_Peak_Found);

      if Channel_Types.Extended_Channel_Type'(Centroid rem Toolbox.MULT) >
        Channel_Types.Extended_Channel_Type (Toolbox.MULT / 2) then
         Upper_Peak_Centroid := Channel_Types.Data_Channel_Number (Centroid / Toolbox.MULT) + 1;
      else
         Upper_Peak_Centroid := Channel_Types.Data_Channel_Number (Centroid / Toolbox.MULT);
      end if;

      Toolbox.Peak_Search.Find_Centroid (Search_Array   => Lower_Search_Array,
                                         Centroid       => Centroid,
                                         Is_Successful => Lower_Peak_Found);

      if Channel_Types.Extended_Channel_Type'(Centroid rem Toolbox.MULT) >
        Channel_Types.Extended_Channel_Type (Toolbox.MULT / 2) then
         Lower_Peak_Centroid := Channel_Types.Data_Channel_Number (Centroid / Toolbox.MULT) + 1;
      else
         Lower_Peak_Centroid := Channel_Types.Data_Channel_Number (Centroid / Toolbox.MULT);
      end if;
   end Find_Calibration_Centroids;

   -------------------------------------------------------------------
   --  Name       : Perform_Two_Point_Calibration
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Perform_Two_Point_Calibration
     (Is_Successful          : out Boolean)
   --# global in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out Gain_Adjustment.State;
   --#           out Lower_Peak_ROI;
   --#           out Offset;
   --#           out Timer.Setup;
   --#           out Upper_Peak_ROI;
   --# derives ADC.State,
   --#         Is_Successful,
   --#         Lower_Peak_ROI,
   --#         Offset,
   --#         Timer.Setup,
   --#         Upper_Peak_ROI        from ADC.State,
   --#                                    Timer.Timeout &
   --#         Gain_Adjustment.State from *,
   --#                                    ADC.State,
   --#                                    Timer.Timeout;

   is

      --  Flag for whether the calibration has run for the maximum allowable time
      Is_Timed_Out                    : Boolean;

      --  The number of channels the peaks are offset by
      Lower_Peak_Offset               : Calibration_Offset_Type;
      Upper_Peak_Offset               : Calibration_Offset_Type;

      --  The target channel for the upper peak to be in during course calibration
      Target_Channel                  : Channel_Types.Data_Channel_Number;

      --  Types for use in the Iteration checks
      subtype Adjustment_Type is Mod_Types.Unsigned_8 range 1 .. 10;
      subtype Course_Adjustment_Type is Adjustment_Type range 1 .. 3;

      --  Location of the upper calibration peak
      Upper_Peak_Location             : Channel_Types.Data_Channel_Number;

      --  Locations of the lower calibration peak
      Lower_Peak_Location             : Channel_Types.Data_Channel_Number;

      --  Boolean flags stating whether find centroid returned a valid result
      High_Peak_Found                 : Boolean;
      Lo_Peak_Found                   : Boolean;

   begin
      --  Engineering use: print statements to identify where in the operating
      --  cycle the system is
      Usart1.Send_String (Item => ("Calibrating"));
      Usart1.Send_Message_New_Line;
      Usart1.Send_String (Item => ("Gathering Data"));
      Usart1.Send_Message_New_Line;

      --  The Data gathering / calibration attenuator adjustment cycle:
      --  On the early iterations, the loop attempts to predict the correct gain
      --  adjustment based on the number of channels of error in the upper and lower
      --  peaks. The assumption here is that the upper peak is dominated by gain
      --  errors and the lower peak dominated by DC offset
      --  On subsequent iterations, the gain adjustment is merely step by step
      --  until the offset of the two peaks equalises.
      for Iteration in Adjustment_Type loop
         --# assert Iteration in Adjustment_Type;
         --  Engineering use: print statements to identify which iteration the
         --  calibration is on
         Usart1.Send_String (Item => "Iteration: ");
         Usart1.Send_Message_8 (Data => Iteration);
         Usart1.Send_Message_New_Line;

         --  set the timeout for this iteration of the calibration adjustment cycle
         Timer.Set_Timeout_Seconds (The_Interval => Timeouts.CALIBRATION);
         Timer.Init;
         Is_Timed_Out := Timer.Check_Timeout;

         --  Note that Is_Timed_Out is only used to exit this loop after the
         --  calibration data is output using the engineering use functionality
         Gather_Calibration_Data (Timed_Out => Is_Timed_Out);

         --  Calculate the peak locations
         Find_Calibration_Centroids (Upper_Search_Array  => Upper_Peak_ROI,
                                     Lower_Search_Array  => Lower_Peak_ROI,
                                     Upper_Peak_Centroid => Upper_Peak_Location,
                                     Lower_Peak_Centroid => Lower_Peak_Location,
                                     Upper_Peak_Found    => High_Peak_Found,
                                     Lower_Peak_Found    => Lo_Peak_Found);

         --  From the calculations determine the offset from the theoretical channels
         Upper_Peak_Offset := Calibration_Offset_Type (Upper_Peak_Location) -
           Calibration_Offset_Type (EU152_778_PEAK_REFERENCE.Centre_Channel);
         Lower_Peak_Offset := Calibration_Offset_Type (Lower_Peak_Location) -
           Calibration_Offset_Type (EU152_121_PEAK_REFERENCE.Centre_Channel);

         --  Engineering use:  print the details of the upper peak
         Dump_Cal_Data (Peak_Boundaries => EU152_778_PEAK_REFERENCE,
                        Peak_ROI        => Upper_Peak_ROI,
                        ROI_Name        => "778keV peak");
         Usart1.Send_String (Item => "Peak_Position:");
         Usart1.Send_Message_16 (Data => Upper_Peak_Location);
         Usart1.Send_Message_New_Line;

         --  Engineering use: print the details of the lower peak
         Dump_Cal_Data (Peak_Boundaries => EU152_121_PEAK_REFERENCE,
                        Peak_ROI        => Lower_Peak_ROI,
                        ROI_Name        => "121keV peak");
         Usart1.Send_String (Item => "Peak_Position:");
         Usart1.Send_Message_16 (Data => Lower_Peak_Location);
         Usart1.Send_Message_New_Line;

         --  Calibration is finished if a time out has occured or
         --  the offset for the upper and lower calibration peaks are the same
         exit when Is_Timed_Out or
           (Upper_Peak_Offset = Lower_Peak_Offset and
            High_Peak_Found and Lo_Peak_Found);

         --  Apply the appropriate adjustment to the gain
         if not High_Peak_Found or else not Lo_Peak_Found then
            --  do nothing
            null;
         elsif Iteration in Course_Adjustment_Type then

            Target_Channel := Channel_Types.Data_Channel_Number (Integer
                  (EU152_778_PEAK_REFERENCE.Centre_Channel) + Lower_Peak_Offset);
            Gain_Adjustment.Adjust_Gain (Peak_Location => Upper_Peak_Location,
                                         Ideal_Channel => Target_Channel);

         elsif Upper_Peak_Offset > Lower_Peak_Offset then

            Gain_Adjustment.Decrease;

         else

            Gain_Adjustment.Increase;

         end if;

         --  Engineering use: print statement for end of iteration
         Usart1.Send_String (Item => "End Iteration:");
         Usart1.Send_Message_8 (Data => Iteration);
         Usart1.Send_Message_New_Line;
         Usart1.Send_Message_New_Line;

      end loop;

      --  Check if the calibration has been successful, and return flag accordingly
      if (Upper_Peak_Offset = Lower_Peak_Offset) and
        Upper_Peak_Offset in Calibration_Peak.Offset_Type and
        High_Peak_Found and Lo_Peak_Found and
        not Is_Timed_Out then

         Is_Successful := True;
         Offset := Upper_Peak_Offset;

      else

         Usart1.Send_String (Item => "Upper_Peak_Offset: ");
         if Upper_Peak_Offset < 0 then
            Usart1.Send_String (Item => "-");
            Usart1.Send_Message_32 (Data => Mod_Types.Unsigned_32 (-Upper_Peak_Offset));
         else
            Usart1.Send_Message_32 (Data => Mod_Types.Unsigned_32 (Upper_Peak_Offset));
         end if;
         Usart1.Send_Message_New_Line;

         Usart1.Send_String (Item => "Lower_Peak_Offset: ");
         if Lower_Peak_Offset < 0 then
            Usart1.Send_String (Item => "-");
            Usart1.Send_Message_32 (Data => Mod_Types.Unsigned_32 (-Lower_Peak_Offset));
         else
            Usart1.Send_Message_32 (Data => Mod_Types.Unsigned_32 (Lower_Peak_Offset));
         end if;
         Usart1.Send_Message_New_Line;

         if High_Peak_Found then
            Usart1.Send_String (Item => "Hi Peak Found");
         else
            Usart1.Send_String (Item => "Hi Peak Not Found");
         end if;
         Usart1.Send_Message_New_Line;

         if Lo_Peak_Found then
            Usart1.Send_String (Item => "Lo Peak Found");
         else
            Usart1.Send_String (Item => "Lo Peak Not Found");
         end if;
         Usart1.Send_Message_New_Line;

         if Is_Timed_Out then
            Usart1.Send_String (Item => "Timed Out");
         else
            Usart1.Send_String (Item => "Is not Timed Out");
         end if;
         Usart1.Send_Message_New_Line;

         Is_Successful := False;
         Offset := 0; -- default value

      end if;

   end Perform_Two_Point_Calibration;

   -------------------------------------------------------------------
   --  Name       : Perform_Calibration
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Perform_Calibration (Is_Successful : out Boolean)
   --# global in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out Gain_Adjustment.State;
   --#           out Lower_Peak_ROI;
   --#           out Offset;
   --#           out Timer.Setup;
   --#           out Upper_Peak_ROI;
   --# derives ADC.State,
   --#         Is_Successful,
   --#         Lower_Peak_ROI,
   --#         Offset,
   --#         Timer.Setup,
   --#         Upper_Peak_ROI        from ADC.State,
   --#                                    Timer.Timeout &
   --#         Gain_Adjustment.State from *,
   --#                                    ADC.State,
   --#                                    Timer.Timeout;
   is

   begin
      --  reset the attenuators to their default values
      Full_Reset;

      --  perform a 2 point calibration using Europium's 121 and 778 peaks
      Perform_Two_Point_Calibration (Is_Successful          => Is_Successful);

      --  Engineering use: Return whether calibration was successful
      Usart1.Send_String (Item => "Calibration ");
      if Is_Successful then
         Usart1.Send_String (Item => "Successful");
         Usart1.Send_Message_New_Line;
      else
         Usart1.Send_String (Item => "Failed");
         Usart1.Send_Message_New_Line;
      end if;

   end Perform_Calibration;

   -------------------------------------------------------------------
   --  Name       : Get_Offset
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Get_Offset return Calibration_Peak.Offset_Type
   --# global in Offset;
   is
   begin
      return Offset;
   end Get_Offset;

   -------------------------------------------------------------------
   --  Name       : Verify_Calibration
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Verify_Calibration (Is_Successful : out Boolean)
   --# global in     Offset;
   --#        in     Timer.Timeout;
   --#        in out ADC.State;
   --#           out Lower_Peak_ROI;
   --#           out Timer.Setup;
   --#           out Upper_Peak_ROI;
   --# derives ADC.State,
   --#         Lower_Peak_ROI,
   --#         Upper_Peak_ROI from ADC.State,
   --#                             Timer.Timeout &
   --#         Is_Successful  from ADC.State,
   --#                             Offset,
   --#                             Timer.Timeout &
   --#         Timer.Setup    from ;
   is

      --  Definitions of the upper and lower calibration peaks
      LOWER_CALIBRATION_PEAK          : constant Calibration_Peak.Peak_Record_Type := EU152_121_PEAK_REFERENCE;
      UPPER_CALIBRATION_PEAK          : constant Calibration_Peak.Peak_Record_Type := EU152_778_PEAK_REFERENCE;

      --  Flag for whether the calibration has run for the maximum allowable time
      Is_Timed_Out                    : Boolean;
      --  Locations of the peaks
      Upper_Peak_Location_Verify      : Channel_Types.Data_Channel_Number := 0;
      Lower_Peak_Location_Verify      : Channel_Types.Data_Channel_Number := 0;

      --  Boolean flags stating whether find centroid returned a valid result
      High_Peak_Found                 : Boolean;
      Lo_Peak_Found                   : Boolean;

   begin

--        Lower_Peak_ROI := Lower_Peak_Type'(others => 0);
      --  Engineering use: print statements to identify where in the operating
      --  cycle the system is
      Usart1.Send_String (Item => ("Verifying Calibration"));
      Usart1.Send_Message_New_Line;
      Usart1.Send_String (Item => ("Gathering Data"));
      Usart1.Send_Message_New_Line;

      --  set the timeout for this iteration of the calibration adjustment cycle
      Timer.Set_Timeout_Seconds (The_Interval => Timeouts.CALIBRATION);
      Timer.Init;
      Is_Timed_Out := Timer.Check_Timeout;

      --  Collect the calibration distribution

      Gather_Calibration_Data (Timed_Out => Is_Timed_Out);

      --  if sufficient counts have been collected then check if the peak locations
      --  are within tolerance
      if not Is_Timed_Out then
         Find_Calibration_Centroids (Upper_Search_Array  => Upper_Peak_ROI,
                                     Lower_Search_Array  => Lower_Peak_ROI,
                                     Upper_Peak_Centroid => Upper_Peak_Location_Verify,
                                     Lower_Peak_Centroid => Lower_Peak_Location_Verify,
                                     Upper_Peak_Found    => High_Peak_Found,
                                     Lower_Peak_Found    => Lo_Peak_Found);

         Upper_Peak_Location_Verify  := Channel_Types.Data_Channel_Number
           (Integer (Upper_Peak_Location_Verify) - Offset);

         Lower_Peak_Location_Verify  := Channel_Types.Data_Channel_Number
           (Integer (Lower_Peak_Location_Verify) - Offset);

         if Upper_Peak_Location_Verify  in
           UPPER_CALIBRATION_PEAK.Centre_Channel - VERIFICATION_TOLERANCE ..
             UPPER_CALIBRATION_PEAK.Centre_Channel + VERIFICATION_TOLERANCE and
             Lower_Peak_Location_Verify  in
               LOWER_CALIBRATION_PEAK.Centre_Channel - VERIFICATION_TOLERANCE ..
                 LOWER_CALIBRATION_PEAK.Centre_Channel + VERIFICATION_TOLERANCE and
                 High_Peak_Found and Lo_Peak_Found then
            Is_Successful := True;
         else
            Is_Successful := False;
         end if;
      else
         Is_Successful := False;
      end if;

      --  Engineering use: print the details of the upper peak
      Dump_Cal_Data (Peak_Boundaries => UPPER_CALIBRATION_PEAK,
                     Peak_ROI        => Upper_Peak_ROI,
                     ROI_Name        => "778 keV peak");
      Usart1.Send_String (Item => "Peak_Position:");
      Usart1.Send_Message_16 (Data => Upper_Peak_Location_Verify);
      Usart1.Send_Message_New_Line;

      --  Engineering use: print the details of the lower peak
      Dump_Cal_Data (Peak_Boundaries => LOWER_CALIBRATION_PEAK,
                     Peak_ROI        => Lower_Peak_ROI,
                     ROI_Name        => "122 keV peak");
      Usart1.Send_String (Item => "Peak_Position:");
      Usart1.Send_Message_16 (Data => Lower_Peak_Location_Verify);
      Usart1.Send_Message_New_Line;

   end Verify_Calibration;

end Calibration;
