library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity uart_tb is
end uart_tb;

architecture behavioral of uart_tb is

    component uart_tx
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
    end component;

    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal enable : std_logic := '0';
    signal char : std_logic_vector(7 downto 0);
    signal ready : std_logic;
    signal dout : std_logic;
begin

    uart_tx1 : uart_tx
        generic map (
            PARITY => "00",
            STOP_BITS_NR => 1
        )
        port map (
            CLK => clk,
            RST => rst,
            EN  => enable,
            DATA_TX => char,
            RDY  => ready,
            DOUT => dout
            );

    process
    begin
        wait for 10 ns;
        clk <= not clk;
    end process;

    process
    begin
        wait for 30 ns;
        rst <= '0';
        wait for 30 ns;
        rst <= '1';
        wait for 100 ns;
        wait until rising_edge(clk);
        char <= x"AF";
        enable <= '1';
        wait until rising_edge(clk);
        enable <= '0';

        wait until rising_edge(ready);
        report "Testbench ended!" severity note;

        wait for 200 ns;

    end process;

end behavioral;

