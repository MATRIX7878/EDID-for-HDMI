library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;

library work;
   use work.states.all;
   use work.databytes.all;

entity edid_tb is
   generic (
      -- File containing the EDID data (256 bytes of binary data)
      -- On linux, this file can be obtained by the command:
      -- sudo get-edid > edid.bin
      G_EDID_ROM_FILENAME : string := "edid.bin"
   );
end entity edid_tb;

architecture behavior of edid_tb is

   -- Signals connected to DUT
   signal   clk            : std_logic           := '1';
   signal   enable         : std_logic;
   signal   compi2c        : std_logic;
   signal   bytercv        : std_logic_vector(7 downto 0);
   signal   ready          : std_logic;
   signal   enablei2c      : std_logic;
   signal   instructioni2c : state;
   signal   readdata       : data;
   signal   bytesend       : std_logic_vector(7 downto 0);

   signal   led         : std_logic;
   signal   horpixel    : std_logic_vector(11 downto 0);
   signal   vertpixel   : std_logic_vector(11 downto 0);
   signal   refreshrate : std_logic_vector(11 downto 0);
   signal   screenname  : std_logic_vector(103 downto 0);

   type     char_file_type is file of character;

   type     edid_rom_type is array(natural range <>) of std_logic_vector(7 downto 0);

   -- Read binary data from file

   impure function read_edid_rom (
      file_name : string
   ) return edid_rom_type is
      file     char_file   : char_file_type;
      variable char_read_v : character;
      variable byte_v      : std_logic_vector(7 downto 0);
      variable index_v     : natural range 0 to 255;
      variable edid_rom_v  : edid_rom_type(0 to 255);
   begin
      file_open(char_file, file_name, READ_MODE);

      index_v := 0;

      -- Loop over entire file
      while not endfile(char_file) loop
         read(char_file, char_read_v);
         edid_rom_v(index_v) := std_logic_vector(to_unsigned(character'pos(char_read_v), 8));
         if index_v = 255 then
            exit;
         end if;
         index_v := index_v + 1;
      end loop;

      file_close(char_file);

      return edid_rom_v;
   end function read_edid_rom;

   -- Array containing contents of EDID
   constant C_EDID_ROM : edid_rom_type(0 to 255) := read_edid_rom(G_EDID_ROM_FILENAME);

   -- Used by i2c_slave_proc
   signal   rom_addr : natural range 0 to 255;

begin

   -- Generate clock (arbitrarily with frequency of 100 MHz)
   clk    <= not clk after 5 ns;

   -- Generate stimulus.
   -- This is not a complete functioning I2C slave, but rather the minimum
   -- needed to feed the DUT with the stimulus.
   i2c_slave_proc : process (clk)
   begin
      if rising_edge(clk) then
         compi2c <= '0';
         if enablei2c = '1' and compi2c = '0' then
            compi2c <= '1';
            if instructioni2c = READ then
               bytercv  <= C_EDID_ROM(rom_addr);
               rom_addr <= (rom_addr + 1) mod 256;
            end if;
         end if;
      end if;
   end process i2c_slave_proc;

   enable <= '1';


   -- Instantiate DUT
   edidi2c_inst : entity work.edidi2c
      port map (
         -- inputs
         clk            => clk,
         enable         => enable,
         compi2c        => compi2c,
         bytercv        => bytercv,
         -- outputs
         ready          => ready,
         enablei2c      => enablei2c,
         instructioni2c => instructioni2c,
         readdata       => readdata,
         bytesend       => bytesend
      ); -- edidi2c_inst

   edid_inst : entity work.edid
      port map (
         clk         => clk,
         enable      => enable,
         readdata    => readdata,
         led         => led,
         horpixel    => horpixel,
         vertpixel   => vertpixel,
         refreshrate => refreshrate,
         screenname  => screenname
      ); -- edid_inst


   -- Show output
   output_proc : process
      variable s_v : string(1 to screenname'left / 8 + 1);
   begin
      wait until rising_edge(ready);

      for i in 0 to screenname'left / 8 loop
         s_v(i + 1) := character'val(to_integer(unsigned(screenname(8 * i + 7 downto 8 * i))));
      end loop;

      report "Horizontal pixels = " & to_string(to_integer(unsigned(horpixel)));
      report "Vertical pixels   = " & to_string(to_integer(unsigned(vertpixel)));
      report "Refresh rate      = " & to_string(to_integer(unsigned(refreshrate)));
      report "Screen Name       = " & s_v;

      wait;
   end process output_proc;

end architecture behavior;

