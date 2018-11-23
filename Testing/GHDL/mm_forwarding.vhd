library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mm_forwarding is
	port( EX_MM_AR2, MM_WB_AR3 : in std_logic_vector(2 downto 0);
		  op_MM_WB, op_EX_MM : in std_logic_vector(3 downto 0);
		  EX_MM_AR2_valid, MM_WB_AR3_valid : in std_logic;
		  mem_forward_mux : out std_logic;
		  clk : in std_logic);
end entity;

architecture behave of mm_forwarding is
	signal ar_equal : std_logic := '0';
begin
	ar_equal <= (EX_MM_AR2_valid and MM_WB_AR3_valid)  when (EX_MM_AR2 = MM_WB_AR3) else '0';
	mem_forward_mux <= ar_equal when((op_MM_WB = "0100") and (op_EX_MM = "0101")) else '0';
end architecture;
		