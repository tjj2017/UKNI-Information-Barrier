----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Region_Of_Interest
--  Stored Filename: $Id: Region_Of_Interest.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package provides definitions of types associated with the
--  *            regions of interest
--  </description>
----------------------------------------------------------------------

with Channel_Types,
     Mod_Types;

--# inherit Channel_Types,
--#         Mod_Types;

package Region_Of_Interest is

   --  The IB stops counting at 65535 in any channel.  When curve fitting, the
   --  calculated maximum may be greater than this range
   subtype Peak_Height_Type is Mod_Types.Unsigned_32 range 0 .. 76000;

   --  The ROI will consist of a number of channels each containing up to 2 ** 16
   --  readings
   type Region_Of_Interest_Type is array
     (Channel_Types.Data_Channel_Number range <>) of Mod_Types.Unsigned_16;

   --  Define a type which will hold the ROI limits for each peak
   type Peak_ROI_Locations_Type is record

      Ideal_Centre_Channel       : Channel_Types.Data_Channel_Number;
      Background1_LL             : Channel_Types.Data_Channel_Number;
      Background1_UL             : Channel_Types.Data_Channel_Number;
      Peak_LL                    : Channel_Types.Data_Channel_Number;
      Peak_UL                    : Channel_Types.Data_Channel_Number;
      Background2_LL             : Channel_Types.Data_Channel_Number;
      Background2_UL             : Channel_Types.Data_Channel_Number;
   end record;

end Region_Of_Interest;
