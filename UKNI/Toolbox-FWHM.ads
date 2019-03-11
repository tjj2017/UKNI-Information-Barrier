----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.FWHM
--  Stored Filename: $Id: Toolbox-FWHM.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package contains subprograms to calculate the FWHM
--  </description>
----------------------------------------------------------------------

with Region_Of_Interest;

--# inherit Channel_Types,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Toolbox.Peak_Net_Area,
--#         Toolbox.Peak_Search,
--#         Usart1;

package Toolbox.FWHM is

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> FWHM_Channels </name>
   --  <description> Calculate the FWHM of a passed in peak
   --  </description>
   --  <input name="Confidence">
   --     The required confidence level
   --  </input><input name="Peak_ROI_Locations">
   --     The details of the specification of the peak being analysed
   --  </input><input name="Peak_ROI">
   --     The ROI to run the Currie Critical Test on
   --  </input>
   --  <returns>
   --     The FWHM
   --  </returns>
   -------------------------------------------------------------------
   function FWHM_Channels (Peak_ROI_Locations   : in Region_Of_Interest.Peak_ROI_Locations_Type;
                           Peak_ROI             : in Region_Of_Interest.Region_Of_Interest_Type)
                           return Mod_Types.Unsigned_32;
   --# pre Peak_ROI_Locations.Background1_LL < Peak_ROI_Locations.Background1_UL and
   --#      Peak_ROI_Locations.Background1_UL <= Peak_ROI_Locations.Peak_LL and
   --#      Peak_ROI_Locations.Peak_LL <  Peak_ROI_Locations.Peak_UL and
   --#      Peak_ROI_Locations.Peak_UL <= Peak_ROI_Locations.Background2_LL and
   --#      Peak_ROI_Locations.Background2_LL < Peak_ROI_Locations.Background2_UL and
   --#      Peak_ROI'first <= Peak_ROI_Locations.Background1_LL and
   --#      Peak_ROI'last >= Peak_ROI_Locations.Background2_UL;
end Toolbox.FWHM;
