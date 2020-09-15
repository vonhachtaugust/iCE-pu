-------------------------------------------------------------------------------
-- Title      : uart
-- Project    :
-------------------------------------------------------------------------------
-- File       : uart_top.vhdl
-- Author     : John Doe  <john@doe.com>
-- Company    :
-- Created    : 2020-06-19
-- Last update: 2020-07-09
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: uart top
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-06-19  1.0      Augus   Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- RS-232 devices may be classified as Data Terminal Equipment (DTE) or Data Circuit-terminating Equipment (DCE)

entity uart_top is
  port
  (
    clk          : in std_logic;

    -- DCD - Data Carrier Detect: DCE is receiving a carrier from a remote DCE.
    dcd          : out std_logic;

    -- DSR - Data set ready: On this pin the FPGA can indicate, that it's ready to receive more data
    dsr          : out std_logic;

    -- DTR - Host PC is ready to recieve. DTE is ready to receive, initiate, or continue a call.
    dtr          : in std_logic;

    -- CTS - Clear To Send: On this pin the FPGA can indicate, that it's ready to receive more data
    cts          : out std_logic;

    -- RTS - Request To Send: DTE requests the DCE prepare to transmit data.
    rts          : in std_logic;

    RS232_Tx_TTL : out std_logic;

    RS232_Rx_TTL : in std_logic
  );

end entity uart_top;
architecture rtl of uart_top is

  -- design clock frequency
  constant freq                   : integer                      := 11520000;

  -- uart baudrate
  constant baudrate               : integer                      := 115200;
  constant c_CLKS_PER_BIT         : integer                      := 100;
  constant c_counter_max          : integer                      := (2 ** 31 - 1);

  -- LED register
  signal LED_int                  : std_logic_vector(3 downto 0) := "0000";

  -- RX register
  signal rx_detected              : std_logic;
  signal rx_recieved              : std_logic;
  signal rx_data                  : std_logic_vector(7 downto 0);
  signal rx_active                : std_logic;
  signal rx_active_keep           : std_logic := '0';

  -- interprocess communication register
  signal transmit                 : std_logic;

  -- TX register
  signal tx_transmit              : std_logic := '0';
  signal tx_data                  : std_logic_vector(7 downto 0);
  signal tx_active                : std_logic;
  signal tx_active_keep           : std_logic := '0';
  signal tx_done                  : std_logic;

  procedure hold(variable counter : inout integer;
  variable go                     : inout boolean) is
begin
  if counter > 1000000 then
    go      := true;
    counter := 0;
  else
    go      := false;
    counter := counter + 1;
  end if;
end procedure;
begin -- architecture rtl

i_uart_rx : entity work.UART_RX(rtl)
  generic
  map (
  g_CLKS_PER_BIT => c_CLKS_PER_BIT)
  port map
  (
    i_Clk       => clk,
    i_RX_Serial => RS232_Rx_TTL, -- Input
    o_RX_Detect => rx_detected,  -- Detect input is coming
    o_RX_DV     => rx_recieved,  -- signals rx completed
    o_RX_Byte   => rx_data);     -- register with data

i_uart_tx : entity work.UART_TX(rtl)
  generic
  map (
  g_CLKS_PER_BIT => c_CLKS_PER_BIT)
  port
  map (
  i_Clk       => clk,
  i_TX_DV     => tx_transmit,  -- Trigger transmission start
  i_TX_Byte   => tx_data,      -- Bytes to output
  o_TX_Active => tx_active,    -- High signals = Transmitting
  o_TX_Serial => RS232_Tx_TTL, -- Output
  o_TX_Done   => tx_done       -- High signals = DONE
  );

p_led : process (clk) is
begin
  if rising_edge(clk) then
    if tx_active_keep = '1' then
      LED_int <= "1110";
    elsif rx_active_keep = '1' then
      LED_int <= "0001";
    else
      LED_int <= "0000";
    end if;
  end if;
end process p_led;

LED <= LED_int;

p_interprocess : process (clk) is
begin
  if rising_edge(clk) then
    if rx_recieved = '1' then
      tx_data  <= rx_data;
      transmit <= '1';
    elsif tx_done = '1' then
      transmit <= '0';
    end if;
  end if;
end process p_interprocess;
p_rx : process (clk) is
  type t_state is (s_idle, s_running);
  variable v_state   : t_state;
  variable v_done    : boolean;
  variable v_go      : boolean;
  variable v_counter : natural range 0 to c_counter_max;
begin -- process p_led
  if rising_edge(clk) then
    case v_state is
      when s_idle =>
        if rx_detected = '1' then
          dsr            <= '0';
          rx_active_keep <= '1';
          v_state := s_running;
        else
          dsr <= '1';
        end if;

      when s_running =>
        hold(v_counter, v_go);

        if rx_recieved = '1' then
          v_done := true;
        end if;

        if v_go then
          rx_active_keep <= '0';
          v_done  := false;
          v_state := s_idle;
        end if;
    end case;
  end if;
end process p_rx;
p_tx : process (clk) is
  type t_state is (s_idle, s_running);
  variable v_state   : t_state;
  variable v_go      : boolean;
  variable v_counter : natural range 0 to c_counter_max;
begin
  if rising_edge(clk) then
    case v_state is
      when s_idle =>
        if transmit = '1' and dtr = '0' then
          tx_transmit    <= '1';
          tx_active_keep <= '1';
          v_state := s_running;
        end if;

      when s_running =>
        hold(v_counter, v_go);

        if tx_done = '1' then
          tx_transmit <= '0';
        end if;

        if v_go then
          tx_active_keep <= '0';
          v_state := s_idle;
        end if;
    end case;
  end if;
end process p_tx;

end architecture rtl;