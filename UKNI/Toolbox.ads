----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox
--  Stored Filename: $Id: Toolbox.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               Parent package for any manipulations required on the distribution
--  </description>
----------------------------------------------------------------------

with Mod_Types;

use type Mod_Types.Unsigned_16,
    Mod_Types.Unsigned_32;

--# inherit Mod_Types;

package Toolbox is

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  multiplication factor such that calculations are accurate
   MULT            : constant := 16384;

   --  constant determining the size of the width of the peaks to be examined
   PEAK_EVAL_WIDTH : constant := 18;

   --  constant determining the size of the guard to check against when examining peaks
   PEAK_EVAL_GUARD : constant := (PEAK_EVAL_WIDTH / 2 + 1) * MULT;

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   subtype Extended_Channel_Size is Mod_Types.Unsigned_32 range 0 ..
     Mod_Types.Unsigned_32 (Mod_Types.Unsigned_16'Last) * MULT;

end Toolbox;
