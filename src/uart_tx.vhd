----------------------------------------------------------------------------------
-- Created by: Robin Staub
--
-- Create Date:    01-04-2022
-- Design Name:
-- Module Name:    uart_tx
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
-- TODO: (flow control? RTS/CTS), FIFO?, WBL/APB interface? --> top entity
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;


entity uart_tx is
    generic(
        CLKDIV          : integer := 278;                       -- CLK Frequency divided by Baudrate
        DATA_BITS_NR    : integer := 8;                         -- Number of data bits per transfer (5 to 9)
        STOP_BITS_NR    : integer := 1;                         -- Can be 1 or 2
        PARITY          : std_logic_vector(1 downto 0) := "00"  -- 0: no parity, 1: odd parity, 2: even parity
    );
    port(
        CLK             : in    std_logic;
        RST             : in    std_logic;
        EN              : in    std_logic;
        DATA_TX         : in    std_logic_vector(DATA_BITS_NR-1 downto 0);

        RDY             : out   std_logic;
        DOUT            : out   std_logic
);
end uart_tx;

architecture behavioral of uart_tx is

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
    signal tx_state : STATE := IDLE;
    signal clk_count : integer range 0 to CLKDIV;
    signal bit_index : integer range 0 to DATA_BITS_NR-1;
    signal DATA_TX_internal   : std_logic_vector(DATA_BITS_NR-1 downto 0);

begin

    process(CLK)
    begin
        if (rising_edge(CLK)) then

            if (RST = '0') then
                clk_count <= 0;
                bit_index <= 0;
                tx_state <= IDLE;
            else
                clk_count <= clk_count + 1;
                case tx_state is

                    when IDLE =>
                        clk_count <= 0;
                        bit_index <= 0;
                        DOUT <= '1';
                        RDY <= '1';
                        if (EN = '1') then
                            DATA_TX_internal <= DATA_TX;    -- register DATA_TX for stable signal during transmit
                            tx_state <= START_BIT;
                        end if;

                    when START_BIT =>
                        DOUT <= '0';
                        RDY <= '0';
                        if (clk_count = (CLKDIV-1)) then
                            clk_count <= 0;
                            tx_state <= DATA_BITS;
                        end if;

                    when DATA_BITS =>
                        DOUT <= DATA_TX_internal(bit_index);
                        if (clk_count = (CLKDIV-1)) then
                            if (bit_index < DATA_BITS_NR-1) then
                                bit_index <= bit_index + 1;
                            else
                                bit_index <= 0;
                                if (PARITY = "00") then
                                    tx_state <= STOP_BIT;
                                else
                                    tx_state <= PARITY_BIT;
                                end if;
                            end if;
                            clk_count <= 0;
                        end if;

                    when PARITY_BIT =>
                        DOUT <= (popcount(DATA_TX_internal) and PARITY(1)) or (not(popcount(DATA_TX_internal)) and PARITY(0));
                        if (clk_count = (CLKDIV-1)) then
                            clk_count <= 0;
                            tx_state <= STOP_BIT;
                        end if;

                    when STOP_BIT =>
                        DOUT <= '1';
                        if (clk_count = (CLKDIV-1)) then
                            if (bit_index = STOP_BITS_NR-1) then
                                tx_state <= IDLE;
                            else
                                bit_index <= bit_index+1;
                            end if;
                        clk_count <= 0;
                        end if;
                    when others =>
                            tx_state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end behavioral;

