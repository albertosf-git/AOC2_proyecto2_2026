library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_io_md_hierarchy_paths is
end tb_io_md_hierarchy_paths;

architecture behavior of tb_io_md_hierarchy_paths is

    component IO_Data_Memory_Subsystem is
        port (
            CLK : in std_logic;
            reset : in std_logic;
            ADDR : in std_logic_vector(31 downto 0);
            Din : in std_logic_vector(31 downto 0);
            WE : in std_logic;
            RE : in std_logic;
            IO_Mem_ready : out std_logic;
            Data_abort : out std_logic;
            Dout : out std_logic_vector(31 downto 0);
            Ext_IRQ : in std_logic;
            INT_ACK : out std_logic;
            MIPS_IRQ : out std_logic;
            IO_input : in std_logic_vector(31 downto 0);
            IO_output : out std_logic_vector(31 downto 0)
        );
    end component;

    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal addr_s : std_logic_vector(31 downto 0) := (others => '0');
    signal din_s : std_logic_vector(31 downto 0) := (others => '0');
    signal we_s : std_logic := '0';
    signal re_s : std_logic := '0';
    signal ready_s : std_logic;
    signal data_abort_s : std_logic;
    signal dout_s : std_logic_vector(31 downto 0);
    signal ext_irq_s : std_logic := '0';
    signal int_ack_s : std_logic;
    signal mips_irq_s : std_logic;
    signal io_input_s : std_logic_vector(31 downto 0) := x"11111111";
    signal io_output_s : std_logic_vector(31 downto 0);

    constant clk_period : time := 10 ns;

begin

    uut: IO_Data_Memory_Subsystem
        port map (
            CLK => clk,
            reset => reset,
            ADDR => addr_s,
            Din => din_s,
            WE => we_s,
            RE => re_s,
            IO_Mem_ready => ready_s,
            Data_abort => data_abort_s,
            Dout => dout_s,
            Ext_IRQ => ext_irq_s,
            INT_ACK => int_ack_s,
            MIPS_IRQ => mips_irq_s,
            IO_input => io_input_s,
            IO_output => io_output_s
        );

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    stim_proc: process
        procedure go_idle is
        begin
            re_s <= '0';
            we_s <= '0';
            addr_s <= (others => '0');
            din_s <= (others => '0');
        end procedure;

        procedure start_read(constant a : std_logic_vector(31 downto 0)) is
        begin
            addr_s <= a;
            re_s <= '1';
            we_s <= '0';
        end procedure;

        procedure start_write(constant a : std_logic_vector(31 downto 0); constant d : std_logic_vector(31 downto 0)) is
        begin
            addr_s <= a;
            din_s <= d;
            re_s <= '0';
            we_s <= '1';
        end procedure;

        procedure wait_until_ready(variable cycles : inout integer) is
        begin
            cycles := 0;
            wait for 1 ns;
            while ready_s = '0' loop
                wait until rising_edge(clk);
                wait for 1 ns;
                cycles := cycles + 1;
            end loop;
            wait for 1 ns;
        end procedure;

        variable cycles_a_miss : integer;
        variable cycles_hit_write : integer;
        variable cycles_b_miss : integer;
        variable cycles_c_dirty : integer;
        variable cycles_a_refetch : integer;
        variable cycles_d_write_miss : integer;
        variable cycles_d_first_read : integer;
        variable cycles_d_second_read : integer;
        variable cycles_scratch_write : integer;
        variable cycles_scratch_read : integer;
        variable cycles_error_read : integer;
    begin
        go_idle;
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period;
        wait for 1 ns;

        start_read(x"00000000");
        wait_until_ready(cycles_a_miss);
        assert dout_s = x"00000001"
            report "First read of block A returned unexpected data" severity failure;
        go_idle;
        wait for clk_period;

        start_write(x"00000000", x"1EADBEEF");
        wait_until_ready(cycles_hit_write);
        assert data_abort_s = '0'
            report "Write hit on block A must not raise Data_abort" severity failure;
        wait until rising_edge(clk);
        wait for 1 ns;
        go_idle;
        wait for clk_period;

        start_read(x"00000040");
        wait_until_ready(cycles_b_miss);
        assert dout_s = x"00000001"
            report "Read of block B returned unexpected data" severity failure;
        go_idle;
        wait for clk_period;

        start_read(x"00000080");
        wait_until_ready(cycles_c_dirty);
        assert dout_s = x"00000010"
            report "Read of block C returned unexpected data" severity failure;
        go_idle;
        wait for clk_period;

        start_read(x"00000000");
        wait_until_ready(cycles_a_refetch);
        assert dout_s = x"1EADBEEF"
            report "Copy-back did not preserve the modified word of block A in MD" severity failure;
        go_idle;
        wait for clk_period;

        start_write(x"000000C0", x"0AFEBABE");
        wait_until_ready(cycles_d_write_miss);
        assert data_abort_s = '0'
            report "Write-around write miss must complete without Data_abort" severity failure;
        wait until rising_edge(clk);
        wait for 1 ns;
        go_idle;
        wait for clk_period;

        start_read(x"000000C0");
        wait_until_ready(cycles_d_first_read);
        assert dout_s = x"0AFEBABE"
            report "First read after write-around did not fetch the updated value from MD" severity failure;
        go_idle;
        wait for clk_period;

        start_read(x"000000C0");
        wait_until_ready(cycles_d_second_read);
        assert dout_s = x"0AFEBABE"
            report "Second read of block D should hit in cache and keep the updated value" severity failure;
        go_idle;
        wait for clk_period;

        start_write(x"10000004", x"12345678");
        wait_until_ready(cycles_scratch_write);
        assert data_abort_s = '0'
            report "Scratch write must not raise Data_abort" severity failure;
        wait until rising_edge(clk);
        wait for 1 ns;
        go_idle;
        wait for clk_period;

        start_read(x"10000004");
        wait_until_ready(cycles_scratch_read);
        assert dout_s = x"12345678"
            report "Scratch read did not return the recently written value" severity failure;
        go_idle;
        wait for clk_period;

        start_read(x"00000002");
        wait until rising_edge(clk);
        wait for 1 ns;
        assert data_abort_s = '1'
            report "Unaligned access must raise Data_abort in the integrated subsystem" severity failure;
        go_idle;
        wait for clk_period;

        start_read(x"01000000");
        wait_until_ready(cycles_error_read);
        assert dout_s = x"00000002"
            report "Addr_Error_Reg must keep the exact unaligned byte address" severity failure;
        wait until rising_edge(clk);
        wait for 1 ns;
        go_idle;
        wait for clk_period;
        wait for 1 ns;
        assert data_abort_s = '0'
            report "Reading Addr_Error_Reg must clear Data_abort" severity failure;

        assert cycles_d_first_read > cycles_d_second_read
            report "The first read after a write-around should miss, while the second should hit" severity failure;
        assert cycles_scratch_write < cycles_d_first_read and cycles_scratch_read < cycles_d_first_read
            report "Scratch accesses should stay cheaper than a cacheable miss to MD in the integrated subsystem" severity failure;

        report "Integrated path latencies summary:" severity note;
        report "  read A miss cycles=" & integer'image(cycles_a_miss) severity note;
        report "  write A hit cycles=" & integer'image(cycles_hit_write) severity note;
        report "  read B miss cycles=" & integer'image(cycles_b_miss) severity note;
        report "  read C dirty-replacement cycles=" & integer'image(cycles_c_dirty) severity note;
        report "  read A refetch cycles=" & integer'image(cycles_a_refetch) severity note;
        report "  write D write-around cycles=" & integer'image(cycles_d_write_miss) severity note;
        report "  read D first cycles=" & integer'image(cycles_d_first_read) severity note;
        report "  read D second cycles=" & integer'image(cycles_d_second_read) severity note;
        report "  scratch write cycles=" & integer'image(cycles_scratch_write) severity note;
        report "  scratch read cycles=" & integer'image(cycles_scratch_read) severity note;
        report "  Addr_Error_Reg read cycles=" & integer'image(cycles_error_read) severity note;
        report "tb_io_md_hierarchy_paths completed successfully" severity note;
        wait;
    end process;

end behavior;
