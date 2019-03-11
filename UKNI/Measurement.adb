----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement
--  Stored Filename: $Id: Measurement.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: Performs the measurements required by the IB
----------------------------------------------------------------------

with ADC,
     Calibration,
     Calibration_Peak,
     Channel_Types,
     Count_Types,
     Measurement.Isotopics,
     Measurement.Identification,
     Mod_Types,
     Region_Of_Interest,
     Timer,
     Timeouts,
     Toolbox,
     Usart1;

use type Channel_Types.Data_Channel_Number,
         Mod_Types.Unsigned_32,
         Mod_Types.Unsigned_64,
         Region_Of_Interest.Region_Of_Interest_Type;

package body Measurement
--# own Data_Store is Measurement.Isotopics.Isotopic_ROI,
--#                   Measurement.Identification.ID_ROI;
is
   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Clear_Store
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Clear_Store
   --# global out Identification.ID_ROI;
   --#        out Isotopics.Isotopic_ROI;
   --# derives Identification.ID_ROI,
   --#         Isotopics.Isotopic_ROI from ;
   --# post (for all I in Identification.ID_ROI_Index_Type =>
   --#               (Identification.ID_ROI (I) = 0)) and
   --#        (for all I in Isotopics.ISO_ROI_Index_Type =>
   --#               (Isotopics.Isotopic_ROI (I) = 0));
   is
      --# hide Clear_Store;
      --  hidden body, as array initialisation done via loop
      --  avoiding expensive memory constant array
   begin
      Isotopics.Clear_Isotopic_Store;

      Identification.Clear_Identification_Store;

   end Clear_Store;

   -------------------------------------------------------------------
   --  Name       : Gather_Data
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Gather_Data (Target_Counts_Reached : out Boolean)
   --# global in     Calibration.State;
   --#        in     Timer.Timeout;
   --#        in out ADC.State;
   --#           out Identification.ID_ROI;
   --#           out Isotopics.Isotopic_ROI;
   --#           out Timer.Setup;
   --# derives ADC.State              from *,
   --#                                     Timer.Timeout &
   --#         Identification.ID_ROI,
   --#         Isotopics.Isotopic_ROI,
   --#         Target_Counts_Reached  from ADC.State,
   --#                                     Calibration.State,
   --#                                     Timer.Timeout &
   --#         Timer.Setup            from ;
   is
      --  The offset to be applied
      Offset                   : Calibration_Peak.Offset_Type;

      --  Boolean flag stating whether the timer has timed out
      Is_Timed_Out             : Boolean;

      --  The channel in which to attempt to increment the count in
      Count_Channel            : Channel_Types.Data_Channel_Number;

      --  The number of counts in the 413 peak
      Pu239_413_Count          : Count_Types.Measurement_Count_Type := 0;

      --  Whether enough counts have been collected in the isotopics region
      Isotopics_Maxed_Out      : Boolean := False;

   -------------------------------------------------------------------
   --  Name: Get_Next_Count
   --  Description: Get the next count from the ADC and apply the offset to
   --               return the IB channel in which the count is to increment
   --  Input: None
   --  Output: Count - The channel in which the next count sits
   -------------------------------------------------------------------
      procedure Get_Next_Count (Count : out Channel_Types.Data_Channel_Number)
      --# global in     Offset;
      --#        in out ADC.State;
      --# derives ADC.State from * &
      --#         Count     from ADC.State,
      --#                        Offset;
      is
      begin
         ADC.Get_Reading (Reading           => Count);
         --  Need to guard against offset taking count outside range of available channels
         --  offset > Count (would give negative value)
         --  Count - offset > (Data_Channel_Number'Last)
         if Offset <= Integer (Count) and then
           Offset <= (Integer (Channel_Types.Data_Channel_Number'Last) - Integer (Count)) and then
           ((Integer (Count) - Offset) <= Integer (Channel_Types.Data_Channel_Number'Last)) then

            Count := Mod_Types.Unsigned_16 (Integer (Count) - Offset);

         elsif Offset > Integer (Count) then
            Count := Channel_Types.Data_Channel_Number'First;
         else
            Count := Channel_Types.Data_Channel_Number'Last;
         end if;

      end Get_Next_Count;
      pragma Inline (Get_Next_Count);

      -------------------------------------------------------------------
      --  Name: ID_Max_Reached
      --  Description: Increment the count of the number of Identification ROI elements stored
      --               and indicate whether the required maximum has been reached
      --  Input: Index - The element of the Identification ROI that was incremented
      --  Output: Count_Reached - Boolean flag stating whether 50,000 counts exist within the 413keV peak
      -------------------------------------------------------------------
      procedure ID_Max_Reached (Index : in Identification.ID_ROI_Index_Type;
                                Count_Reached : out Boolean)
      --# global in out Pu239_413_Count;
      --# derives Count_Reached,
      --#         Pu239_413_Count from Index,
      --#                              Pu239_413_Count;
      --# pre Pu239_413_Count < 50_000;
      --# post Pu239_413_Count < 50_000 or Count_Reached;
      is

         --  The maximum number of counts to be collected in the 413 peak
         MAX_COUNTS               : constant := 50_000;
      begin
         Count_Reached := False;

         if Index in Identification.ID_ROI_413_LL .. Identification.ID_ROI_413_UL then
            Pu239_413_Count := Pu239_413_Count + 1;

            --  Maximum number of counts in the 413 peak
            if Pu239_413_Count = MAX_COUNTS then
               Count_Reached := True;
               Usart1.Send_String (Item => "Target counts in ID peak reached");
               Usart1.Send_Message_New_Line;
            end if;
         end if;
      end ID_Max_Reached;
      pragma Inline (ID_Max_Reached);

      -------------------------------------------------------------------
      --  Name: ISO_Max_Reached
      --  Description: Increment the count of the number of Isotopics ROI elements stored
      --               and indicate whether the required maximum has been reached
      --  Input: Index - The element of the Isotopics ROI that was incremented
      --  Output: Boolean flag stating whether the channel has reached maximum capacity
      -------------------------------------------------------------------
      function ISO_Max_Reached (Index : in Isotopics.ISO_ROI_Index_Type) return Boolean
      --# global in Isotopics.Isotopic_ROI;
      is
         Count_Reached            : Boolean := False;
         --  The maximum number of counts to be collected in the isotopics region
         MAX_COUNTS               : constant := Mod_Types.Unsigned_16'Last;
      begin
         if Isotopics.Isotopic_ROI (Index) = MAX_COUNTS then
            Count_Reached := True;
         end if;

         return Count_Reached;
      end ISO_Max_Reached;
      pragma Inline (ISO_Max_Reached);

   begin
      --  Make sure measurement data is initialised to zero
      Clear_Store;
      --# check (for all I in Identification.ID_ROI_Index_Type =>
      --#               (Identification.ID_ROI (I) = 0)) and
      --#        (for all I in Isotopics.ISO_ROI_Index_Type =>
      --#               (Isotopics.Isotopic_ROI (I) = 0));

      --  Setup the timer
      Timer.Init;
      --  Set the timeout interval
      Timer.Set_Timeout_Seconds (The_Interval => Timeouts.MEASUREMENT);
      --  Poll the timeout for initial state
      Is_Timed_Out := Timer.Check_Timeout;

      --  Store the DC offset correction derived during calibration in offset.
      --  This is then applied to all incoming counts by using the Get_Next_Count
      --  procedure.
      Offset := Calibration.Get_Offset;
      Target_Counts_Reached := False;

      while not Is_Timed_Out loop
         --  Get a new count and store it in the isotopics ROI if it falls within
         --  the range.
         Get_Next_Count (Count => Count_Channel);

         --  If the count is in the isotopics range, then increment the
         --  appropriate isotopic roi channel
         if Count_Channel in Isotopics.ISO_ROI_Index_Type and then
           not Isotopics_Maxed_Out then

            Isotopics.Increment_ROI_Element (Index => Count_Channel);

            Isotopics_Maxed_Out := ISO_Max_Reached (Index => Count_Channel);

         --  If the count is in the ID range, then increment the
         --  appropriate ID roi channel and check whether 50_000 number
         --  of counts have been collected in the 413 peak
         elsif Count_Channel in Identification.ID_ROI_Index_Type and then
           Identification.ID_ROI (Count_Channel) < Mod_Types.Unsigned_16'Last and then
           not Target_Counts_Reached then

            Identification.Increment_ROI_Element (Index => Count_Channel);

            ID_Max_Reached (Index         => Count_Channel,
                            Count_Reached => Target_Counts_Reached);
         end if;
         --# assert (for all I in Identification.ID_ROI_Index_Type =>
         --#               (Identification.ID_ROI (I) in Mod_Types.Unsigned_16)) and
         --#        (for all I in Isotopics.ISO_ROI_Index_Type =>
         --#               (Isotopics.Isotopic_ROI (I) in Mod_Types.Unsigned_16)) and
         --#        (Pu239_413_Count < 50_000 or Target_Counts_Reached);
         Is_Timed_Out := Timer.Check_Timeout;

      end loop;

   end Gather_Data;

   -------------------------------------------------------------------
   --  Name: Dump_Measurement_Data
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Dump_Measurement_Data
   is
      --  This procedure is hidden because
      --  1. This procedure is for engineering use only and its assurance is
      --     not part of the evidance pack
      --  2. This procedure calls the usart1 package which contains directives
      --     below the SPARK layer of influence
      --  3. All non-usart calls are analysed elsewhere or are not part of normal
      --     execution flow
      --# hide Dump_Measurement_Data;
      Offset : Calibration_Peak.Offset_Type;
   begin
      Offset := Calibration.Get_Offset;
      Usart1.Send_String ("Channel offset from Calibration applied to ROI: ");
      if Offset >= 0 then
         Usart1.Send_Message_16 (Data => Mod_Types.Unsigned_16 (Offset));
      else
         Usart1.Send_String ("-");
         Usart1.Send_Message_16 (Data => Mod_Types.Unsigned_16 (-Offset));
      end if;
      Usart1.Send_Message_New_Line;

      Usart1.Send_String ("Spectrum in ID region ROI");
      Usart1.Send_Message_New_Line;

      --  Print the ID region of interest
      for J in Identification.ID_ROI_Index_Type loop
         Usart1.Send_Message_16 (Data => J);
         Usart1.Send_String (Item => ",");
         Usart1.Send_Message_16 (Data => Identification.ID_ROI (J));
         Usart1.Send_Message_New_Line;
      end loop;
      Usart1.Send_Message_New_Line;
      Usart1.Send_Message_New_Line;

      Usart1.Send_String ("Spectrum in Isotopics region ROI");
      Usart1.Send_Message_New_Line;

      --  Print the isotopics region of interest
      for I in Isotopics.ISO_ROI_Index_Type loop
         Usart1.Send_Message_16 (Data => I);
         Usart1.Send_String (Item => ",");
         Usart1.Send_Message_16 (Data => Isotopics.Isotopic_ROI (I));
         Usart1.Send_Message_New_Line;
      end loop;
   end Dump_Measurement_Data;

   -------------------------------------------------------------------
   --  Name: Measurement_Calculations
   --  Implementation Information: Includes engineering use print statements
   --                              in subprocedure.
   -------------------------------------------------------------------
   procedure Measurement_Calculations (Is_Present : out Boolean)
   --# global in     Identification.ID_ROI;
   --#        in     Isotopics.Isotopic_ROI;
   --#        in out Measurement_Peaks.State;
   --# derives Is_Present,
   --#         Measurement_Peaks.State from Identification.ID_ROI,
   --#                                      Isotopics.Isotopic_ROI,
   --#                                      Measurement_Peaks.State;
   is

      --  The Pu239/240 ratio
      Ratio                   : Mod_Types.Unsigned_32 := Mod_Types.Unsigned_32'Last;

      --  Flag stating if Pu has been detected
      Pu_Present              : Boolean;

      --  Flag stating whether the 662 peak has been found
      Peak_Found_662          : Boolean := False;

   -------------------------------------------------------------------
   --  Name: Dump_Result_Data
   --  Description: Engineering use only
   --               Print the results of whether Pu 239 has been found
   --               and the isotopic ratio
   --  Input: None
   --  Output: None
   -------------------------------------------------------------------
      procedure Dump_Result_Data
      --# derives;
      is
         --  This procedure is hidden because
         --  1. This procedure is for engineering use only and its assurance is
         --     not part of the evidance pack
         --  2. This procedure calls the usart1 package which contains directives
         --     below the SPARK layer of influence
         --  3. All non-usart calls are analysed elsewhere or are not part of normal
         --     execution flow
         --# hide Dump_Result_Data;
      begin

         if Pu_Present then
            Usart1.Send_String (Item => "Pu 239 Present");
            Usart1.Send_Message_New_Line;
         else
            Usart1.Send_String (Item => "Pu 239 Not Present");
            Usart1.Send_Message_New_Line;
         end if;

         if Ratio < Mod_Types.Unsigned_32 (Toolbox.MULT / 10) then
            Usart1.Send_String (Item => "Interesting Material Present");
            Usart1.Send_Message_New_Line;
         else
            Usart1.Send_String (Item => "Interesting Material Not Present");
            Usart1.Send_Message_New_Line;
         end if;

         Usart1.Send_String (Item => "===========================================================================");
         Usart1.Send_Message_New_Line;
         Usart1.Send_String (Item => "MEASUREMENT DATA:");
         Usart1.Send_Message_New_Line;
         Usart1.Send_Message_New_Line;

         Usart1.Send_String (Item => "Ratio: ");
         Usart1.Send_Message_32 (Data => Ratio);
         Usart1.Send_Message_New_Line;
         Usart1.Send_String (Item => "===========================================================================");
         Usart1.Send_Message_New_Line;

      end Dump_Result_Data;

   begin
      --  For Pu239 Identification need to:
      --  1. Collect counts in ID_ROI until 50000 counts in 413keV peak (ID_ROI
      --  covers 345, 375, 413, 392 / 392, 451 peaks and background regions)
      --  413 peak is used as attenuation from Pb shield makes this the highest count
      --  2. Currie test all 5 peaks (? is this valid for the doublet?)
      --  3. Compare net counts with the tolerances (given ref.peak size)
      --  4. Calculate relative energy spacing from true centroid (rel. to ref. peak)
      --  5. Calculate FWHM of all 5 peaks and compare with tolerances
      Identification.Identify_Pu239 (Pu_Present => Pu_Present);

      --  For 640keV Measurement, need to:
      --    1. Establish true centroid of Pu239 645 peak
      --    2. Make further offset adjustment to ROIs
      --    3. Get net peak areas for regions A, B and D
      --    4. Apply the equation
      --    5. Test if result above or below 10% threshold

      ------------------------------
      --  New Isotopic Calculation
      ------------------------------

      if Pu_Present then
         Isotopics.Determine_Isotopic_Ratio (Peaks_Found => Peak_Found_662,
                                             Ratio       => Ratio);
      end if;

      if Pu_Present and Peak_Found_662 and Ratio < Mod_Types.Unsigned_32 (Toolbox.MULT / 10) then
         Is_Present := True;
      else
         Is_Present := False;
      end if;

      Dump_Result_Data;

   end Measurement_Calculations;

   -------------------------------------------------------------------
   --  Name: Perform_Measurement
   --  Implementation Information: Includes engineering use print statements.
   -------------------------------------------------------------------
   procedure Perform_Measurement (Is_Present : out Boolean)
   --# global in     Calibration.State;
   --#        in     Timer.Timeout;
   --#        in out ADC.State;
   --#        in out Measurement_Peaks.State;
   --#           out Identification.ID_ROI;
   --#           out Isotopics.Isotopic_ROI;
   --#           out Timer.Setup;
   --# derives ADC.State               from *,
   --#                                      Timer.Timeout &
   --#         Identification.ID_ROI,
   --#         Isotopics.Isotopic_ROI,
   --#         Timer.Setup             from  &
   --#         Is_Present,
   --#         Measurement_Peaks.State from ADC.State,
   --#                                      Calibration.State,
   --#                                      Measurement_Peaks.State,
   --#                                      Timer.Timeout;

   is
      --  Flag to state whether the source is active enough
      Target_Count_Reached : Boolean;
   begin
      Usart1.Send_String (Item   => "Performing Measurement:");
      Usart1.Send_Message_New_Line;

      --  Gather the measurement data
      Gather_Data (Target_Counts_Reached => Target_Count_Reached);

      --  And print to the debug port
      Dump_Measurement_Data;

      if Target_Count_Reached then
         Measurement_Calculations (Is_Present => Is_Present);
      else
         Usart1.Send_String (Item => "Measurement Timed Out");
         Usart1.Send_Message_New_Line;
         Is_Present := False;
      end if;

      if Is_Present then
         Usart1.Send_String (Item => "Measurement Result 'Present'");
         Usart1.Send_Message_New_Line;
      else
         Usart1.Send_String (Item => "Measurement Result 'Not Proven'");
         Usart1.Send_Message_New_Line;
      end if;
      Clear_Store;

   end Perform_Measurement;

end Measurement;
