library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use ieee.numeric_std_unsigned.all;

entity toplevel_tb is
   generic (
      G_RAM_INIT_FILE : string := "edid.bin"
   );
end entity toplevel_tb;

architecture behavior of toplevel_tb is

   signal clk     : std_logic := '1';
   signal btn1    : std_logic := '1';
   signal rst     : std_logic := '1';
   signal scl     : std_logic := 'Z';
   signal tx      : std_logic;
   signal mirrord : std_logic;
   signal mirrorc : std_logic;
   signal sda     : std_logic := 'Z';

begin

   -- Generate a clock with the frequency of approximately 27 MHz
   clk <= not clk after 18.5 ns;

   -- Assert reset for a few clock cycles
   rst <= '1', '0' after 200 ns;

   -- Generate button input after a small delay
   btn1 <= '1', '0' after 500 ns;

   -- Instantiate DUT
   toplevel_inst : entity work.toplevel
      port map (
         -- inputs
         clk     => clk,
         btn1    => btn1,
         rst     => rst,
         -- outputs
         scl     => scl,
         tx      => tx,
         mirrord => mirrord,
         mirrorc => mirrorc,
         -- inouts
         sda     => sda
      ); -- toplevel_inst

   -- Simulate the EDID memory
   i2c_mem_sim_inst : entity work.i2c_mem_sim
      generic map (
         G_ADDRESS       => X"50",
         G_RAM_INIT_FILE => G_RAM_INIT_FILE
      )
      port map (
         scl_io => scl,
         sda_io => sda
      ); -- i2c_mem_sim_inst

   -- Simulate the UART receiver
   uart_sim_inst : entity work.uart_sim
      generic map (
         G_BAUDRATE => 115_200
      )
      port map (
         rxd_i => tx
      ); -- uart_sim_inst

end architecture behavior;

