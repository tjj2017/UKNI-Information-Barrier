----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Usart_Types
--  Stored Filename: $Id: usart_types.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               Types package for the usart
--  </description>
----------------------------------------------------------------------

with Mod_Types;

use type Mod_Types.Unsigned_8;

--# inherit Mod_Types;

package Usart_Types is

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  AVR_String is not part of the Ada Referenc Manual, so create
   --  A_String for use in the usart package.
   type A_String is array (Mod_Types.Unsigned_8 range <>) of Mod_Types.Unsigned_8;
   --  The equivalent to Standard.String except that it is indexed not
   --  by Positive (2 bytes) but by Unsigned_8 (1 byte).

   --  some string subtypes with predefined length, used for set size data transfer.
   subtype s3_index  is Mod_Types.Unsigned_8 range 1 .. 3;
   subtype s5_index  is Mod_Types.Unsigned_8 range 1 .. 5;
   subtype s10_index is Mod_Types.Unsigned_8 range 1 .. 10;
   subtype s20_index is Mod_Types.Unsigned_8 range 1 .. 20;

   --  fixed size string representations for use whilst transmitting data
   subtype AStr3  is A_String (s3_index);
   subtype AStr5  is A_String (s5_index);
   subtype AStr10 is A_String (s10_index);
   subtype AStr20 is A_String (s20_index);

end Usart_Types;
