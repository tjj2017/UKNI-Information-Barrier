----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Toolbox.Peak_Search
--  Stored Filename: $Id: toolbox-peak_search.ads 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  <description>
--               This package contains subprograms to find maximums and centroids
--               of the peaks that the IB requires to either identify or are
--               relevant to determine the isotopic ration
--  </description>
----------------------------------------------------------------------
with Channel_Types,
     Region_Of_Interest;

--# inherit Channel_Types,
--#         Measurement_Peaks,
--#         Mod_Types,
--#         Region_Of_Interest,
--#         Toolbox,
--#         Usart_Types,
--#         Usart1;

package Toolbox.Peak_Search is

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  <name> Search_For_Peak </name>
   --  <description> Locate the maximum count channel in a particular region of
   --                interest
   --  </description>
   --  <input name="Search_Array">
   --     The region of interest to find the maximum of
   --  </input>
   --  <input name="Upper_Location">
   --     The Upper point in the region of interest to look in
   --  </input>
   --  <input name="Lower_Location">
   --     The lower point in the region of interest to look in
   --  </input>
   --  <returns>
   --     The channel containing the maximum count
   --  </returns>
   -------------------------------------------------------------------
   function Search_For_Peak (Search_Array   : in Region_Of_Interest.Region_Of_Interest_Type;
                             Upper_Location : in Channel_Types.Data_Channel_Number;
                             Lower_Location : in Channel_Types.Data_Channel_Number)
                             return Channel_Types.Data_Channel_Number;
   --# pre Lower_Location >= Search_Array'First and
   --#     Upper_Location <= Search_Array'Last and
   --#     Lower_Location < Upper_Location;
   --# return M => (for all Y in Channel_Types.Data_Channel_Number range
   --#   M .. Upper_Location => (Search_Array(M) >= Search_Array(Y))) and
   --#             (for all X in Channel_Types.Data_Channel_Number range
   --#   Lower_Location .. M => (Search_Array(M) > Search_Array(X) or
   --#                              (Search_Array(M) = Search_Array(X) and M = X))) and
   --#              (M in Lower_Location .. Upper_Location) and
   --#              (M in Search_Array'First .. Search_Array'Last);

   pragma Inline (Search_For_Peak);

   -------------------------------------------------------------------
   --  <name> Find_Centroid </name>
   --  <description> Calculates the true centroid of an ROI
   --  </description>
   --  <input name="Search_Array">
   --     The region of interest containing the peak to find the centroid of [@real]
   --  </input>
   --  <output name="Centroid">
   --     The location of the centroid [@*mult]
   --  </output>
   -------------------------------------------------------------------
   procedure Find_Centroid (Search_Array   : in  Region_Of_Interest.Region_Of_Interest_Type;
                            Centroid       : out Channel_Types.Extended_Channel_Type;
                            Is_Successful  : out Boolean);
   --# derives Centroid,
   --#         Is_Successful from Search_Array;
   --# pre Search_Array'Length(1) > 5 and
   --#        Search_Array'Last < 4090;
   --# post Channel_Types.Data_Channel_Number (Centroid / Toolbox.MULT) in Search_Array'Range;
   pragma Inline (Find_Centroid);

end Toolbox.Peak_Search;
