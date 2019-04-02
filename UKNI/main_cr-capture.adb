----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Main.Measure
--  Stored Filename: --  $Id: Main_CR-Capture.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Date Created:
--  Description: A description of the purpose of the package
--  Implementation Information: Nested subprogram body from Main.adb
--                             separate files
----------------------------------------------------------------------
separate (Main_CR)
procedure Capture

is

   subtype Capture_ROI_Index_Type is Channel_Types.Data_Channel_Number range
     512 .. 3700;
   subtype Capture_ROI_Type is Region_Of_Interest.Region_Of_Interest_Type (Capture_ROI_Index_Type);
   Capture_ROI : Capture_ROI_Type;

   Total_Count : Mod_Types.Unsigned_32 := 0;

   procedure Clear_CR_Store
   is
   begin
      for K in Capture_ROI_Index_Type loop
         Capture_ROI (K) := 0;
      end loop;
      Total_Count := 0;
   end Clear_CR_Store;
   pragma Inline (Clear_CR_Store);

   procedure Get_Next_Count (Count : out Channel_Types.Data_Channel_Number)
   is
   begin
      ADC.Get_Reading (Reading           => Count);
      --  Need to guard against offset taking count outside range of available channels

      if Count in Capture_ROI_Index_Type and then Capture_ROI (Count) < Mod_Types.Unsigned_16 'Last then
         if Total_Count < Mod_Types.Unsigned_32'Last then
            Total_Count := Total_Count + 1;
         end if;
      end if;
   end Get_Next_Count;
   pragma Inline (Get_Next_Count);

   procedure Dump_CR_Data
   is
   begin
      Usart1.Send_String ("Data Start");
      Usart1.Send_Message_New_Line;
      for I in Capture_ROI_Index_Type loop
         Usart1.Send_Message_16 ((I));
         Usart1.Send_Message_Comma;
         Usart1.Send_Message_16 ((Capture_ROI (I)));
         Usart1.Send_Message_New_Line;
      end loop;
      Usart1.Send_String ("Total Counts:");
      Usart1.Send_Message_32 (Data => (Total_Count));
      Usart1.Send_Message_New_Line;
      Usart1.Send_String ("Data End");
      Usart1.Send_Message_New_Line;
      Usart1.Send_Message_New_Line;
   end Dump_CR_Data;
   pragma Inline (Dump_CR_Data);

   Count_Channel     : Channel_Types.Data_Channel_Number;
   Continue_Counting : Boolean := True;
begin
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.MEASUREMENT_PRESENT);
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.MEASUREMENT_NOT_PROVEN);
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_PASS);
   Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_FAIL);
   Clear_CR_Store;

   Count_Range_Check.Check_Count (In_Range => Unused);
   while Continue_Counting loop
      Get_Next_Count (Count => Count_Channel);

      --  If the count is in the isotopics range, then increment the
      --  appropriate isotopic roi channel
      if Count_Channel in Capture_ROI_Index_Type then

         if Capture_ROI (Count_Channel) < Mod_Types.Unsigned_16'Last then
            Capture_ROI (Count_Channel) := Capture_ROI (Count_Channel) + 1;
         else
            Dump_CR_Data;
            Continue_Counting := False;
         end if;
      end if;

      Switch.Check_State (Selected_Switch => Selected_Switch);
      if Selected_Switch = Switch.Measure then
         Dump_CR_Data;
      elsif Selected_Switch /= Switch.None then
         Continue_Counting := False;
      end if;

   end loop;
end Capture;
