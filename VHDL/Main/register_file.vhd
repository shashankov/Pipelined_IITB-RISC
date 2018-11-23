library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity register_file is
	generic(
		word_length: integer := 16;
		num_words: integer := 8);
		
	port(
		data_in, R7_in: in std_logic_vector(word_length-1 downto 0);
		data_out1, data_out2, R0: out std_logic_vector(word_length-1 downto 0);
		sel_in, sel_out1, sel_out2: in std_logic_vector(integer(ceil(log2(real(num_words))))-1 downto 0);
		clk, wr_ena, R7_ena, reset: in std_logic);
		
end entity;

architecture trial of register_file is
	type word_bus is array(num_words-1 downto 0) of std_logic_vector(word_length-1 downto 0);
	signal reg_out: word_bus;
	signal ena: std_logic_vector(num_words-1 downto 0);
	signal r7_ena_temp: std_logic;
	signal data_out, R7_reg_in: std_logic_vector(word_length-1 downto 0);
	
begin
	
	r7_ena_temp <= R7_ena or ena(7);
	GEN_REG: 
	for i in 0 to num_words-2 generate
		REG: my_reg
			generic map(word_length)
			port map(clk => clk, ena => ena(i), 
				Din => data_in, Dout => reg_out(i), clr => reset);
	end generate GEN_REG;
	
	R7: my_reg
		generic map(word_length)
		port map(clk => clk, ena => r7_ena_temp, 
			Din => R7_reg_in, Dout => reg_out(7), clr => reset);
	
	R7_reg_in <= R7_in when (R7_ena = '1')
		else data_in;
		
	in_decode: process(sel_in, wr_ena)
	begin
		ena <= (others => '0');
		ena(to_integer(unsigned(sel_in))) <= wr_ena;
	end process;
	
	data_out1 <= reg_out(to_integer(unsigned(sel_out1)));
	data_out2 <= reg_out(to_integer(unsigned(sel_out2)));
	R0 <= reg_out(0);
	
end architecture;
