----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Main.Count_Is_In_Range
--  Stored Filename: $Id: Main-Count_Is_In_Range.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: Seperation of the count range check from the main procedure
--  Implementation Information: Nested subprogram body from Main.adb
--                             separate files
----------------------------------------------------------------------
separate (Main)

-------------------------------------------------------------------
--  Name       : Count_Is_In_Range
--  Implementation Information: None.
-------------------------------------------------------------------
procedure Count_Is_In_Range (In_Range : out Boolean)
is
begin
   Count_Range_Check.Check_Count (In_Range => In_Range);
end Count_Is_In_Range;
