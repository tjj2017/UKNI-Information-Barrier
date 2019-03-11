----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.Peak_Net_Area
--  Stored Filename: $Id: toolbox-peak_net_area.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package contains subprograms to analyse regions of intereset
--               with respect to background and area
--  </description>
----------------------------------------------------------------------
with Channel_Types,
     Region_Of_Interest;

--# inherit Channel_Types,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Toolbox,
--#         Usart_Types,
--#         Usart1;

package Toolbox.Peak_Net_Area is

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> ROI_Area </name>
   --  <description> Calculate the total number of counts within a region of interest
   --     as bounded by the upper and lower channels
   --  </description>
   --  <input name="First_Channel">
   --     The first channel to count from when performing summation
   --  </input><input name="Last_Channel">
   --     The last channel to count to when performing summation
   --  </input><input name="ROI">
   --     The region of interest in which to undertake the counting
   --  </input>
   --  <returns>
   --     The total number of counts within the region of interest as bounded
   --     by the upper and lower channels
   --  </returns>
   -------------------------------------------------------------------
   function ROI_Area (First_Channel : in Channel_Types.Data_Channel_Number;
                      Last_Channel  : in Channel_Types.Data_Channel_Number;
                      ROI           : in Region_Of_Interest.Region_Of_Interest_Type)
                      return Mod_Types.Unsigned_32;
   --# pre ROI'first <=First_Channel and ROI'last>=Last_Channel;
   --# return M => M <= Mod_Types.Unsigned_32((Long_Integer(Last_Channel - First_Channel + 1) *
   --#                                                  Long_Integer(Mod_Types.Unsigned_16'last)));
   pragma Inline (ROI_Area);

   -------------------------------------------------------------------
   --  <name> Calculate_Peak_Net_Area </name>
   --  <description> Calculates the net area of a peak
   --  </description>
   --  <input name="Peak_ROI_Locations">
   --     The information of the ROI
   --  </input><<input name="Peak_ROI">
   --     The region of interest in which to undertake the counting
   --  </input>
   --  <returns>
   --     The net area of the ROI
   --  </returns>
   -------------------------------------------------------------------
   function Calculate_Peak_Net_Area
     (Peak_ROI_Locations   : in Region_Of_Interest.Peak_ROI_Locations_Type;
      Peak_ROI             : in Region_Of_Interest.Region_Of_Interest_Type)
      return Mod_Types.Unsigned_32;
   --# pre Peak_ROI_Locations.Background1_LL < Peak_ROI_Locations.Background1_UL and
   --#      Peak_ROI_Locations.Background1_UL <= Peak_ROI_Locations.Peak_LL and
   --#      Peak_ROI_Locations.Peak_LL <= Peak_ROI_Locations.Peak_UL and
   --#      Peak_ROI_Locations.Peak_UL <= Peak_ROI_Locations.Background2_LL and
   --#      Peak_ROI_Locations.Background2_LL < Peak_ROI_Locations.Background2_UL and
   --#      Peak_ROI'first <= Peak_ROI_Locations.Background1_LL and
   --#      Peak_ROI'last >= Peak_ROI_Locations.Background2_UL;
   pragma Inline (Calculate_Peak_Net_Area);

   -------------------------------------------------------------------
   --  <name> Interpolate_Background </name>
   --  <description> Perform a linear interpolation to calculate the background per channel
   --  </description>
   --  <input name="Peak_ROI_Locations">
   --     The information of the ROI
   --  </input><<input name="Peak_ROI">
   --     The region of interest in which to undertake the calculation
   --  </input>
   --  <returns>
   --     The background of the ROI
   --  </returns>
   -------------------------------------------------------------------
   function Interpolate_Background
     (Peak_ROI_Locations : in Region_Of_Interest.Peak_ROI_Locations_Type;
      Peak_ROI           : in Region_Of_Interest.Region_Of_Interest_Type)
      return Mod_Types.Unsigned_32;
   --# pre Peak_ROI_Locations.Background1_LL < Peak_ROI_Locations.Background1_UL and
   --#      Peak_ROI_Locations.Background1_UL <= Peak_ROI_Locations.Peak_LL and
   --#      Peak_ROI_Locations.Peak_LL <= Peak_ROI_Locations.Peak_UL and
   --#      Peak_ROI_Locations.Peak_UL <= Peak_ROI_Locations.Background2_LL and
   --#      Peak_ROI_Locations.Background2_LL < Peak_ROI_Locations.Background2_UL and
   --#      Peak_ROI'first <= Peak_ROI_Locations.Background1_LL and
   --#      Peak_ROI'last >= Peak_ROI_Locations.Background2_UL and
   --#      Peak_ROI'first <= Peak_ROI_Locations.Background1_LL and
   --#      Peak_ROI'last >= Peak_ROI_Locations.Background2_UL;
   pragma Inline (Interpolate_Background);

   -------------------------------------------------------------------
   --  <name> Peak_Area_Data </name>
   --  <description> Calculates the background, gross and net area of the ROI
   --  </description>
   --  <input name="Peak_ROI_Locations">
   --     The information of the ROI
   --  </input><<input name="Peak_ROI">
   --     The region of interest in which to undertake the counting
   --  </input>
   --  <<output name="Equivalent_Background">
   --     The calculated background of the ROI
   --  </output><<output name="Gross_Area">
   --     The gross area of the ROI
   --  </output><<output name="Net_Area">
   --     The net area of the ROI
   --  </output>
   -------------------------------------------------------------------
   procedure Peak_Area_Data (Peak_ROI_Locations    : in Region_Of_Interest.Peak_ROI_Locations_Type;
                             Peak_ROI              : in Region_Of_Interest.Region_Of_Interest_Type;
                             Equivalent_Background : out Mod_Types.Unsigned_32;
                             Gross_Area            : out Mod_Types.Unsigned_32;
                             Net_Area              : out Mod_Types.Unsigned_32);
   --# derives Equivalent_Background,
   --#         Gross_Area,
   --#         Net_Area              from Peak_ROI,
   --#                                    Peak_ROI_Locations;
   --# pre Peak_ROI_Locations.Background1_LL < Peak_ROI_Locations.Background1_UL and
   --#      Peak_ROI_Locations.Background1_UL <= Peak_ROI_Locations.Peak_LL and
   --#      Peak_ROI_Locations.Peak_LL <= Peak_ROI_Locations.Peak_UL and
   --#      Peak_ROI_Locations.Peak_UL <= Peak_ROI_Locations.Background2_LL and
   --#      Peak_ROI_Locations.Background2_LL < Peak_ROI_Locations.Background2_UL and
   --#      Peak_ROI'first <= Peak_ROI_Locations.Background1_LL and
   --#      Peak_ROI'last >= Peak_ROI_Locations.Background2_UL and
   --#      Peak_ROI'first <= Peak_ROI_Locations.Background1_LL and
   --#      Peak_ROI'last >= Peak_ROI_Locations.Background2_UL;

   -------------------------------------------------------------------
   --  <name> Calculate_Background </name>
   --  <description> Calculate the background per channel of the ROI
   --                calculated using linear interpolation of the rhs
   --  </description>
   --  <input name="First_Channel">
   --     The start of the background region [@real]
   --  </input><input name="Last_Channel">
   --     The end of the background region [@real]
   --  </input><input name="ROI">
   --     The region of interest to calculate the background for [@real]
   --  </input>
   --  <returns>
   --     The mean background [@mult]
   --  </returns>
   -------------------------------------------------------------------
   function Calculate_Background (First_Channel : in Channel_Types.Data_Channel_Number;
                                  Last_Channel  : in Channel_Types.Data_Channel_Number;
                                  ROI           : in Region_Of_Interest.Region_Of_Interest_Type)
                                  return Toolbox.Extended_Channel_Size;
   --# pre ROI'first <= First_Channel and
   --#     ROI'last  >= Last_Channel and
   --#     (Last_Channel - First_Channel) + 1 > 4;
   pragma Inline (Calculate_Background);

private
   -------------------------------------------------------------------
   --  <name> Dump_Peak_Area_Data </name>
   --  <description> Sends the passed in information to the engineering use debug port
   --  </description>
   --  <input name="Channels_In_Peak">
   --     The number of channels in the peak
   --  </input><input name="Background">
   --     The interpoloated background count of the peak
   --  </input><input name="Equivalent_Background">
   --     The total background of the peak, calculated from Background
   --  </input><input name="Gross_Area">
   --     The gross area of the peak
   --  </input><input name="Net_Area">
   --     The net area of the peak
   --  </input>
   --  <output name = "None">
   --  </output>
   -------------------------------------------------------------------
   procedure Dump_Peak_Area_Data (Channels_In_Peak      : in Mod_Types.Unsigned_16;
                                  Background            : in Mod_Types.Unsigned_32;
                                  Equivalent_Background : in Mod_Types.Unsigned_32;
                                  Gross_Area            : in Mod_Types.Unsigned_32;
                                  Net_Area              : in Mod_Types.Unsigned_32);
   --# derives null from Background,
   --#                   Channels_In_Peak,
   --#                   Equivalent_Background,
   --#                   Gross_Area,
   --#                   Net_Area;
   pragma Inline (Dump_Peak_Area_Data);

end Toolbox.Peak_Net_Area;
