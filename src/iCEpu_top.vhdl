library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iCEpu is
  port
  (
    -- Clock
    clk          : in std_logic;

    -- LEDs
    LED          : out std_logic_vector(3 downto 0);

    -- UART ctrl
    dcd          : out std_logic;
    dsr          : out std_logic;
    dtr          : in std_logic;
    cts          : out std_logic;
    rts          : in std_logic;

    -- UART data
    RS232_Tx_TTL : out std_logic;
    RS232_Rx_TTL : in std_logic
  );
end iCEpu;

architecture rtl of iCEpu is

begin

  LED <= "1111";

end architecture rtl;