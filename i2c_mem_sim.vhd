-- This provides a model of a small I2C memory.

-- This module is only used for simulation; it can not be synthesized.

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.numeric_std.all;
   use ieee.numeric_std_unsigned.all;

entity i2c_mem_sim is
   generic (
      G_ADDRESS       : std_logic_vector(7 downto 0);
      G_RAM_INIT_FILE : string := ""
   );
   port (
      -- Device side
      scl_io : inout std_logic;
      sda_io : inout std_logic
   );
end entity i2c_mem_sim;

architecture simulation of i2c_mem_sim is

   signal bit_cnt       : unsigned(3 downto 0);
   signal addr          : std_logic;
   signal address       : std_logic_vector(7 downto 0);
   signal data          : std_logic;
   signal read_cmd      : std_logic;
   signal nack          : std_logic;
   signal wr_data_shift : std_logic_vector(7 downto 0);
   signal wr_data       : std_logic_vector(7 downto 0);
   signal rd_data       : std_logic_vector(7 downto 0);

   type   state_type is (IDLE_ST, WRITE_ST);
   signal state : state_type       := IDLE_ST;
   signal rst   : std_logic        := '1';
   signal wr_en : std_logic        := '0';
   signal ptr   : std_logic_vector(7 downto 0);

   type   ram_type is array (natural range <>) of std_logic_vector(7 downto 0);

   type   char_file_type is file of character;

   -- Read binary data from file

   impure function read_init_ram (
      file_name : string
   ) return ram_type is
      file     char_file   : char_file_type;
      variable char_read_v : character;
      variable byte_v      : std_logic_vector(7 downto 0);
      variable index_v     : natural range 0 to 255;
      variable ram_v       : ram_type(0 to 255) := (others => (others => '0'));
   begin
      if file_name /= "" then
         file_open(char_file, file_name, READ_MODE);

         index_v := 0;

         -- Loop over entire file
         while not endfile(char_file) loop
            read(char_file, char_read_v);
            ram_v(index_v) := std_logic_vector(to_unsigned(character'pos(char_read_v), 8));
            if index_v = 255 then
               exit;
            end if;
            index_v := index_v + 1;
         end loop;

         file_close(char_file);
      end if;

      return ram_v;
   end function read_init_ram;

   -- Array containing contents of RAM
   signal ram : ram_type(0 to 255) := read_init_ram(G_RAM_INIT_FILE);

begin

   sim_proc : process (all)
   begin
      if scl_io /= '0' and falling_edge(sda_io) then
         -- Start
         bit_cnt <= (others => '0');
         addr    <= '1';
         data    <= '0';
         nack    <= '0';
         rst     <= '0';
      elsif scl_io /= '0' and rising_edge(sda_io) then
         -- Stop
         addr <= '0';
         data <= '0';
         rst  <= '1';
      elsif rising_edge(scl_io) then
         if bit_cnt < 8 then
            bit_cnt <= bit_cnt + 1;
         else
            bit_cnt <= (others => '0');
            if read_cmd /= '0' then
               nack <= sda_io;
            end if;
         end if;
         if read_cmd = '0' and data = '1' then
            wr_data_shift <= wr_data_shift(6 downto 0) & sda_io;
         end if;
         if addr = '1' then
            address <= address(6 downto 0) & sda_io;
            if bit_cnt = 7 then
               read_cmd <= sda_io;
               rd_data  <= ram(to_integer(ptr));
            end if;
         end if;
      elsif falling_edge(scl_io) then
         wr_en <= '0';
         if bit_cnt = 8 then
            if data = '1' and read_cmd = '0' then
               wr_data <= wr_data_shift;
               wr_en   <= '1';
            end if;
            addr <= '0';
            data <= '1';
            if (addr = '1' or read_cmd = '0') and address(7 downto 1) = G_ADDRESS(7 downto 1) then
               sda_io <= '0' after 10 ns;
            else
               sda_io <= 'Z';
            end if;
         elsif data = '1' and read_cmd /= '0' and nack = '0' and address(7 downto 1) = G_ADDRESS(7 downto 1) then
            sda_io  <= rd_data(7) after 10 ns;
            rd_data <= rd_data(6 downto 0) & rd_data(7);
         else
            sda_io <= 'Z';
         end if;
      end if;
   end process sim_proc;

   fsm_proc : process (rst, nack, scl_io)
   begin
      if rst = '1' or nack = 'H' or nack = '1' then
         state <= IDLE_ST;
      elsif rising_edge(scl_io) then

         case state is

            when IDLE_ST =>
               if wr_en = '1' then
                  ptr   <= wr_data;
                  state <= WRITE_ST;
               end if;

            when WRITE_ST =>
               if wr_en = '1' then
                  ram(to_integer(ptr)) <= wr_data;
                  state                <= IDLE_ST;
               end if;

            when others =>
               null;

         end case;

      end if;
   end process fsm_proc;

end architecture simulation;

