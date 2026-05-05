----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:10:07 04/01/2026 
-- Design Name: 
-- Module Name:    ALU - Behavioral with support for vectorial MAC with internal accumulation
-- Additional Comments: by AOC2 Team Unizar 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;



entity ALU_Vector_MAC is
    Port ( DA : in  STD_LOGIC_VECTOR (31 downto 0); --input 1
           DB : in  STD_LOGIC_VECTOR (31 downto 0); --input 2
           valid_I_EX : in  STD_LOGIC;
           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
		   ready : out STD_LOGIC; --initially is always '1', but if ALU supports multicycle ops, it will be cero when the output is not ready
           ALUctrl : in  STD_LOGIC_VECTOR (2 downto 0); -- Ops: "000" add, "001" sub, "010" AND, "011" OR, "100" MAC with internal acc, "101" MAC without previous acc.
           Dout : out  STD_LOGIC_VECTOR (31 downto 0)); -- Output
end ALU_Vector_MAC;

architecture Behavioral of ALU_Vector_MAC is

component reg is
    generic (size: natural := 32);  -- por defecto son de 32 bits, pero se puede usar cualquier tama�o
	Port ( Din : in  STD_LOGIC_VECTOR (size -1 downto 0);
           clk : in  STD_LOGIC;
		   reset : in  STD_LOGIC;
           load : in  STD_LOGIC;
           Dout : out  STD_LOGIC_VECTOR (size -1 downto 0));
end component;

signal Dout_internal: STD_LOGIC_VECTOR (31 downto 0);
signal ACC_out : STD_LOGIC_VECTOR (31 downto 0) := X"00000000";
signal ACC_input : Signed (31 downto 0);
signal load_acc, Acc_op, MAC_start : STD_LOGIC;

type state_type is (IDLE, S_PROD, S_ACC); -- estados de la FSM
signal state, next_state : state_type := IDLE;
signal reg_prod0, reg_prod1, reg_prod2, reg_prod3 : Signed(15 downto 0); -- registros intermedios
signal reg_sum_total: Signed(31 downto 0); -- resultado de la suma total extendido a 32 bits
begin
-- IMPORTANT
-- VHDL is strongly typed.
-- In VHDL, types do not just describe the size of a signal, they describe its meaning. 
-- A std_logic_vector means �a bundle of bits,� nothing more. 
-- A signed signal means �a two's complement number.� Because the language is strongly typed, VHDL won�t let you accidentally treat raw bits as a number or mix numeric and non-numeric types without being explicit.
-- In VHDL, you need to use the signed type for C2 (two�s-complement) arithmetic because arithmetic operators like +, -, and comparisons are only numerically defined for the signed and unsigned types in numeric_std, not for std_logic_vector. 
-- A std_logic_vector is just a collection of bits with no inherent numerical meaning, so the compiler has no way to know whether those bits represent a positive or negative number or how to interpret the sign bit.
-- By converting the operands to signed, you explicitly tell VHDL to interpret the MSB as the sign bit and to perform proper two�s-complement arithmetic. 
-- After the calculation, the result is typically converted back to std_logic_vector to store it in a register because registers and ports are often defined as std_logic_vector for generality and compatibility with other logic, interfaces, and synthesis tools. 
-- This separation keeps arithmetic correct and unambiguous while still allowing flexible storage and data movement.
-- NOTE: If you add additional registers you will have to adjust types
-- See the ACC_register for an example: 
-- 1) To use ACC_input as input, first it is transformed to std_logic_vector with: std_logic_vector(ACC_input)
-- 2) To use the output for signed arithmetic operations, first it is transformed to signed: else sum_total_ext + signed(ACC_out);
	
	--It is important not to update the ACC register with invalid instructions
	Acc_op <= '1' when (ALUctrl(2 downto 1) = "10") else '0'; --Acc operations: "100" and "101" 
	load_acc <= '1' when (state = S_ACC) else '0';
	MAC_start <=   '1' when (ALUctrl(0) = '1') else '0'; -- If ALUCtrl = "101" the accumulation register is restarted
	
	ACC_input	 <= 	reg_sum_total when (MAC_start = '1')
						else reg_sum_total + signed(ACC_out);	
	--reset is currentlly unused in the ALU, but it will be needed if it becomes multicycle
	ACC_register: reg 	generic map (size => 32)
						port map (	Din => std_logic_vector(ACC_input), clk => clk, reset => reset, load => load_acc, Dout => ACC_out);
	
	
	Dout_internal <= 	DA + DB when (ALUctrl="000") 
				else DA - DB when (ALUctrl="001") 
				else DA AND DB when (ALUctrl="010")
				else DA OR DB when (ALUctrl="011")
				else std_logic_vector(ACC_input) when (ALUctrl(2 downto 1) = "10")
				else "00000000000000000000000000000000";
	Dout <= Dout_internal;
	-- to be updated:
	-- Proceso de cambio de estado de la FSM
	process(clk)
	begin
		if rising_edge(clk) then
			if reset = '1' then
				state <= IDLE;
			else
				state <= next_state;
			end if;
		end if;
	end process;
	
	-- Proceso de transiciones de la FSM
	process(state, Acc_op, valid_I_EX)
	begin
		next_state <= state;
		ready <= '1'; -- por defecto esta libre

		case state is
			when IDLE =>
				if Acc_op = '1' and valid_I_EX = '1' then
					next_state <= S_PROD;
					ready <= '0'; -- empieza y se bloquea el MIPS
				end if;
			when S_PROD =>
				next_state <= S_ACC;
				ready <= '0';
			when S_ACC =>
				next_state <= IDLE;
				ready <= '1'; -- operación terminada, dato listo
			when others =>
				next_state <= IDLE;
		end case;
	end process;

	-- Ciclo 1: calculo de productos parciales
	process(clk)
	begin
		if rising_edge(clk) then
			if state = IDLE and Acc_op = '1' then
				reg_prod0 <= signed(DA(7 downto 0)) * signed(DB(7 downto 0));
				reg_prod1 <= signed(DA(15 downto 8)) * signed(DB(15 downto 8));
				reg_prod2 <= signed(DA(23 downto 16)) * signed(DB(23 downto 16));
				reg_prod3 <= signed(DA(31 downto 24)) * signed(DB(31 downto 24));
			end if;
		end if;
	end process;

	-- Ciclo 2: suma de productos parciales
	process(clk)
	begin
		if rising_edge(clk) then
			if state = S_PROD then
				reg_sum_total <= resize((reg_prod0 + reg_prod1) + (reg_prod2 + reg_prod3), 32); -- asegurar que el resultado se ajusta a 32 bits
			end if;
		end if;
	end process;

end Behavioral;