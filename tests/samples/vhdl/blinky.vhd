library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity blinky is
  port (
    clk : in  std_logic;
    led : out std_logic
  );
end entity blinky;

architecture rtl of blinky is
  signal counter : unsigned(23 downto 0) := (others => '0');
begin
  process (clk) is
  begin
    if rising_edge(clk) then
      counter <= counter + 1;
    end if;
  end process;

  led <= counter(counter'high);
end architecture rtl;
