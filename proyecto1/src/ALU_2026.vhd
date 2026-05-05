----------------------------------------------------------------------------------
-- Author: Alberto Serrano Fernández
--	Date: 06/04/2026
-- NIP: 817959
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:10:07 04/01/2026 
-- Design Name: 
-- Module Name:    ALU - Behavioral with support for vectorial MAC with internal accumulation
-- Additional Comments: by AOC2 Team Unizar 

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ALU_Vector_MAC is
    Port (
        DA         : in  STD_LOGIC_VECTOR (31 downto 0);
        DB         : in  STD_LOGIC_VECTOR (31 downto 0);
        valid_I_EX : in  STD_LOGIC;
        clk        : in  STD_LOGIC;
        reset      : in  STD_LOGIC;
        ready      : out STD_LOGIC;
        ALUctrl    : in  STD_LOGIC_VECTOR (2 downto 0);
        Dout       : out STD_LOGIC_VECTOR (31 downto 0)
    );
end ALU_Vector_MAC;

architecture Behavioral of ALU_Vector_MAC is

    type state_type is (S_IDLE, S_MULT, S_ADD);
    signal current_state, next_state : state_type := S_IDLE;

    signal prod0, prod1, prod2, prod3 : signed(15 downto 0) := (others => '0');
    signal prod0_reg, prod1_reg, prod2_reg, prod3_reg : signed(15 downto 0) := (others => '0');

    signal sum1, sum2    : signed(16 downto 0) := (others => '0');
    signal sum_total     : signed(17 downto 0) := (others => '0');
    signal sum_total_reg : signed(17 downto 0) := (others => '0');

    signal acc_reg   : signed(31 downto 0) := (others => '0');
    signal acc_input : signed(31 downto 0);

    signal Acc_op    : std_logic;
    signal MAC_start : std_logic;

begin

    -- Operación MAC
    Acc_op    <= '1' when (ALUctrl(2 downto 1) = "10") else '0';
    MAC_start <= ALUctrl(0);

    -- Próximo estado (combinacional)
    next_state <= S_MULT when (current_state = S_IDLE and Acc_op = '1' and valid_I_EX = '1') else
                  S_ADD  when (current_state = S_MULT) else
                  S_IDLE when (current_state = S_ADD)  else
                  S_IDLE;

    -- Registro de estado
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                current_state <= S_IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;

    -- Multiplicaciones por bytes
    prod0 <= signed(DA( 7 downto  0)) * signed(DB( 7 downto  0));
    prod1 <= signed(DA(15 downto  8)) * signed(DB(15 downto  8));
    prod2 <= signed(DA(23 downto 16)) * signed(DB(23 downto 16));
    prod3 <= signed(DA(31 downto 24)) * signed(DB(31 downto 24));

    -- Sumas parciales
    sum1      <= resize(prod0_reg, 17) + resize(prod1_reg, 17);
    sum2      <= resize(prod2_reg, 17) + resize(prod3_reg, 17);
    sum_total <= resize(sum1, 18) + resize(sum2, 18);

    -- Extensión a 32 bits para el acumulador
    acc_input <= resize(sum_total_reg, 32) when MAC_start = '1' else
                 resize(sum_total_reg, 32) + acc_reg;

    -- Registro de datos
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                prod0_reg     <= (others => '0');
                prod1_reg     <= (others => '0');
                prod2_reg     <= (others => '0');
                prod3_reg     <= (others => '0');
                sum_total_reg <= (others => '0');
                acc_reg       <= (others => '0');
            else
                case current_state is
                    when S_IDLE =>
                        if (Acc_op = '1' and valid_I_EX = '1') then
                            prod0_reg <= prod0;
                            prod1_reg <= prod1;
                            prod2_reg <= prod2;
                            prod3_reg <= prod3;
                        end if;

                    when S_MULT =>
                        sum_total_reg <= sum_total;

                    when S_ADD =>
                        acc_reg <= acc_input;
                end case;
            end if;
        end if;
    end process;

    -- Salida de la ALU
    Dout <= std_logic_vector(signed(DA) + signed(DB)) when (ALUctrl = "000") else
            std_logic_vector(signed(DA) - signed(DB)) when (ALUctrl = "001") else
            (DA and DB)                                 when (ALUctrl = "010") else
            (DA or DB)                                  when (ALUctrl = "011") else
            std_logic_vector(acc_input)                 when (ALUctrl(2 downto 1) = "10") else
            (others => '0');

    -- Señal ready
    ready <= '0' when (current_state = S_MULT or
                       (current_state = S_IDLE and Acc_op = '1' and valid_I_EX = '1'))
             else '1';

end Behavioral;