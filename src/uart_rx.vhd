----------------------------------------------------------------------------------
-- Created by: Robin Staub
--
-- Create Date:    01-04-2022
-- Design Name:
-- Module Name:    uart_rx
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- TODO: Flow control (RTS/CTS)
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity uart_rx is
    generic(
        CLKDIV          : integer := 278;                       -- CLK Frequency divided by Baudrate
        DATA_BITS_NR    : integer := 8;                         -- Number of data bits per transfer (5 to 9)
        STOP_BITS_NR    : integer := 1;                         -- Can be 1 or 2
        PARITY          : std_logic_vector(1 downto 0) := "00"  -- 0: no parity, 1: odd parity, 2: even parity
    );
    port(
        CLK             : in    std_logic;
        RST             : in    std_logic;
        DIN             : in   std_logic;

        DATA_VALID      : out    std_logic;
        DATA_RX         : out    std_logic_vector(DATA_BITS_NR-1 downto 0)
);
end uart_rx;

architecture behavioral of uart_rx is

    -- returns 1 if number of 1's in DATA is odd, otherwise returns 0
    function popcount(DATA : std_logic_vector(DATA_BITS_NR-1 downto 0)) return std_logic is
        variable count : std_logic := '0';
    begin
        for i in 0 to DATA_BITS_NR-1 loop
            count := count xor DATA(i);
        end loop;
        return count;
    end function;

    type STATE is (IDLE, START_BIT, DATA_BITS, PARITY_BIT, STOP_BIT);
    signal rx_state : STATE := IDLE;
    signal clk_count : integer range 0 to CLKDIV-1 := 0;
    signal bit_index : integer range 0 to DATA_BITS_NR-1 := 0;
    signal DATA_RX_internal : std_logic_vector(DATA_BITS_NR-1 downto 0);
    signal parity_valid : std_logic := '0';

begin

    DATA_RX <= DATA_RX_internal;

    process(CLK)
    begin
        if (rising_edge(CLK)) then

            if (RST = '0') then
                clk_count <= 0;
                bit_index <= 0;
                rx_state <= IDLE;
            else
                clk_count <= clk_count + 1;
                case rx_state is

                    when IDLE =>
                        clk_count <= 0;
                        bit_index <= 0;
                        if (DIN = '0') then
                            rx_state <= START_BIT;
                        end if;

                    when START_BIT =>
                        if (clk_count >= (CLKDIV/2)) then
                            clk_count <= 0;
                            rx_state <= DATA_BITS;
                        elsif (DIN /= '0') then
                            rx_state <= IDLE; -- Glitch in Start Bit
                        end if;

                    when DATA_BITS =>
                        if (clk_count = CLKDIV-1) then
                            DATA_RX_internal(bit_index) <= DIN;
                            if (bit_index < DATA_BITS_NR-1) then
                                bit_index <= bit_index + 1;
                            else
                                bit_index <= 0;
                                if (PARITY = "00") then
                                    rx_state <= STOP_BIT;
                                else
                                    rx_state <= PARITY_BIT;
                                end if;
                            end if;
                            clk_count <= 0;
                        end if;

                    when PARITY_BIT =>
                        if (clk_count = CLKDIV-1) then
                            parity_valid <= (popcount(DATA_RX_internal) and PARITY(1)) or (not(popcount(DATA_RX_internal)) and PARITY(0));
                            clk_count <= 0;
                            rx_state <= STOP_BIT;
                        end if;

                    when STOP_BIT =>
                        if (clk_count = CLKDIV-1) then
                            if (bit_index = STOP_BITS_NR-1) then
                                rx_state <= IDLE;
                                DATA_VALID <= parity_valid and DIN;
                            else
                                bit_index <= bit_index+1;
                                clk_count <= 0;
                                parity_valid <= parity_valid and DIN;
                            end if;
                        end if;
                    when others =>
                            rx_state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end behavioral;

