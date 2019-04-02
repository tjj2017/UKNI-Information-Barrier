----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement_Peaks.Isotopics
--  Stored Filename: $Id: Measurement-Isotopics.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: C Marsh
--  Date Created: 15/01/14
--  <description>
--               Package containing calculations for the isotopic calculation
--  </description>
----------------------------------------------------------------------
with Channel_Types,
     Measurement_Peaks,
     Mod_Types,
     Region_Of_Interest,
     Toolbox;

use type Channel_Types.Data_Channel_Number,
         Mod_Types.Unsigned_32,
         Mod_Types.Unsigned_64;

--# inherit Calibration,
--#         Calibration_Peak,
--#         Channel_Types,
--#         Measurement,
--#         Measurement_Peaks,
--#         Measurement_Peaks.Curve_Fit,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Toolbox,
--#         Toolbox.Maths,
--#         Toolbox.Peak_Net_Area,
--#         Toolbox.Peak_Search,
--#         Usart1;

private package Measurement.Isotopics
--# own Isotopic_ROI;
is
   ----------------------------------------------------------------------------
   --  START OF REGION OF INTEREST DEFINITIONS FOR THE ISOTOPIC RATIO CALC
   ----------------------------------------------------------------------------
   --  The ROI for the istopic measurement is one large ROI, subdivided into
   --  background regions and peak regions (640kev aggregate region,
   --  Am241 662keV peak region and Pu239 645keV peak region)
   --  Constants and types associated with the peaks

   ISO_662_LL                   : constant := 3055;
   ISO_662_UL                   : constant := 3073;
   ISO_662_CENTRE_CHANNEL       : constant := 3064;
   subtype Pu662_ROI_Index_Type is Channel_Types.Data_Channel_Number range ISO_662_LL .. ISO_662_UL;

   ISO_645_LL                   : constant := 2979;
   ISO_645_UL                   : constant := 2997;
   subtype Pu645_ROI_Index_Type is Channel_Types.Data_Channel_Number range ISO_645_LL .. ISO_645_UL;

   --  The 642keV upper and lower locations are used for the 4 peaks that need to be deconvolved
   --  in order to analyse the Pu240 at 642keV
   ISO_642_LL                   : constant := 2931;
   ISO_642_UL                   : constant := 2985;
   subtype Pu642_ROI_Index_Type is Channel_Types.Data_Channel_Number range ISO_642_LL .. ISO_642_UL;

   --  The centre channel for the Pu240 peak
   ISO_637_PU239_CENTRE_CHANNEL : constant := 2951;
   --  The centre channel for the Pu239 peak
   ISO_640_PU239_CENTRE_CHANNEL : constant := 2961;
   --  The centre channel for the Am241 peak
   ISO_641_AM241_CENTRE_CHANNEL : constant := 2968;
   --  The centre channel for the Pu240 peak
   ISO_642_PU240_CENTRE_CHANNEL : constant := 2972;

   --  The Isotopics ROI is 180 channels wide starting at the ROI_Offset
   ISO_LOWEST_BOUND_ROI         : constant :=
     Channel_Types.Data_Channel_Number (Measurement_Peaks.ISO_ROI_OFFSET);
   ISO_HIGHEST_BOUND_ROI        : constant :=
     Channel_Types.Data_Channel_Number (Measurement_Peaks.ISO_ROI_OFFSET) + 180;

   subtype ISO_ROI_Index_Type is Channel_Types.Data_Channel_Number range
     ISO_LOWEST_BOUND_ROI .. ISO_HIGHEST_BOUND_ROI;
   subtype ISO_ROI_Type is Region_Of_Interest.Region_Of_Interest_Type (ISO_ROI_Index_Type);
   Isotopic_ROI            : ISO_ROI_Type;

   ----------------------------------------------------------------------------
   --  END OF REGION OF INTEREST DEFINITIONS FOR THE ISOTOPIC RATIO CALC
   ----------------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Determine_Isotopic_Ratio </name>
   --  <description>
   --     Determine the Isotopic ratio of the Isotopic ROI
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Peaks_Found">
   --     Boolean flag stating whether the isotopic peaks have been found
   --  </output><output name="Ratio">
   --     The Pu239:Pu240 Ratio [@mult]
   --  </output>
   -------------------------------------------------------------------
   procedure Determine_Isotopic_Ratio  (Peaks_Found : out Boolean;
                                        Ratio       : out Mod_Types.Unsigned_32);
   --# global in     Isotopic_ROI;
   --#        in out Measurement_Peaks.State;
   --# derives Measurement_Peaks.State,
   --#         Peaks_Found,
   --#         Ratio                   from Isotopic_ROI,
   --#                                      Measurement_Peaks.State;
   pragma Inline (Determine_Isotopic_Ratio);

   -------------------------------------------------------------------
   --  <name> Clear_Isotopic_Store </name>
   --  <description>
   --     Clear the Isotopic ROI
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Clear_Isotopic_Store;
   --# global out Isotopic_ROI;
   --# derives Isotopic_ROI from ;
   --# post (for all I in ISO_ROI_Index_Type => (Isotopic_ROI(I) = 0));
   pragma Inline (Clear_Isotopic_Store);

   -------------------------------------------------------------------
   --  <name> Increment_ROI_Element </name>
   --  <description>
   --     Increment an element of the  Isotopic ROI
   --  </description>
   --  <input name="Element">
   --     The element of the Isotopic ROI to be incremented
   --  </input>
   --  <output name="None">
   --  </output>
   -------------------------------------------------------------------
   procedure Increment_ROI_Element (Index : in ISO_ROI_Index_Type);
   --# global in out Isotopic_ROI;
   --# derives Isotopic_ROI from *,
   --#                           Index;
   pragma Inline (Increment_ROI_Element);

private

   -------------------------------------------------------------------
   --  Constants
   -------------------------------------------------------------------

   --  Boundary conditions for location of the 640 peak
   --  The theoretical location of the 637 peak is in channel 2951.
   --  With the ISO offset of 2931, this is in slot 20 of the ROI i.e. at
   --  c. 327680 given a multiplication factor of 16384.  10 channels either
   --  gives the following boundaries
   Pu239_637_Max_Location : constant :=
     (ISO_637_PU239_CENTRE_CHANNEL - Measurement_Peaks.ISO_ROI_OFFSET) *
     Toolbox.MULT + 10 * Toolbox.MULT;
   Pu239_637_Min_Location : constant :=
     (ISO_637_PU239_CENTRE_CHANNEL - Measurement_Peaks.ISO_ROI_OFFSET) *
     Toolbox.MULT - 10 * Toolbox.MULT;

   --  The theoretical location of the 640 peak is in channel 2961
   --  With the ISO offset of 2931, this is in slot 30 of the ROI i.e. at
   --  c. 491520 given a multiplication factor of 16384.  10 channels either
   --  gives the following boundaries
   Pu239_640_Max_Location : constant :=
     (ISO_640_PU239_CENTRE_CHANNEL - Measurement_Peaks.ISO_ROI_OFFSET) *
     Toolbox.MULT + 10 * Toolbox.MULT;
   Pu239_640_Min_Location : constant :=
     (ISO_640_PU239_CENTRE_CHANNEL - Measurement_Peaks.ISO_ROI_OFFSET) *
     Toolbox.MULT - 10 * Toolbox.MULT;

   --  The theoretical location of the 641 peak is in channel 2968
   --  With the ISO offset of 1621, this is in slot 37 of the ROI i.e. at
   --  c. 606208 given a multiplication factor of 16384.  10 channels either
   --  gives the following boundaries
   Am241_641_Max_Location : constant :=
     (ISO_641_AM241_CENTRE_CHANNEL - Measurement_Peaks.ISO_ROI_OFFSET) *
     Toolbox.MULT + 10 * Toolbox.MULT;
   Am241_641_Min_Location : constant :=
     (ISO_641_AM241_CENTRE_CHANNEL - Measurement_Peaks.ISO_ROI_OFFSET) *
     Toolbox.MULT - 10 * Toolbox.MULT;

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Analyse_662_Peak </name>
   --  <description>
   --               Determine the location and height of the 662 peak and then
   --  *            from the location determine the offset to be applied to
   --  *            other peaks.  Also sets the FWHM to be used on when analysing
   --  *            the other peaks
   --  </description>
   --  <input name="None">
   --  </input><
   --  <output name="Location_Difference">
   --               The offset to be applied to the location of all other peaks
   --  </output><output name="Height">
   --               The height of the 662 peak
   --  </output><output name="Curve_Fitted">
   --               Whether the curve fit was successful
   --  </output>
   -------------------------------------------------------------------
   procedure Analyse_662_Peak (Location_Difference : out Measurement_Peaks.Difference_Type;
                               Height              : out Region_Of_Interest.Peak_Height_Type;
                               Curve_Fitted        : out Boolean);
   --# global in     Isotopic_ROI;
   --#        in out Measurement_Peaks.State;
   --# derives Curve_Fitted,
   --#         Height,
   --#         Location_Difference     from Isotopic_ROI &
   --#         Measurement_Peaks.State from *,
   --#                                      Isotopic_ROI;

   -------------------------------------------------------------------
   --  <name> Analyse_645_Peak </name>
   --  <description>
   --               Determine the height of the 645 peak
   --  </description>
   --  <input name="Location_Difference">
   --               The offset to be applied to the location of all other peaks
   --  </input>
   --  <output name="Height">
   --               The height of the 645 peak
   --  </output><output name="Curve_Fitted">
   --               Whether the curve fit was successful
   --  </output>
   -------------------------------------------------------------------
   procedure Analyse_645_Peak (Difference_662 : in  Measurement_Peaks.Difference_Type;
                               Difference_645 : out  Measurement_Peaks.Difference_Type;
                               Height         : out Region_Of_Interest.Peak_Height_Type;
                               Curve_Fitted   : out Boolean);
   --# global in Isotopic_ROI;
   --#        in Measurement_Peaks.State;
   --# derives Curve_Fitted,
   --#         Height         from Difference_662,
   --#                             Isotopic_ROI,
   --#                             Measurement_Peaks.State &
   --#         Difference_645 from Isotopic_ROI;
   --# post  Height > 0 or not Curve_Fitted;

   -------------------------------------------------------------------
   --  <name> Analyse_642_Peak </name>
   --  <description>
   --               Determine the height of the 642 peak
   --  </description>
   --  <input name="Location_Difference">
   --               The offset to be applied to the location of all other peaks
   --  </input>
   --  <input name="Height_662">
   --                The height of the 662 peak
   --  </input>
   --  <input name="Height_645">
   --                The height of the 645 peak
   --  </input>
   --  <output name="Height_642">
   --               The height of the 642 peak
   --  </output><output name="Curve_Fitted">
   --               Whether the curve fit was successful
   --  </output>
   -------------------------------------------------------------------
   procedure Analyse_642_Peak (Location_Difference : in  Measurement_Peaks.Difference_Type;
                               Height_662          : in  Region_Of_Interest.Peak_Height_Type;
                               Height_645          : in  Region_Of_Interest.Peak_Height_Type;
                               Height_642          : out Region_Of_Interest.Peak_Height_Type;
                               Curve_Fitted        : out Boolean);
   --# global in Isotopic_ROI;
   --#        in Measurement_Peaks.State;
   --# derives Curve_Fitted,
   --#         Height_642   from Height_645,
   --#                           Height_662,
   --#                           Isotopic_ROI,
   --#                           Location_Difference,
   --#                           Measurement_Peaks.State;

   -------------------------------------------------------------------
   --  <name> Set_642_Peaks </name>
   --  <description>
   --               Produce a estimate of the composition of the 642 peak
   --  </description>
   --  <input name="Search_Array">
   --     The region of interest to fit a curve to [@*real]
   --  </input><input name="Height_662">
   --               The height of the 662 peak [@*real]
   --  </input><input name="Height_645">
   --               The height of the 645 peak [@*real]
   --  </input><input name="Difference">
   --               The difference betrween the channel where the max is
   --  *            and the calculated centroid
   --  </input>
   --  <output name="Guess_240">
   --               The guestimated 642 peak
   --  </output><output name="Centroid">
   --               The guestimated location of the 642 centroid
   --  </output>><output name="Is_Successful">
   --               Flag stating whether the 642 deconvolution is successful
   --  </output>
   -------------------------------------------------------------------
   procedure Set_642_Peaks (Search_Array  : in     Region_Of_Interest.Region_Of_Interest_Type;
                            Height_662    : in     Region_Of_Interest.Peak_Height_Type;
                            Height_645    : in     Region_Of_Interest.Peak_Height_Type;
                            Difference    : in     Measurement_Peaks.Difference_Type;
                            Guess_240     : out    Measurement_Peaks.ROI_640_Type;
                            Centroid      : out    Channel_Types.Extended_Channel_Type;
                            Is_Successful : out Boolean);
   --# global in Measurement_Peaks.State;
   --# derives Centroid,
   --#         Is_Successful from Difference &
   --#         Guess_240     from Difference,
   --#                            Height_645,
   --#                            Height_662,
   --#                            Measurement_Peaks.State,
   --#                            Search_Array;
   --# pre Search_Array'First >= Channel_Types.Data_Channel_Number'First and
   --#     Search_Array'First <= Channel_Types.Data_Channel_Number'Last and
   --#     Measurement_Peaks.ROI_640_Size'Last + Search_Array'First <= Search_Array'Last and
   --#     Measurement_Peaks.ROI_640_Size'Last <= Search_Array'Last;

   -------------------------------------------------------------------
   --  <name> Find_662_Centroid </name>
   --  <description>
   --     Calculate the position of the Am241 peak at 662 keV
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Centroid">
   --     The position of the Am241 peak at 662 keV [@mult]
   --  </output><output name="Difference">
   --     The differnce of where the 662 peak is from the theoretical location [@mult]
   --  </output><output name="Peak_Found">
   --     Boolean flag stating whether the peak was found
   --  </output>
   -------------------------------------------------------------------
   procedure Find_662_Centroid (Centroid   : out Channel_Types.Extended_Channel_Type;
                                Difference : out Measurement_Peaks.Difference_Type);
   --# global in Isotopic_ROI;
   --# derives Centroid,
   --#         Difference from Isotopic_ROI;
   pragma Inline (Find_662_Centroid);

   -------------------------------------------------------------------
   --  <name> Find_645_Centroid </name>
   --  <description>
   --     Calculate the position of the Pu239 peak at 645 keV
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Centroid">
   --     The position of the Pu239 peak at 645 keV [@mult]
   --  </output><output name="Difference">
   --     The differnce of where the 645 peak is from the theoretical location [@mult]
   --  </output><output name="Peak_Found">
   --     Boolean flag stating whether the peak was found
   --  </output>
   -------------------------------------------------------------------
   procedure Find_645_Centroid (Centroid   : out Channel_Types.Extended_Channel_Type;
                                Difference : out Measurement_Peaks.Difference_Type);
   --# global in Isotopic_ROI;
   --# derives Centroid,
   --#         Difference from Isotopic_ROI;
   pragma Inline (Find_645_Centroid);

   -------------------------------------------------------------------
   --  <name> Calculate_662_Background </name>
   --  <description>
   --     Calculate the background for the 662 peak
   --  </description>
   --  <input name="None">
   --  </input>
   --  <output name="Background">
   --     The background of the 662 peak [@mult]
   --  </output><output name="Centroid_645">
   --     The location of the 645 centroid [@mult]
   --  </output>
   -------------------------------------------------------------------
   procedure Calculate_662_Background (Background : out Mod_Types.Unsigned_32);
   --# global in Isotopic_ROI;
   --# derives Background from Isotopic_ROI;
   pragma Inline (Calculate_662_Background);

   -------------------------------------------------------------------
   --  <name> Fit_662_Curve </name>
   --  <description>
   --     Fit a curve to the 662 peak
   --  </description>
   --  <input name="Peak_Lo">
   --     Estimates of the start of the 662 peak [@mult]
   --  </input><input name="Centroid">
   --     The location of the 662 centroid [@mult]
   --  </input><input name="Background">
   --     The background of the 662 peak [@mult]
   --  </input>
   --  <output name="Height">
   --     The height of the 662 peak
   --  </output><output name="Good_Fit">
   --     Boolean flag stating whether a good fit for the curve was achieved
   --  </output>
   -------------------------------------------------------------------
   procedure Fit_662_Curve (Peak_Lo    : in Pu662_ROI_Index_Type;
                            Centroid   : in Channel_Types.Extended_Channel_Type;
                            Background : in Mod_Types.Unsigned_32;
                            Height     : out Region_Of_Interest.Peak_Height_Type;
                            Good_Fit   : out Boolean);
   --# global in     Isotopic_ROI;
   --#        in out Measurement_Peaks.State;
   --# derives Good_Fit,
   --#         Height                  from Background,
   --#                                      Centroid,
   --#                                      Isotopic_ROI,
   --#                                      Peak_Lo &
   --#         Measurement_Peaks.State from *,
   --#                                      Background,
   --#                                      Centroid,
   --#                                      Isotopic_ROI,
   --#                                      Peak_Lo;
   --# pre Background >= Toolbox.MULT and
   --#     Background <= Mod_Types.Unsigned_32 (Mod_Types.Unsigned_16'Last) * Toolbox.MULT and
   --#     Centroid > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid < Channel_Types.Extended_Channel_Type'Last  - Toolbox.PEAK_EVAL_GUARD;
   pragma Inline (Fit_662_Curve);

   -------------------------------------------------------------------
   --  <name> Fit_645_Curve </name>
   --  <description>
   --     Fit a curve to the 645 peak
   --  </description>
   --  <input name="Peak_Lo">
   --     Estimates of the start of the 645 peak [@mult]
   --  </input><input name="Centroid">
   --     The location of the 645 centroid [@mult]
   --  </input>
   --  <output name="Height">
   --     The height of the 645 peak
   --  </output><output name="Good_Fit">
   --     Boolean flag stating whether a good fit for the curve was achieved
   --  </output>
   -------------------------------------------------------------------
   procedure Fit_645_Curve (Peak_Lo  : in ISO_ROI_Index_Type;
                            Centroid : in Channel_Types.Extended_Channel_Type;
                            Height   : out Region_Of_Interest.Peak_Height_Type;
                            Good_Fit : out Boolean);
   --# global in Isotopic_ROI;
   --#        in Measurement_Peaks.State;
   --# derives Good_Fit,
   --#         Height   from Centroid,
   --#                       Isotopic_ROI,
   --#                       Measurement_Peaks.State,
   --#                       Peak_Lo;
   --# pre Centroid > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid < Channel_Types.Extended_Channel_Type'Last  - Toolbox.PEAK_EVAL_GUARD and
   --#     Peak_Lo in Pu645_ROI_Index_Type;
   pragma Inline (Fit_645_Curve);

   -------------------------------------------------------------------
   --  <name> Deconvolve_642_Triplet </name>
   --  <description>
   --     Extract an estimate of the Pu240 peak from the 642 triplet
   --  </description>
   --  <input name="Height_662_Peak">
   --     The height of the 662 peak
   --  </input><input name="Height_645_Peak">
   --     The height of the 645 peak
   --  </input><input name="Difference">
   --     The difference of where the 662 peak is from the theoretical location [@mult]
   --  </input>
   --  <output name="Guess">
   --     Array containing the estimated Pu640 peak [@mult]
   --  </output><output name="Centroid">
   --     An estimate of the location of the Pu240 centroid [@mult]
   --  </output><output name="Is_Successful">
   --     Boolean flag stating whether the extraction was successful
   --  </output>
   -------------------------------------------------------------------
   procedure Deconvolve_642_Triplet  (Height_662_Peak : in Region_Of_Interest.Peak_Height_Type;
                                      Height_645_Peak : in Region_Of_Interest.Peak_Height_Type;
                                      Difference      : in Measurement_Peaks.Difference_Type;
                                      Guess           : out Measurement_Peaks.ROI_640_Type;
                                      Centroid        : out Channel_Types.Extended_Channel_Type;
                                      Is_Successful   : out Boolean);
   --# global in Isotopic_ROI;
   --#        in Measurement_Peaks.State;
   --# derives Centroid,
   --#         Is_Successful from Difference &
   --#         Guess         from Difference,
   --#                            Height_645_Peak,
   --#                            Height_662_Peak,
   --#                            Isotopic_ROI,
   --#                            Measurement_Peaks.State;
   pragma Inline (Deconvolve_642_Triplet);

   -------------------------------------------------------------------
   --  <name> Fit_642_Curve </name>
   --  <description>
   --     Fit a curve to the 642 peak
   --  </description>
   --  <input name="Peak_Lo">
   --     Estimates of the start of the 642 peak [@mult]
   --  </input><input name="Centroid">
   --     The location of the 642 centroid [@mult]
   --  </input><input name="ROI">
   --     The estimate ROI containing the Pu240 peeak [@mult]
   --  </input>
   --  <output name="Height">
   --     The height of the 642 peak
   --  </output><output name="Good_Fit">
   --     Boolean flag stating whether a good fit for the curve was achieved
   --  </output>
   -------------------------------------------------------------------
   procedure Fit_642_Curve (Peak_Lo  : in Measurement_Peaks.ROI_640_Size;
                            Centroid : in Channel_Types.Extended_Channel_Type;
                            ROI      : in Measurement_Peaks.ROI_640_Type;
                            Height   : out Region_Of_Interest.Peak_Height_Type;
                            Good_Fit : out Boolean);
   --# global in Measurement_Peaks.State;
   --# derives Good_Fit,
   --#         Height   from Centroid,
   --#                       Measurement_Peaks.State,
   --#                       Peak_Lo,
   --#                       ROI;
   --# pre Centroid > Channel_Types.Extended_Channel_Type'First + Toolbox.PEAK_EVAL_GUARD and
   --#     Centroid < Channel_Types.Extended_Channel_Type'Last  - Toolbox.PEAK_EVAL_GUARD and
   --#     Peak_Lo >   Measurement_Peaks.ROI_640_Type'First and
   --#     Peak_Lo <  Measurement_Peaks.ROI_640_Type'Last - Toolbox.PEAK_EVAL_WIDTH;
   pragma Inline (Fit_642_Curve);

   -------------------------------------------------------------------
   --  <name> Calculate_637_Location </name>
   --  <description>
   --               Calculate the location of the 637 centroid from the location of
   --  *            the 645 peak
   --  </description>
   --  <input name="Difference">
   --               The difference between the channel where the 645 centroid is
   --  *            and the calculated centroid
   --  </input>
   --  <output name="Centroid">
   --               The location of the 637 centroid
   --  </output>><output name="Is_Successful">
   --               Flag stating whether the centroid is in a valid location
   --  </output>
   -------------------------------------------------------------------
   procedure Calculate_637_Location (Difference    : in  Measurement_Peaks.Difference_Type;
                                     Centroid      : out Channel_Types.Extended_Channel_Type;
                                     Is_Successful : out Boolean);
   --# derives Centroid,
   --#         Is_Successful from Difference;
   --# post (Centroid <= Pu239_637_Max_Location and
   --#       Centroid >= Pu239_637_Min_Location) or not Is_Successful;
   pragma Inline (Calculate_637_Location);

   -------------------------------------------------------------------
   --  <name> Calculate_640_Location </name>
   --  <description>
   --               Calculate the location of the 640 centroid from the location of
   --  *            the 645 peak
   --  </description>
   --  <input name="Difference">
   --               The difference between the channel where the 645 centroid is
   --  *            and the calculated centroid
   --  </input>
   --  <output name="Centroid">
   --               The location of the 640 centroid
   --  </output>><output name="Is_Successful">
   --               Flag stating whether the centroid is in a valid location
   --  </output>
   -------------------------------------------------------------------
   procedure Calculate_640_Location (Difference    : in  Measurement_Peaks.Difference_Type;
                                     Centroid      : out Channel_Types.Extended_Channel_Type;
                                     Is_Successful : out Boolean);
   --# derives Centroid,
   --#         Is_Successful from Difference;
   --# post (Centroid <= Pu239_640_Max_Location and
   --#       Centroid >= Pu239_640_Min_Location) or not Is_Successful;
   pragma Inline (Calculate_640_Location);

   -------------------------------------------------------------------
   --  <name> Calculate_641_Location </name>
   --  <description>
   --               Calculate the location of the 641 centroid from the location of
   --  *            the 645 peak
   --  </description>
   --  <input name="Difference">
   --               The difference between the channel where the 645 centroid is
   --  *            and the calculated centroid
   --  </input>
   --  <output name="Centroid">
   --               The location of the 641 centroid
   --  </output>><output name="Is_Successful">
   --               Flag stating whether the centroid is in a valid location
   --  </output>
   -------------------------------------------------------------------
   procedure Calculate_641_Location (Difference    : in  Measurement_Peaks.Difference_Type;
                                     Centroid      : out Channel_Types.Extended_Channel_Type;
                                     Is_Successful : out Boolean);
   --# derives Centroid,
   --#         Is_Successful from Difference;
   --# post (Centroid <= Am241_641_Max_Location and
   --#       Centroid >= Am241_641_Min_Location) or not Is_Successful;
   pragma Inline (Calculate_641_Location);

   -------------------------------------------------------------------
   --  <name> Calculate_642_Location </name>
   --  <description>
   --               Calculate the location of the 642 centroid from the location of
   --  *            the 645 peak
   --  </description>
   --  <input name="Difference">
   --               The difference between the channel where the 645 centroid is
   --  *            and the calculated centroid
   --  </input>
   --  <output name="Centroid">
   --               The location of the 642 centroid
   --  </output>><output name="Is_Successful">
   --               Flag stating whether the centroid is in a valid location
   --  </output>
   -------------------------------------------------------------------
   procedure Calculate_642_Location (Difference    : in  Measurement_Peaks.Difference_Type;
                                     Centroid      : out Channel_Types.Extended_Channel_Type;
                                     Is_Successful : out Boolean);
   --# derives Centroid,
   --#         Is_Successful from Difference;
   pragma Inline (Calculate_642_Location);

   -------------------------------------------------------------------
   --  <name> Estimate_640_Peak </name>
   --  <description>
   --               Estimate the 640 peak from within the 642 triplet
   --  </description>
   --  <input name="Search_Array">
   --               The array containing the 642 triplet
   --  </input><input name="Height_637">
   --               The height of the 637 peak
   --  </input><input name="Height_640">
   --               The height of the 640 peak
   --  </input><input name="Height_641">
   --               The height of the 641 peak
   --  </input><input name="Centroid_637">
   --               The centroid location of the 637 peak [@*16384]
   --  </input><input name="Centroid_640">
   --               The centroid location of the 640 peak [@*16384]
   --  </input><input name="Centroid_641">
   --               The centroid location of the 641 peak [@*16384]
   --  </input>
   --  <returns>
   --               The array containing the Pu240 peak
   --  </returns>
   -------------------------------------------------------------------
   function Estimate_640_Peak (Search_Array : in  Region_Of_Interest.Region_Of_Interest_Type;
                               Height_637   : in  Measurement_Peaks.Extended_Height_Type;
                               Height_640   : in  Measurement_Peaks.Extended_Height_Type;
                               Height_641   : in  Measurement_Peaks.Extended_Height_Type;
                               Centroid_637 : in  Channel_Types.Extended_Channel_Type;
                               Centroid_640 : in  Channel_Types.Extended_Channel_Type;
                               Centroid_641 : in  Channel_Types.Extended_Channel_Type)
                               return Measurement_Peaks.ROI_640_Type;
   --# global in Measurement_Peaks.State;
   --# pre Centroid_637 <= Pu239_637_Max_Location and
   --#     Centroid_637 >= Pu239_637_Min_Location and
   --#     Centroid_640 <= Pu239_640_Max_Location and
   --#     Centroid_640 >= Pu239_640_Min_Location and
   --#     Centroid_641 <= Am241_641_Max_Location and
   --#     Centroid_641 >= Am241_641_Min_Location and
   --#     Search_Array'First >= Channel_Types.Data_Channel_Number'First and
   --#     Search_Array'Last <= Channel_Types.Data_Channel_Number'Last and
   --#     Measurement_Peaks.ROI_640_Size'Last + Search_Array'First >= Search_Array'First and
   --#     Measurement_Peaks.ROI_640_Size'Last + Search_Array'First <= Search_Array'Last;
   pragma Inline (Estimate_640_Peak);
end Measurement.Isotopics;
