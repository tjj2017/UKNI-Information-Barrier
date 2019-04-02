----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Main.Initialize
--  Stored Filename: $Id: Main-Initialize.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: C Marsh
--  Date Created: 27/03/14
--  Description: Seperation of the initialization functionality run at bootup
--  Implementation Information: Nested subprogram body from Main.adb
--                             separate files
----------------------------------------------------------------------

separate (Main)

-------------------------------------------------------------------
--  Name       : Initialize
--  Implementation Information: Includes engineering use print statements.
-------------------------------------------------------------------
procedure Initialize
is
   Memory_Test_Result : Boolean;
begin

   --  Setup the debug port
   Usart1.Start_Up (UCSRB     => 2#0000_1000#,
                    UCSRC     => 2#0000_0110#,
                    Baud_Rate => 15); -- 57k600 Baud

   --  Clear any stored measurement data
   Measurement.Clear_Store;

   --  Return the calibration attenuators to their default location
   Calibration.Full_Reset;

   --  Clear all indicators
   Indicator.Clear_All_Result_Indicators;
   Indicator.Clear_All_Mode_Indicators;

   --  Perform a check on the memory
   Memory_Test (Result => Memory_Test_Result);

   --  Perform a visual check on the indicators
   --# accept F, 22, "Expression is non-variant outside SPARK domain";
   if Memory_Test_Result then
      --# end accept;
      Power_On_Lamp_Test;
   end if;

   --  Transmit the IB software version number
   Usart1.Send_String (Item => "Information Barrier Phase III, software revision 128");
   Usart1.Send_Message_New_Line;
end Initialize;
