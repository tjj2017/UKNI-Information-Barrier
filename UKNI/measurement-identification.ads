----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement_Peaks.Identification
--  Stored Filename: $Id: Measurement-Identification.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: C Marsh
--  Date Created: 04/02/14
--  <description>
--               Package containing calculations for the isotopic calculation
--  </description>
----------------------------------------------------------------------
with Channel_Types,
     Mod_Types,
     Region_Of_Interest;

use type Channel_Types.Data_Channel_Number,
         Mod_Types.Unsigned_32,
         Mod_Types.Unsigned_64;

--# inherit Calibration,
--#         Calibration_Peak,
--#         Channel_Types,
--#         Count_Types,
--#         Measurement,
--#         Measurement_Peaks,
--#         Measurement_Peaks.Curve_Fit,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Toolbox,
--#         Toolbox.Currie,
--#         Toolbox.FWHM,
--#         Toolbox.Peak_Net_Area,
--#         Toolbox.Peak_Search,
--#         Usart1;

private package Measurement.Identification
--# own ID_ROI;
is

   ----------------------------------------------------------------------------
   --  START OF REGION OF INTEREST DEFINITIONS FOR THE PU239 ID CALC
   ----------------------------------------------------------------------------
   --  The ROI for the Pu239 ID is one large ROI, subdivided into background
   --  regions and peak regions for the five Pu 239 peaks to be measured.
   --  The peaks are (345.008, 375.045, 392.56/393.136 doublet, 413.707 and
   --  451.480keV).

   --  Constants and types associated with the peaks
   ID_ROI_345_LL                 : constant := 1586;
   ID_ROI_345_UL                 : constant := 1606;
   ID_ROI_345_CENTRE_CHANNEL     : constant := ((ID_ROI_345_UL - ID_ROI_345_LL) / 2) + ID_ROI_345_LL;
   subtype ID_ROI_345_Index_Type is Channel_Types.Data_Channel_Number range ID_ROI_345_LL .. ID_ROI_345_UL;
   subtype ID_ROI_345_Array_Type is Region_Of_Interest.Region_Of_Interest_Type (ID_ROI_345_Index_Type);

   ID_ROI_375_LL                 : constant := 1725;
   ID_ROI_375_UL                 : constant := 1745;
   ID_ROI_375_CENTRE_CHANNEL     : constant := ((ID_ROI_375_UL - ID_ROI_375_LL) / 2) + ID_ROI_375_LL;
   subtype ID_ROI_375_Index_Type is Channel_Types.Data_Channel_Number range ID_ROI_375_LL .. ID_ROI_375_UL;
   subtype ID_ROI_375_Array_Type is Region_Of_Interest.Region_Of_Interest_Type (ID_ROI_375_Index_Type);

   ID_ROI_DOUBLET_LL             : constant := 1805;
   ID_ROI_DOUBLET_UL             : constant := 1829;
   ID_ROI_DOUBLET_CENTRE_CHANNEL : constant := ((ID_ROI_DOUBLET_UL - ID_ROI_DOUBLET_LL) / 2) + ID_ROI_DOUBLET_LL;
   subtype ID_ROI_DOUBLET_Index_Type is Channel_Types.Data_Channel_Number range ID_ROI_DOUBLET_LL .. ID_ROI_DOUBLET_UL;
   subtype ID_ROI_DOUBLET_Array_Type is Region_Of_Interest.Region_Of_Interest_Type (ID_ROI_DOUBLET_Index_Type);

   ID_ROI_413_LL                 : constant := 1902;
   ID_ROI_413_UL                 : constant := 1926;
   ID_ROI_413_CENTRE_CHANNEL     : constant := ((ID_ROI_413_UL - ID_ROI_413_LL) / 2) + ID_ROI_413_LL;
   subtype ID_ROI_413_Index_Type is Channel_Types.Data_Channel_Number range ID_ROI_413_LL .. ID_ROI_413_UL;
   subtype ID_ROI_413_Array_Type is Region_Of_Interest.Region_Of_Interest_Type (ID_ROI_413_Index_Type);

   ID_ROI_451_LL                 : constant := 2075;
   ID_ROI_451_UL                 : constant := 2101;
   ID_ROI_451_CENTRE_CHANNEL     : constant := ((ID_ROI_451_UL - ID_ROI_451_LL) / 2) + ID_ROI_451_LL;
   subtype ID_ROI_451_Index_Type is Channel_Types.Data_Channel_Number range ID_ROI_451_LL .. ID_ROI_451_UL;
   subtype ID_ROI_451_Array_Type is Region_Of_Interest.Region_Of_Interest_Type (ID_ROI_451_Index_Type);

   --  Constants associated with the backgrounds
   ID_BG_ROI_1_LL : constant := 1505;
   ID_BG_ROI_1_UL : constant := 1525;

   ID_BG_ROI_2_LL : constant := 1624;
   ID_BG_ROI_2_UL : constant := 1660;

   ID_BG_ROI_3_LL : constant := 1780;
   ID_BG_ROI_3_UL : constant := 1804;

   ID_BG_ROI_4_LL : constant := 1846;
   ID_BG_ROI_4_UL : constant := 1890;

   ID_BG_ROI_5_LL : constant := 2000;
   ID_BG_ROI_5_UL : constant := 2046;

   ID_BG_ROI_6_LL : constant := 2110;
   ID_BG_ROI_6_UL : constant := 2150;

   --  Constants and types defining the start and end of the identification ROI
   ID_LOWEST_BOUND_ROI  : constant := ID_BG_ROI_1_LL;
   ID_HIGHEST_BOUND_ROI : constant := ID_BG_ROI_6_UL;

   subtype ID_ROI_Index_Type is Channel_Types.Data_Channel_Number range
     ID_LOWEST_BOUND_ROI .. ID_HIGHEST_BOUND_ROI;
   subtype ID_ROI_Type is Region_Of_Interest.Region_Of_Interest_Type (ID_ROI_Index_Type);
   ID_ROI    : ID_ROI_Type;

   --  For use with the toolbox, define a set of ROI locations for each region
   ID_ROI_345_Locations : constant Region_Of_Interest.Peak_ROI_Locations_Type :=
     Region_Of_Interest.Peak_ROI_Locations_Type'
       (Ideal_Centre_Channel => ID_ROI_345_CENTRE_CHANNEL,
        Background1_LL       => ID_BG_ROI_1_LL,
        Background1_UL       => ID_BG_ROI_1_UL,
        Peak_LL              => ID_ROI_345_LL,
        Peak_UL              => ID_ROI_345_UL,
        Background2_LL       => ID_BG_ROI_2_LL,
        Background2_UL       => ID_BG_ROI_2_UL);

   ID_ROI_375_Locations : constant Region_Of_Interest.Peak_ROI_Locations_Type :=
     Region_Of_Interest.Peak_ROI_Locations_Type'
       (Ideal_Centre_Channel => ID_ROI_375_CENTRE_CHANNEL,
        Background1_LL       => ID_BG_ROI_2_LL,
        Background1_UL       => ID_BG_ROI_2_UL,
        Peak_LL              => ID_ROI_375_LL,
        Peak_UL              => ID_ROI_375_UL,
        Background2_LL       => ID_BG_ROI_3_LL,
        Background2_UL       => ID_BG_ROI_3_UL);

   ID_ROI_DOUBLET_Locations : constant Region_Of_Interest.Peak_ROI_Locations_Type :=
     Region_Of_Interest.Peak_ROI_Locations_Type'
       (Ideal_Centre_Channel => ID_ROI_DOUBLET_CENTRE_CHANNEL,
        Background1_LL       => ID_BG_ROI_3_LL,
        Background1_UL       => ID_BG_ROI_3_UL,
        Peak_LL              => ID_ROI_DOUBLET_LL,
        Peak_UL              => ID_ROI_DOUBLET_UL,
        Background2_LL       => ID_BG_ROI_4_LL,
        Background2_UL       => ID_BG_ROI_4_UL);

   ID_ROI_413_Locations     : constant Region_Of_Interest.Peak_ROI_Locations_Type :=
     Region_Of_Interest.Peak_ROI_Locations_Type'
       (Ideal_Centre_Channel => ID_ROI_413_CENTRE_CHANNEL,
        Background1_LL       => ID_BG_ROI_4_LL,
        Background1_UL       => ID_BG_ROI_4_UL,
        Peak_LL              => ID_ROI_413_LL,
        Peak_UL              => ID_ROI_413_UL,
        Background2_LL       => ID_BG_ROI_5_LL,
        Background2_UL       => ID_BG_ROI_5_UL);

   ID_ROI_451_Locations : constant Region_Of_Interest.Peak_ROI_Locations_Type :=
     Region_Of_Interest.Peak_ROI_Locations_Type'
       (Ideal_Centre_Channel => ID_ROI_451_CENTRE_CHANNEL,
        Background1_LL       => ID_BG_ROI_5_LL,
        Background1_UL       => ID_BG_ROI_5_UL,
        Peak_LL              => ID_ROI_451_LL,
        Peak_UL              => ID_ROI_451_UL,
        Background2_LL       => ID_BG_ROI_6_LL,
        Background2_UL       => ID_BG_ROI_6_UL);

   ----------------------------------------------------------------------------
   --  END OF REGION OF INTEREST DEFINITIONS FOR THE PU239 ID CALC
   ----------------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Identify_Pu239 </name>
   --  <description>
   --     Determine whether Pu239 is present or not
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Pu_Present">
   --     Boolean flag stating whether the identification peaks have been found
   --  </output
   -------------------------------------------------------------------
   procedure Identify_Pu239 (Pu_Present : out Boolean);
   --# global in ID_ROI;
   --# derives Pu_Present from ID_ROI;
   pragma Inline (Identify_Pu239);

   -------------------------------------------------------------------
   --  <name> Clear_Identification_Store </name>
   --  <description>
   --     Clear the Identification ROI
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Clear_Identification_Store;
   --# global out ID_ROI;
   --# derives ID_ROI from ;
   --# post (for all I in ID_ROI_Index_Type => (ID_ROI(I) = 0));
   pragma Inline (Clear_Identification_Store);

   -------------------------------------------------------------------
   --  <name> Increment_ROI_Element </name>
   --  <description>
   --     Increment an element of the  Identification ROI
   --  </description>
   --  <input name="Index">
   --     The element of the Identification ROI to be incremented
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Increment_ROI_Element (Index : in ID_ROI_Index_Type);
   --# global in out ID_ROI;
   --# derives ID_ROI from *,
   --#                     Index;
   pragma Inline (Increment_ROI_Element);

private

   -------------------------------------------------------------------
   --  <name> Test_Centroid_Locations </name>
   --  <description>
   --     Test to see whether the centroids are in the expected locations
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns>
   --     Boolean flag stating whether the peaks are in the expected locations
   --  </Returns>
   -------------------------------------------------------------------
   function Test_Centroid_Locations return Boolean;
   --# global in ID_ROI;

   -------------------------------------------------------------------
   --  <name> Test_Critical_Limit </name>
   --  <description>
   --     Perfom the Currie critical test on the 5 ID peaks
   --  </description>
   --  <input name="None">
   --  </input>
   --  <Returns>
   --     Boolean flag stating whether the peaks passed the Currie critical Test
   --  </Returns>
   -------------------------------------------------------------------
   function Test_Critical_Limit return Boolean;
   --# global in ID_ROI;
   pragma Inline (Test_Critical_Limit);

   -------------------------------------------------------------------
   --  <name> Test_FWHM_Limits </name>
   --  <description>
   --     Calculate the FWHM for the non-doublet peaks and ensure that the
   --  *  results are within the set limit
   --  </description>
   --  <input name="None">
   --  </input>
   --  </Returns>
   --     Boolean flag stating whether the peaks passed the FWHM Test
   --  </Returns>
   -------------------------------------------------------------------
   function Test_FWHM_Limits return Boolean;
   --# global in ID_ROI;
   pragma Inline (Test_FWHM_Limits);

   -------------------------------------------------------------------
   --  <name> Peak_Present </name>
   --  <description>
   --     Checks whether there is a peak within the specified part of the passed
   --  *  in region of interest
   --  </description>
   --  <input name="Peak_ROI">
   --     The region of interest to be checked
   --  </input><input name="Ideal_Location">
   --     The expected location of the peak
   --  </input>
   --  </output><output name="ID_Peak_Present">
   --     Boolean flag stating whether the peaks  is present
   --  </output>
   -------------------------------------------------------------------
   procedure Peak_Present (Peak_ROI        : in  Region_Of_Interest.Region_Of_Interest_Type;
                           Ideal_Location  : in  Channel_Types.Extended_Channel_Type;
                           ID_Peak_Present : out Boolean);
   --# derives ID_Peak_Present from Ideal_Location,
   --#                              Peak_ROI;
   --# pre Peak_ROI'Length(1) > 5 and
   --#     Peak_ROI'Last < 4090 and
   --#     Ideal_Location >= Channel_Types.Extended_Channel_Type'First + Toolbox.MULT and
   --#     Ideal_Location <= Channel_Types.Extended_Channel_Type'First - Toolbox.MULT;
   pragma Inline (Peak_Present);

end Measurement.Identification;
