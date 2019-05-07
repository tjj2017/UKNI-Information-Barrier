-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  ASVAT 3-May-2019 memory_checks.shw
--  This a shadow file which replaces memory_checks.adb for ASVAT analysis
--  since the distributed package body uses an assember program not hendled
--  ASVAT.
-- ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-----------------------------------------------------------------------
--  This software is made available under the Open Government License
--  3.0.  Please attribute to the United Kingdom - Norway Initiative,
--  http://ukni.info (2016)
----------------------------------------------------------------------
--  Name: Memory_Checks
--  Stored Filename: $Id: memory_checks.adb 140 2016-02-03 12:34:43Z CMarsh $
--  Status: Operational
--  Date Created: June 2009
--  Description: Defines the external interface to the Memory.
--  Specification Version: Development/Interfaces/Memory/Memory.ads
--  Note: Flash is CRC checked up to 16#1fffe#, and the PBIT checks between
--       16#200# and 16#2199#
--
--       DO NOT USE PRETTY PRINT ON THIS FILE!!!
--
----------------------------------------------------------------------

with Mod_Types,
     System,
     System.Machine_Code,
     System.Storage_Elements,
     Usart1;

use type Mod_Types.Unsigned_8;

package body Memory_Checks is
   --# hide Memory_Checks;
   ----------------------------------------------------------------------
   --  constants
   ----------------------------------------------------------------------
   RAM_Start : constant Mod_Types.Unsigned_16 := 16#0200#;
   RAM_End   : constant Mod_Types.Unsigned_16 := 16#2199#;

   ----------------------------------------------------------------------
   --  Register Information
   ----------------------------------------------------------------------
   R2 : Mod_Types.Unsigned_8;
   for R2'Address use System'To_Address (16#02#);
   pragma Volatile (R2);

   R3 : Mod_Types.Unsigned_8;
   for R3'Address use System'To_Address (16#03#);
   pragma Volatile (R3);
   ----------------------------------------------------------------------

   ----------------------------------------------------------------------
   --  Name                       : PBIT_Test
   --  Implementation Information : None.
   ----------------------------------------------------------------------
   function PBIT_Test return Boolean is
      ----------------------------------------------------------------------
      --  Name                       : Address_OK
      --  Description                : Check one address within the RAM
      --  Inputs                     : Address - The address being check.
      --  Outputs                    : True if the address can be written and
      --                              read from.
      --  Implementation Information : None.
      ----------------------------------------------------------------------
      function Address_OK
        (Address    : in System.Storage_Elements.Integer_Address)
         return Boolean
      is
         --  Current value of a memory location
         Current_Value : Mod_Types.Unsigned_8;

         --  whether the check on the memory location has passed
         Test_Passed   : Boolean := True;

         --  Memory location under test
         Location      : Mod_Types.Unsigned_8;
         for Location'Address use System.Storage_Elements.To_Address (Value => (Address));
      begin
         --  store the current value
         Current_Value := Location;
         --  read and write 2#01010101# from this memory loc
         Location := 16#55#;
         if Location /= 16#55# then
            Test_Passed := False;
         end if;

         --  read and write 2#10101010# from this memory loc
         Location := 16#AA#;
         if Location /= 16#AA# then
            Test_Passed := False;
         end if;

         --  restore original value
         Location := Current_Value;

         return Test_Passed;
      end Address_OK;

      Test_Passed : Boolean := True;

   begin
      for I in Mod_Types.Unsigned_16 range RAM_Start .. RAM_End loop

         if not Address_OK
                  (Address => System.Storage_Elements.Integer_Address (I))
         then
            Test_Passed := False;
         end if;
         exit when not Test_Passed;

      end loop;

      return Test_Passed;
   end PBIT_Test;

   ----------------------------------------------------------------------
   --  Name                       : CRC_Test
   --  Implementation Information : Implementation of the routine in AVR236
   --                              Note this code does not pick up the RAMPZ
   --                              flag.  It calculates its value
   --  Note this only works with the srec in the software directory,
   --  not the one in the default path.
   --  srec command is:
   --  srec_cat ($target).ihex -intel --crop 0 0x3FFFE --fill 0x00 0x0000
   --  0x40000
   --  -output ($target2).ihex -intel
   --  --address_length=2 --line_length=44
   --  where
   --  ($target) : generated ihex file from make
   --  -intel  : specified intel format
   --  --crop A B : specifies that only the data between A and B is being summed
   --  --fill A B C : fills holes between B and C with A
   --  -output ($target2).ihex : write the result to ($target2).ihex
   --  --address_length=2
   --  --line_length=44 : use correct ihex format
   --  The CRC can then be appended at the end of the file, and the checksum
   --  calculated as the 2's complement of the last line of the hex file
   ----------------------------------------------------------------------
   function CRC_Test return Boolean is
      --  ASVAT does not analyse assembler code.  Replace this assembler
      --  code to run a CRC test on memory by a dummy function always
      --  returning True.
--        use ASCII;
--     begin
--        System.Machine_Code.Asm
--          (Template => LF & HT &
--           "; ***** constants" & LF & HT &
--           ".equ LAST_PROG_ADDR, 0x3FFFF;Last program memory address" & LF & HT &
--           ".equ CR, 0x1021; CCITT CRC div.  Seed starts at zero" & LF & HT &
--           "; so use XMODEM" & LF & HT &
--           "; start by jumping to crc initialisation code" & LF & HT &
--
--           "rjmp Init;" & LF & HT &
--
--           "; ***** " & LF & HT &
--           "; * Name : crc_gen" & LF & HT &
--           "; * Description : This subroutine generates the checksum" & LF & HT &
--           "; *               for the program code.  32 bits are " & LF & HT &
--           "; *               loaded into 4 registers, the uppper " & LF & HT &
--           "; *               16 bits are XORed with the divisor val" & LF & HT &
--           "; *               each time 1 is shifted into the carry" & LF & HT &
--           "; *               flag  from the MSB." & LF & HT &
--           "; *               " & LF & HT &
--           "; *               The checksum is the result in r2 & r3" & LF & HT &
--           "; ***** " & LF & HT &
--           "crc_gen   : " & LF & HT &
--           "ldi r17, lo8(LAST_PROG_ADDR) ; load last program" & LF & HT &
--           "ldi r18, hi8(LAST_PROG_ADDR); memory address" & LF & HT &
--           "ldi r19, hlo8(LAST_PROG_ADDR)" & LF & HT &
--           "clr r30; clear the z pointer" & LF & HT &
--           "clr r31" & LF & HT &
--           "ldi r21,hi8(CR) ; Load Divisor value" & LF & HT &
--           "ldi r20,lo8(CR)" & LF & HT &
--           "elpm ; load first memory location" & LF & HT &
--           "mov r3, r0 ; move to highest byte" & LF & HT &
--           "adiw r30,0x01 ; increment z" & LF & HT &
--           "elpm ; load next location" & LF & HT &
--           "mov r2, r0 ; move to 2nd highest byte" & LF & HT &
--           "clr r22" & LF & HT &
--
--           "; ***** " & LF & HT &
--           "; * Name : next_byte" & LF & HT &
--           "; * Description : Processes the next word from the " & LF & HT &
--           "; *               program memory " & LF & HT &
--           "; ***** " & LF & HT &
--           "next_byte : " & LF & HT &
--           "lds r22, 0x005B ; load RAMPZ into r22" & LF & HT &
--           " ;              - doesn't work, so using SRAM loc 0x005B" & LF & HT &
--           "cp r30,r17 ;loop starts here" & LF & HT &
--           "cpc r31,r18" & LF & HT &
--           "cpc r22,r19" & LF & HT &
--           "brge end; jump if end of code" & LF & HT &
--           "adiw r30, 0x01 ; increment z" & LF & HT &
--           "brcc next1 ; branch if Z pointer does not wrap to next1" & LF & HT &
--           "inc r22; increment the overflow pointer for Z" & LF & HT &
--           "sts 0x005b, r22; and store back to sram" & LF & HT &
--
--           "next1 : " & LF & HT &
--           "elpm ; load next location" & LF & HT &
--           "mov r1, r0 ; move to 2nd byte" & LF & HT &
--           "adiw r30, 0x01 ; increment z" & LF & HT &
--           "brcc next2 ; branch if Z pointer does not wrap to next2" & LF & HT &
--           "inc r22; increment the overflow pointer for Z" & LF & HT &
--           "sts 0x005b, r22; and store back to sram" & LF & HT &
--
--           "next2 : " & LF & HT &
--           "elpm ; load next location" & LF & HT &
--           "call rot_word" & LF & HT &
--           "jmp next_byte" & LF & HT &
--
--           "; ***** " & LF & HT &
--           "; * Name : end" & LF & HT &
--           "; * Description : return to main prog " & LF & HT &
--           "; ***** " & LF & HT &
--           "end       : " & LF & HT &
--           "ret" & LF & HT &
--
--           "; ***** " & LF & HT &
--           "; * Name : rot_word" & LF & HT &
--           "; * Name : rot_loop" & LF & HT &
--           "; * Description : shift the word up through the " & LF & HT &
--           "; *               the registers, XORing if the msb is 1" & LF & HT &
--           "; ***** " & LF & HT &
--           "rot_word  : " & LF & HT &
--           "ldi r22,0x11 ; set the counter to 17" & LF & HT &
--           "rot_loop  : " & LF & HT &
--           "dec r22; decrement the counter" & LF & HT &
--           "breq stop; break if the counter is 0" & LF & HT &
--           "lsl r0 ; shift zero into lowest bit" & LF & HT &
--           "rol r1 ; shift in carry from prev byte" & LF & HT &
--           "rol r2" & LF & HT &
--           "rol r3" & LF & HT &
--           "brcc rot_loop; loop if MSB = 0" & LF & HT &
--           "eor r2, r20" & LF & HT &
--           "eor r3, r21 ; xor high word if msb = 1" & LF & HT &
--           "rjmp rot_loop" & LF & HT &
--
--           "; ***** " & LF & HT &
--           "; * Name : stop" & LF & HT &
--           "; * Description : return to crc_gen " & LF & HT &
--           "; ***** " & LF & HT &
--           "stop      : " & LF & HT &
--           "ret" & LF & HT &
--
--           "; ***** " & LF & HT &
--           "; * Name : Init" & LF & HT &
--           "; * Description : crc check initialisation code " & LF & HT &
--           "; ***** " & LF & HT &
--           "Init     : " & LF & HT &
--           "ldi r16, hi8(__data_end) ; init the stack pointer" & LF & HT &
--           "ldi r17, lo8(__data_end)" & LF & HT &
--           "call crc_gen",
--           Volatile => True);
--
--        Usart1.Send_String (Item => "R2: ");
--        Usart1.Send_Message_8 (Data => R2);
--        Usart1.Send_Message_New_Line;
--
--        Usart1.Send_String (Item => "R3: ");
--        Usart1.Send_Message_8 (Data => R3);
--        Usart1.Send_Message_New_Line;
--
--        --  r2 and r3 should be zero if the test has passed
--        return R2 = 0 and R3 = 0;

   begin
      return True;
   end CRC_Test;

end Memory_Checks;
