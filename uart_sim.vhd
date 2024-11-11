-- This simply reads text data from the UART and dumps it to the console.
--
-- This module is only used for simulation; it can not be synthesized.

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use ieee.numeric_std_unsigned.all;

library std;
   use std.textio.all;

entity uart_sim is
   generic (
      G_BAUDRATE : natural
   );
   port (
      rxd_i : in    std_logic
   );
end entity uart_sim;

architecture simulation of uart_sim is

   -- Calculate time for one bit
   constant C_BIT_PERIOD : time := 1.0 us * (1000000.0 / real(G_BAUDRATE));

   signal   rx_data : std_logic_vector(7 downto 0);

begin

   uart_rx_proc : process
      variable l : line;
   begin
      -- Wait for start bit
      wait until falling_edge(rxd_i);

      -- Sample in the middle of each bit
      wait for C_BIT_PERIOD / 2;

      -- Read eight bits
      for i in 0 to 7 loop
         wait for C_BIT_PERIOD;
         rx_data(i) <= rxd_i;
      end loop;

      -- Ensure serial line is idle after byte
      -- (this checks that the baudrate is roughly correct)
      wait for C_BIT_PERIOD;
      assert rxd_i = '1'
         report "UART error: Unexpected value of rxd_i"
         severity error;

      -- Dump a complete line to the console output
      if rx_data = X"0D" then
         null;
      elsif rx_data = X"0A" then
         writeline(output, l);
      elsif is_x(rx_data) then
         writeline(output, l);
         report "Error: X's in UART data";
      else
         write(l, character'val(to_integer(rx_data)));
      end if;
   end process uart_rx_proc;

end architecture simulation;

