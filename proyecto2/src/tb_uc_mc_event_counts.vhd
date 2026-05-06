library ieee;
use ieee.std_logic_1164.all;

entity tb_uc_mc_event_counts is
end tb_uc_mc_event_counts;

architecture behavior of tb_uc_mc_event_counts is

    component UC_MC_CB is
        port (
            clk : in std_logic;
            reset : in std_logic;
            RE : in std_logic;
            WE : in std_logic;
            ready : out std_logic;
            hit0 : in std_logic;
            hit1 : in std_logic;
            via_2_rpl : in std_logic;
            addr_non_cacheable : in std_logic;
            internal_addr : in std_logic;
            MC_WE0 : out std_logic;
            MC_WE1 : out std_logic;
            MC_bus_Read : out std_logic;
            MC_bus_Write : out std_logic;
            MC_tags_WE : out std_logic;
            palabra : out std_logic_vector(1 downto 0);
            mux_origen : out std_logic;
            block_addr : out std_logic;
            mux_output : out std_logic_vector(1 downto 0);
            inc_m : out std_logic;
            inc_w : out std_logic;
            inc_r : out std_logic;
            inc_cb : out std_logic;
            unaligned : in std_logic;
            Mem_ERROR : out std_logic;
            load_addr_error : out std_logic;
            send_dirty : out std_logic;
            Update_dirty : out std_logic;
            dirty_bit_rpl : in std_logic;
            Block_copied_back : out std_logic;
            bus_TRDY : in std_logic;
            Bus_DevSel : in std_logic;
            Bus_grant : in std_logic;
            MC_send_addr_ctrl : out std_logic;
            MC_send_data : out std_logic;
            Frame : out std_logic;
            last_word : out std_logic;
            Bus_req : out std_logic
        );
    end component;

    signal clk : std_logic := '0';
    signal reset : std_logic := '0';
    signal re_s, we_s, ready_s, hit0_s, hit1_s, via_2_rpl_s, addr_non_cacheable_s, internal_addr_s : std_logic := '0';
    signal mc_we0_s, mc_we1_s, mc_bus_read_s, mc_bus_write_s, mc_tags_we_s, mux_origen_s, block_addr_s : std_logic;
    signal inc_m_s, inc_w_s, inc_r_s, inc_cb_s, unaligned_s, mem_error_s, load_addr_error_s, send_dirty_s, update_dirty_s, dirty_bit_rpl_s : std_logic := '0';
    signal block_copied_back_s, bus_trdy_s, bus_devsel_s, bus_grant_s, mc_send_addr_ctrl_s, mc_send_data_s, frame_s, last_word_s, bus_req_s : std_logic := '0';
    signal palabra_s : std_logic_vector(1 downto 0);
    signal mux_output_s : std_logic_vector(1 downto 0);

    constant clk_period : time := 10 ns;

    procedure clear_inputs(
        signal re_p : out std_logic;
        signal we_p : out std_logic;
        signal hit0_p : out std_logic;
        signal hit1_p : out std_logic;
        signal via_2_rpl_p : out std_logic;
        signal addr_non_cacheable_p : out std_logic;
        signal internal_addr_p : out std_logic;
        signal unaligned_p : out std_logic;
        signal dirty_bit_rpl_p : out std_logic;
        signal bus_trdy_p : out std_logic;
        signal bus_devsel_p : out std_logic;
        signal bus_grant_p : out std_logic
    ) is
    begin
        re_p <= '0';
        we_p <= '0';
        hit0_p <= '0';
        hit1_p <= '0';
        via_2_rpl_p <= '0';
        addr_non_cacheable_p <= '0';
        internal_addr_p <= '0';
        unaligned_p <= '0';
        dirty_bit_rpl_p <= '0';
        bus_trdy_p <= '0';
        bus_devsel_p <= '0';
        bus_grant_p <= '0';
    end procedure;

begin

    uut: UC_MC_CB
        port map (
            clk => clk,
            reset => reset,
            RE => re_s,
            WE => we_s,
            ready => ready_s,
            hit0 => hit0_s,
            hit1 => hit1_s,
            via_2_rpl => via_2_rpl_s,
            addr_non_cacheable => addr_non_cacheable_s,
            internal_addr => internal_addr_s,
            MC_WE0 => mc_we0_s,
            MC_WE1 => mc_we1_s,
            MC_bus_Read => mc_bus_read_s,
            MC_bus_Write => mc_bus_write_s,
            MC_tags_WE => mc_tags_we_s,
            palabra => palabra_s,
            mux_origen => mux_origen_s,
            block_addr => block_addr_s,
            mux_output => mux_output_s,
            inc_m => inc_m_s,
            inc_w => inc_w_s,
            inc_r => inc_r_s,
            inc_cb => inc_cb_s,
            unaligned => unaligned_s,
            Mem_ERROR => mem_error_s,
            load_addr_error => load_addr_error_s,
            send_dirty => send_dirty_s,
            Update_dirty => update_dirty_s,
            dirty_bit_rpl => dirty_bit_rpl_s,
            Block_copied_back => block_copied_back_s,
            bus_TRDY => bus_trdy_s,
            Bus_DevSel => bus_devsel_s,
            Bus_grant => bus_grant_s,
            MC_send_addr_ctrl => mc_send_addr_ctrl_s,
            MC_send_data => mc_send_data_s,
            Frame => frame_s,
            last_word => last_word_s,
            Bus_req => bus_req_s
        );

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    stim_proc: process
        variable total_m : integer := 0;
        variable total_w : integer := 0;
        variable total_r : integer := 0;
        variable total_cb : integer := 0;
    begin
        clear_inputs(re_s, we_s, hit0_s, hit1_s, via_2_rpl_s, addr_non_cacheable_s, internal_addr_s, unaligned_s, dirty_bit_rpl_s, bus_trdy_s, bus_devsel_s, bus_grant_s);
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for 1 ns;

        re_s <= '1';
        hit0_s <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        total_r := total_r + 1;
        clear_inputs(re_s, we_s, hit0_s, hit1_s, via_2_rpl_s, addr_non_cacheable_s, internal_addr_s, unaligned_s, dirty_bit_rpl_s, bus_trdy_s, bus_devsel_s, bus_grant_s);
        wait for clk_period;

        we_s <= '1';
        hit1_s <= '1';
        wait until rising_edge(clk);
        wait for 1 ns;
        total_w := total_w + 1;
        clear_inputs(re_s, we_s, hit0_s, hit1_s, via_2_rpl_s, addr_non_cacheable_s, internal_addr_s, unaligned_s, dirty_bit_rpl_s, bus_trdy_s, bus_devsel_s, bus_grant_s);
        wait for clk_period;

        re_s <= '1';
        addr_non_cacheable_s <= '1';
        wait for clk_period;
        bus_grant_s <= '1';
        bus_devsel_s <= '1';
        wait for clk_period;
        bus_trdy_s <= '1';
        clear_inputs(re_s, we_s, hit0_s, hit1_s, via_2_rpl_s, addr_non_cacheable_s, internal_addr_s, unaligned_s, dirty_bit_rpl_s, bus_trdy_s, bus_devsel_s, bus_grant_s);
        wait for clk_period;

        we_s <= '1';
        wait for 1 ns;
        total_w := total_w + 1;
        total_m := total_m + 1;
        wait for clk_period;
        bus_grant_s <= '1';
        bus_devsel_s <= '1';
        wait for clk_period;
        bus_trdy_s <= '1';
        clear_inputs(re_s, we_s, hit0_s, hit1_s, via_2_rpl_s, addr_non_cacheable_s, internal_addr_s, unaligned_s, dirty_bit_rpl_s, bus_trdy_s, bus_devsel_s, bus_grant_s);
        wait for clk_period;

        re_s <= '1';
        via_2_rpl_s <= '1';
        wait for 1 ns;
        total_r := total_r + 1;
        total_m := total_m + 1;
        wait for clk_period;
        bus_grant_s <= '1';
        bus_devsel_s <= '1';
        wait for clk_period;
        for i in 0 to 3 loop
            bus_trdy_s <= '1';
            wait for clk_period;
        end loop;
        clear_inputs(re_s, we_s, hit0_s, hit1_s, via_2_rpl_s, addr_non_cacheable_s, internal_addr_s, unaligned_s, dirty_bit_rpl_s, bus_trdy_s, bus_devsel_s, bus_grant_s);

        re_s <= '1';
        dirty_bit_rpl_s <= '1';
        wait for 1 ns;
        total_r := total_r + 1;
        total_m := total_m + 1;
        wait for clk_period;
        bus_grant_s <= '1';
        bus_devsel_s <= '1';
        wait for clk_period;
        total_cb := total_cb + 1;
        for i in 0 to 3 loop
            bus_trdy_s <= '1';
            wait for clk_period;
        end loop;
        bus_trdy_s <= '0';
        wait for clk_period;
        bus_grant_s <= '1';
        bus_devsel_s <= '1';
        wait for clk_period;
        for i in 0 to 3 loop
            bus_trdy_s <= '1';
            wait for clk_period;
        end loop;
        clear_inputs(re_s, we_s, hit0_s, hit1_s, via_2_rpl_s, addr_non_cacheable_s, internal_addr_s, unaligned_s, dirty_bit_rpl_s, bus_trdy_s, bus_devsel_s, bus_grant_s);
        wait for 1 ns;

        assert total_m = 3 report "Unexpected expected miss count in testbench bookkeeping" severity failure;
        assert total_w = 2 report "Unexpected expected write count in testbench bookkeeping" severity failure;
        assert total_r = 3 report "Unexpected expected read count in testbench bookkeeping" severity failure;
        assert total_cb = 1 report "Unexpected expected copy-back count in testbench bookkeeping" severity failure;

        report "Expected counter events for this sequence: m=3 w=2 r=3 cb=1" severity note;
        report "tb_uc_mc_event_counts completed successfully" severity note;
        wait;
    end process;

    pulse_check: process
        variable m_pulses : integer := 0;
        variable w_pulses : integer := 0;
        variable r_pulses : integer := 0;
        variable cb_pulses : integer := 0;
    begin
        wait until reset = '0';
        loop
            wait until rising_edge(clk);
            wait for 1 ns;
            if inc_m_s = '1' then
                m_pulses := m_pulses + 1;
            end if;
            if inc_w_s = '1' then
                w_pulses := w_pulses + 1;
            end if;
            if inc_r_s = '1' then
                r_pulses := r_pulses + 1;
            end if;
            if inc_cb_s = '1' then
                cb_pulses := cb_pulses + 1;
            end if;

            if now > 250 ns then
                report "Observed pulses: m=" & integer'image(m_pulses) &
                       " w=" & integer'image(w_pulses) &
                       " r=" & integer'image(r_pulses) &
                       " cb=" & integer'image(cb_pulses) severity note;
                assert m_pulses = 3 report "inc_m did not pulse exactly 3 times" severity failure;
                assert w_pulses = 2 report "inc_w did not pulse exactly 2 times" severity failure;
                assert r_pulses = 3 report "inc_r did not pulse exactly 3 times" severity failure;
                assert cb_pulses = 1 report "inc_cb did not pulse exactly 1 time" severity failure;
                wait;
            end if;
        end loop;
    end process;

end behavior;
