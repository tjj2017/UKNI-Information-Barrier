----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Memory_Checks
--  Stored Filename: $Id: memory_checks.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Date Created: June 2009
--  Created By: C Marsh
--  <description>
--               Defines the external interface to the Memory.
--  </description>
----------------------------------------------------------------------

--# inherit Mod_Types;
package Memory_Checks
is

   ----------------------------------------------------------------------
   --  <name> PBIT_Test </name>
   --  <description>
   --               Runs the PBIT test of the RAM
   --  </description>
   --  <input name="None">
   --  </input>
   --  <returns>
   --               True if the PBIT test successfully completes
   --  </returns>
   ----------------------------------------------------------------------
   function PBIT_Test return Boolean;

   ----------------------------------------------------------------------
   --  <name>  CRC_Test </name>
   --  <description>
   --               Runs the CRC test of the code
   --  </description>
   --  <input name="None">
   --  </input>
   --  <returns>
   --                True if the CRC test successfully completes
   --  </returns>
   ----------------------------------------------------------------------
   function CRC_Test return Boolean;

end Memory_Checks;
