-------------------------------------------------------------------------------
-- Title      : Register file
-- Project    : iCEpu
-------------------------------------------------------------------------------
-- File       : register_file.vhdl
-- Author     : August  <vonhachtaugust@gmail.com>
-- Company    :
-- Created    : 2020-07-01
-- Last update: 2020-07-07
-- Platform   : Lattice iCEstick Evaluation Kit
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Register file
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

entity reg32_8 is
  port
  (
    -- Clock
    clk       : in std_logic;

    -- Read/Write enable
    r_en      : in std_logic;
    w_en      : in std_logic;

    -- Data in/out
    data_in   : in std_logic_vector(31 downto 0);
    data_outA : out std_logic_vector(31 downto 0);
    data_outB : out std_logic_vector(31 downto 0);

    -- Select port
    sel       : in std_logic_vector(2 downto 0);
    selA      : in std_logic_vector(2 downto 0);
    selB      : in std_logic_vector(2 downto 0);
  );
end entity reg32_8;
architecture rtl of reg32_8 is

  type t_regs is array(0 to 7) of std_logic_vector(31 downto 0);
  signal regs : t_regs := (others => '0');

begin

  p_main : process (clk) is
  begin
    if rising_edge(clk) then
      if r_en = '1' then
        data_outA <= regs(to_integer(unsigned(selA)));
        data_outB <= regs(to_integer(unsigned(selB)));
      end if;
      if w_en = '1' then
        regs(to_integer(unsigned(sel))) <= data_in;
      end if;
    end if;
  end process p_main;

end architecture rtl;