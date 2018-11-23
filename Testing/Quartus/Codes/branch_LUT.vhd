library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

library work;
use work.basic.all;

entity branch_LUT is
	port(
		clk, reset, is_BEQ, toggle: in std_logic;
		new_PC_in, PC_in, BA_in: in std_logic_vector(15 downto 0);
		BA: out std_logic_vector(15 downto 0);
		is_taken: out std_logic;
		address_in: in std_logic_vector(2 downto 0);
		address_out: out std_logic_vector(2 downto 0));
end entity;

architecture for_BEQ of branch_LUT is
	type multi_vector_long is array (0 to 7) of std_logic_vector(15 downto 0);
	signal PCs_out, PCs_in, BAs_in, BAs_out: multi_vector_long := (others => (others => '0'));
	signal taken_in, taken_out, taken_ena, PC_ena, BA_ena: std_logic_vector(7 downto 0) := (others => '0');
	signal counter_out, counter_in: std_logic_vector(2 downto 0) := "000";
	signal counter_ena: std_logic := '0';
begin
	counter: my_reg
		generic map(3)
		port map(
			clk => clk, ena => counter_ena, clr => reset,
			Din => counter_in, Dout => counter_out);
	
	Registers: for i in 0 to 7 generate
		PCX: my_reg
			generic map(16)
			port map(clk => clk, ena => PC_ena(i), clr => reset,
				Din => new_PC_in, Dout => PCs_out(i));
		BAX: my_reg
			generic map(16)
			port map(clk => clk, ena => BA_ena(i), clr => reset,
				Din => BA_in, Dout => BAs_out(i));	
		takenX: my_reg
			generic map(1)
			port map(clk => clk, ena => taken_ena(i), clr => reset,
				Din => taken_in(i downto i), Dout => taken_out(i downto i));
	end generate;
	
	taken_in <= not taken_out;
	counter_in <= std_logic_vector(unsigned(counter_out) + to_unsigned(1, 3));

	process(PC_in, PCs_out, BAs_out, taken_out)
	begin
		BA <= (others => '-');
		is_taken <= '0';
		address_out <= "---";
		for i in 0 to 7 loop
			if (PC_in = PCs_out(i)) then
				address_out <= std_logic_vector(to_unsigned(i, 3));
				BA <= BAs_out(i);
				is_taken <= taken_out(i);
				exit;
			end if;
		end loop;
	end process;

	process(is_BEQ, new_PC_in, PCs_out, counter_out)
	variable temp: boolean := false;
	begin
		temp := false;
		for i in 0 to 7 loop
			if (new_PC_in = PCs_out(i)) then
				temp := true;
			end if;
		end loop;
		
		counter_ena <= '0';
		PC_ena <= (others => '0');
		BA_ena <= (others => '0');
			
		if (temp = false) and (is_BEQ = '1') then
			counter_ena <= '1';
			PC_ena(to_integer(unsigned(counter_out))) <= '1';
			BA_ena(to_integer(unsigned(counter_out))) <= '1';
		end if;
	end process;
	
	process(address_in, toggle)
	begin
		taken_ena <= (others => '0');
		if(toggle = '1') then
			taken_ena(to_integer(unsigned(address_in))) <= '1';
		end if;
	end process;
end architecture;