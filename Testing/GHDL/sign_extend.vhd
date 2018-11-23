-- Title				: Sign Extender 
-- Purpose				:
-- Brief Description	:
-- Author				: Shashank OV
-- Date					: Oct. 8, 2016 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sign_extend is
	generic(output_width: integer := 16);
	port(
		input: in std_logic_vector(output_width-1 downto 0);
		output: out std_logic_vector(output_width-1 downto 0);
		sel_6_9, bypass: in std_logic);
end entity;

architecture basic of sign_extend is
	signal output_6: std_logic_vector(output_width-1 downto 0) := (others => '0');
	signal output_9: std_logic_vector(output_width-1 downto 0) := (others => '0');
begin
	
	output_6(5 downto 0) <= input(5 downto 0);
	output_9(8 downto 0) <= input(8 downto 0);
	
	extend_6:
	for i in 6 to output_width-1 generate
		output_6(i) <= input(5) and (not bypass);
	end generate;

	extend_9:
	for i in 9 to output_width-1 generate
		output_9(i) <= input(8) and (not bypass);
	end generate;
	
	output <= output_6 when (sel_6_9 = '1') else
		output_9;

end architecture;
