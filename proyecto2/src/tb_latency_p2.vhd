library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_latency_p2 is
end tb_latency_p2;

architecture behavior of tb_latency_p2 is

    component MD_cont_2026 is
        port (
            CLK : in std_logic;
            reset : in std_logic;
            Bus_Frame : in std_logic;
            bus_last_word : in std_logic;
            bus_Read : in std_logic;
            bus_Write : in std_logic;
            Bus_Addr : in std_logic_vector(31 downto 0);
            Bus_Data : in std_logic_vector(31 downto 0);
            MD_Bus_DEVsel : out std_logic;
            MD_Bus_TRDY : out std_logic;
            MD_send_data : out std_logic;
            MD_Dout : out std_logic_vector(31 downto 0)
        );
    end component;

    component MD_scratch is
        port (
            CLK : in std_logic;
            reset : in std_logic;
            Bus_Frame : in std_logic;
            bus_Read : in std_logic;
            bus_Write : in std_logic;
            Bus_Addr : in std_logic_vector(31 downto 0);
            Bus_Data : in std_logic_vector(31 downto 0);
            MD_Bus_DEVsel : out std_logic;
            MD_Bus_TRDY : out std_logic;
            MD_send_data : out std_logic;
            MD_Dout : out std_logic_vector(31 downto 0)
        );
    end component;

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

    signal md_frame : std_logic := '0';
    signal md_last_word : std_logic := '0';
    signal md_read : std_logic := '0';
    signal md_write : std_logic := '0';
    signal md_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal md_data : std_logic_vector(31 downto 0) := (others => '0');
    signal md_devsel : std_logic;
    signal md_trdy : std_logic;
    signal md_send_data : std_logic;
    signal md_dout : std_logic_vector(31 downto 0);

    signal scratch_frame : std_logic := '0';
    signal scratch_read : std_logic := '0';
    signal scratch_write : std_logic := '0';
    signal scratch_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal scratch_data : std_logic_vector(31 downto 0) := (others => '0');
    signal scratch_devsel : std_logic;
    signal scratch_trdy : std_logic;
    signal scratch_send_data : std_logic;
    signal scratch_dout : std_logic_vector(31 downto 0);

    signal io_addr : std_logic_vector(31 downto 0) := (others => '0');
    signal io_din : std_logic_vector(31 downto 0) := (others => '0');
    signal io_we : std_logic := '0';
    signal io_re : std_logic := '0';
    signal io_ready : std_logic;
    signal io_abort : std_logic;
    signal io_dout : std_logic_vector(31 downto 0);
    signal ext_irq : std_logic := '0';
    signal int_ack : std_logic;
    signal mips_irq : std_logic;
    signal io_input : std_logic_vector(31 downto 0) := x"12345678";
    signal io_output : std_logic_vector(31 downto 0);

    constant clk_period : time := 10 ns;

begin

    md_uut: MD_cont_2026
        port map (
            CLK => clk,
            reset => reset,
            Bus_Frame => md_frame,
            bus_last_word => md_last_word,
            bus_Read => md_read,
            bus_Write => md_write,
            Bus_Addr => md_addr,
            Bus_Data => md_data,
            MD_Bus_DEVsel => md_devsel,
            MD_Bus_TRDY => md_trdy,
            MD_send_data => md_send_data,
            MD_Dout => md_dout
        );

    scratch_uut: MD_scratch
        port map (
            CLK => clk,
            reset => reset,
            Bus_Frame => scratch_frame,
            bus_Read => scratch_read,
            bus_Write => scratch_write,
            Bus_Addr => scratch_addr,
            Bus_Data => scratch_data,
            MD_Bus_DEVsel => scratch_devsel,
            MD_Bus_TRDY => scratch_trdy,
            MD_send_data => scratch_send_data,
            MD_Dout => scratch_dout
        );

    io_uut: IO_Data_Memory_Subsystem
        port map (
            CLK => clk,
            reset => reset,
            ADDR => io_addr,
            Din => io_din,
            WE => io_we,
            RE => io_re,
            IO_Mem_ready => io_ready,
            Data_abort => io_abort,
            Dout => io_dout,
            Ext_IRQ => ext_irq,
            INT_ACK => int_ack,
            MIPS_IRQ => mips_irq,
            IO_input => io_input,
            IO_output => io_output
        );

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    stim_proc: process
        variable md_block_cycles : integer := 0;
        variable md_write_cycles : integer := 0;
        variable scratch_read_cycles : integer := 0;
        variable scratch_write_cycles : integer := 0;
        variable io_read_cycles : integer := 0;
        variable io_write_cycles : integer := 0;
        variable words_seen : integer := 0;
    begin
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for 1 ns;

        md_frame <= '1';
        md_read <= '1';
        md_addr <= x"00000000";
        words_seen := 0;
        md_block_cycles := 0;
        while words_seen < 4 loop
            if words_seen = 3 then
                md_last_word <= '1';
            else
                md_last_word <= '0';
            end if;
            wait until rising_edge(clk);
            wait for 1 ns;
            md_block_cycles := md_block_cycles + 1;
            if md_trdy = '1' then
                words_seen := words_seen + 1;
            end if;
        end loop;
        md_frame <= '0';
        md_read <= '0';
        md_last_word <= '0';
        wait for clk_period;

        md_frame <= '1';
        md_write <= '1';
        md_last_word <= '1';
        md_addr <= x"00000004";
        md_data <= x"CAFEBABE";
        md_write_cycles := 0;
        loop
            wait until rising_edge(clk);
            wait for 1 ns;
            md_write_cycles := md_write_cycles + 1;
            exit when md_trdy = '1';
        end loop;
        md_frame <= '0';
        md_write <= '0';
        md_last_word <= '0';
        wait for clk_period;

        scratch_frame <= '1';
        scratch_write <= '1';
        scratch_addr <= x"10000000";
        scratch_data <= x"00000055";
        scratch_write_cycles := 0;
        loop
            wait until rising_edge(clk);
            wait for 1 ns;
            scratch_write_cycles := scratch_write_cycles + 1;
            exit when scratch_trdy = '1';
        end loop;
        scratch_frame <= '0';
        scratch_write <= '0';
        wait for clk_period;

        scratch_frame <= '1';
        scratch_read <= '1';
        scratch_addr <= x"10000000";
        scratch_read_cycles := 0;
        loop
            wait until rising_edge(clk);
            wait for 1 ns;
            scratch_read_cycles := scratch_read_cycles + 1;
            exit when scratch_trdy = '1';
        end loop;
        scratch_frame <= '0';
        scratch_read <= '0';
        wait for clk_period;

        io_re <= '1';
        io_addr <= x"00007000";
        io_read_cycles := 0;
        loop
            wait until rising_edge(clk);
            wait for 1 ns;
            io_read_cycles := io_read_cycles + 1;
            exit when io_ready = '1';
        end loop;
        assert io_dout = x"12345678"
            report "IO input register read returned an unexpected value" severity failure;
        io_re <= '0';
        wait for clk_period;

        io_we <= '1';
        io_addr <= x"00007004";
        io_din <= x"89ABCDEF";
        io_write_cycles := 0;
        loop
            wait until rising_edge(clk);
            wait for 1 ns;
            io_write_cycles := io_write_cycles + 1;
            exit when io_ready = '1';
        end loop;
        assert io_output = x"89ABCDEF"
            report "IO output register write did not update the visible output" severity failure;
        io_we <= '0';
        wait for clk_period;

        report "Measured CrB(MD) = " & integer'image(md_block_cycles) severity note;
        report "Measured CwW(MD) = " & integer'image(md_write_cycles) severity note;
        report "Measured CrW(MDscratch) = " & integer'image(scratch_read_cycles) severity note;
        report "Measured CwW(MDscratch) = " & integer'image(scratch_write_cycles) severity note;
        report "Measured CrW(IO_REG) = " & integer'image(io_read_cycles) severity note;
        report "Measured CwW(IO_REG) = " & integer'image(io_write_cycles) severity note;

        assert md_block_cycles = 17
            report "Unexpected CrB(MD) cycle count" severity failure;
        assert md_write_cycles = 6
            report "Unexpected CwW(MD) cycle count" severity failure;
        assert scratch_read_cycles = 2
            report "Unexpected CrW(MDscratch) cycle count" severity failure;
        assert scratch_write_cycles = 1
            report "Unexpected CwW(MDscratch) cycle count" severity failure;
        assert io_read_cycles = 1
            report "Unexpected CrW(IO_REG) cycle count" severity failure;
        assert io_write_cycles = 1
            report "Unexpected CwW(IO_REG) cycle count" severity failure;

        report "tb_latency_p2 completed successfully" severity note;
        wait;
    end process;

end behavior;
