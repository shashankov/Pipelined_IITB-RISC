library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity forwarding_logic1 is 
	port( ID_RR_AR: in std_logic_vector(2 downto 0);
		  ID_RR_PC : in std_logic_vector(15 downto 0);
		  ID_RR_AR_valid : in std_logic;
		  clk : in std_logic;
		  --------------------------------------------
		  RR_EX_mux_control : in std_logic_vector(2 downto 0);
		  RR_EX_AR3_valid : in std_logic;
		  RR_EX_AR3 : in std_logic_vector(2 downto 0);
		  RR_EX_ALU_out : in std_logic_vector(15 downto 0); -- directly from ALU output
		  RR_EX_LS_PC : in std_logic_vector(15 downto 0);
		  RR_EX_SE : in std_logic_vector(15 downto 0);
		  RR_EX_PC_inc : in std_logic_vector(15 downto 0);	
		  --------------------------------------------
		  EX_MM_mux_control : in std_logic_vector(2 downto 0);
		  EX_MM_AR3_valid : in std_logic;
		  EX_MM_AR3 : in std_logic_vector(2 downto 0);
		  EX_MM_ALU_out : in std_logic_vector(15 downto 0); -- from EX_MM register
		  EX_MM_LS_PC : in std_logic_vector(15 downto 0);
		  EX_MM_SE : in std_logic_vector(15 downto 0);
		  EX_MM_PC_inc : in std_logic_vector(15 downto 0);
		  EX_MM_mem_out: in std_logic_vector(15 downto 0); -- directly from output of memory
		  --------------------------------------------
		  MM_WB_AR3_valid : in std_logic;
		  MM_WB_AR3 : in std_logic_vector(2 downto 0);
		  MM_WB_data : in std_logic_vector(15 downto 0);		  
		  --------------------------------------------
		  DO_forward_control : out std_logic;
		  DO_forward_data : out std_logic_vector(15 downto 0));
end entity;

architecture forward of forwarding_logic1 is
	signal EX_MM_data, RR_EX_data : std_logic_vector(15 downto 0);
begin
			
	RR_EX_data <= RR_EX_ALU_out when (RR_EX_mux_control = "000") else
		RR_EX_LS_PC when (RR_EX_mux_control = "001") else
		RR_EX_SE when (RR_EX_mux_control = "010") else
		RR_EX_PC_inc when (RR_EX_mux_control = "011") else
		(others => '-');
			
	EX_MM_data <= EX_MM_ALU_out when (EX_MM_mux_control = "000") else
		EX_MM_LS_PC when (EX_MM_mux_control = "001") else
		EX_MM_SE when (EX_MM_mux_control = "010") else
		EX_MM_PC_inc when (EX_MM_mux_control = "011") else
		EX_MM_mem_out when (EX_MM_mux_control = "100") else
		(others => '-');

	------------------------------------------------------------------------------------------------
	process(clk, RR_EX_data, EX_MM_data, MM_WB_data, ID_RR_AR_valid, RR_EX_AR3_valid, EX_MM_AR3_valid, MM_WB_AR3_valid)
	begin
		DO_forward_control <= '0';
		DO_forward_data <= (others => '-');
		if(ID_RR_AR_valid) then
			DO_forward_control <= '1';
			if(ID_RR_AR = "111") then
				DO_forward_data <= ID_RR_PC;
			elsif (RR_EX_AR3_valid and (ID_RR_AR = RR_EX_AR3)) then
				DO_forward_data <= RR_EX_data;
			elsif (EX_MM_AR3_valid and (ID_RR_AR = EX_MM_AR3)) then
				DO_forward_data <= EX_MM_data;
			elsif(MM_WB_AR3_valid and (MM_WB_AR3 = ID_RR_AR)) then
				DO_forward_data <= MM_WB_data;
			else
				DO_forward_control <= '0';
			end if;
		end if;
	end process;

end architecture;
