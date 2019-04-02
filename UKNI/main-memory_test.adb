----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Main.Memory_Test
--  Stored Filename: $Id: Main-Memory_Test.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Date Created: 20-08-2010
--  Created By: D Curtis
--  Description: Seperation of the memory checking functions from the main procedure
--  Implementation Information: Nested subprogram body from Main.adb
--                             separate files
----------------------------------------------------------------------

separate (Main)

-------------------------------------------------------------------
--  Name       : Memory_Test
--  Implementation Information: Includes engineering use print statements.
-------------------------------------------------------------------
procedure Memory_Test (Result : out Boolean)
is
   PBIT_Passed       : Boolean;
   CRC_Passed        : Boolean;

begin
   --  Run the PBIT and CRC checks
   PBIT_Passed := Memory_Checks.PBIT_Test;
   CRC_Passed  := Memory_Checks.CRC_Test;

   --  Report to the usart the result of the PBIT test
   --# accept F, 22, "PBit Test appears invariant to SPARK";
   if PBIT_Passed then
      --# end accept;
      Usart1.Send_String (Item => "PBIT test Passed");
   else
      Usart1.Send_String (Item => "PBIT test Failed");
   end if;
   Usart1.Send_Message_New_Line;

   --  Report to the usart the result of the CRC check
   --# accept F, 22, "CRC Test appears invariant to SPARK";
   if CRC_Passed then
      --# end accept;
      Usart1.Send_String (Item => "CRC test Passed");
      Result := True;
   else
      Usart1.Send_String (Item => "CRC test Failed");
      Result := False;
   end if;
   Usart1.Send_Message_New_Line;
   Usart1.Send_Message_New_Line;

end Memory_Test;
