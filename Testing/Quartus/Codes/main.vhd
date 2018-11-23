library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.basic.all;
use work.pipeline_register.all;

entity processor is
	port(
		clk, reset: in std_logic;
		Disp: out std_logic_vector(15 downto 0));
end entity;

architecture pipelined of processor is
	component ROM_SIM is
		generic(num_words: integer := 256;
			word_length: integer := 16);
		port(
			address: in std_logic_vector(word_length-1 downto 0);
			data_out: out std_logic_vector(word_length-1 downto 0);
			rd_ena ,clk : in std_logic);
	end component;
	
	component branch_LUT is
		port(
			clk, reset, is_BEQ, toggle: in std_logic;
			new_PC_in, PC_in, BA_in: in std_logic_vector(15 downto 0);
			BA: out std_logic_vector(15 downto 0);
			is_taken: out std_logic;
			address_in: in std_logic_vector(2 downto 0);
			address_out: out std_logic_vector(2 downto 0));
	end component;
	
	component decoder is
		port(
			INS: in std_logic_vector(0 to 15);
			SE9_6, ID_PC, LS_PC, LLI: out std_logic; 
			LM, SM, LW, SE_DO2, BEQ: out std_logic;
			WB_mux, AR1, AR2, AR3, valid, Flag_C: out std_logic_vector(2 downto 0);
			ALU_C, Cond, WR: out std_logic_vector(1 downto 0)
			);
	end component;
	
	component sign_extend is
		generic(output_width: integer := 16);
		port(
			input: in std_logic_vector(output_width-1 downto 0);
			output: out std_logic_vector(output_width-1 downto 0);
			sel_6_9, bypass: in std_logic);
	end component;
	
	component LM_SM is 
		port(
			input: in std_logic_vector(7 downto 0);
			LM, SM ,clk, reset: in std_logic;
			AR2 : out std_logic_vector(2 downto 0);
			AR3 : out std_logic_vector(2 downto 0);
			clear, disable, RF_DO1_mux, ALU2_mux, AR3_mux, mem_in_mux, AR2_mux, input_mux: out std_logic);
	end component;
	
	component forwarding_logic is 
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
	end component;

	component hazard_RR is 
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
	end component;
	
	component staller is 
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
	end component;

	component register_file is
		generic(
			word_length: integer := 16;
			num_words: integer := 8);
			
		port(
			data_in, R7_in: in std_logic_vector(word_length-1 downto 0);
			data_out1, data_out2, R0: out std_logic_vector(word_length-1 downto 0);
			sel_in, sel_out1, sel_out2: in std_logic_vector(integer(ceil(log2(real(num_words))))-1 downto 0);
			clk, wr_ena, R7_ena, reset: in std_logic);
			
	end component;	
	
	component alu is
		generic(word_length: integer := 16);
		port(
			input1, input2: in std_logic_vector(word_length-1 downto 0);
			output: out std_logic_vector(word_length-1 downto 0);
			cin: in std_logic;
			sel: in std_logic_vector(1 downto 0);
			CY, OV, Z: out std_logic);
	end component;
	
	component hazard_EX is 
		port( 
			RR_EX_AR3, RR_EX_valid, RR_EX_mux_control  : in std_logic_vector(2 downto 0);
			RR_EX_opcode : in std_logic_vector(3 downto 0);
			EX_MM_FC, MM_WB_FC : in std_logic;
			RR_EX_C : in std_logic_vector(1 downto 0);	--conditions
			EX_MM_F, MM_WB_F, F, alu_F : in std_logic_vector(2 downto 0);  -- EX_MM flafs must be taken from MM hazard block
			ALU_out, PC_inc, SE_PC : in  std_logic_vector(15 downto 0);
			beq_is_taken, beq_bit: in std_logic;
			table_toggle : out std_logic;
			pass_beq_taken : out std_logic;
			top_EX_mux_data : out std_logic_vector(15 downto 0);
			top_EX_mux : out std_logic;
			flush,clear_current : out std_logic;
			clk : in std_logic);
	end component;
	
	component RAM_SIM is
		generic(
			word_length: integer := 16;
			num_words: integer := 256);
			
		port(
			data_in: in std_logic_vector(word_length-1 downto 0);
			data_out : out std_logic_vector(word_length-1 downto 0);
			address: in std_logic_vector(word_length-1 downto 0);
			clk, wr_ena, rd_ena, reset: in std_logic);
			
	end component;
	
	component mm_forwarding is
		port( 
			EX_MM_AR2, MM_WB_AR3 : in std_logic_vector(2 downto 0);
			op_MM_WB, op_EX_MM : in std_logic_vector(3 downto 0);
			EX_MM_AR2_valid, MM_WB_AR3_valid : in std_logic;
			mem_forward_mux : out std_logic;
			clk : in std_logic);
	end component;
	

	component hazard_MM is 
		port( 
			EX_MM_AR3,EX_MM_valid,EX_MM_mux_control : in std_logic_vector(2 downto 0);
			EX_MM_flags : in std_logic_vector(2 downto 0);
			m_out : in std_logic_vector(15 downto 0);
			MM_flags_out : out std_logic_vector(2 downto 0);
			top_MM_mux : out std_logic;
			clear : out std_logic);
	end component;
	
	component hazard_conditional_WB is 
	port( 
		AR3_MM_WB: in std_logic_vector(2 downto 0);
		MM_WB_LS_PC, MM_WB_PC_inc : in std_logic_vector(15 downto 0);
		
		MM_WB_valid		  : in std_logic_vector (2 downto 0);
		-----------------------------------------------------------
		r7_write, top_WB_mux_control, clear: out std_logic;
		r7_select 	: out std_logic_vector(1 downto 0);
		top_WB_mux_data : out std_logic_vector(15 downto 0);
		---------------------------------------------------------------
		is_taken	: in std_logic;
		opcode		: in std_logic_vector(3 downto 0)
		);
	end component;

	signal BEQ_PC, JAL_PC: std_logic_vector(15 downto 0);
	signal unflush_out : std_logic_vector(0 downto 0);
	
	signal PC_in, PC_out, IM_AI, IM_DO, PCpp, BA: std_logic_vector(15 downto 0);
	signal PC_ena, is_BEQ, toggle, is_taken: std_logic;
	signal disable_IF_ID, clear_control_IF_ID, disable_ID_RR, clear_control_ID_RR: std_logic;
	signal BLUT_index_in, BLUT_index_out: std_logic_vector(2 downto 0);
	signal BLUT_ID, BLUT_RR: std_logic_vector(3 downto 0);
	
	signal PC_ID, PCpp_ID, INS_ID, SE_PC_ID, SE_ID: std_logic_vector(15 downto 0);	
	signal ALU_C_ID, Cond_ID, WR_ID: std_logic_vector(1 downto 0);
	signal LM_ID, LM_RR, LM_SM_ID_RR: std_logic_vector(7 downto 0);
	signal SE9_6, ID_PC, LLI, SM: std_logic;
	signal AR1_ID, AR2_ID, AR3_ID, FC_ID: std_logic_vector(2 downto 0);
	signal CL_ID, CL_RR: std_logic_vector(11 downto 0);
	signal SM_start_control, SM_block : std_logic;
	
	signal PC_RR, PCpp_RR, SE_PC_RR, SE_RR: std_logic_vector(15 downto 0);
	signal OP_RR: std_logic_vector(3 downto 0);
	signal ALU_C_RR, Cond_RR, WR_RR: std_logic_vector(1 downto 0);
	signal AR1_RR, AR2_RR, AR3_RR, AR2_DD, AR3_DD, FC_RR: std_logic_vector(2 downto 0);
	signal clear_LM_SM, ALU2_mux, mem_in_mux, disable_LM_SM, RF_DO1_mux, AR2_mux,AR3_mux, LM_SM_input_sel: std_logic;
	signal LS_PC_RR, LS_RR, DO1_RR, DO2_RR : std_logic_vector (15 downto 0);
	signal hazard_RR_clear, top_mux_RR_control, staller_disable, staller_clear : std_logic; 
	signal top_mux_RR_data ,top_mux_RR: std_logic_vector(15 downto 0);
	
	signal AR2_RF : std_logic_vector(2 downto 0);
	signal DO1_RF, DO2_RF, F1_mux: std_logic_vector(15 downto 0);
	signal clear_control_RR_EX, disable_RR_EX: std_logic;
		
	signal CL_EX : std_logic_vector(12 downto 0);
	signal AR2_EX, AR3_EX, FC_EX, AR3_before_EX : std_logic_vector(2 downto 0);
	signal ALU_out, LS_PC_EX, SE_EX, PCpp_EX, DO1_EX, DO2_EX, top_mux_EX_data: std_logic_vector(15 downto 0);
	signal ALU_C_EX, Cond_EX, WR_EX : std_logic_vector(1 downto 0);
	signal forward1_control, forward2_control, reset_temp : std_logic;
	signal forward1_data, forward2_data, top_mux_EX: std_logic_vector(15 downto 0);
	signal BLUT_EX, OP_EX: std_logic_vector(3 downto 0);
	signal is_taken_EX, top_mux_EX_control, hazard_EX_flush, hazard_EX_clear_current: std_logic;
	
	signal SE_DO2, ALU2_input: std_logic_vector(15 downto 0);
	signal flags_EX, flags_user : std_logic_vector(2 downto 0);
		
	signal CL_MM : std_logic_vector(8 downto 0);
	signal AR3_MM, AR2_MM : std_logic_vector(2 downto 0);
	signal ALU_out_MM, LS_PC_MM, SE_MM, PCpp_MM, mem_out, DO1_MM, DO2_MM, top_mux_MM: std_logic_vector(15 downto 0);
	signal FC_MM, flags_MM, flags_MM_hazard: std_logic_vector(2 downto 0);
	signal clear_control_EX_MM, hazard_MM_clear, top_mux_MM_control, forward_mux_control_MM : std_logic;
	signal WR_MM : std_logic_vector(1 downto 0);
	signal BLUT_MM, OP_MM : std_logic_vector(3 downto 0);
	signal mem_address, mem_data: std_logic_vector(15 downto 0);
	
	signal CL_WB : std_logic_vector(7 downto 0);
	signal AR3_WB, FC_WB, flags_WB : std_logic_vector(2 downto 0);
	signal D3_data, R7_in, LS_PC_WB, SE_WB, ALU_out_WB, mem_out_WB, DO1_WB, PCpp_WB: std_logic_vector(15 downto 0);
	signal WR_WB : std_logic_vector(1 downto 0);
	signal clear_control_MM_WB : std_logic;
	signal BLUT_WB, OP_WB : std_logic_vector(3 downto 0);

	signal R7_write, top_mux_WB_control, hazard_WB_clear : std_logic;
	signal r7_select : std_logic_vector(1 downto 0);
	signal top_mux_WB_data : std_logic_vector(15 downto 0);
	
	signal concatenation_BLUT_IF_ID, concatenation_BLUT_EX_MM: std_logic_vector(3 downto 0);
	signal concatenation_CL_RR_EX: std_logic_vector(12 downto 0);
	signal concatenation_CL_EX_MM: std_logic_vector(8 downto 0);
	signal concatenation_CL_MM_WB: std_logic_vector(7 downto 0);
	
	signal R7_write_temp: std_logic;
begin

	---------------------------------
	---- Instruction Fetch Stage ----
	---------------------------------
	PC: my_reg
		generic map(16)
		port map(
			clk => clk, clr => reset, ena => PC_ena,
			Din => PC_in, Dout => PC_out);
	
	PC_ena	<= not(staller_disable or disable_LM_SM);
	
	PCpp <= std_logic_vector(unsigned(PC_out) + to_unsigned(1,16));
	IM_AI <= PC_out;
	
	IM: ROM_SIM
		port map(
			address => IM_AI, data_out => IM_DO,
			rd_ena => '1', clk => clk);
	
	BLUT: branch_LUT
		port map(
		clk => clk, reset => reset, is_BEQ => is_BEQ, toggle => toggle,
		new_PC_in => PC_ID, PC_in => PC_out, BA_in => SE_PC_ID, is_taken => is_taken, 
		BA => BA, address_in => BLUT_index_in, address_out => BLUT_index_out);
		
	BEQ_PC <= PCpp when (is_taken = '0') else BA;
	
	---------------------------------
	---- IF/ID Pipeline Register ----
	---------------------------------
	concatenation_BLUT_IF_ID <= BLUT_index_out & is_taken;
	pipe_IF_ID: IF_ID
		port map(
		PC_in => PC_out, Inst_in => IM_DO, PC_inc_in => PCpp,
		clk => clk, clear => reset, clear_control => clear_control_IF_ID, 
		disable => disable_IF_ID, BLUT_in => concatenation_BLUT_IF_ID,
		Inst_out => INS_ID, PC_out => PC_ID, PC_inc_out => PCpp_ID, BLUT_out => BLUT_ID, unflush_out => unflush_out);

	clear_control_IF_ID <= (not disable_ID_RR) and (ID_PC or hazard_RR_clear or hazard_EX_flush or hazard_MM_clear or hazard_WB_clear);	-- to clear IFID in case of JAL
	disable_IF_ID	    <= staller_disable or disable_LM_SM;
	
	--
	-- Instruction Decode Stage
	--
	
	decode_ins: decoder
		port map(
			INS => INS_ID, SE9_6 => SE9_6, ID_PC => ID_PC, LS_PC => CL_ID(0),
			LLI => LLI, LM => CL_ID(2), SM => SM, LW => CL_ID(3), 
			SE_DO2 => CL_ID(4), BEQ => CL_ID(1), WB_mux => CL_ID(7 downto 5),
			AR1 => AR1_ID, AR2 => AR2_ID, AR3 => AR3_ID, valid => CL_ID(10 downto 8),
			ALU_C => ALU_C_ID, Flag_C => FC_ID, Cond => Cond_ID, WR => WR_ID);
	
	SE: sign_extend
		port map(
			input => INS_ID, output => SE_ID, 
			sel_6_9 => SE9_6, bypass => LLI);
	
	LM_SM_ID_RR <= LM_RR when  (LM_SM_input_sel = '1') else LM_ID; 			
	SE_PC_ID <= std_logic_vector(unsigned(PC_ID) + unsigned(SE_ID));
	JAL_PC <= BEQ_PC when (ID_PC = '0') else SE_PC_ID;
	is_BEQ <= CL_ID(1);
	CL_ID(11) <= unflush_out(0);
	
	--
	-- ID/RR Pipeline Register
	--
	
	LM_ID <= INS_ID(7 downto 0);
	pipe_ID_RR: ID_RR
		port map(
			PC_in => PC_ID, SE_PC_in => SE_PC_ID, SE_in => SE_ID,
			CL_in => CL_ID, ALU_C_in => ALU_C_ID, FC_in => FC_ID,
			Cond_in => Cond_ID, Write_in => WR_ID, AR1_in => AR1_ID,
			AR2_in => AR2_ID, AR3_in => AR3_ID, PC_inc_in => PCpp_ID, 
			LM_in => LM_ID, clk => clk, clear => reset, 
			clear_control => clear_control_ID_RR, disable => disable_ID_RR,
			PC_out => PC_RR, SE_PC_out => SE_PC_RR, SE_out => SE_RR, 
			CL_out => CL_RR, ALU_C_out => ALU_C_RR, FC_out => FC_RR, 
			Cond_out => Cond_RR, Write_out => WR_RR, AR1_out => AR1_RR, AR2_out => AR2_RR, AR3_out => AR3_RR,
			PC_inc_out => PCpp_RR, LM_out => LM_RR, op_in => INS_ID(15 downto 12),
			op_out => OP_RR, BLUT_in => BLUT_ID, BLUT_out => BLUT_RR);
			
	
	clear_control_ID_RR <= (not disable_RR_EX) and (hazard_RR_clear or staller_clear or hazard_EX_flush or hazard_MM_clear or hazard_WB_clear); 
	disable_ID_RR	    <= disable_LM_SM;
	
	--
	-- Register Read Stage
	--
	-- LM SM Block
	SM_block <= (not SM_start_control) and SM;
	LM_SM_inst: LM_SM
		port map(
		input => LM_SM_ID_RR, LM => CL_RR(2), SM => SM_block, clk => clk,
		reset => reset, AR2 =>AR2_DD , AR3 =>AR3_DD , clear => clear_LM_SM, disable => disable_LM_SM ,
		input_mux => LM_SM_input_sel, RF_DO1_mux => RF_DO1_mux, AR2_mux => AR2_mux, AR3_mux => AR3_mux, mem_in_mux => mem_in_mux, ALU2_mux => ALU2_mux );
	
	--Forwarding Block
	ForwardingBlock1 : forwarding_logic
		port map(
		ID_RR_AR => AR1_RR, ID_RR_AR_valid => CL_RR(10), ID_RR_PC => PC_RR, clk => clk, 
		RR_EX_mux_control => CL_EX(5 downto 3), RR_EX_AR3_valid => CL_EX(6), RR_EX_AR3 => AR3_EX, 
		RR_EX_ALU_out => ALU_out, RR_EX_LS_PC => LS_PC_EX, RR_EX_SE => SE_EX, RR_EX_PC_inc => PCpp_EX,
		EX_MM_mux_control => CL_MM(3 downto 1), EX_MM_AR3_valid => CL_MM(4), EX_MM_AR3 => AR3_MM,
		EX_MM_ALU_out => ALU_out_MM, EX_MM_LS_PC => LS_PC_MM, EX_MM_SE => SE_MM, EX_MM_PC_inc => PCpp_MM, EX_MM_mem_out => mem_out,
		MM_WB_AR3_valid => CL_WB(4), MM_WB_AR3 => AR3_WB, MM_WB_data => D3_data,
		DO_forward_control => forward1_control, DO_forward_data => forward1_data);
	
	ForwardingBlock2 : forwarding_logic
		port map(
		ID_RR_AR => AR2_RR, ID_RR_AR_valid => CL_RR(9), ID_RR_PC => PC_RR, clk => clk, 
		RR_EX_mux_control => CL_EX(5 downto 3), RR_EX_AR3_valid => CL_EX(6), RR_EX_AR3 => AR3_EX, 
		RR_EX_ALU_out => ALU_out, RR_EX_LS_PC => LS_PC_EX, RR_EX_SE => SE_EX, RR_EX_PC_inc => PCpp_EX,
		EX_MM_mux_control => CL_MM(3 downto 1), EX_MM_AR3_valid => CL_MM(4), EX_MM_AR3 => AR3_MM,
		EX_MM_ALU_out => ALU_out_MM, EX_MM_LS_PC => LS_PC_MM, EX_MM_SE => SE_MM, EX_MM_PC_inc => PCpp_MM, EX_MM_mem_out => mem_out,
		MM_WB_AR3_valid => CL_WB(4), MM_WB_AR3 => AR3_WB, MM_WB_data => D3_data,
		DO_forward_control => forward2_control, DO_forward_data => forward2_data);	
		
	-- Hazard RR
	hazard_RR_inst: hazard_RR
		port map(
		AR3_ID_RR => AR3_RR, ID_RR_valid => CL_RR(10 downto 8), SE_ID_RR => SE_RR, LS_PC_ID_RR => LS_PC_RR,
		DO1_ID_RR => DO1_RR, opcode => OP_RR, clk => clk, clear => hazard_RR_clear, top_mux_RR_control => top_mux_RR_control,
		data_mux_RR => top_mux_RR_data);
		
	-- Staller
	staller_inst: staller
		port map(
		decoder_AR1 => AR1_ID, decoder_AR2 => AR2_ID, ID_RR_LW => CL_RR(3),
		IF_ID_cond => Cond_ID, ID_RR_AR3 => AR3_RR, ID_RR_valid => CL_RR(10 downto 8),
		decoder_valid => CL_ID(10 downto 8), opcode_ID_RR => OP_RR, opcode_IF_ID => INS_ID(15 downto 12),
		clk => clk, disable_out => staller_disable, SM_start_control => SM_start_control, clear => staller_clear);
	
	-- Left shift
	LS_RR <= SE_RR(8 downto 0) & "0000000";
	
	-- LS_PC mux
	LS_PC_RR <= LS_RR when(CL_RR(0) = '1') else SE_PC_RR;
	
	-- top_mux_RR
	top_mux_RR <= top_mux_RR_data when (top_mux_RR_control = '1') else JAL_PC;
	
	-- AR2 mux
	AR2_RF <= AR2_DD when(AR2_mux = '1') else AR2_RR;
	
	--F1 mux
	F1_mux <= forward1_data when(forward1_control = '1') else DO1_RF;
	
	--F2 mux
	DO2_RR <= forward2_data when(forward2_control = '1') else DO2_RF;
	
	--RR LM SM mux
	DO1_RR <= ALU_out when(RF_DO1_mux = '1') else F1_mux;
	
	--Register File
	RegisterFile: register_file
		port map(data_in => D3_data, R7_in => R7_in, data_out1 => DO1_RF,
				 data_out2 => DO2_RF, R0 => Disp, sel_in => AR3_WB, sel_out1 => AR1_RR,
				 sel_out2 => AR2_RF, clk => clk, wr_ena => WR_WB(1), R7_ena => R7_write, 
				 reset => reset);
	
	--
	-- RR/EX Pipeline Register
	--
	concatenation_CL_RR_EX <= (CL_RR(11) & ALU2_mux & mem_in_mux & AR3_mux & CL_RR(10 downto 3) & CL_RR(1));
	pipe_RR_EX: RR_EX
		port map(
		LS_PC_in => LS_PC_RR, SE_in => SE_RR, CL_in => concatenation_CL_RR_EX,
		ALU_C_in => ALU_C_RR, FC_in => FC_RR, Cond_in => Cond_RR, Write_in => WR_RR, DO1_in => DO1_RR, DO2_in => DO2_RR, 
		AR2_in => AR2_RR, AR3_in => AR3_RR, PC_inc_in => PCpp_RR, clk => clk, clear => reset, clear_control => clear_control_RR_EX, disable => disable_RR_EX, LM_SM_en => RF_DO1_mux,
		LS_PC_out => LS_PC_EX, SE_out => SE_EX, CL_out => CL_EX, ALU_C_out => ALU_C_EX, FC_out => FC_EX, 
		Cond_out => Cond_EX, Write_out => WR_EX, DO1_out => DO1_EX, DO2_out => DO2_EX, AR2_out => AR2_EX, AR3_out => AR3_before_EX, PC_inc_out => PCpp_EX, BLUT_in => BLUT_RR,
		BLUT_out => BLUT_EX, op_in => OP_RR, op_out => OP_EX);
	
	disable_RR_EX <= disable_LM_SM and (not CL_RR(2));
	clear_control_RR_EX <= clear_LM_SM or hazard_EX_flush or hazard_MM_clear or hazard_WB_clear;
	
	--
	-- Execution Stage
	--
	
	-- SE_DO2 mux
	SE_DO2 <= SE_EX when(CL_EX(2) = '1') else DO2_EX;
	
	-- ALU2 input mux
	ALU2_input <= "0000000000000001" when(CL_EX(11) = '1') else SE_DO2;

	-- ALU 
	ALU_instance: alu
		port map(
			input1 => DO1_EX, input2 => ALU2_input, output => ALU_out, cin => '0', sel => ALU_C_EX,
			CY => flags_EX(1), OV => flags_EX(2), Z => flags_EX(0));
			
	-- top mux EX
	top_mux_EX <= top_mux_EX_data when(top_mux_EX_control = '1') else top_mux_RR;
		
	-- LM SM mux
	AR3_EX <= AR3_DD when(CL_EX(9) = '1') else AR3_before_EX;
	
	-- Hazard EX block
	Hazard_EX_instance: hazard_EX
		port map(
			RR_EX_AR3 => AR3_EX, RR_EX_valid => CL_EX(8 downto 6), RR_EX_mux_control =>CL_EX(5 downto 3), 
			RR_EX_opcode => OP_EX, EX_MM_FC => FC_MM(0), MM_WB_FC => FC_WB(0), RR_EX_C => Cond_EX, EX_MM_F => flags_MM,
			MM_WB_F => flags_WB, F => flags_user, alu_F => flags_EX, ALU_out => ALU_out, PC_inc => PCpp_EX, SE_PC => LS_PC_EX, 
			beq_is_taken => BLUT_EX(0)  , beq_bit => CL_EX(0) ,table_toggle => toggle ,pass_beq_taken =>is_taken_EX , 
			top_EX_mux_data =>top_mux_EX_data , top_EX_mux => top_mux_EX_control, flush => hazard_EX_flush , clear_current => hazard_EX_clear_current, 
			clk => clk);
	
	-- Sending BLUT address
	BLUT_index_in <= BLUT_EX(3 downto 1);
	
	--
	-- EX/MM Pipeline Register
	--
	concatenation_CL_EX_MM <= (CL_EX(12) & CL_EX(10) & CL_EX(8 downto 6) & CL_EX(5 downto 3) & CL_EX(0));
	concatenation_BLUT_EX_MM <= (BLUT_EX(3 downto 1) & is_taken_EX);
	pipe_EX_MM: EX_MM
		port map(
			LS_PC_in => LS_PC_EX, SE_in => SE_EX, CL_in => concatenation_CL_EX_MM,
			FC_in => FC_EX, Write_in => WR_EX, Flags_in => flags_EX, ALU_out_in => ALU_out, DO1_in => DO1_EX, DO2_in => DO2_EX,
			AR2_in => AR2_EX, AR3_in => AR3_EX, PC_inc_in => PCpp_EX, clk => clk, clear => reset , clear_control => clear_control_EX_MM,
			clear_conditional => hazard_EX_clear_current, LS_PC_out => LS_PC_MM, SE_out => SE_MM, CL_out => CL_MM, FC_out => FC_MM, Write_out => WR_MM, 
			Flags_out => flags_MM, ALU_out_out => ALU_out_MM, DO1_out => DO1_MM, DO2_out => DO2_MM, AR2_out => AR2_MM, AR3_out => AR3_MM, 
			PC_inc_out => PCpp_MM, BLUT_in => concatenation_BLUT_EX_MM, BLUT_out => BLUT_MM, op_in => OP_EX, op_out => OP_MM);
	
	clear_control_EX_MM <= hazard_MM_clear or hazard_WB_clear;
	--
	-- Memory Read/Write Stage
	--
	-- address mux
	mem_address <= DO1_MM when(CL_MM(7) = '1') else ALU_out_MM;
	
	-- forwarding data mux
	mem_data <= mem_out_WB when(forward_mux_control_MM = '1') else DO2_MM;
	
	-- top mux MM
	top_mux_MM <= mem_out when(top_mux_MM_control = '1') else top_mux_EX;
	
	-- Data memory
	data_memory_instance: RAM_SIM
		port map(
			data_in => mem_data, data_out => mem_out, address => mem_address, clk => clk,
			wr_ena => WR_MM(0), rd_ena => '1', reset => reset);
		
	
	-- Hazard MM block
	hazard_MM_instance : hazard_MM
		port map(
			EX_MM_AR3 => AR3_MM, EX_MM_valid => CL_MM(6 downto 4), EX_MM_mux_control => CL_MM(3 downto 1),
			EX_MM_flags => flags_MM, m_out => mem_out, MM_flags_out => flags_MM_hazard, top_MM_mux => top_mux_MM_control,
			clear => hazard_MM_clear);
	
	-- Memory forwarding block
	memory_forwarding_instance : mm_forwarding
		port map(
			EX_MM_AR2 => AR2_MM, MM_WB_AR3 => AR3_WB, op_MM_WB => OP_WB, op_EX_MM => OP_MM,
			EX_MM_AR2_valid => CL_MM(5), MM_WB_AR3_valid => CL_WB(4), mem_forward_mux => forward_mux_control_MM,
			clk => clk);
	
	--
	-- MM/WB Pipeline Register
	--
	concatenation_CL_MM_WB <= CL_MM(8) & CL_MM(6 downto 0);
	pipe_MM_WB: MM_WB
		port map(
			LS_PC_in => LS_PC_MM, SE_in => SE_MM, CL_in => concatenation_CL_MM_WB, FC_in => FC_MM, Write_in => WR_MM,
			Flags_in => flags_MM_hazard, ALU_out_in => ALU_out_MM, Mem_out_in => mem_out, DO1_in => DO1_MM,
			AR3_in => AR3_MM, PC_inc_in => PCpp_MM, clk => clk, clear => reset, clear_control => clear_control_MM_WB,
			LS_PC_out => LS_PC_WB, SE_out => SE_WB, CL_out => CL_WB, FC_out => FC_WB, Write_out => WR_WB,
			Flags_out => flags_WB, ALU_out_out => ALU_out_WB, Mem_out_out => mem_out_WB, DO1_out => DO1_WB,
			AR3_out => AR3_WB, PC_inc_out => PCpp_WB, BLUT_in => BLUT_MM, BLUT_out => BLUT_WB, op_in => OP_MM, op_out => OP_WB);
	
	clear_control_MM_WB <= hazard_WB_clear;
	--
	-- Write Back Stage
	--
	-- Write back mux
	D3_data <= ALU_out_WB when(CL_WB(3 downto 1) = "000") else LS_PC_WB when(CL_WB(3 downto 1) = "001") else
			   SE_WB when(CL_WB(3 downto 1) = "010") else PCpp_WB when(CL_WB(3 downto 1) = "011") else mem_out_WB;
	
	-- R7 input mux
	R7_in <= DO1_WB when(r7_select = "00") else 
		PCpp_WB when(r7_select = "01") else
		LS_PC_WB;		
	
	R7_Write <= CL_WB(7) and R7_write_temp;
	-- Hazard WB block
	hazard_WB_instance : hazard_conditional_WB
		port map(
			AR3_MM_WB => AR3_WB, MM_WB_LS_PC => LS_PC_WB, MM_WB_PC_inc => PCpp_WB, MM_WB_valid => CL_WB(6 downto 4),
			r7_write => R7_write_temp, r7_select => r7_select, top_WB_mux_control => top_mux_WB_control, clear => hazard_WB_clear,  
			top_WB_mux_data => top_mux_WB_data, is_taken => BLUT_WB(0), opcode => OP_WB); 
		
	-- top mux WB
	PC_in <= top_mux_WB_data when(top_mux_WB_control = '1') else top_mux_MM;
	
	-- flags registers
	OV_instance: my_reg
		generic map(1)
		port map(
			clk => clk, clr => reset, ena => FC_WB(2),
			Din => flags_WB(2 downto 2), Dout => flags_user(2 downto 2));
	
	C_instance: my_reg
		generic map(1)
		port map(
			clk => clk, clr => reset, ena => FC_WB(1),
			Din => flags_WB(1 downto 1), Dout => flags_user(1 downto 1));
			
	Z_instance: my_reg
		generic map(1)
		port map(
			clk => clk, clr => reset, ena => FC_WB(0),
			Din => flags_WB(0 downto 0), Dout => flags_user(0 downto 0));
		
end architecture;
