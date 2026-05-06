library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_p2_abort_monitor is
end tb_p2_abort_monitor;

architecture behavior of tb_p2_abort_monitor is

    component AOC2_SoC is
        Port (
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            EXT_IRQ : in STD_LOGIC;
            INT_ACK : out STD_LOGIC;
            IO_input : in STD_LOGIC_VECTOR (31 downto 0);
            IO_output : out STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;

    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal EXT_IRQ : std_logic := '0';
    signal INT_ACK : std_logic;
    signal IO_input : std_logic_vector(31 downto 0) := (others => '0');
    signal IO_output : std_logic_vector(31 downto 0);

    constant CLK_period : time := 10 ns;

begin

    uut: AOC2_SoC
        port map (
            clk => clk,
            reset => reset,
            EXT_IRQ => EXT_IRQ,
            INT_ACK => INT_ACK,
            IO_input => IO_input,
            IO_output => IO_output
        );

    clk_process: process
    begin
        clk <= '0';
        wait for CLK_period / 2;
        clk <= '1';
        wait for CLK_period / 2;
    end process;

    stim_proc: process
        variable saw_abort_marker : boolean := false;
        variable saw_error_addr : boolean := false;
    begin
        reset <= '1';
        wait for CLK_period * 2;
        reset <= '0';

        while now < 12 us loop
            wait for 1 ns;

            if IO_output = x"00000AB0" then
                saw_abort_marker := true;
                report "Abort marker observed on IO_output" severity note;
            elsif IO_output = x"00000274" then
                saw_error_addr := true;
                report "Abort address observed on IO_output" severity note;
            end if;

            exit when saw_abort_marker and saw_error_addr;
        end loop;

        assert saw_abort_marker
            report "The integrated test never reached the abort marker 0x00000AB0" severity failure;
        assert saw_error_addr
            report "The integrated test never exposed the abort address 0x00000274" severity failure;

        report "tb_p2_abort_monitor completed successfully" severity note;
        wait;
    end process;

end behavior;
