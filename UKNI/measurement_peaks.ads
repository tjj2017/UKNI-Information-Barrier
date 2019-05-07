----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement_Peaks
--  Stored Filename: $Id: Measurement_Peaks.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: C Marsh
--  Date Created: 15/11/13
--  <description>
--               Package container for the definition of a isotopic peaks
--  </description>
----------------------------------------------------------------------

with Mod_Types,
     Channel_Types,
     Region_Of_Interest,
     Toolbox;

use type Mod_Types.Unsigned_8,
    Mod_Types.Unsigned_32,
    Mod_Types.Unsigned_64,
    Channel_Types.Data_Channel_Number;

--# inherit Channel_Types,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Toolbox,
--#         Toolbox.Maths,
--#         Usart1;

package Measurement_Peaks
--# own State;

--# initializes State;
 is

   -------------------------------------------------------------------
   --  Constants Section 1
   -------------------------------------------------------------------
   --  The Isotopics ROI starts at channel 2931 as far as the sample data goes
   ISO_ROI_OFFSET          : constant := 2931;
   EXTENDED_ISO_ROI_OFFSET : constant := ISO_ROI_OFFSET * Toolbox.MULT;

   --  Constant part of the Gaussian Constant
   --  The peaks Gaussian Constant is dependant on the FWHM
   --  Calculated as -1*4*ln(2) * 16384^3
   GG_CONST                : constant := -12193974156573;

   --  The default starting value for the FWHM is 7.4
   --  This has been calculated from analysis of previous recorded distributions
   --  ASSUMES a mult of 16384
   FWHM_DEFAULT            : constant := 121242;

   --  Energy constants
   --  For accuracy, these need to be precalculated
   --  ASSUMES a mult of 16384
   --  calculated as ((energy * 16384) - CAL_OFFSET) * 16384) / GAIN where
   --  Eu152_LO_ENERGY := 1995271; --  121.7817kEv * mult
   --  Hi energy peak is at 778.904
   --  Lo energy peak is at 121.7817
   --  ENERGY_DIFFERENCE := 10766292; -> (778.904 - 121.7817) * 16384
   --  PEAK_DIFFERENCE := EU152_778_CENTRE_CHANNEL - EU152_121_CENTRE_CHANNEL;
   --  CAL_OFFSET := Eu152_LO_ENERGY - (ENERGY_DIFFERENCE * EU152_121_CENTRE_CHANNEL) / PEAK_DIFFERENCE
   --  Gain := ENERGY_DIFFERENCE / PEAK_DIFFERENCE
   Peak_637_Pu239_ENERGY     : constant := 48339211;  --  Energy of the 637 Peak
   Peak_640_Pu239_ENERGY     : constant := 48508846;  --  Energy of the 640 Peak
   Peak_641_Am241_ENERGY     : constant := 48610790;  --  Energy of the 641 Peak
   Peak_642_Pu240_ENERGY     : constant := 48691133;  --  Energy of the 642 Peak
   Peak_645_Pu239_ENERGY     : constant := 48955587;  --  Energy of the 645 Peak
   Peak_662_Am241_ENERGY     : constant := 50202509;  --  Energy of the 662 Peak

   -------------------------------------------------------------------
   --  Types
   -------------------------------------------------------------------

   --  An offset of anywhere within the Data channel numbers may need to be applied
   --  during calculations
   --  If this is greater than 1 channel apart, then there is an issue with
   --  the calibraiton
   subtype Difference_Type is Long_Integer range
     -1 * Toolbox.MULT .. 1 * Toolbox.MULT;

   --  ASVAT add missing type declaration.  This is probably not the same as
   --  the mising declaration.
   subtype ISO_Difference_Type is Difference_Type;

   --  Type containing the valid range for the FWHM
   subtype ISO_FWHM_Type is Mod_Types.Unsigned_32 range 6 * Toolbox.MULT .. 9 * Toolbox.MULT;

   --  Type and variable for the Gaussian Constant
   --  -1*4*log(2)) / FWHM ^ 2
   --  FWHM range is 6 .. 9 therefore min g_const is -1261
   --                            and max g_const is -560
   subtype G_Const_Type is Integer range -1261 .. -560;

   --  the size of the array for the Pu240 peak at 640keV
   subtype ROI_640_Size is Channel_Types.Data_Channel_Number range 0 .. 54;

   subtype Extended_Height_Type is Mod_Types.Unsigned_32 range 0 ..
     Mod_Types.Unsigned_32 (Mod_Types.Unsigned_16'Last) * Toolbox.MULT;

   --  subtype for containing the Pu240 peak at 640keV
   type ROI_640_Type is array (ROI_640_Size) of Extended_Height_Type;

   --  Type definition of peaks
   type ISO_Identifier_Type is (Peak_637_Pu239,
                                Peak_640_Pu239,
                                Peak_641_Am241,
                                Peak_642_Pu240,
                                Peak_645_Pu239,
                                Peak_662_Am241);

   --  The maximum energy we are interested in the isotopics region is 662
   subtype ISO_Channel_Type is Mod_Types.Unsigned_64 range
     Peak_637_Pu239_ENERGY .. Peak_662_Am241_ENERGY;

   --  Type for IB Channels at
   type ISO_Information_Type is array (ISO_Identifier_Type) of
     ISO_Channel_Type;

   --  ASVAT add missing type declaration.  This is probably not the same as
   --  the mising declaration.
   subtype Extended_Channel_Type is Mod_Types.Unsigned_64;

   -------------------------------------------------------------------
   --  Constants section 2
   -------------------------------------------------------------------

   --  Array containing where the peaks should be
   ROI_Peak : constant ISO_Information_Type := ISO_Information_Type'(Peak_637_Pu239_ENERGY,
                                                                     Peak_640_Pu239_ENERGY,
                                                                     Peak_641_Am241_ENERGY,
                                                                     Peak_642_Pu240_ENERGY,
                                                                     Peak_645_Pu239_ENERGY,
                                                                     Peak_662_Am241_ENERGY);

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Get_FWHM </name>
   --  <description>
   --               Returns the stored FWHM
   --  </description>
   --  <input name="None">
   --  </input>
   --  <returns>
   --               the stored FWHM.
   --  </returns>
   -------------------------------------------------------------------
   function Get_FWHM return ISO_FWHM_Type;
   --# global in State;

   -------------------------------------------------------------------
   --  <name> Reset_FWHM </name>
   --  <description>
   --               Reset the  FWHM to its default state
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Reset_FWHM;
   --# global out State;
   --# derives State from ;

   -------------------------------------------------------------------
   --  <name> Set_FWHM </name>
   --  <description>
   --               Set the  FWHM
   --  </description>
   --  <input name="FWHM_Value">
   --               The new value for the FWHM
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Set_FWHM (FWHM_Value : in ISO_FWHM_Type);
   --# global out State;
   --# derives State from FWHM_Value;

   -------------------------------------------------------------------
   --  <name> Calculate_Ratio </name>
   --  <description>
   --               Calculates the Pu240 to Pu239 ratio
   --  </description>
   --  <input name="Pu240_Height">
   --     The height of the Pu 240 peak [@*real]
   --  </input><input name="Pu239_Height">
   --     The height of the Pu 240 peak [@*real]
   --  </input>
   --  <Returns>
   --     The calculated Ratio
   --  </output>
   -------------------------------------------------------------------
   function Calculate_Ratio (Pu240_Height   : in     Region_Of_Interest.Peak_Height_Type;
                             Pu239_Height   : in     Region_Of_Interest.Peak_Height_Type)
                             return Mod_Types.Unsigned_32;
   --# pre Pu239_Height > 0;

end Measurement_Peaks;
