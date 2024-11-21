library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std_unsigned.all;

entity uart_two_proc is
  generic (
    G_DIVISOR : natural := 234
  );
  port (
    clk_i      : in    std_logic;
    rst_i      : in    std_logic;
    tx_ready_o : out   std_logic;
    tx_valid_i : in    std_logic;
    tx_data_i  : in    std_logic_vector(7 downto 0);
    tx_out_o   : out   std_logic
  );
end entity uart_two_proc;

architecture behavior of uart_two_proc is

  constant C_BAUD : std_logic_vector(7 downto 0) := to_stdlogicvector(G_DIVISOR, 8);

  type     state_type is (IDLE_ST, START_ST, SEND_ST, STOP_ST);

  -- Registers (current values)
  signal   currentstate_r : state_type;
  signal   bits_r         : integer RANGE 7 downto 0;
  signal   counter_r      : std_logic_vector(7 downto 0);
  signal   tx_ready_r     : std_logic;
  signal   tx_out_r       : std_logic;

  -- Combinatorial signals (new values)
  signal   new_currentstate_s : state_type;
  signal   new_bits_s         : integer RANGE 7 downto 0;
  signal   new_counter_s      : std_logic_vector(7 downto 0);
  signal   new_tx_ready_s     : std_logic;
  signal   new_tx_out_s       : std_logic;

begin

  tx_ready_o <= tx_ready_r;
  tx_out_o   <= tx_out_r;

  comb_proc : process (all)
  begin
    -- Default values (to avoid latches)
    new_currentstate_s <= currentstate_r;
    new_bits_s         <= bits_r;
    new_counter_s      <= counter_r;
    new_tx_ready_s     <= tx_ready_r;
    new_tx_out_s       <= tx_out_r;

    case currentstate_r is

      when IDLE_ST =>
        if tx_valid_i = '1' then
          new_tx_ready_s     <= '0';
          new_tx_out_s       <= '1';
          new_currentstate_s <= START_ST;
        else
          new_tx_ready_s <= '0';
        end if;

      when START_ST =>
        if counter_r = C_BAUD then
          new_tx_out_s       <= '0';
          new_counter_s      <= (others => '0');
          new_currentstate_s <= SEND_ST;
        else
          new_counter_s <= counter_r + '1';
        end if;

      when SEND_ST =>
        if counter_r = C_BAUD and bits_r = 0 then
          new_tx_out_s       <= tx_data_i(7-bits_r);
          new_counter_s      <= (others => '0');
          new_currentstate_s <= STOP_ST;
        elsif counter_r = C_BAUD and bits_r > 0 then
          new_tx_out_s  <= tx_data_i(7-bits_r);
          new_counter_s <= (others => '0');
          new_bits_s    <= bits_r - 1;
        else
          new_counter_s <= counter_r + '1';
        end if;

      when STOP_ST =>
        if counter_r = C_BAUD then
          new_bits_s         <= 7;
          new_tx_ready_s     <= '1';
          new_tx_out_s       <= '1';
          new_counter_s      <= (others => '0');
          new_currentstate_s <= IDLE_ST;
        else
          new_counter_s <= counter_r + '1';
        end if;

    end case;

    if rst_i then
      new_tx_ready_s     <= '1';
      new_tx_out_s       <= '1';
      new_currentstate_s <= IDLE_ST;
      new_bits_s         <= 7;
      new_counter_s      <= (others => '0');
    end if;
  end process comb_proc;


  regs_proc : process (clk_i)
  begin
    if rising_edge(clk_i) then
      currentstate_r <= new_currentstate_s;
      bits_r         <= new_bits_s;
      counter_r      <= new_counter_s;
      tx_ready_r     <= new_tx_ready_s;
      tx_out_r       <= new_tx_out_s;
    end if;
  end process regs_proc;

end architecture behavior;

