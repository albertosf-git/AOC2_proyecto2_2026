library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity UC_MC_CB is
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
end UC_MC_CB;

architecture Behavioral of UC_MC_CB is

component counter is
    generic (
        size : integer := 10
    );
    Port (
        clk : in STD_LOGIC;
        reset : in STD_LOGIC;
        count_enable : in STD_LOGIC;
        count : out STD_LOGIC_VECTOR (size-1 downto 0)
    );
end component;

type state_type is (
    Inicio,
    single_word_transfer_addr,
    Send_Addr,
    single_word_transfer_data,
    block_transfer_addr,
    read_block,
    block_transfer_data,
    Send_ADDR_CB,
    write_dirty_block,
    CopyBack,
    fallo,
    bajar_Frame
);

type error_type is (memory_error, No_error);

signal state, next_state : state_type;
signal error_state, next_error_state : error_type;
signal last_word_block : STD_LOGIC;
signal count_enable : STD_LOGIC;
signal count_reset : STD_LOGIC;
signal count_reset_full : STD_LOGIC;
signal hit : STD_LOGIC;
signal palabra_UC : STD_LOGIC_VECTOR (1 downto 0);

begin

hit <= hit0 or hit1;

word_counter: counter
    generic map (size => 2)
    port map (clk => clk, reset => count_reset_full, count_enable => count_enable, count => palabra_UC);

last_word_block <= '1' when palabra_UC = "11" else '0';
palabra <= palabra_UC;
count_reset_full <= reset or count_reset;

State_reg: process (clk)
begin
    if (clk'event and clk = '1') then
        if (reset = '1') then
            state <= Inicio;
        else
            state <= next_state;
        end if;
    end if;
end process;

error_reg: process (clk)
begin
    if (clk'event and clk = '1') then
        if (reset = '1') then
            error_state <= No_error;
        else
            error_state <= next_error_state;
        end if;
    end if;
end process;

Mem_ERROR <= '1' when (error_state = memory_error) else '0';

OUTPUT_DECODE: process (
    state, hit, hit0, hit1, last_word_block, bus_TRDY, RE, WE, Bus_DevSel,
    Bus_grant, via_2_rpl, dirty_bit_rpl, addr_non_cacheable, internal_addr,
    unaligned, error_state
)
begin
    MC_WE0 <= '0';
    MC_WE1 <= '0';
    MC_bus_Read <= '0';
    MC_bus_Write <= '0';
    MC_tags_WE <= '0';
    ready <= '0';
    mux_origen <= '0';
    MC_send_addr_ctrl <= '0';
    MC_send_data <= '0';
    next_state <= state;
    count_enable <= '0';
    count_reset <= '0';
    Frame <= '0';
    block_addr <= '0';
    inc_m <= '0';
    inc_w <= '0';
    inc_r <= '0';
    inc_cb <= '0';
    Bus_req <= '0';
    mux_output <= "00";
    last_word <= '0';
    next_error_state <= error_state;
    load_addr_error <= '0';
    send_dirty <= '0';
    Update_dirty <= '0';
    Block_copied_back <= '0';

    case state is
        when Inicio =>
            count_reset <= '1';
            ready <= '1';

            if (RE = '0' and WE = '0') then
                next_state <= Inicio;
            elsif (((RE = '1') or (WE = '1')) and (unaligned = '1')) then
                next_state <= Inicio;
                next_error_state <= memory_error;
                load_addr_error <= '1';
            elsif (RE = '1' and internal_addr = '1') then
                next_state <= Inicio;
                mux_output <= "10";
                next_error_state <= No_error;
            elsif (WE = '1' and internal_addr = '1') then
                next_state <= Inicio;
                next_error_state <= memory_error;
                load_addr_error <= '1';
            elsif (RE = '1' and hit = '1') then
                next_state <= Inicio;
                inc_r <= '1';
                mux_output <= "00";
            elsif (WE = '1' and hit = '1') then
                next_state <= Inicio;
                inc_w <= '1';
                MC_WE0 <= hit0;
                MC_WE1 <= hit1;
                Update_dirty <= '1';
            elsif (RE = '1' and hit = '0') then
                ready <= '0';
                if (addr_non_cacheable = '1') then
                    next_state <= single_word_transfer_addr;
                else
                    inc_r <= '1';
                    inc_m <= '1';
                    if (dirty_bit_rpl = '1') then
                        next_state <= Send_ADDR_CB;
                    else
                        next_state <= block_transfer_addr;
                    end if;
                end if;
            elsif (WE = '1' and hit = '0') then
                ready <= '0';
                if (addr_non_cacheable = '1') then
                    next_state <= single_word_transfer_addr;
                else
                    inc_w <= '1';
                    inc_m <= '1';
                    next_state <= single_word_transfer_addr;
                end if;
            end if;

        when single_word_transfer_addr =>
            count_reset <= '1';
            ready <= '0';
            Bus_req <= '1';

            if (Bus_grant = '1') then
                next_state <= Send_Addr;
            end if;

        when Send_Addr =>
            Frame <= '1';
            MC_send_addr_ctrl <= '1';
            block_addr <= '0';
            MC_bus_Read <= RE;
            MC_bus_Write <= WE;

            if (Bus_DevSel = '1') then
                next_state <= single_word_transfer_data;
            else
                next_state <= fallo;
            end if;

        when single_word_transfer_data =>
            ready <= '0';
            Frame <= '1';
            last_word <= '1';
            if (WE = '1') then
                MC_send_data <= '1';
            else
                mux_output <= "01";
            end if;

            if (bus_TRDY = '1') then
                ready <= '1';
                next_state <= Inicio;
            end if;

        when block_transfer_addr =>
            count_reset <= '1';
            ready <= '0';
            Bus_req <= '1';

            if (Bus_grant = '1') then
                next_state <= read_block;
            end if;

        when read_block =>
            Frame <= '1';
            MC_send_addr_ctrl <= '1';
            MC_bus_Read <= '1';
            block_addr <= '1';

            if (Bus_DevSel = '1') then
                next_state <= block_transfer_data;
            else
                next_state <= fallo;
            end if;

        when block_transfer_data =>
            ready <= '0';
            Frame <= '1';
            mux_origen <= '1';
            MC_WE0 <= bus_TRDY and (not via_2_rpl);
            MC_WE1 <= bus_TRDY and via_2_rpl;
            count_enable <= bus_TRDY;
            last_word <= last_word_block;

            if (bus_TRDY = '1') then
                if (last_word_block = '1') then
                    MC_tags_WE <= '1';
                    next_state <= bajar_Frame;
                else
                    next_state <= block_transfer_data;
                end if;
            end if;

        when Send_ADDR_CB =>
            count_reset <= '1';
            ready <= '0';
            Bus_req <= '1';

            if (Bus_grant = '1') then
                next_state <= write_dirty_block;
            end if;

        when write_dirty_block =>
            Frame <= '1';
            MC_send_addr_ctrl <= '1';
            MC_bus_Write <= '1';
            send_dirty <= '1';
            inc_cb <= '1';

            if (Bus_DevSel = '1') then
                next_state <= CopyBack;
            else
                next_state <= fallo;
            end if;

        when CopyBack =>
            ready <= '0';
            Frame <= '1';
            mux_origen <= '1';
            send_dirty <= '1';
            MC_send_data <= '1';
            last_word <= last_word_block;
            count_enable <= bus_TRDY;

            if (bus_TRDY = '1') then
                if (last_word_block = '1') then
                    Block_copied_back <= '1';
                    next_state <= block_transfer_addr;
                else
                    next_state <= CopyBack;
                end if;
            end if;

        when fallo =>
            count_reset <= '1';
            ready <= '1';
            next_error_state <= memory_error;
            load_addr_error <= '1';
            next_state <= Inicio;

        when bajar_Frame =>
            count_reset <= '1';
            ready <= '1';
            mux_output <= "00";
            next_state <= Inicio;

        when others =>
            next_state <= Inicio;
    end case;
end process;

end Behavioral;
