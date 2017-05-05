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
	signal clear_temp :std_logic := '0';
begin

    --------------------------------------------------------------------

	clear <= clear_temp;
	top_mux_RR_control   <= clear_temp;

    --------------------------------------------------------------------

	-- ID_RR_mux_control will decide the operation for LHI and LLI if all 'X' are 0
	LHI_R7_flush <= '1' when(opcode = "0011" and AR3_ID_RR = "111" and ID_RR_valid(0) = '1') else '0';
	LLI_R7_flush <= '1' when(opcode = "1011" and AR3_ID_RR = "111" and ID_RR_valid(0) = '1') else '0';
	JLR  	     <= '1' when(opcode = "1001") else '0';
	data_mux_RR  <= SE_ID_RR when(LLI_R7_flush = '1') else LS_PC_ID_RR when(LHI_R7_flush = '1') else DO1_ID_RR;
	clear_temp   <= LHI_R7_flush or LLI_R7_flush or JLR;
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
		IF_ID_cond : in std_logic_vector(1 downto 0);
		-- LW from ID_RR
		ID_RR_AR3 : in std_logic_vector(2 downto 0);
		ID_RR_valid : in std_logic_vector(2 downto 0);
		decoder_valid : in std_logic_vector(2 downto 0);
		opcode_ID_RR, opcode_IF_ID : in std_logic_vector(3 downto 0);
		clk: in std_logic;
		---------------------------------------
		disable_out : out std_logic := '0';
		SM_start_control : out std_logic := '0';
		clear : out std_logic := '0');
end entity;

-- to be changed staller
architecture hazard of staller is 
	signal disable : std_logic := '0';
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
			elsif (((opcode_IF_ID(3 downto 2) & opcode_IF_ID(0)) = "000") and (IF_ID_cond = "01")) then
				disable <= '1';
			end if;
		end if;	
	end process
	
	clear <= disable;
	disable_out <= disable;
	

end architecture;

--#######################################################################################################

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hazard_EX is 
	port( 
		RR_EX_AR3, RR_EX_valid, RR_EX_mux_control  : in std_logic_vector(2 downto 0);
		RR_EX_opcode : in std_logic_vector(3 downto 0);
		EX_MM_FC, MM_WB_FC : in std_logic;
		EX_MM_C : in std_logic_vector(1 downto 0);	--conditions
		EX_MM_F, MM_WB_F, F, alu_F : in std_logic_vector(2 downto 0);  -- EX_MM flafs must be taken from MM hazard block
		ALU_out, PC_inc, SE_PC : in  std_logic_vector(15 downto 0);
		beq_is_taken, beq_bit : std_logic;
		table_toggle : out std_logic;
		pass_beq_taken : out std_logic;
		top_EX_mux_data : out std_logic_vector(15 downto 0);
		top_EX_mux : out std_logic;
		flush,clear_current : out std_logic;
		clk : in std_logic);
end entity;

architecture hazard of hazard_EX is 
	signal R7_update : std_logic := '0';
	signal valid_flags : std_logic_vector(2 downto 0);  --(OV C V)
	signal cond_ar_ins : std_logic := '0';
	signal false_cond_ar : std_logic := '0';
	signal ar_ins : std_logic := '0';
	signal tmp_table_toggle : std_logic := '0';
begin 
	ar_ins <= (not RR_EX_opcode(3)) and (not RR_EX_opcode(2)) and (not RR_EX_opcode(0)); 
	cond_ar_ins <= '1' when ((EX_MM_C /= "00") and (ar_ins = '1')) else '0';
	false_cond_ar <= '1' when ((cond_ar_ins = '1') and (((EX_MM_C = "01") and (valid_flags(0) = '0')) or ((EX_MM_C = "10") and (valid_flags(1) = '0')) or ((EX_MM_C = "11") and (valid_flags(2) = '0'))) else '0';
	
	process(clk, MM_WB_F, MM_WB_FC, EX_MM_F, EX_MM_FC, F)
	begin
		valid_flags <= F;
		if(EX_MM_FC = '1') then
			valid_flags <= EX_MM_F;   --LSB for FC
		elsif(MM_WB_FC = '1') then
			valid_flags <= MM_WB_F;
		end if;
	end process;
	
	clear_current <= false_cond_ar;
	
	process(false_cond_ar, RR_EX_AR3, RR_EX_valid, RR_EX_mux_control)
	begin
		R7_update <= '0';
		table_toggle <= '0';
		top_EX_mux_data <= (others => '0');
		if(RR_EX_AR3 = "111" and RR_EX_valid(0) = '1' and ar_ins = '1') then
			if (false_cond_ar = '0') then
				R7_update <= '1';
				top_EX_mux_data <= ALU_out;
			end if;
		elsif(beq_bit = '1') then
			if(beq_is_taken = '1' and alu_F(0) = '0') then --beq not taken but taken
				R7_update <= '1';
				top_EX_mux_data <= PC_inc;
				tmp_table_toggle <= '1';
			elsif(beq_is_taken = '0' and alu_F(0) = '1') then 
				R7_update <= '1';
				top_EX_mux_data <= SE_PC;
				tmp_table_toggle <= '1';
			end if;	
		end if;
	end process;
	
	flush <= R7_update;
	top_EX_mux <= R7_update;
	table_toggle <= tmp_table_toggle;
	pass_beq_taken <= beq_is_taken xor tmp_table_toggle;
	
end architecture;

--############################################################################################################

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hazard_MM is 
	port( 
		EX_MM_AR3,EX_MM_valid,EX_MM_mux_control : in std_logic_vector(2 downto 0);
		EX_MM_flags : in std_logic_vector(2 downto 0);
		m_out : in std_logic_vector(15 downto 0);
		MM_flags_out : out std_logic_vector(2 downto 0);
		top_MM_mux : out std_logic;
		clear : out std_logic);
end entity;

architecture hazard of hazard_MM is 
begin 
	top_MM_mux <= '1' when (AR3_EX_MM = "111" and valid_EX_MM(0) = '1' and EX_MM_mux_control = "100") else '0';
	clear 	   <= '1' when (AR3_EX_MM = "111" and valid_EX_MM(0) = '1' and EX_MM_mux_control = "100") else '0';
	MM_flags_out(2 downto 1) <= EX_MM_flags(2 dowto 1);
	MM_flags_out(0) <= '1' when (m_out = (others => '0') and EX_MM_mux_control = "100") else '0';
end architecture;

--################################################################################################################

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity hazard_conditional_WB is 
	port( 
		AR3_MM_WB: in std_logic_vector(2 downto 0);
		MM_WB_LS_PC, MM_WB_PC_inc : in std_logic_vector(15 downto 0);
		
		MM_WB_valid		  : in std_logic_vector (2 downto 0);
		-----------------------------------------------------------
		r7_write, reg_write_out, top_WB_mux_control, clear: out std_logic;
		r7_select 	: out std_logic_vector(1 downto 0);
		top_WB_mux_data : out std_logic_vector(15 downto 0);
		flags_enable    : out std_logic_vector( 2 downto 0);
		---------------------------------------------------------------
		is_taken	: in std_logic;
		opcode		: in std_logic(3 downto 0);
		);
end entity;

architecture hazard of hazard_conditional_WB is
	signal JLR_flush,JAL_flush, flush: std_logic;
begin 

	JLR_flush      <= '1' when ( opcode = "1001" and AR3_MM_WB = "111") else '0';
	JAL_flush      <= '1' when ( opcode = "1000" and AR3_MM_WB = "111") else '0';
	
 		-- The outputs
	flush <= (JLR_flush or JAL_flush);
	clear 	       	   <= flush;
	top_WB_mux_control <= flush; 
	top_WB_mux_data    <= MM_WB_PC_inc when (flush = '1') else 
			      (others => '0');
	
  	r7_select	   <= "00"  when(opcode = "1001") else "10" when( is_taken = '1' or opcode = "1000") else "01";

	r7_write	   <= '0'  when(AR3_MM_WB = "111" and MM_WB_valid(0) = '1') else '1';  -- Since PC+1 will be written using Reg write

end architecture;
