----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Measurement.Identification
--  Stored Filename: $Id: Measurement-Identification.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: C Marsh
--  Date Created: 04/02/14
--  Description: This private child package handles the isotopic calculations
----------------------------------------------------------------------

with Toolbox.Currie,
     Toolbox.FWHM,
     Toolbox.Peak_Search,
     Usart1;

package body Measurement.Identification is

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Peak_Present
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Peak_Present (Peak_ROI        : in  Region_Of_Interest.Region_Of_Interest_Type;
                           Ideal_Location  : in  Channel_Types.Extended_Channel_Type;
                           ID_Peak_Present : out Boolean)
   is
      --  The centroid location
      Centroid   : Channel_Types.Extended_Channel_Type;

      --  Flag indicating whether Find_Centroid was succcessful
      Peak_Found : Boolean;

   begin
      Toolbox.Peak_Search.Find_Centroid (Search_Array   => Peak_ROI,
                                         Centroid       => Centroid,
                                         Is_Successful => Peak_Found);

      ID_Peak_Present := (Centroid >= Ideal_Location - 2 * Toolbox.MULT) and
        (Centroid <= Ideal_Location + 2 * Toolbox.MULT) and
        Peak_Found;

   end Peak_Present;

   -------------------------------------------------------------------
   --  Name       : Test_Centroid_Locations
   --  Implementation Information: Not a true function, as engineering
   --                              debug calls are made which change the
   --                              register state.
   -------------------------------------------------------------------
   function Test_Centroid_Locations return Boolean
   is

      -------------------------------------------------------------------
      --  Variables
      -------------------------------------------------------------------
      Peak_Present_345        : Boolean;
      Peak_Present_375        : Boolean;
      Peak_Present_413        : Boolean;
      Peak_Present_Doublet    : Boolean;
      Peak_Present_451        : Boolean;

      ID_345_ROI              : ID_ROI_345_Array_Type := ID_ROI_345_Array_Type'(others => 0);
      ID_375_ROI              : ID_ROI_375_Array_Type := ID_ROI_375_Array_Type'(others => 0);
      ID_DOUBLET_ROI          : ID_ROI_DOUBLET_Array_Type := ID_ROI_DOUBLET_Array_Type'(others => 0);
      ID_413_ROI              : ID_ROI_413_Array_Type := ID_ROI_413_Array_Type'(others => 0);
      ID_451_ROI              : ID_ROI_451_Array_Type := ID_ROI_451_Array_Type'(others => 0);

      -------------------------------------------------------------------
      --  Constants
      -------------------------------------------------------------------
      --  from analysis of data, the ideal centroid locations are
      --  345: 1595.7 -> 26143949
      --  375: 1734.6 -> 28419686
      --  dou: 1817.3 -> 29774643
      --  413: 1913.5 -> 31350784
      --  451: 2088.2 -> 34213069

      --  The ideal 345 location
      ID_345_LOCATION         : constant := 26143949;

      --  The ideal 375 location
      ID_375_LOCATION         : constant := 28419686;

      --  The ideal doublet location
      ID_DOUBLET_LOCATION     : constant := 29774643;

      --  The ideal 413 location
      ID_413_LOCATION         : constant := 31350784;

      --  The ideal 451 location
      ID_451_LOCATION         : constant := 34213069;
   begin
      Usart1.Send_Message_New_Line;
      Usart1.Send_String ("Centroid");
      Usart1.Send_Message_New_Line;

      --  Cannot array slice, so iteratively get the 345 region
      for I in Channel_Types.Data_Channel_Number range ID_ROI_345_Array_Type'Range loop
         ID_345_ROI (I) := ID_ROI (I);
      end loop;

      --  Check for the presense of the 345 peak
      Peak_Present (Peak_ROI        => ID_345_ROI,
                    Ideal_Location  => ID_345_LOCATION,
                    ID_Peak_Present => Peak_Present_345);

      --  Cannot array slice, so iteratively get the 375 region
      for I in Channel_Types.Data_Channel_Number range ID_ROI_375_Array_Type'Range loop
         ID_375_ROI (I) := ID_ROI (I);
      end loop;

      --  Check for the presense of the 375 peak
      Peak_Present (Peak_ROI        => ID_375_ROI,
                    Ideal_Location  => ID_375_LOCATION,
                    ID_Peak_Present => Peak_Present_375);

      --  Cannot array slice, so iteratively get the doublet
      for I in Channel_Types.Data_Channel_Number range ID_ROI_DOUBLET_Array_Type'Range loop
         ID_DOUBLET_ROI (I) := ID_ROI (I);
      end loop;

      --  Check for the presense of the doublet
      Peak_Present (Peak_ROI        => ID_DOUBLET_ROI,
                    Ideal_Location  => ID_DOUBLET_LOCATION,
                    ID_Peak_Present => Peak_Present_Doublet);

      --  Cannot array slice, so iteratively get the 413 region
      for I in Channel_Types.Data_Channel_Number range ID_ROI_413_Array_Type'Range loop
         ID_413_ROI (I) := ID_ROI (I);
      end loop;

      --  Check for the presense of the 413 peak
      Peak_Present (Peak_ROI        => ID_413_ROI,
                    Ideal_Location  => ID_413_LOCATION,
                    ID_Peak_Present => Peak_Present_413);

      --  Cannot array slice, so iteratively get the 451 region
      for I in Channel_Types.Data_Channel_Number range ID_ROI_451_Array_Type'Range loop
         ID_451_ROI (I) := ID_ROI (I);
      end loop;

      --  Check for the presense of the 451 peak
      Peak_Present (Peak_ROI        => ID_451_ROI,
                    Ideal_Location  => ID_451_LOCATION,
                    ID_Peak_Present => Peak_Present_451);

      --# accept F, 10, "Ineffective statement due to declaration of the send string annotation";
      if Peak_Present_345 and Peak_Present_375 and Peak_Present_Doublet and
        Peak_Present_413 and Peak_Present_451 then
         Usart1.Send_String (Item => "Pass");
      else
         Usart1.Send_String (Item => "Fail");
      end if;
      Usart1.Send_Message_New_Line;

      return Peak_Present_345 and Peak_Present_375 and Peak_Present_Doublet and
        Peak_Present_413 and Peak_Present_451;
   end Test_Centroid_Locations;

   -------------------------------------------------------------------
   --  Name       : Test_Critical_Limit
   --  Implementation Information: Not a true function, as engineering
   --                              debug calls are made which change the
   --                              register state..
   -------------------------------------------------------------------
   function Test_Critical_Limit return Boolean
   is
      Peak_Present_345        : Boolean;
      Peak_Present_375        : Boolean;
      Peak_Present_413        : Boolean;
      Peak_Present_Doublet    : Boolean;
      Peak_Present_451        : Boolean;
   begin

      Usart1.Send_Message_New_Line;
      Usart1.Send_String (Item => "CL");
      Usart1.Send_Message_New_Line;

      Peak_Present_345 := Toolbox.Currie.Critical_Limit (Confidence         => Toolbox.Currie.CONFIDENCE_95_PERCENT,
                                                         Peak_ROI_Locations => ID_ROI_345_Locations,
                                                         Peak_ROI           => ID_ROI);

      Peak_Present_375 := Toolbox.Currie.Critical_Limit (Confidence         => Toolbox.Currie.CONFIDENCE_95_PERCENT,
                                                         Peak_ROI_Locations => ID_ROI_375_Locations,
                                                         Peak_ROI           => ID_ROI);

      Peak_Present_Doublet := Toolbox.Currie.Critical_Limit (Confidence         => Toolbox.Currie.CONFIDENCE_95_PERCENT,
                                                             Peak_ROI_Locations => ID_ROI_DOUBLET_Locations,
                                                             Peak_ROI           => ID_ROI);

      Peak_Present_413 := Toolbox.Currie.Critical_Limit (Confidence         => Toolbox.Currie.CONFIDENCE_95_PERCENT,
                                                         Peak_ROI_Locations => ID_ROI_413_Locations,
                                                         Peak_ROI           => ID_ROI);

      Peak_Present_451 := Toolbox.Currie.Critical_Limit (Confidence         => Toolbox.Currie.CONFIDENCE_95_PERCENT,
                                                         Peak_ROI_Locations => ID_ROI_451_Locations,
                                                         Peak_ROI           => ID_ROI);

      --# accept F, 10, "Ineffective statement due to declaration of the send string annotation";
      if Peak_Present_345 and Peak_Present_375 and Peak_Present_Doublet and
        Peak_Present_413 and Peak_Present_451 then
         Usart1.Send_String (Item => "Pass");
      else
         Usart1.Send_String (Item => "Fail");
      end if;
      Usart1.Send_Message_New_Line;

      return Peak_Present_345 and Peak_Present_375 and Peak_Present_Doublet and Peak_Present_413 and Peak_Present_451;
   end Test_Critical_Limit;

   -------------------------------------------------------------------
   --  Name       : Test_FWHM_Limits
   --  Implementation Information: None.
   -------------------------------------------------------------------
   function Test_FWHM_Limits return Boolean
   is

      -------------------------------------------------------------------
      --  Constant and type definitions of allowable FWHM ranges
      -------------------------------------------------------------------
      CHANNEL        : constant := 1000;
      --  Ideal FWHM values based on experimental data
      --  345: 5613 +/- 1 ch
      --  375: 5989 +/- 1 ch
      --  413: 6201 +/- 1 ch
      --  451: 6006 +/- 1 ch
      FWHM_345_IDEAL : constant := 5613;
      FWHM_345_MAX   : constant := FWHM_345_IDEAL + CHANNEL;
      FWHM_345_MIN   : constant := FWHM_345_IDEAL - CHANNEL;

      subtype Allowable_345_FWHM_Range is Mod_Types.Unsigned_32 range
        FWHM_345_MIN .. FWHM_345_MAX;

      FWHM_375_IDEAL : constant := 5989;
      FWHM_375_MAX   : constant := FWHM_375_IDEAL + CHANNEL;
      FWHM_375_MIN   : constant := FWHM_375_IDEAL - CHANNEL;

      subtype Allowable_375_FWHM_Range is Mod_Types.Unsigned_32 range
        FWHM_375_MIN .. FWHM_375_MAX;

      FWHM_413_IDEAL : constant := 6201;
      FWHM_413_MAX   : constant := FWHM_413_IDEAL + CHANNEL;
      FWHM_413_MIN   : constant := FWHM_413_IDEAL - CHANNEL;

      subtype Allowable_413_FWHM_Range is Mod_Types.Unsigned_32 range
        FWHM_413_MIN .. FWHM_413_MAX;

      FWHM_451_IDEAL : constant := 6006;
      FWHM_451_MAX   : constant := FWHM_451_IDEAL + CHANNEL;
      FWHM_451_MIN   : constant := FWHM_451_IDEAL - CHANNEL;

      subtype Allowable_451_FWHM_Range is Mod_Types.Unsigned_32 range
        FWHM_451_MIN .. FWHM_451_MAX;

      -------------------------------------------------------------------
      --  Variables
      -------------------------------------------------------------------
      --  Temporary variables to hold the FWHM of the 4 peaks being tested
      FWHM_345 : Mod_Types.Unsigned_32;
      FWHM_375 : Mod_Types.Unsigned_32;
      FWHM_413 : Mod_Types.Unsigned_32;
      FWHM_451 : Mod_Types.Unsigned_32;
   begin

      Usart1.Send_Message_New_Line;
      Usart1.Send_String (Item => "FWHM");
      Usart1.Send_Message_New_Line;

      FWHM_345 := Toolbox.FWHM.FWHM_Channels (Peak_ROI_Locations => ID_ROI_345_Locations,
                                              Peak_ROI           => ID_ROI);

      FWHM_375 := Toolbox.FWHM.FWHM_Channels (Peak_ROI_Locations => ID_ROI_375_Locations,
                                              Peak_ROI           => ID_ROI);

      FWHM_413 := Toolbox.FWHM.FWHM_Channels (Peak_ROI_Locations => ID_ROI_413_Locations,
                                              Peak_ROI           => ID_ROI);

      FWHM_451 := Toolbox.FWHM.FWHM_Channels (Peak_ROI_Locations => ID_ROI_451_Locations,
                                              Peak_ROI           => ID_ROI);

      --# accept F, 10, "Ineffective statement due to declaration of the send string annotation";
      if  FWHM_345 in Allowable_345_FWHM_Range and
        FWHM_375 in Allowable_375_FWHM_Range and
        FWHM_413 in Allowable_413_FWHM_Range and
        FWHM_451 in Allowable_451_FWHM_Range then
         Usart1.Send_String (Item => "Pass");
      else
         Usart1.Send_String (Item => "Fail");
      end if;
      Usart1.Send_Message_New_Line;
      Usart1.Send_Message_New_Line;

      return FWHM_345 in Allowable_345_FWHM_Range and
        FWHM_375 in Allowable_375_FWHM_Range and
        FWHM_413 in Allowable_413_FWHM_Range and
        FWHM_451 in Allowable_451_FWHM_Range;
   end Test_FWHM_Limits;

   -------------------------------------------------------------------
   --  Name       : Identify_Pu239
   --  Implementation Information: Counts engineering use debug statements.
   -------------------------------------------------------------------
   procedure Identify_Pu239 (Pu_Present : out Boolean)
   is
   begin
      Pu_Present := Test_Centroid_Locations;

      Pu_Present := Pu_Present and Test_Critical_Limit;

      Pu_Present := Pu_Present and Test_FWHM_Limits;
   end Identify_Pu239;

   -------------------------------------------------------------------
   --  Name       : Clear_Identification_Store
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Clear_Identification_Store
   is
      --# hide Clear_Identification_Store;
   begin
      --  hidden body, as array initialisation done via loop
      --  avoiding expensive memory constant array

      for J in ID_ROI_Index_Type loop
         ID_ROI (J) := 0;
      end loop;
   end Clear_Identification_Store;

   -------------------------------------------------------------------
   --  Name       : Increment_ROI_Element
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Increment_ROI_Element (Index : in ID_ROI_Index_Type)
   is
   begin

      if ID_ROI (Index) < Mod_Types.Unsigned_16'Last then
         ID_ROI (Index) := ID_ROI (Index) + 1;
      end if;

   end Increment_ROI_Element;

end Measurement.Identification;
