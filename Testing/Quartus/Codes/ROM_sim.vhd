library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity ROM_SIM is
	generic(num_words: integer := 256;
		word_length: integer := 16);
	port(
		address: in std_logic_vector(15 downto 0);
		data_out: out std_logic_vector(word_length-1 downto 0);
		rd_ena ,clk : in std_logic);
end entity;

architecture behave of ROM_SIM is
	type int_array is array (0 to num_words-1) of integer;
	signal memory: int_array := (others => 0);
	signal address_concat: std_logic_vector(integer(ceil(log2(real(num_words))))-1 downto 0);
begin

	address_concat <= address(integer(ceil(log2(real(num_words))))-1 downto 0);
	process(rd_ena, address_concat)
	begin
		data_out <= std_logic_vector(to_unsigned(memory(to_integer(unsigned(address_concat))),word_length));
	end process;

	memory(0) <= 12529;
	memory(1) <= 13042;	memory(2) <= 13555;	memory(3) <= 14068;	memory(4) <= 14597;
	memory(5) <= 15110;	memory(6) <= 15616;	memory(7) <= 31999;	memory(8) <= 12288;
	memory(9) <= 12800;	memory(10) <= 13312;	memory(11) <= 13824;	memory(12) <= 14336;
	memory(13) <= 14848;	memory(14) <= 27839;
end architecture;