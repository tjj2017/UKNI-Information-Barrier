----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: ADC
--  Stored Filename: $Id: ADC.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Created By: D Curtis
--  Description: ADC interface for the ATMEGA2560
----------------------------------------------------------------------

with Registers,
     System.Storage_Elements;

package body ADC
--# own State is in     ADC_LSB,
--#              in     ADC_MSB,
--#              in     Trigger,
--#                 out ADC_Enable,
--#                     ADC_Enable_Stored,
--#                     Last_Trigger_Value;
is

   -------------------------------------------------------------------
   --  Register Definitions
   -------------------------------------------------------------------

   --  ADC Control lines on port G
   Trigger_Enable_DDR : constant Mod_Types.Unsigned_8 := 2#00001000#;
   --# accept w, 351, Trigger_Enable_DDR, "Constant with address clause";
   for Trigger_Enable_DDR'Address use System.Storage_Elements.To_Address (Registers.DDRG);
   --# end accept;

   Trigger            : Mod_Types.Unsigned_8;
   --# assert Trigger'Always_Valid;
   for Trigger'Address use System.Storage_Elements.To_Address (Registers.PING);
   pragma Volatile (Trigger);

   ADC_Enable         : Mod_Types.Unsigned_8;
   for ADC_Enable'Address use System.Storage_Elements.To_Address (Registers.PORTG);
   pragma Volatile (ADC_Enable);

   --  ADC Data lines, with the low byte on port H, and the high byte on port B
   ADC_LSB_DDR        : constant Mod_Types.Unsigned_8 := Registers.DDR_INPUT;
   --# accept w, 351, ADC_LSB_DDR, "Constant with address clause";
   for ADC_LSB_DDR'Address use System.Storage_Elements.To_Address (Registers.DDRH);
   --# end accept;

   ADC_MSB_DDR        : constant Mod_Types.Unsigned_8 := Registers.DDR_INPUT;
   --# accept w, 351, ADC_MSB_DDR, "Constant with address clause";
   for ADC_MSB_DDR'Address use System.Storage_Elements.To_Address (Registers.DDRB);
   --# end accept;

   ADC_LSB            : Mod_Types.Unsigned_8;
   --# assert ADC_LSB'Always_Valid;
   for ADC_LSB'Address use System.Storage_Elements.To_Address (Registers.PINH);
   pragma Volatile (ADC_LSB);

   ADC_MSB            : Mod_Types.Unsigned_8;
   --# assert ADC_MSB'Always_Valid;
   for ADC_MSB'Address use System.Storage_Elements.To_Address (Registers.PINB);
   pragma Volatile (ADC_MSB);

   -------------------------------------------------------------------
   --  Variables
   -------------------------------------------------------------------

   --  Stored value on whether the ADC is currently enabled
   ADC_Enable_Stored  : Mod_Types.Unsigned_8 := 2#1111_1111#;

   --  Stored value of the state of the ADC trigger
   Last_Trigger_Value : Mod_Types.Unsigned_8 := 2#0000_0000#; -- safe initial value

   -------------------------------------------------------------------
   --  Subprograms
   -------------------------------------------------------------------

   -------------------------------------------------------------------
   --  Name       : Enable_ADC
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Enable_ADC
   --# global in out ADC_Enable_Stored;
   --#           out ADC_Enable;
   --# derives ADC_Enable,
   --#         ADC_Enable_Stored from ADC_Enable_Stored;
   is
   begin
      ADC_Enable_Stored := ADC_Enable_Stored and 2#1111_0111#; -- _Adc_Enable is UC on Pin G3
      ADC_Enable := ADC_Enable_Stored;
   end Enable_ADC;

   -------------------------------------------------------------------
   --  Name       : Disable_ADC
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Disable_ADC
   --# global in out ADC_Enable_Stored;
   --#           out ADC_Enable;
   --# derives ADC_Enable,
   --#         ADC_Enable_Stored from ADC_Enable_Stored;
   is
   begin
      ADC_Enable_Stored := ADC_Enable_Stored or 2#0000_1000#; -- _Adc_Enable is UC on Pin G3
      ADC_Enable := ADC_Enable_Stored;
   end Disable_ADC;

   -------------------------------------------------------------------
   --  Name       : Check_Trigger_Edge
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Check_Trigger_Edge (Triggered : out Boolean)
   --# global in     Trigger;
   --#        in out Last_Trigger_Value;
   --# derives Last_Trigger_Value from Trigger &
   --#         Triggered          from Last_Trigger_Value,
   --#                                 Trigger;
   --# post (Trigger = Trigger'Tail(Trigger~));
   is
      --  Temporary variable used for calculating whether the ADC has triggered
      LTrigger : Mod_Types.Unsigned_8;
   begin
      --  Read the ADC Control register
      LTrigger := Trigger;
      --# assert LTrigger >= 0 and LTrigger <= 255 and Trigger = Trigger'Tail(Trigger~);

      --  Mask the trigger pin, and check for an edge
      LTrigger := LTrigger and 2#0010_0000#;
      if Last_Trigger_Value = 2#0010_0000# and LTrigger = 2#0000_0000# then
         Triggered := True; -- Returns True on Falling edge only (ensures reading is new)
      else
         Triggered := False;
      end if;

      --  Store the current state of the trigger pin
      Last_Trigger_Value := LTrigger;
   end Check_Trigger_Edge;

   -------------------------------------------------------------------
   --  Name       : Assemble_Reading
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Assemble_Reading (Reading : out Channel_Types.Data_Channel_Number)
   --# global in ADC_LSB;
   --#        in ADC_MSB;
   --# derives Reading from ADC_LSB,
   --#                      ADC_MSB;
   is
      --  Temporary variables for holding the ADC
      LADC_MSB : Mod_Types.Unsigned_8;
      LADC_LSB : Mod_Types.Unsigned_8;
   begin
      --  Get the high byte of the ADC, and mask out the un-used nibble
      LADC_MSB := ADC_MSB;
      LADC_MSB := LADC_MSB and 2#0000_1111#;

      --  Get the low byte of the ADC
      LADC_LSB := ADC_LSB;
      --# assert LADC_MSB <= 15 and LADC_LSB <=255 and LADC_MSB >= 0 and LADC_LSB >= 0;

      --  Assemble the reading
      Reading := Mod_Types.Unsigned_16 (LADC_MSB) * 256 + Mod_Types.Unsigned_16 (LADC_LSB);
   end Assemble_Reading;

   -------------------------------------------------------------------
   --  Name       : Get_Reading
   --  Implementation Information: None.
   -------------------------------------------------------------------
   procedure Get_Reading (Reading : out Channel_Types.Data_Channel_Number)
   --# global in     ADC_LSB;
   --#        in     ADC_MSB;
   --#        in     Trigger;
   --#        in out ADC_Enable_Stored;
   --#        in out Last_Trigger_Value;
   --#           out ADC_Enable;
   --# derives ADC_Enable,
   --#         ADC_Enable_Stored  from ADC_Enable_Stored &
   --#         Last_Trigger_Value from *,
   --#                                 Trigger &
   --#         Reading            from ADC_LSB,
   --#                                 ADC_MSB;
   is
      --  Boolean flag used to spin until an edge has been detected
      Is_Triggered : Boolean;

   begin
      --  enable the ADC
      Enable_ADC;

      --  wait for an edge
      Check_Trigger_Edge (Triggered => Is_Triggered);

      while not Is_Triggered loop
         Check_Trigger_Edge (Triggered => Is_Triggered);
      end loop;

      --  disable the ADC
      Disable_ADC;

      --  and assemble the reading
      Assemble_Reading (Reading => Reading);
   end Get_Reading;

end ADC;
