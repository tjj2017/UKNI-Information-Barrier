----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.Currie
--  Stored Filename: $Id: Toolbox-Currie.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package contains subprograms to calculate the Currie Tests
--  </description>
----------------------------------------------------------------------
with Channel_Types,
     Region_Of_Interest;

--# inherit Channel_Types,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Toolbox.Maths,
--#         Toolbox.Peak_Net_Area,
--#         Toolbox.Peak_Search,
--#         Usart_Types,
--#         Usart1;

package Toolbox.Currie is

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  Required confidence levels for the Currie Tests (@ * 1000)
   CONFIDENCE_95_PERCENT : constant := 1645;

   -------------------------------------------------------------------
   --  Proof Functions
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> MAX_WIDTH_PF </name>
   --  <description>
   --     Proof function used as a proof constant describing the maximum difference
   --  *  between the lower and upper limit of either a background region or a peak
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns">
   --     The proof constant
   --  </Returns>
   -------------------------------------------------------------------
   --# function MAX_WIDTH_PF return Channel_Types.Data_Channel_Number;

   -------------------------------------------------------------------
   --  <name> MIN_WIDTH_PF </name>
   --  <description>
   --     Proof function used as a proof constant describing the minimum difference
   --  *  between the lower and upper limit of either a background region or a peak
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns">
   --     The proof constant
   --  </Returns>
   -------------------------------------------------------------------
   --# function MIN_WIDTH_PF return Channel_Types.Data_Channel_Number;

   -------------------------------------------------------------------
   --  <name> MAX_ANALYSIS_CHANNEL_PF </name>
   --  <description>
   --     Proof function used as a proof constant describing the maximum location
   --  *  of a upper or lower limit of either a background region or peak
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns">
   --     The proof constant
   --  </Returns>
   -------------------------------------------------------------------
   --# function MAX_ANALYSIS_CHANNEL_PF return Channel_Types.Data_Channel_Number;

   -------------------------------------------------------------------
   --  <name> MIN_ANALYSIS_CHANNEL_PF </name>
   --  <description>
   --     Proof function used as a proof constant describing the minimum location
   --  *  of a upper or lower limit of either a background region or peak
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns">
   --     The proof constant
   --  </Returns>
   -------------------------------------------------------------------
   --# function MIN_ANALYSIS_CHANNEL_PF return Channel_Types.Data_Channel_Number;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Critical_Limit </name>
   --  <description> Calculate the Currie Critical Limit of a passed in peak
   --  *             and return whether it passes the test
   --  </description>
   --  <input name="Confidence">
   --     The required confidence level
   --  </input><input name="Peak_ROI_Locations">
   --     The details of the specification of the peak being analysed
   --  </input><input name="Peak_ROI">
   --     The ROI to run the Currie Critical Test on
   --  </input>
   --  <returns>
   --     The channel containing the maximum count
   --  </returns>
   -------------------------------------------------------------------
   function Critical_Limit
     (Confidence         : in Mod_Types.Unsigned_16;
      Peak_ROI_Locations : in Region_Of_Interest.Peak_ROI_Locations_Type;
      Peak_ROI           : in Region_Of_Interest.Region_Of_Interest_Type)
      return               Boolean;
   --# pre Peak_ROI_Locations.Background1_LL < Peak_ROI_Locations.Background1_UL and
   --#      Peak_ROI_Locations.Background1_UL - Peak_ROI_Locations.Background1_LL + 1 < MAX_WIDTH_PF and
   --#      Peak_ROI_Locations.Background1_UL - Peak_ROI_Locations.Background1_LL + 1 >= MIN_WIDTH_PF and
   --#      Peak_ROI_Locations.Background1_UL <= Peak_ROI_Locations.Peak_LL and
   --#      Peak_ROI_Locations.Peak_LL < Peak_ROI_Locations.Peak_UL and
   --#      Peak_ROI_Locations.Peak_UL - Peak_ROI_Locations.Peak_LL + 1 < MAX_WIDTH_PF and
   --#      Peak_ROI_Locations.Peak_UL - Peak_ROI_Locations.Peak_LL + 1 >= MIN_WIDTH_PF and
   --#      Peak_ROI_Locations.Peak_UL <= Peak_ROI_Locations.Background2_LL and
   --#      Peak_ROI_Locations.Background2_LL < Peak_ROI_Locations.Background2_UL and
   --#      Peak_ROI_Locations.Background2_UL - Peak_ROI_Locations.Background2_LL + 1 < MAX_WIDTH_PF and
   --#      Peak_ROI_Locations.Background2_UL - Peak_ROI_Locations.Background2_LL + 1 >= MIN_WIDTH_PF and
   --#      Peak_ROI_Locations.Background1_LL >= MIN_ANALYSIS_CHANNEL_PF and
   --#      Peak_ROI_Locations.Background1_UL <= MAX_ANALYSIS_CHANNEL_PF and
   --#      Peak_ROI_Locations.Background2_LL >= MIN_ANALYSIS_CHANNEL_PF and
   --#      Peak_ROI_Locations.Background2_UL <= MAX_ANALYSIS_CHANNEL_PF and
   --#      Peak_ROI'first <= Peak_ROI_Locations.Background1_LL and
   --#      Peak_ROI'last >= Peak_ROI_Locations.Background2_UL;
   pragma Inline (Critical_Limit);

private
   -------------------------------------------------------------------
   --  <name> Calculate_Background_Variance </name>
   --  <description> Calculate the variance caused by the background
   --                on one side of the peak
   --  </description>
   --  <input name="Upper_Channel_Centre">
   --     The centroid of rhs region
   --     For the upper background, this will be background 2
   --     For the lower background, this will be the peak
   --  </input><input name="Lower_Channel_Centre">
   --     The centroid of rhs region
   --     For the upper background, this will be the peak
   --     For the lower background, this will be background 1
   --  </input><input name="Width_Of_Peak">
   --     The width of the peak
   --  </input><input name="BG_Centre_Difference">
   --     The difference between the centre point of background regions 1 and 2
   --  </input><input name="Background_UL">
   --     The upper limit of the background region
   --  </input><input name="Background_LL">
   --     The lower limit of the background region
   --  </input><input name="Search_Array">
   --     The ROI to which the FWHM is being applied
   --  </input>
   --  <returns>
   --     The variance due to the passed in background region
   --  </returns>
   -------------------------------------------------------------------
   function Calculate_Background_Variance (Upper_Channel_Centre : in Mod_Types.Unsigned_16;
                                           Lower_Channel_Centre : in Mod_Types.Unsigned_16;
                                           Width_Of_Peak        : in Channel_Types.Data_Channel_Number;
                                           BG_Centre_Difference : in Channel_Types.Data_Channel_Number;
                                           Background_UL        : in Channel_Types.Data_Channel_Number;
                                           Background_LL        : in Channel_Types.Data_Channel_Number;
                                           Search_Array         : in Region_Of_Interest.Region_Of_Interest_Type)
                                              return Mod_Types.Unsigned_16;
   --# pre Upper_Channel_Centre > Lower_Channel_Centre and
   --#     BG_Centre_Difference > 0 and
   --#     Width_Of_Peak <  MAX_WIDTH_PF and
   --#     Width_Of_Peak >= MIN_WIDTH_PF and
   --#     Background_UL - Background_LL + 1 <  MAX_WIDTH_PF and
   --#     Background_UL - Background_LL + 1 >= MIN_WIDTH_PF and
   --#     Background_UL > Background_LL and
   --#     Search_Array'first <= Background_LL and
   --#     Search_Array'last  >= Background_UL;
   pragma Inline (Calculate_Background_Variance);
end Toolbox.Currie;
