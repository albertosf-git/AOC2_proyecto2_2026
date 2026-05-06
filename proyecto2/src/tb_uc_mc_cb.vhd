library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_uc_mc_cb is
end tb_uc_mc_cb;

architecture behavior of tb_uc_mc_cb is

    component UC_MC_CB is
        Port (
            clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            RE : in STD_LOGIC;
            WE : in STD_LOGIC;
            ready : out STD_LOGIC;
            hit0 : in STD_LOGIC;
            hit1 : in STD_LOGIC;
            via_2_rpl : in STD_LOGIC;
            addr_non_cacheable : in STD_LOGIC;
            internal_addr : in STD_LOGIC;
            MC_WE0 : out STD_LOGIC;
            MC_WE1 : out STD_LOGIC;
            MC_bus_Read : out STD_LOGIC;
            MC_bus_Write : out STD_LOGIC;
            MC_tags_WE : out STD_LOGIC;
            palabra : out STD_LOGIC_VECTOR (1 downto 0);
            mux_origen : out STD_LOGIC;
            block_addr : out STD_LOGIC;
            mux_output : out std_logic_vector(1 downto 0);
            inc_m : out STD_LOGIC;
            inc_w : out STD_LOGIC;
            inc_r : out STD_LOGIC;
            inc_cb : out STD_LOGIC;
            unaligned : in STD_LOGIC;
            Mem_ERROR : out std_logic;
            load_addr_error : out std_logic;
            send_dirty : out std_logic;
            Update_dirty : out STD_LOGIC;
            dirty_bit_rpl : in STD_LOGIC;
            Block_copied_back : out STD_LOGIC;
            bus_TRDY : in STD_LOGIC;
            Bus_DevSel : in STD_LOGIC;
            Bus_grant : in STD_LOGIC;
            MC_send_addr_ctrl : out STD_LOGIC;
            MC_send_data : out STD_LOGIC;
            Frame : out STD_LOGIC;
            last_word : out STD_LOGIC;
            Bus_req : out STD_LOGIC
        );
    end component;

    signal clk, reset, RE, WE, ready, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr : std_logic := '0';
    signal MC_WE0, MC_WE1, MC_bus_Read, MC_bus_Write, MC_tags_WE, mux_origen, block_addr : std_logic;
    signal inc_m, inc_w, inc_r, inc_cb, unaligned, Mem_ERROR, load_addr_error, send_dirty, Update_dirty, dirty_bit_rpl : std_logic := '0';
    signal Block_copied_back, bus_TRDY, Bus_DevSel, Bus_grant, MC_send_addr_ctrl, MC_send_data, Frame, last_word, Bus_req : std_logic := '0';
    signal palabra : std_logic_vector(1 downto 0);
    signal mux_output : std_logic_vector(1 downto 0);

    constant CLK_period : time := 10 ns;

    procedure clear_inputs(
        signal RE_s : out std_logic;
        signal WE_s : out std_logic;
        signal hit0_s : out std_logic;
        signal hit1_s : out std_logic;
        signal via_2_rpl_s : out std_logic;
        signal addr_non_cacheable_s : out std_logic;
        signal internal_addr_s : out std_logic;
        signal unaligned_s : out std_logic;
        signal dirty_bit_rpl_s : out std_logic;
        signal bus_TRDY_s : out std_logic;
        signal Bus_DevSel_s : out std_logic;
        signal Bus_grant_s : out std_logic
    ) is
    begin
        RE_s <= '0';
        WE_s <= '0';
        hit0_s <= '0';
        hit1_s <= '0';
        via_2_rpl_s <= '0';
        addr_non_cacheable_s <= '0';
        internal_addr_s <= '0';
        unaligned_s <= '0';
        dirty_bit_rpl_s <= '0';
        bus_TRDY_s <= '0';
        Bus_DevSel_s <= '0';
        Bus_grant_s <= '0';
    end procedure;

begin

    uut: UC_MC_CB
        port map (
            clk => clk,
            reset => reset,
            RE => RE,
            WE => WE,
            ready => ready,
            hit0 => hit0,
            hit1 => hit1,
            via_2_rpl => via_2_rpl,
            addr_non_cacheable => addr_non_cacheable,
            internal_addr => internal_addr,
            MC_WE0 => MC_WE0,
            MC_WE1 => MC_WE1,
            MC_bus_Read => MC_bus_Read,
            MC_bus_Write => MC_bus_Write,
            MC_tags_WE => MC_tags_WE,
            palabra => palabra,
            mux_origen => mux_origen,
            block_addr => block_addr,
            mux_output => mux_output,
            inc_m => inc_m,
            inc_w => inc_w,
            inc_r => inc_r,
            unaligned => unaligned,
            Mem_ERROR => Mem_ERROR,
            load_addr_error => load_addr_error,
            send_dirty => send_dirty,
            Update_dirty => Update_dirty,
            dirty_bit_rpl => dirty_bit_rpl,
            Block_copied_back => Block_copied_back,
            bus_TRDY => bus_TRDY,
            Bus_DevSel => Bus_DevSel,
            Bus_grant => Bus_grant,
            MC_send_addr_ctrl => MC_send_addr_ctrl,
            MC_send_data => MC_send_data,
            Frame => Frame,
            last_word => last_word,
            Bus_req => Bus_req,
            inc_cb => inc_cb
        );

    clk_process: process
    begin
        clk <= '0';
        wait for CLK_period / 2;
        clk <= '1';
        wait for CLK_period / 2;
    end process;

    stim_proc: process
        variable saw_copyback_done : boolean;
    begin
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);
        reset <= '1';
        wait for CLK_period * 2;
        reset <= '0';
        wait for 1 ns;

        assert ready = '1' report "Idle should keep ready high" severity failure;

        RE <= '1';
        hit0 <= '1';
        wait for 1 ns;
        assert ready = '1' and inc_r = '1' and mux_output = "00"
            report "Read hit behavior is wrong" severity failure;
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);
        wait for CLK_period;

        WE <= '1';
        hit1 <= '1';
        wait for 1 ns;
        assert ready = '1' and inc_w = '1' and MC_WE1 = '1' and Update_dirty = '1'
            report "Write hit behavior is wrong" severity failure;
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);
        wait for CLK_period;

        RE <= '1';
        internal_addr <= '1';
        wait for 1 ns;
        assert ready = '1' and mux_output = "10"
            report "Internal register read behavior is wrong" severity failure;
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);
        wait for CLK_period;

        WE <= '1';
        internal_addr <= '1';
        wait for 1 ns;
        assert ready = '1' and load_addr_error = '1'
            report "Internal register write must raise an error" severity failure;
        wait for CLK_period;
        wait for 1 ns;
        assert Mem_ERROR = '1' report "Mem_ERROR should latch after illegal write" severity failure;
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);
        RE <= '1';
        internal_addr <= '1';
        wait for 1 ns;
        assert mux_output = "10" report "Internal read should be selected to clear error" severity failure;
        wait for CLK_period;
        wait for 1 ns;
        assert Mem_ERROR = '0' report "Mem_ERROR should clear after reading the internal register" severity failure;
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);
        wait for CLK_period;

        RE <= '1';
        addr_non_cacheable <= '1';
        wait for 1 ns;
        assert ready = '0' report "Scratch read miss must stall before bus access" severity failure;
        wait for CLK_period;
        Bus_grant <= '1';
        Bus_DevSel <= '1';
        wait for CLK_period;
        wait for 1 ns;
        assert Frame = '1' and MC_send_addr_ctrl = '1' and MC_bus_Read = '1' and block_addr = '0'
            report "Scratch read address phase is wrong" severity failure;
        wait for CLK_period;
        bus_TRDY <= '1';
        wait for 1 ns;
        assert ready = '1' and mux_output = "01" and last_word = '1'
            report "Scratch read data phase is wrong" severity failure;
        wait for CLK_period;
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);

        WE <= '1';
        wait for 1 ns;
        assert inc_w = '1' and inc_m = '1' and ready = '0'
            report "Cacheable write miss must count w+m and stall" severity failure;
        wait for CLK_period;
        Bus_grant <= '1';
        Bus_DevSel <= '1';
        wait for CLK_period;
        wait for 1 ns;
        assert MC_bus_Write = '1' and MC_send_addr_ctrl = '1' and block_addr = '0'
            report "Write-around address phase is wrong" severity failure;
        wait for CLK_period;
        bus_TRDY <= '1';
        wait for 1 ns;
        assert ready = '1' and MC_send_data = '1' and last_word = '1'
            report "Write-around data phase is wrong" severity failure;
        wait for CLK_period;
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);

        RE <= '1';
        via_2_rpl <= '1';
        wait for 1 ns;
        assert inc_r = '1' and inc_m = '1' and ready = '0'
            report "Clean read miss must count r+m and stall" severity failure;
        wait for CLK_period;
        Bus_grant <= '1';
        Bus_DevSel <= '1';
        wait for CLK_period;
        wait for 1 ns;
        assert MC_bus_Read = '1' and MC_send_addr_ctrl = '1' and block_addr = '1'
            report "Block read address phase is wrong" severity failure;
        wait for CLK_period;
        for i in 0 to 2 loop
            bus_TRDY <= '1';
            wait for 1 ns;
            assert mux_origen = '1' and MC_WE1 = '1' and MC_tags_WE = '0'
                report "Intermediate block fill cycle is wrong" severity failure;
            wait for CLK_period;
        end loop;
        bus_TRDY <= '1';
        wait for 1 ns;
        assert mux_origen = '1' and MC_WE1 = '1' and MC_tags_WE = '1' and last_word = '1'
            report "Last block fill cycle must write tags" severity failure;
        wait for CLK_period;
        wait for 1 ns;
        assert ready = '1' and mux_output = "00"
            report "Read miss must finish with a cache output cycle" severity failure;
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);
        wait for CLK_period;

        RE <= '1';
        dirty_bit_rpl <= '1';
        wait for 1 ns;
        assert inc_r = '1' and inc_m = '1' and ready = '0'
            report "Dirty read miss must count r+m and stall" severity failure;
        wait for CLK_period;
        Bus_grant <= '1';
        Bus_DevSel <= '1';
        wait for CLK_period;
        wait for 1 ns;
        assert MC_bus_Write = '1' and MC_send_addr_ctrl = '1' and send_dirty = '1' and inc_cb = '1'
            report "Copy-back address phase is wrong" severity failure;
        wait for CLK_period;
        saw_copyback_done := false;
        for i in 0 to 6 loop
            bus_TRDY <= '1';
            wait for 1 ns;
            if Block_copied_back = '1' then
                saw_copyback_done := true;
                exit;
            end if;
            assert MC_send_data = '1' and send_dirty = '1' and mux_origen = '1'
                report "Copy-back data cycle is wrong" severity failure;
            wait for CLK_period;
        end loop;
        assert saw_copyback_done
            report "The UC never completed the copy-back sequence" severity failure;
        wait for CLK_period;
        Bus_grant <= '1';
        Bus_DevSel <= '1';
        bus_TRDY <= '0';
        wait for CLK_period;
        wait for 1 ns;
        assert MC_bus_Read = '1' and MC_send_addr_ctrl = '1' and block_addr = '1'
            report "After copy-back, block fetch must start" severity failure;
        clear_inputs(RE, WE, hit0, hit1, via_2_rpl, addr_non_cacheable, internal_addr, unaligned, dirty_bit_rpl, bus_TRDY, Bus_DevSel, Bus_grant);
        wait for CLK_period;

        RE <= '1';
        wait for 1 ns;
        wait for CLK_period;
        Bus_grant <= '1';
        Bus_DevSel <= '0';
        wait for CLK_period;
        wait for 1 ns;
        assert Mem_ERROR = '1' report "Error path must latch Mem_ERROR" severity failure;

        report "tb_uc_mc_cb completed successfully" severity note;
        wait;
    end process;

end behavior;
