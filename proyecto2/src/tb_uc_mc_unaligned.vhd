library ieee;
use ieee.std_logic_1164.all;

entity tb_uc_mc_unaligned is
end tb_uc_mc_unaligned;

architecture behavior of tb_uc_mc_unaligned is

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
    begin
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for 1 ns;

        re_s <= '1';
        unaligned_s <= '1';
        wait for 1 ns;
        assert ready_s = '1' and load_addr_error_s = '1'
            report "Unaligned access must be rejected immediately and load the error register" severity failure;
        assert inc_m_s = '0' and inc_w_s = '0' and inc_r_s = '0'
            report "Unaligned access must not affect MC performance counters directly" severity failure;

        wait for clk_period;
        wait for 1 ns;
        assert mem_error_s = '1'
            report "Mem_ERROR must latch after an unaligned access" severity failure;

        re_s <= '1';
        unaligned_s <= '0';
        internal_addr_s <= '1';
        wait for 1 ns;
        assert mux_output_s = "10"
            report "Internal register read must be selected to clear Mem_ERROR" severity failure;

        wait for clk_period;
        wait for 1 ns;
        assert mem_error_s = '0'
            report "Mem_ERROR must clear after reading the internal error register" severity failure;

        report "tb_uc_mc_unaligned completed successfully" severity note;
        wait;
    end process;

end behavior;
