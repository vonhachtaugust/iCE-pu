-------------------------------------------------------------------------------
-- Title      : Register file test bench
-- Project    : icePU
-------------------------------------------------------------------------------
-- File       : reg32_8_tb.vhdl
-- Author     : August  <vonhachtaugust@gmail.com>
-- Company    :
-- Created    : 2020-07-01
-- Last update: 2020-07-07
-- Platform   : Lattice iCEstick Evaluation Kit
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Register file test bench
-------------------------------------------------------------------------------
-- Copyright (c) 2020
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2020-07-01  1.0      August  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library design_library;

entity reg32_8_tb is
end entity reg32_8_tb;

architecture tb of reg32_8_tb is

  -- Test bench constants
  signal c_tb_clk_period : time      := 10 ns;

  -- Test bench signals
  signal tb_clk          : std_logic := '0';
  signal sim_done        : boolean   := false;
  -- Ports
  signal r_en            : std_logic;
  signal w_en            : std_logic;
  signal data_in         : std_logic_vector(31 downto 0);
  signal data_outA       : std_logic_vector(31 downto 0);
  signal data_outB       : std_logic_vector(31 downto 0);
  signal sel             : std_logic_vector(2 downto 0);
  signal selA            : std_logic_vector(2 downto 0);
  signal selB            : std_logic_vector(2 downto 0);

begin

  tb_clk <= '0' when sim_done else
    not tb_clk after c_tb_clk_period/2;

  i_DUT : entity design_library.reg32_8(rtl)
    port map
    (
      clk       => tb_clk,
      r_en      => r_en,
      w_en      => w_en,
      data_in   => data_in,
      data_outA => data_outA,
      data_outB => data_outB,
      sel       => sel,
      selA      => selA,
      selB      => selB
    );

  p_dut : process is
  begin
    -- hold
    wait for 3 * c_tb_clk_period/2;

    -- go
    r_en    <= '0';

    -- test writing
    -- r0 = 0x0000fab5
    selA    <= "000";
    selB    <= "001";
    sel     <= "000";
    data_in <= x"0000fab5";
    w_en    <= '1';
    wait for c_tb_clk_period;

    -- r2 = 0x00003333
    selA    <= "000";
    selB    <= "001";
    sel     <= "010";
    data_in <= x"00003333";
    wait for c_tb_clk_period;

    -- test reading, with no write
    selA    <= "000";
    selB    <= "001";
    sel     <= "000";
    data_in <= x"0000feed";
    r_en    <= '1';
    wait for c_tb_clk_period;

    -- data_outA should not be '0000feed'
    selA <= "001";
    selB <= "010";
    wait for c_tb_clk_period;

    selA <= "011";
    selB <= "100";
    wait for c_tb_clk_period;

    selA    <= "000";
    selB    <= "001";
    sel     <= "100";
    data_in <= x"00004444";
    w_en    <= '1';
    wait for c_tb_clk_period;

    w_en <= '0';
    wait for c_tb_clk_period;

    -- nop
    wait for c_tb_clk_period;

    selA <= "100";
    selB <= "100";
    wait for c_tb_clk_period;

    -- done
    sim_done <= true;
    wait;
  end process p_dut;

end architecture tb;