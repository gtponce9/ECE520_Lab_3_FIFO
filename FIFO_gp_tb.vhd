library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;


entity FIFO_gp_tb is
end FIFO_gp_tb;

architecture Behavioral of FIFO_gp_tb is

    component FIFO_gp is
        generic (
            WIDTH                  : natural;
            DEPTH                  : natural;
            ALMOST_FULL_THRESHOLD  : natural;
            ALMOST_EMPTY_THRESHOLD : natural;
            READ_LATENCY           : natural
        );
        port (
            clk          : in  std_logic;
            srst         : in  std_logic;
            data_in      : in  std_logic_vector(WIDTH-1 downto 0);
            write_enable : in  std_logic;
            read_enable  : in  std_logic;
            data_count   : out std_logic_vector(5 downto 0);
            valid        : out std_logic;
            data_out     : out std_logic_vector(WIDTH-1 downto 0);
            almost_full  : out std_logic;
            almost_empty : out std_logic;
            full         : out std_logic;
            empty        : out std_logic
        );
    end component;

    constant WIDTH        : natural := 16;
    constant DEPTH        : natural := 32;
    constant READ_LATENCY : natural := 1;
    constant CLK_PERIOD   : time    := 20 ns; -- 50MHz Clock
    constant FILE_NAME    : string  := "input.txt";

    signal clk          : std_logic := '0';
    signal srst         : std_logic := '1';   -- reset starts asserted
    signal data_in      : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal write_enable : std_logic := '0';
    signal read_enable  : std_logic := '0';
    signal data_count   : std_logic_vector(5 downto 0);  -- ceil(log2(33)) = 6 bits
    signal valid        : std_logic;
    signal data_out     : std_logic_vector(WIDTH-1 downto 0);
    signal almost_full  : std_logic;
    signal almost_empty : std_logic;
    signal full         : std_logic;
    signal empty        : std_logic;


    type value_array is array (natural range <>) of std_logic_vector(WIDTH-1 downto 0);

    -- Count how many valid lines (two hex bytes) the file contains
    -- the impure function allows the value that are read to be different - the function changes output based on the text file - hence impure
    impure function count_words return natural is
        file f      : text open read_mode is FILE_NAME;
        variable l  : line;
        variable b1 : std_logic_vector(7 downto 0);
        variable b2 : std_logic_vector(7 downto 0);
        variable g1 : boolean;
        variable g2 : boolean;
        variable n  : natural := 0;
    begin
        while not endfile(f) loop
            readline(f, l);
            hread(l, b1, g1);
            hread(l, b2, g2);
            if g1 and g2 then
                n := n + 1;
            end if;
        end loop;
        return n;
    end function;

    constant NUM_WORDS : natural := count_words;

    -- Read the file into an array
    impure function load_words return value_array is
        file f      : text open read_mode is FILE_NAME;
        variable l  : line;
        variable b1 : std_logic_vector(7 downto 0);
        variable b2 : std_logic_vector(7 downto 0);
        variable g1 : boolean;
        variable g2 : boolean;
        variable n  : natural := 0;
        variable r  : value_array(0 to NUM_WORDS-1);
    begin
        while not endfile(f) loop
            readline(f, l);
            hread(l, b1, g1);
            hread(l, b2, g2);
            if g1 and g2 then
                r(n) := b1 & b2;
                n := n + 1;
            end if;
        end loop;
        return r;
    end function;

    -- The values we write, and expect to read back in the same order
    constant TEST_VALUES : value_array(0 to NUM_WORDS-1) := load_words;

begin

    -- Device under test
    DUT : FIFO_gp
        generic map (
            WIDTH                  => WIDTH,
            DEPTH                  => DEPTH,
            ALMOST_FULL_THRESHOLD  => 31,
            ALMOST_EMPTY_THRESHOLD => 1,
            READ_LATENCY           => READ_LATENCY
        )
        port map (
            clk          => clk,
            srst         => srst,
            data_in      => data_in,
            write_enable => write_enable,
            read_enable  => read_enable,
            data_count   => data_count,
            valid        => valid,
            data_out     => data_out,
            almost_full  => almost_full,
            almost_empty => almost_empty,
            full         => full,
            empty        => empty
        );
-- 50MHz clock - indefinite
    clk_process : process
    begin
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus
    stim_process : process
    begin
        -- Reset asserted for the first 5 clock cycles
        srst <= '1';
        for i in 1 to 5 loop
            wait until rising_edge(clk);
        end loop;
        srst <= '0';

        -- Write all values (one per clock cycle)
        for i in 0 to NUM_WORDS-1 loop
            wait until rising_edge(clk);
            write_enable <= '1';
            data_in      <= TEST_VALUES(i);
        end loop;
        wait until rising_edge(clk);
        write_enable <= '0';

        -- Wait a couple of cycles so data_count can be seen at NUM_WORDS
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Read all values back (one per clock cycle)
        read_enable <= '1';
        for i in 0 to NUM_WORDS-1 loop
            wait until rising_edge(clk);
        end loop;
        read_enable <= '0';

        -- Let the output pipeline flush (wait 5 clock cycles)
        for i in 1 to 5 loop
            wait until rising_edge(clk);
        end loop;

 -- Manually write three values from the table
        wait until rising_edge(clk);
        write_enable <= '1';
        data_in      <= TEST_VALUES(0);

        wait until rising_edge(clk);
        data_in      <= TEST_VALUES(1);

        wait until rising_edge(clk);
        data_in      <= TEST_VALUES(2);
        
        wait until rising_edge(clk);    
        write_enable <= '0';


        -- Wait a couple of cycles so data_count can be seen at 3
        wait until rising_edge(clk);
        wait until rising_edge(clk);

        -- Assert reset for 5 clock cycles while the FIFO still holds data
        srst <= '1';
        for i in 1 to 5 loop
            wait until rising_edge(clk);
        end loop;
        srst <= '0';
        wait;
    end process;

    -- Checker: whenever valid is high, data_out must match the next expected value
    check_process : process (clk)
        variable idx : natural := 0;
    begin
        if rising_edge(clk) then
            if valid = '1' then
                assert idx < NUM_WORDS
                    report "Received more than " & integer'image(NUM_WORDS) & " values!" severity error;
                if idx < NUM_WORDS then
                    assert data_out = TEST_VALUES(idx)
                        report "Data mismatch on read " & integer'image(idx)
                        severity error;
                    report "Read " & integer'image(idx) & " OK";
                end if;
                idx := idx + 1;
            end if;
        end if;
    end process;

end Behavioral;