----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Main
--  Stored Filename: --  $Id: Main_CR.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Date Created:
--  Description: A description of the purpose of the package
--  Implementation Information: Note nested subprogram bodies in
--                             separate files
----------------------------------------------------------------------
--  567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
with ADC,
     Calibration,
     Channel_Types,
     Count_Range_Check,
     Indicator,
     Mod_Types,
     Region_Of_Interest,
     Switch,
     Timer,
     Usart1;

use type Mod_Types.Unsigned_16,
    Mod_Types.Unsigned_32,
    Switch.SELECTION;

procedure Main_CR

is
   Selected_Switch : Switch.SELECTION;
   Is_Calibrated   : Boolean;
   Unused          : Boolean;

   procedure Power_On_Lamp_Test
   is
      Is_Timed_Out : Boolean;
      subtype Order_Array_Index is Mod_Types.Unsigned_8 range 1 .. 9;
      type Order_Array_Type is array (Order_Array_Index) of Indicator.Indicator_Type;
      Indicator_Array : constant Order_Array_Type := Order_Array_Type'
        (1 => Indicator.CALIBRATION_MODE,
         2 => Indicator.CALIBRATION_PASS,
         3 => Indicator.CALIBRATION_FAIL,
         4 => Indicator.MEASUREMENT_MODE,
         5 => Indicator.MEASUREMENT_PRESENT,
         6 => Indicator.MEASUREMENT_NOT_PROVEN,
         7 => Indicator.CALIBRATION_VERIFY_MODE,
         8 => Indicator.CALIBRATION_VERIFY_PASS,
         9 => Indicator.CALIBRATION_VERIFY_FAIL);

   begin
      --  Clear display to start with
      Indicator.Clear_All_Result_Indicators;
      Indicator.Clear_All_Mode_Indicators;
      --  loop over each result indicator in turn
      Indicator_Loop :
      for I in Order_Array_Index loop
         --  Setup timing for 1 second timeout
         Timer.Set_Timeout_Seconds (1);
         Timer.Init;
         case Indicator_Array (I) is
         when Indicator.CALIBRATION_MODE .. Indicator.CALIBRATION_VERIFY_MODE =>
            Indicator.Set_Current_Mode_Indicator (Indicator_Array (I));
         when Indicator.CALIBRATION_PASS .. Indicator.CALIBRATION_VERIFY_FAIL =>
            Indicator.Set_Result_Indicator (Indicator_Array (I));
         end case;

         --  Check whether timed out
         Is_Timed_Out := Timer.Check_Timeout;
         --  delay until timed out
         Delay_Loop :
         while not Is_Timed_Out loop
            Is_Timed_Out := Timer.Check_Timeout;
         end loop Delay_Loop;
         --  switch off the indicator
         Indicator.Clear_All_Indicators;
      end loop Indicator_Loop;

      --  switch on all result indicators
      Indicator.Set_All_Result_Indicators;
      Indicator.Set_All_Mode_Indicators;
      --  setup 1 second timeout
      Timer.Init;
      Timer.Set_Timeout_Seconds (1);
      Is_Timed_Out := Timer.Check_Timeout;
      --  delay until timed out
      Delay_Loop3 :
      while not Is_Timed_Out loop
         Is_Timed_Out := Timer.Check_Timeout;
      end loop Delay_Loop3;
      --  switch off all result indicators
      Indicator.Clear_All_Result_Indicators;
      Indicator.Clear_All_Mode_Indicators;
   end Power_On_Lamp_Test;
   pragma Inline (Power_On_Lamp_Test);

   procedure Capture
   is separate;

begin

   Calibration.Full_Reset;

   Usart1.Start_Up (Ucsrb     => 2#0001_1000#,
                    Ucsrc     => 2#0000_0110#,
                    Baud_Rate => 23); -- 38k400 Baud
   Indicator.Clear_All_Result_Indicators;
   Indicator.Clear_All_Mode_Indicators;
   Power_On_Lamp_Test;
   Usart1.Send_String (Item => "Store");
   Usart1.Send_Message_New_Line;

   loop
      Switch.Check_State (Selected_Switch => Selected_Switch);
      case Selected_Switch is
         when Switch.Calibrate =>
            Indicator.Set_Current_Mode_Indicator (Indicator_ID => Indicator.CALIBRATION_MODE);
            Usart1.Send_String ("Calibration");
            Usart1.Send_Message_New_Line;
            Count_Range_Check.Check_Count (In_Range => Unused);
            Calibration.Full_Reset;
            Calibration.Perform_Calibration (Is_Successful => Is_Calibrated);
            if Is_Calibrated then
               Indicator.Set_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_PASS);
            else
               Indicator.Set_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_FAIL);
            end if;
            Indicator.Clear_All_Mode_Indicators;
         when Switch.Measure =>
            Indicator.Set_Current_Mode_Indicator (Indicator_ID => Indicator.MEASUREMENT_MODE);
            Capture;
            Indicator.Clear_All_Mode_Indicators;
            Usart1.Send_Message_New_Line;
         when Switch.Verify =>
            Indicator.Set_Current_Mode_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_MODE);
            Usart1.Send_String ("Verify:");
            Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_PASS);
            Indicator.Clear_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_FAIL);

            Count_Range_Check.Check_Count (In_Range => Unused);
            Calibration.Verify_Calibration (Is_Successful => Is_Calibrated);
            if Is_Calibrated then
               Indicator.Set_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_PASS);
            else
               Indicator.Set_Result_Indicator (Indicator_ID => Indicator.CALIBRATION_VERIFY_FAIL);
            end if;
            Indicator.Clear_All_Mode_Indicators;
            Usart1.Send_Message_New_Line;
         when Switch.None =>
            null;
      end case;

   end loop;
end Main_CR;
