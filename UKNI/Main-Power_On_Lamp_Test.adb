----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Main.Power_On_Lamp_Test
--  Stored Filename: $Id: Main-Power_On_Lamp_Test.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Date Created:
--  Description: Seperation of the indicator checking functions from the main procedure
--  Implementation Information: Nested subprogram body from Main.adb
--                             separate files
----------------------------------------------------------------------
separate (Main)

-------------------------------------------------------------------
--  Name       : Power_On_Lamp_Test
--  Implementation Information: None.
-------------------------------------------------------------------
procedure Power_On_Lamp_Test
is

   -------------------------------------------------------------------
   --  Variables
   -------------------------------------------------------------------

   --  Flag for controller timed events of the lamp test
   Is_Timed_Out : Boolean;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  Representation of the indicators to iterate over
   subtype Order_Array_Index is Mod_Types.Unsigned_8 range 1 .. 9;

   --  type defining the order in which to illuminate the indcators
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

      --  Illuminate the required indicator
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
