----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Mod_Types
--  Stored Filename: $Id: Mod_Types.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package provides modular type definitions for U8, U16, U32 and U64
--  </description>
----------------------------------------------------------------------

package Mod_Types is

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------
   type Unsigned_8 is mod 2 ** 8;
   for Unsigned_8'Size use 8;

   type Unsigned_16 is mod 2 ** 16;
   for Unsigned_16'Size use 16;

   type Unsigned_32 is mod 2 ** 32;
   for Unsigned_32'Size use 32;

   type Unsigned_64 is mod 2 ** 64;
   for Unsigned_64'Size use 64;

end Mod_Types;
