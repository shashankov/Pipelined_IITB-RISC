library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package pipeline_register is
	component IF_ID is
		port(
			PC_in: in std_logic_vector(15 downto 0);
			Inst_in: in std_logic_vector(15 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control : in std_logic;
			-- To clear control signals of IFID ADI Immediate(0) should be used as it doesn't change state of processor. Therefore clear control
			-- only sets the last bit of opcode  
			disable : in std_logic;
			-------------------------------------------
			PC_out: out std_logic_vector(15 downto 0);
			Inst_out: out std_logic_vector(15 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);
			unflush_out : out std_logic_vector(0 downto 0);
			-------------------------------------------
			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0));
			-------------------------------------------

	end component;

	component ID_RR is  
		generic(control_length: integer := 12);
		port( 
			PC_in: in std_logic_vector(15 downto 0);
			SE_PC_in: in std_logic_vector(15 downto 0);
			SE_in: in std_logic_vector(15 downto 0);
			CL_in : in std_logic_vector(control_length-1 downto 0);
			--Control Bits are 
			-- LS_PC(0), BEQ(1) , LM (2) , LW(3) , SE_DO2(4) , WB_mux(5,6,7), valid(8,9,10), unflush(11)  (SM is removed since decoder directly provides)
			ALU_C_in: in std_logic_vector(1 downto 0); --MSB for add ( when 1)) , LSB for comparator
			FC_in: in std_logic_vector(2 downto 0);    --OV,carry,zero
			Cond_in: in std_logic_vector(1 downto 0); 
			Write_in: in std_logic_vector(1 downto 0); --MSB for register file, LSB for memory
			--r7_W_in: in std_logic_vector(0 downto 0);
			AR1_in: in std_logic_vector(2 downto 0);
			AR2_in: in std_logic_vector(2 downto 0);
			AR3_in: in std_logic_vector(2 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			LM_in : std_logic_vector(7 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control : in std_logic;  -- Used for flushing, clears the control bits only
			disable : in std_logic;
			--------------------------------------------
			PC_out: out std_logic_vector(15 downto 0);
			SE_PC_out: out std_logic_vector(15 downto 0);
			SE_out: out std_logic_vector(15 downto 0);
			CL_out : out std_logic_vector(control_length-1 downto 0);
			ALU_C_out: out std_logic_vector(1 downto 0);
			FC_out: out std_logic_vector(2 downto 0);
			Cond_out: out std_logic_vector(1 downto 0);
			Write_out: out std_logic_vector(1 downto 0);
			--r7_W_out: out std_logic_vector(0 downto 0);
			AR1_out: out std_logic_vector(2 downto 0);
			AR2_out: out std_logic_vector(2 downto 0);
			AR3_out: out std_logic_vector(2 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);
			LM_out : out std_logic_vector(7 downto 0);
			-------------------------------------------
			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0);
			-------------------------------------------
			op_in: in std_logic_vector(3 downto 0);
			op_out: out std_logic_vector(3 downto 0));
	end component;

	component RR_EX is  
		generic(control_length: integer :=13);
		port( 
			--PC_in: in std_logic_vector(15 downto 0);
			LS_PC_in: in std_logic_vector(15 downto 0);
			SE_in: in std_logic_vector(15 downto 0);
			CL_in : in std_logic_vector(control_length-1 downto 0);
			--Control Bits are - 
			--BEQ(0) , LW(1) , SE_DO2(2) , WB_mux(3,4,5), valid(6,7,8), LM_SM_control(9,10,11), unflush(12) -> Generated from the LM SM block
			ALU_C_in: in std_logic_vector(1 downto 0);
			FC_in: in std_logic_vector(2 downto 0);  -- OV,carry,zero
			Cond_in: in std_logic_vector(1 downto 0);
			Write_in: in std_logic_vector(1 downto 0);
			--r7_W_in: in std_logic_vector(0 downto 0);
			DO1_in: in std_logic_vector(15 downto 0);
			DO2_in: in std_logic_vector(15 downto 0);
			AR2_in: in std_logic_vector(2 downto 0);
			AR3_in: in std_logic_vector(2 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control : in std_logic;
			disable : in std_logic;
			LM_SM_en : in std_logic;
			--------------------------------------------
			--PC_out: out std_logic_vector(15 downto 0);
			LS_PC_out: out std_logic_vector(15 downto 0);
			SE_out: out std_logic_vector(15 downto 0);
			CL_out : out std_logic_vector(control_length-1 downto 0);
			ALU_C_out: out std_logic_vector(1 downto 0);
			FC_out: out std_logic_vector(2 downto 0);
			Cond_out: out std_logic_vector(1 downto 0);
			Write_out: out std_logic_vector(1 downto 0);
			--r7_W_out: out std_logic_vector(0 downto 0);
			DO1_out: out std_logic_vector(15 downto 0);
			DO2_out: out std_logic_vector(15 downto 0);
			AR2_out: out std_logic_vector(2 downto 0);
			AR3_out: out std_logic_vector(2 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);
			-------------------------------------------
			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0);
			-------------------------------------------
			op_in: in std_logic_vector(3 downto 0);
			op_out: out std_logic_vector(3 downto 0));
			
	end component;

	component EX_MM is 
		generic(control_length: integer :=9);
		port( 
			--PC_in: in std_logic_vector(15 downto 0);
			LS_PC_in: in std_logic_vector(15 downto 0);
			SE_in: in std_logic_vector(15 downto 0);
			CL_in : in std_logic_vector(control_length-1 downto 0);
			--Control Bits are - 
			--BEQ(0) , WB_mux(1,2,3), valid(4,5,6), LM_SM_control(7), unflush(8) 
			FC_in: in std_logic_vector(2 downto 0);
			Write_in: in std_logic_vector(1 downto 0);
			--r7_W_in: in std_logic_vector(0 downto 0);
			Flags_in: in std_logic_vector(2 downto 0);  -- 3 flags 
			ALU_out_in: in std_logic_vector(15 downto 0);
			DO1_in: in std_logic_vector(15 downto 0);
			DO2_in: in std_logic_vector(15 downto 0);
			AR2_in: in std_logic_vector(2 downto 0);
			AR3_in: in std_logic_vector(2 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control, clear_conditional : in  std_logic;
			-- Disable not required here, only required in the registers before
			--------------------------------------------
			LS_PC_out: out std_logic_vector(15 downto 0);
			SE_out: out std_logic_vector(15 downto 0);
			CL_out : out std_logic_vector(control_length-1 downto 0);
			FC_out: out std_logic_vector(2 downto 0);
			Write_out: out std_logic_vector(1 downto 0);
			 -- r7_W_out: out std_logic_vector(0 downto 0);
			Flags_out: out std_logic_vector(2 downto 0);
			ALU_out_out: out std_logic_vector(15 downto 0);
			DO1_out: out std_logic_vector(15 downto 0);
			DO2_out: out std_logic_vector(15 downto 0);
			AR2_out: out std_logic_vector(2 downto 0);
			AR3_out: out std_logic_vector(2 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);
			-------------------------------------------
			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0);
			-------------------------------------------
			op_in: in std_logic_vector(3 downto 0);
			op_out: out std_logic_vector(3 downto 0));
			
	end component;

	component MM_WB is 
		generic(control_length: integer :=8);
		port( 
			--PC_in: in std_logic_vector(15 downto 0);
			LS_PC_in: in std_logic_vector(15 downto 0);
			SE_in: in std_logic_vector(15 downto 0);
			CL_in : in std_logic_vector(control_length-1 downto 0);
			--Control bits are -
			--BEQ(0) , WB_mux(1,2,3), valid(4,5,6), unflush(7) 
			FC_in: in std_logic_vector(2 downto 0);
			Write_in: in std_logic_vector(1 downto 0);  
			--r7_W_in: in std_logic_vector(0 downto 0);
			Flags_in: in std_logic_vector(2 downto 0);
			ALU_out_in: in std_logic_vector(15 downto 0);
			Mem_out_in: in std_logic_vector(15 downto 0);
			DO1_in: in std_logic_vector(15 downto 0);
			AR3_in: in std_logic_vector(2 downto 0);
			PC_inc_in:in std_logic_vector(15 downto 0);
			clk: in std_logic;
			clear: in std_logic;
			clear_control : in std_logic;
			--------------------------------------------
			-- PC_out: out std_logic_vector(15 downto 0);
			LS_PC_out: out std_logic_vector(15 downto 0);
			SE_out: out std_logic_vector(15 downto 0);
			CL_out : out std_logic_vector(control_length-1 downto 0);
			FC_out: out std_logic_vector(2 downto 0);
			Write_out: out std_logic_vector(1 downto 0);
			--r7_W_out: out std_logic_vector(0 downto 0);
			Flags_out: out std_logic_vector(2 downto 0);
			ALU_out_out: out std_logic_vector(15 downto 0);
			Mem_out_out: out std_logic_vector(15 downto 0);
			DO1_out: out std_logic_vector(15 downto 0);
			AR3_out: out std_logic_vector(2 downto 0);
			PC_inc_out:out std_logic_vector(15 downto 0);
			-------------------------------------------
			BLUT_in: in std_logic_vector(3 downto 0);
			BLUT_out: out std_logic_vector(3 downto 0);
			-------------------------------------------
			op_in: in std_logic_vector(3 downto 0);
			op_out: out std_logic_vector(3 downto 0));
			
	end component;

end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;

entity IF_ID is
	port(     PC_in: in std_logic_vector(15 downto 0);
		Inst_in: in std_logic_vector(15 downto 0);
		PC_inc_in:in std_logic_vector(15 downto 0);
		clk: in std_logic;
		clear: in std_logic;
		clear_control : in std_logic;
		-- To clear control signals of IFID ADI Immediate(0) should be used as it doesn't change state of processor. Therefore clear control
		-- only sets the last bit of opcode  
		disable : in std_logic;
		-------------------------------------------
		PC_out: out std_logic_vector(15 downto 0);
		Inst_out: out std_logic_vector(15 downto 0);
		PC_inc_out:out std_logic_vector(15 downto 0);
		unflush_out : out std_logic_vector(0 downto 0);
		-------------------------------------------
  		BLUT_in: in std_logic_vector(3 downto 0);
		BLUT_out: out std_logic_vector(3 downto 0));
		-------------------------------------------

end entity;

architecture one of IF_ID is 
signal enable_temp, clear_temp : std_logic := '1';
signal Inst_temp     : std_logic_vector(15 downto 0);
begin
	enable_temp <= not disable;
	PC_REG: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => PC_in, Dout => PC_out, clr => clear);
		
	Inst_temp <= "0001000000000000" when (clear_control = '1') else Inst_in; -- ADI instruction with adding 0 To R0 register        	 
	Inst_REG: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => Inst_temp, Dout => Inst_out, clr => clear);
	        	 
	PC_inc_REG: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => PC_inc_in, Dout => PC_inc_out, clr => clear);
				 
	BLUT_REG: my_reg
		generic map(4)
		port map(
			clk => clk, ena => enable_temp, clr => clear, 
			Din => BLUT_in, Dout => BLUT_out);
	
	clear_temp <= clear or clear_control;
	UNFLUSH_REG: my_reg
		generic map(1)
		port map(
			clk => clk, ena => enable_temp, clr => clear_temp, 
			Din => "1", Dout => unflush_out);

end architecture; 

--########################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;
--enable assumed to be '1'
entity ID_RR is  
	generic(control_length: integer :=12);
	port( PC_in: in std_logic_vector(15 downto 0);
		SE_PC_in: in std_logic_vector(15 downto 0);
		SE_in: in std_logic_vector(15 downto 0);
		CL_in : in std_logic_vector(control_length-1 downto 0);
		--Control Bits are 
		-- LS_PC(1), BEQ(1) , LM (1) , LW(1) , SE_DO2(1) , WB_mux(3), valid(3), unflush  (SM is removed since decoder directly provides)
		ALU_C_in: in std_logic_vector(1 downto 0); --MSB for add ( when 1)) , LSB for comparator
		FC_in: in std_logic_vector(2 downto 0);    --OV,carry,zero
		Cond_in: in std_logic_vector(1 downto 0); 
		Write_in: in std_logic_vector(1 downto 0); --MSB for register file, LSB for memory
		--r7_W_in: in std_logic_vector(0 downto 0);
		AR1_in: in std_logic_vector(2 downto 0);
		AR2_in: in std_logic_vector(2 downto 0);
		AR3_in: in std_logic_vector(2 downto 0);
		PC_inc_in:in std_logic_vector(15 downto 0);
		LM_in : std_logic_vector(7 downto 0);
		clk: in std_logic;
		clear: in std_logic;
		clear_control : in std_logic;  -- Used for flushing, clears the control bits only
		disable : in std_logic;
		--------------------------------------------
		PC_out: out std_logic_vector(15 downto 0);
		SE_PC_out: out std_logic_vector(15 downto 0);
		SE_out: out std_logic_vector(15 downto 0);
		CL_out : out std_logic_vector(control_length-1 downto 0);
		ALU_C_out: out std_logic_vector(1 downto 0);
		FC_out: out std_logic_vector(2 downto 0);
		Cond_out: out std_logic_vector(1 downto 0);
		Write_out: out std_logic_vector(1 downto 0);
		--r7_W_out: out std_logic_vector(0 downto 0);
		AR1_out: out std_logic_vector(2 downto 0);
		AR2_out: out std_logic_vector(2 downto 0);
		AR3_out: out std_logic_vector(2 downto 0);
		PC_inc_out:out std_logic_vector(15 downto 0);
		LM_out : out std_logic_vector(7 downto 0);
		-------------------------------------------
  		BLUT_in: in std_logic_vector(3 downto 0);
		BLUT_out: out std_logic_vector(3 downto 0);
		-------------------------------------------
		op_in: in std_logic_vector(3 downto 0);
		op_out: out std_logic_vector(3 downto 0));
end entity;

architecture two of ID_RR is 
signal enable_temp : std_logic := '1';
signal clear_temp  : std_logic := '0';
begin
	enable_temp <= not disable;
	PC_REG: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => PC_in, Dout => PC_out, clr => clear);
	SE_PC: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => SE_PC_in, Dout => SE_PC_out, clr => clear);
	SE: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => SE_in, Dout => SE_out, clr => clear);
	
	clear_temp <= (clear or clear_control);
	CL: my_reg
		generic map(control_length)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => CL_in, Dout => CL_out, clr => clear_temp);
	
	ALU_C: my_reg
		generic map(2)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => ALU_C_in, Dout => ALU_C_out, clr => clear);
	FC: my_reg
		generic map(3)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => FC_in, Dout => FC_out, clr => clear_temp);
	Cond: my_reg
		generic map(2)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => Cond_in, Dout => Cond_out, clr => clear);  
	Write: my_reg
		generic map(2)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => Write_in, Dout => Write_out, clr => clear_temp); 
	    
	AR1: my_reg
		generic map(3)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => AR1_in, Dout => AR1_out, clr => clear); 
	
	AR2: my_reg
		generic map(3)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => AR2_in, Dout => AR2_out, clr => clear);  
	        	 
	AR3: my_reg
		generic map(3)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => AR3_in, Dout => AR3_out, clr => clear);  
	        	     	 
	PC_inc_REG: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => PC_inc_in, Dout => PC_inc_out, clr => clear);

	LM_REG: my_reg
		generic map(8)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => LM_in, Dout => LM_out, clr => clear);
				 
	BLUT_REG: my_reg
		generic map(4)
		port map(
			clk => clk, ena => enable_temp, clr => clear_temp, 
			Din => BLUT_in, Dout => BLUT_out);
	
	OP_REG: my_reg
		generic map(4)
		port map(
			clk => clk, ena => enable_temp, clr => clear, 
			Din => op_in, Dout => op_out);
			
end architecture; 
--##############################################################################################################
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;
--enable assumed to be '1'

entity RR_EX is  
	generic(control_length: integer :=13);
	port( --PC_in: in std_logic_vector(15 downto 0);
		LS_PC_in: in std_logic_vector(15 downto 0);
		SE_in: in std_logic_vector(15 downto 0);
		CL_in : in std_logic_vector(control_length-1 downto 0);
		--Control Bits are - 
		--BEQ(1) , LW(1) , SE_DO2(1) , WB_mux(3), valid(3), LM_SM_control(3), unflush -> Generated from the LM SM block
		ALU_C_in: in std_logic_vector(1 downto 0);
		FC_in: in std_logic_vector(2 downto 0);  -- OV,carry,zero
		Cond_in: in std_logic_vector(1 downto 0);
		Write_in: in std_logic_vector(1 downto 0);
		--r7_W_in: in std_logic_vector(0 downto 0);
		DO1_in: in std_logic_vector(15 downto 0);
		DO2_in: in std_logic_vector(15 downto 0);
		AR2_in: in std_logic_vector(2 downto 0);
		AR3_in: in std_logic_vector(2 downto 0);
		PC_inc_in:in std_logic_vector(15 downto 0);
		clk: in std_logic;
		clear: in std_logic;
		clear_control : in std_logic;
		disable : in std_logic;
		LM_SM_en : in std_logic;
		--------------------------------------------
		--PC_out: out std_logic_vector(15 downto 0);
		LS_PC_out: out std_logic_vector(15 downto 0);
		SE_out: out std_logic_vector(15 downto 0);
		CL_out : out std_logic_vector(control_length-1 downto 0);
		ALU_C_out: out std_logic_vector(1 downto 0);
		FC_out: out std_logic_vector(2 downto 0);
		Cond_out: out std_logic_vector(1 downto 0);
		Write_out: out std_logic_vector(1 downto 0);
		--r7_W_out: out std_logic_vector(0 downto 0);
		DO1_out: out std_logic_vector(15 downto 0);
		DO2_out: out std_logic_vector(15 downto 0);
		AR2_out: out std_logic_vector(2 downto 0);
		AR3_out: out std_logic_vector(2 downto 0);
		PC_inc_out:out std_logic_vector(15 downto 0);
		-------------------------------------------
  		BLUT_in: in std_logic_vector(3 downto 0);
		BLUT_out: out std_logic_vector(3 downto 0);
		-------------------------------------------
		op_in: in std_logic_vector(3 downto 0);
		op_out: out std_logic_vector(3 downto 0));
		
end entity;

architecture three of RR_EX is 
signal enable_temp :std_logic := '1';
signal clear_temp  :std_logic := '0';
signal LM_SM_en_temp :std_logic := '1';
begin
	enable_temp <= not disable;
	LM_SM_en_temp <= (enable_temp or LM_SM_en);
	LS_PC: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => LS_PC_in, Dout => LS_PC_out, clr => clear);
	SE: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => SE_in, Dout => SE_out, clr => clear);
	
	clear_temp <= clear or clear_control;
	CL: my_reg
		generic map(control_length)
		port map(clk => clk, ena => LM_SM_en_temp, 
	        	 Din => CL_in, Dout => CL_out, clr => clear_temp);
	
	ALU_C: my_reg
		generic map(2)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => ALU_C_in, Dout => ALU_C_out, clr => clear);
	FC: my_reg
		generic map(3)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => FC_in, Dout => FC_out, clr => clear_temp);
	Cond: my_reg
		generic map(2)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => Cond_in, Dout => Cond_out, clr => clear);  
	Write: my_reg
		generic map(2)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => Write_in, Dout => Write_out, clr => clear_temp); 
	
	DO1: my_reg
		generic map(16)
		port map(clk => clk, ena => LM_SM_en_temp, 
	        	 Din => DO1_in, Dout => DO1_out, clr => clear); 
	
	DO2: my_reg
		generic map(16)
		port map(clk => clk, ena => LM_SM_en_temp, 
	        	 Din => DO2_in, Dout => DO2_out, clr => clear); 
    
	AR2: my_reg
		generic map(3)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => AR2_in, Dout => AR2_out, clr => clear);  	
	
	AR3: my_reg
		generic map(3)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => AR3_in, Dout => AR3_out, clr => clear);      
	        	 	 
	PC_inc_REG: my_reg
		generic map(16)
		port map(clk => clk, ena => enable_temp, 
	        	 Din => PC_inc_in, Dout => PC_inc_out, clr => clear);
				 
	BLUT_REG: my_reg
		generic map(4)
		port map(
			clk => clk, ena => enable_temp, clr => clear_temp, 
			Din => BLUT_in, Dout => BLUT_out);
			
	OP_REG: my_reg
		generic map(4)
		port map(
			clk => clk, ena => enable_temp, clr => clear, 
			Din => op_in, Dout => op_out);

end architecture;

--#########################################################################################################
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;
--enable assumed to be '1'

entity EX_MM is 
	generic(control_length: integer :=9);
	port( --PC_in: in std_logic_vector(15 downto 0);
		LS_PC_in: in std_logic_vector(15 downto 0);
		SE_in: in std_logic_vector(15 downto 0);
		CL_in : in std_logic_vector(control_length-1 downto 0);
		--Control Bits are - 
		--BEQ(1) , WB_mux(3), valid(3), LM_SM_control(1), unflush 
		FC_in: in std_logic_vector(2 downto 0);
		Write_in: in std_logic_vector(1 downto 0);
		--r7_W_in: in std_logic_vector(0 downto 0);
		Flags_in: in std_logic_vector(2 downto 0);  -- 3 flags 
		ALU_out_in: in std_logic_vector(15 downto 0);
		DO1_in: in std_logic_vector(15 downto 0);
		DO2_in: in std_logic_vector(15 downto 0);
		AR2_in: in std_logic_vector(2 downto 0);
		AR3_in: in std_logic_vector(2 downto 0);
		PC_inc_in:in std_logic_vector(15 downto 0);
		clk: in std_logic;
		clear: in std_logic;
		clear_control, clear_conditional : in  std_logic;
		-- Disable not required here, only required in the registers before
		--------------------------------------------
		LS_PC_out: out std_logic_vector(15 downto 0);
		SE_out: out std_logic_vector(15 downto 0);
		CL_out : out std_logic_vector(control_length-1 downto 0);
		FC_out: out std_logic_vector(2 downto 0);
		Write_out: out std_logic_vector(1 downto 0);
		 -- r7_W_out: out std_logic_vector(0 downto 0);
		Flags_out: out std_logic_vector(2 downto 0);
		ALU_out_out: out std_logic_vector(15 downto 0);
		DO1_out: out std_logic_vector(15 downto 0);
		DO2_out: out std_logic_vector(15 downto 0);
		AR2_out: out std_logic_vector(2 downto 0);
		AR3_out: out std_logic_vector(2 downto 0);
		PC_inc_out:out std_logic_vector(15 downto 0);
		-------------------------------------------
  		BLUT_in: in std_logic_vector(3 downto 0);
		BLUT_out: out std_logic_vector(3 downto 0);
		-------------------------------------------
		op_in: in std_logic_vector(3 downto 0);
		op_out: out std_logic_vector(3 downto 0));
		
end entity;

architecture four of EX_MM is 
signal clear_temp, clear_temp_unflush :std_logic := '0';
begin

	LS_PC: my_reg
		generic map(16)
		port map(clk => clk, ena => '1', 
	        	 Din => LS_PC_in, Dout => LS_PC_out, clr => clear);
	SE: my_reg
		generic map(16)
		port map(clk => clk, ena => '1', 
	        	 Din => SE_in, Dout => SE_out, clr => clear);
	
	clear_temp <= clear or clear_control or clear_conditional;
	clear_temp_unflush <= clear or clear_control;
	
	CL: my_reg
		generic map(control_length-1)
		port map(clk => clk, ena => '1', 
	        	 Din => CL_in(control_length-2 downto 0), Dout => CL_out(control_length-2 downto 0), clr => clear_temp);
	        	 
	unflush: my_reg
		generic map(1)
		port map(clk => clk , ena => '1',
				 Din => CL_in(control_length -1 downto control_length -1), Dout => CL_out(control_length -1 downto control_length -1),
				 clr => clear_temp_unflush);
	
	FC: my_reg
		generic map(3)
		port map(clk => clk, ena => '1', 
	        	 Din => FC_in, Dout => FC_out, clr => clear_temp);
 
	Write: my_reg
		generic map(2)
		port map(clk => clk, ena => '1', 
	        	 Din => Write_in, Dout => Write_out, clr => clear_temp); 
	    
	Flags: my_reg
		generic map(3)
		port map(clk => clk, ena => '1', 
	        	 Din => Flags_in, Dout => Flags_out, clr => clear);
	ALU_out: my_reg
		generic map(16)
		port map(clk => clk, ena => '1', 
	        	 Din => ALU_out_in, Dout => ALU_out_out, clr => clear);
	 
	DO1: my_reg
		generic map(16)
		port map(clk => clk, ena => '1', 
	        	 Din => DO1_in, Dout => DO1_out, clr => clear); 
	
	DO2: my_reg
		generic map(16)
		port map(clk => clk, ena => '1', 
		     	 Din => DO2_in, Dout => DO2_out, clr => clear); 
    
	AR2: my_reg
		generic map(3)
		port map(clk => clk, ena => '1', 
	        	 Din => AR2_in, Dout => AR2_out, clr => clear);   
				 
	AR3: my_reg
		generic map(3)
		port map(clk => clk, ena => '1', 
	        	 Din => AR3_in, Dout => AR3_out, clr => clear);      
	        	 	 
	PC_inc_REG: my_reg
		generic map(16)
		port map(clk => clk, ena => '1', 
	        	 Din => PC_inc_in, Dout => PC_inc_out, clr => clear);
				 
	BLUT_REG: my_reg
		generic map(4)
		port map(
			clk => clk, ena => '1', clr => clear_temp, 
			Din => BLUT_in, Dout => BLUT_out);
	
	OP_REG: my_reg
		generic map(4)
		port map(
			clk => clk, ena => '1', clr => clear, 
			Din => op_in, Dout => op_out);

end architecture;

--#############################################################################################################

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.basic.all;
--enable assumed to be '1'

entity MM_WB is 
generic(control_length: integer :=8);
	port( --PC_in: in std_logic_vector(15 downto 0);
		LS_PC_in: in std_logic_vector(15 downto 0);
		SE_in: in std_logic_vector(15 downto 0);
		CL_in : in std_logic_vector(control_length-1 downto 0);
		--Control bits are -
		--BEQ(1) , WB_mux(3), valid(3), unflush 
		FC_in: in std_logic_vector(2 downto 0);
		Write_in: in std_logic_vector(1 downto 0);  
		--r7_W_in: in std_logic_vector(0 downto 0);
		Flags_in: in std_logic_vector(2 downto 0);
		ALU_out_in: in std_logic_vector(15 downto 0);
		Mem_out_in: in std_logic_vector(15 downto 0);
		DO1_in: in std_logic_vector(15 downto 0);
		AR3_in: in std_logic_vector(2 downto 0);
		PC_inc_in:in std_logic_vector(15 downto 0);
		clk: in std_logic;
		clear: in std_logic;
		clear_control : in std_logic;
		--------------------------------------------
		 -- PC_out: out std_logic_vector(15 downto 0);
		LS_PC_out: out std_logic_vector(15 downto 0);
		SE_out: out std_logic_vector(15 downto 0);
		CL_out : out std_logic_vector(control_length-1 downto 0);
		FC_out: out std_logic_vector(2 downto 0);
		Write_out: out std_logic_vector(1 downto 0);
		--r7_W_out: out std_logic_vector(0 downto 0);
		Flags_out: out std_logic_vector(2 downto 0);
		ALU_out_out: out std_logic_vector(15 downto 0);
		Mem_out_out: out std_logic_vector(15 downto 0);
		DO1_out: out std_logic_vector(15 downto 0);
		AR3_out: out std_logic_vector(2 downto 0);
		PC_inc_out:out std_logic_vector(15 downto 0);
		-------------------------------------------
  		BLUT_in: in std_logic_vector(3 downto 0);
		BLUT_out: out std_logic_vector(3 downto 0);
		-------------------------------------------
		op_in: in std_logic_vector(3 downto 0);
		op_out: out std_logic_vector(3 downto 0));
		
end entity;

architecture five of MM_WB is 
signal clear_temp :std_logic := '0';
begin

	LS_PC: my_reg
		generic map(16)
		port map(clk => clk, ena =>  '1', 
	        	 Din => LS_PC_in, Dout => LS_PC_out, clr => clear);
	SE: my_reg
		generic map(16)
		port map(clk => clk, ena =>  '1', 
	        	 Din => SE_in, Dout => SE_out, clr => clear);
	
	clear_temp <= clear or clear_control;
	CL: my_reg
		generic map(control_length)
		port map(clk => clk, ena => '1', 
	        	 Din => CL_in, Dout => CL_out, clr => clear_temp);
	
	FC: my_reg
		generic map(3)
		port map(clk => clk, ena =>  '1', 
	        	 Din => FC_in, Dout => FC_out, clr => clear_temp);
  
	Write: my_reg
		generic map(2)
		port map(clk => clk, ena =>  '1', 
	        	 Din => Write_in, Dout => Write_out, clr => clear_temp); 
	    
	Flags: my_reg
		generic map(3)
		port map(clk => clk, ena => '1', 
	        	 Din => Flags_in, Dout => Flags_out, clr => clear);
	ALU_out: my_reg
		generic map(16)
		port map(clk => clk, ena => '1', 
	        	 Din => ALU_out_in, Dout => ALU_out_out, clr => clear);
	     
	Mem_out: my_reg
		generic map(16)
		port map(clk => clk, ena =>  '1', 
	        	 Din => Mem_out_in, Dout => Mem_out_out, clr => clear);
	 	
	DO1: my_reg
		generic map(16)
		port map(clk => clk, ena =>  '1', 
	        	 Din => DO1_in, Dout => DO1_out, clr => clear); 
       	 	        	 
	AR3: my_reg
		generic map(3)
		port map(clk => clk, ena => '1', 
	        	 Din => AR3_in, Dout => AR3_out, clr => clear);      
	        	 	 
	PC_inc_REG: my_reg
		generic map(16)
		port map(clk => clk, ena =>  '1', 
	        	 Din => PC_inc_in, Dout => PC_inc_out, clr => clear);
				 
	BLUT_REG: my_reg
		generic map(4)
		port map(
			clk => clk, ena => '1', clr => clear_control, 
			Din => BLUT_in, Dout => BLUT_out);
	
	OP_REG: my_reg
		generic map(4)
		port map(
			clk => clk, ena => '1', clr => clear, 
			Din => op_in, Dout => op_out);

end architecture;

-- --##############################################################################
-- library ieee;
-- use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;

-- library work;
-- use work.basic.all;

-- entity WBT is
	-- generic(control_length: integer := 6);
	-- port( AR3_in: in std_logic_vector(2 downto 0);
		-- WB_mux_data_in: in std_logic_vector(15 downto 0);
		-- CL_in : in std_logic_vector(control_length -1 downto 0);
		-- -- Control bits are 
		-- -- WB_mux(3), valid(3)
		-- clk: in std_logic;
		-- clear: in std_logic;
		-- -- clear control not required in this case
		-- -------------------------------------------
		-- AR3_out: out std_logic_vector(15 downto 0);
		-- WB_mux_data_out: out std_logic_vector(15 downto 0);
		-- CL_out : out std_logic_vector(control_length -1 downto 0));
-- end entity;

-- architecture six of WBT is 
-- begin

	-- WB_REG: my_reg
		-- generic map(16)
		-- port map(clk => clk, ena => '1', 
	        	 -- Din => WB_mux_data_in, Dout => WB_mux_data_out, clr => clear);
	        	 
	-- AR3: my_reg
		-- generic map(3)
		-- port map(clk => clk, ena => '1', 
	        	 -- Din => AR3_in, Dout => AR3_out, clr => clear);
	        	 
	-- CL_REG: my_reg
		-- generic map(6)
		-- port map(clk => clk, ena => '1', 
	        	 -- Din => CL_in, Dout => CL_out, clr => clear);

-- end architecture; 

