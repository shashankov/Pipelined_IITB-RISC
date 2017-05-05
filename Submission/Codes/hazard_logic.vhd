library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- checks for hazard LLI R7, LHI R7 or JLR instruction
entity hazard_RR is 
	port( 
		AR3_ID_RR : in std_logic_vector(2 downto 0);
		ID_RR_valid : in std_logic_vector(2 downto 0);
		SE_ID_RR    : in std_logic_vector(15 downto 0);
		LS_PC_ID_RR : in std_logic_vector(15 downto 0);
		DO1_ID_RR   : in std_logic_vector(15 downto 0);
		opcode	    : in std_logic_vector(3 downto 0);
		clk: in std_logic;
		---------------------------------------
		clear : out std_logic := '0';
		top_mux_RR_control : out std_logic;
		data_mux_RR: out std_logic_vector(15 downto 0));
end entity;

architecture hazard0 of hazard_RR is
	signal LLI_R7_flush, LHI_R7_flush, JLR : std_logic := '0';
	--signal clear_temp :std_logic := '0';
begin

    --------------------------------------------------------------------

	clear <= top_WB_mux_control;

    --------------------------------------------------------------------

	-- ID_RR_mux_control will decide the operation for LHI and LLI if all 'X' are 0
	LHI_R7_flush <= '1' when(opcode = "0011" and AR3_ID_RR = "111" and ID_RR_valid(0) = '1') else '0';
	LLI_R7_flush <= '1' when(opcode = "1011" and AR3_ID_RR = "111" and ID_RR_valid(0) = '1') else '0';
	JLR  	     <= '1' when(opcode = "1001") else '0';
	top_mux_RR_control   <= LHI_R7_flush or LLI_R7_flush or JLR;
	data_mux_RR  <= SE_ID_RR when(LLI_R7_flush = '1') else LS_PC_ID_RR when(LHI_R7_flush = '1') else DO1_ID_RR;
	--clear_temp   <= LHI_R7_flush or LLI_R7_flush or JLR;
	-- clears the IDRR and clear signal is passed throug a register for one cycle delay 
end architecture;


--###############################################################################################
library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity staller is 
	port( 
		decoder_AR1 : in std_logic_vector(2 downto 0);
		decoder_AR2 : in std_logic_vector(2 downto 0);
		ID_RR_LW : in std_logic;
		-- LW from ID_RR
		ID_RR_AR3 : in std_logic_vector(2 downto 0);
		ID_RR_valid : in std_logic_vector(2 downto 0);
		decoder_valid : in std_logic_vector(2 downto 0);
		opcode_ID_RR, opcode_IF_ID : in std_logic_vector(3 downto 0);
		clk: in std_logic;
		---------------------------------------
		disable : out std_logic := '0';
		SM_start_control : out std_logic := '0';
		clear : out std_logic := '0');
end entity;

-- to be changed staller
architecture hazard of staller is 
	begin 
	process(opcode_ID_RR, opcode_IF_ID, clk, decoder_AR1, decoder_AR2, ID_RR_LW, ID_RR_valid, ID_RR_AR3)
	begin
		disable <= '0';
		if(ID_RR_LW = '1') then
			if(opcode_IF_ID = "0101") then   --SW ins in IF_ID
				if(decoder_AR1 = ID_RR_AR3) then
					disable <= '1';
			elsif(opcode_IF_ID = "0111") then
				if(decoder_AR1 = ID_RR_AR3) then
					disable <= '1';
					SM_start_control <= '1';
			elsif (((decoder_AR1 = ID_RR_AR3) and decoder_valid(2) = '1') or ((decoder_AR2 = ID_RR_AR3) and decoder_valid(1) = '1')) then
				disable <= '1';
			end if;
		end if;	
	end process
	
	clear <= disable;
	

end architecture;

--#######################################################################################################

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hazard_EX is 
	port( 
		AR3_RR_EX, valid_RR_EX, RR_EX_mux_control  : in std_logic_vector(2 downto 0);
		top_EX_mux : out std_logic;
		clear : out std_logic);
end entity;

architecture hazard of hazard_EX is 
begin 
	top_EX_mux <= '1' when (AR3_RR_EX = "111" and valid_RR_EX(0) = '1' and RR_EX_mux_control = "000") else '0';
	clear      <= '1' when (AR3_RR_EX = "111" and valid_RR_EX(0) = '1' and RR_EX_mux_control = "000") else '0';   -- Clears IF-ID, ID-RR
end architecture;

--############################################################################################################

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hazard_MM is 
	port( 
		AR3_EX_MM,valid_EX_MM,EX_MM_mux_control : in std_logic_vector(2 downto 0);
		top_MM_mux : out std_logic;
		clear : out std_logic);
end entity;

architecture hazard of hazard_MM is 
begin 
	top_MM_mux <= '1' when (AR3_EX_MM = "111" and valid_EX_MM(0) = '1' and EX_MM_mux_control = "100") else '0';
	clear 	   <= '1' when (AR3_EX_MM = "111" and valid_EX_MM(0) = '1' and EX_MM_mux_control = "100") else '0'; 
end architecture;

--################################################################################################################

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hazard_conditional_WB is 
	port( 
		condition 			  : in std_logic_vector(1 downto 0);
		flag_control,flags_ALU,flags_user : in std_logic_vector(2 downto 0);
		BEQ,reg_write_in	 	  : in std_logic;
		MM_WB_mux_control, AR3_MM_WB: in std_logic_vector(2 downto 0);
		MM_WB_LS_PC, MM_WB_PC_inc : in std_logic_vector(15 downto 0);
		
		AR1_ID_RR, AR2_ID_RR      : in std_logic_vector(15 downto 0);
		AR1_RR_EX, AR2_RR_EX      : in std_logic_vector(15 downto 0);
		AR1_EX_MM, AR2_EX_MM      : in std_logic_vector(15 downto 0);
		ID_RR_valid		  : in std_logic_vector (2 downto 0);
		RR_EX_valid		  : in std_logic_vector (2 downto 0);
		EX_MM_valid		  : in std_logic_vector (2 downto 0);
		MM_WB_valid		  : in std_logic_vector (2 downto 0);
		-----------------------------------------------------------
		r7_write, reg_write_out, top_WB_mux_control, clear: out std_logic;
		r7_select 	: out std_logic_vector(1 downto 0);
		top_WB_mux_data : out std_logic_vector(15 downto 0);
		flags_enable    : out std_logic_vector( 2 downto 0);
		---------------------------------------------------------------
		is_taken	: in std_logic;
		opcode		: in std_logic;
		toggle	        : out std_logic);
end entity;

architecture hazard of hazard_conditional_WB is
	signal adc_noR7_flush, adc_R7_flush, JLR_flush,JAL_flush, BEQ_Flush, flush, conditional_ar_bit: std_logic;
	signal equality : std_logic;
begin 
	-- flags is value from user flags
	-- the other ALU flags will go directly connected to the user flags therefore flag_enable will be controlled by this logic
	-- no need to check valid of MM_WB as we are already checking if equal to the instruction
	-- R7 select should be 2 bit. As LS_PC should also be input due to BEQ instruction address available in LS_PC and to be stored in R7
	-- not needed Reg_write as input
	-- equality cones from dependency list

	conditional_ar_bit <= '1' when((flags_user(0) = '0' and condition = "01") or (flags_user(1) = '0' and condition = "10") or (flags_user(2) = '0' and 						condition = "11") ) else '0';

	equality <= '1' when ((AR3_MM_WB = AR1_ID_RR and ID_RR_valid(2) = '1') or (AR3_MM_WB = AR1_RR_EX and RR_EX_valid(2) = '1') or (AR3_MM_WB = AR1_EX_MM 				       and EX_MM_valid(2) = '1') or (AR3_MM_WB = AR2_ID_RR and ID_RR_valid(1) = '1') or (AR3_MM_WB = AR2_RR_EX and RR_EX_valid(1) = 				       '1')  or (AR3_MM_WB = AR2_EX_MM and EX_MM_valid(1) = '1')) else '0';  

	adc_noR7_flush <= '1' when( conditional_ar_bit = '1' and AR3_MM_WB /= "111" and equality= '1')
			      else '0';
	adc_R7_flush   <= '1' when ( conditional_ar_bit = '1' and AR3_MM_WB = "111") else '0';
	JLR_flush      <= '1' when ( opcode = "1001" and AR3_MM_WB = "111") else '0';
	JAL_flush      <= '1' when ( opcode = "1000" and AR3_MM_WB = "111") else '0';

	-- MM_WB_mux_control and MM_WB_valid decides if it is a JLR instruction or JAL instruction or any other instruction
	
	-- For LUT
	BEQ_flush      <= '1' when (BEQ = '1' and ((flags_ALU(0) xor is_taken) = '1' )) else '0'; -- checking if the branch is taken
	toggle         <= BEQ_flush;
	
 	
	-- The outputs
	clear 	       	   <= (adc_noR7_flush or adc_R7_flush or JLR_flush or BEQ_flush or JAL_flush);
	top_WB_mux_control <= '1' when(JLR_flush = '1' or BEQ_flush = '1' or JAL_flush = '1') else '0'; 
	top_WB_mux_data    <= MM_WB_PC_inc when(JLR_flush = '1' or JAL_flush = '1') else 
			      MM_WB_LS_PC  when(BEQ_flush = '1') else
			      (others => '0');
	flags_enable 	   <= "000" when((flags_user(0) = '0' and condition = "01") or (flags_user(1) = '0' and condition = "10") or (flags_user(2) = '0' and 				       condition = "11")) else flag_control;
  	r7_select	   <= "00"  when(opcode = "1001") else "10" when( BEQ_flush = '1' or opcode = "1000") else "01";

	r7_write	   <= '0'  when(AR3_MM_WB = "111") else '1';  -- Since PC+1 will be written using Reg write
	reg_write_out      <= '0'  when(conditional_ar_bit = '1') else reg_write_in;

end architecture;
