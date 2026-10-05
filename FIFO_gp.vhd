


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;



entity FIFO_gp is
generic (
    WIDTH: natural := 16;
    DEPTH: natural := 32;
    ALMOST_FULL_THRESHOLD : natural := 31;
    ALMOST_EMPTY_THRESHOLD: natural := 1;
    READ_LATENCY: natural:= 1
);
    Port ( clk : in STD_LOGIC;
           srst : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (WIDTH -1 downto 0); -- write data
           write_enable : in STD_LOGIC;
           read_enable : in STD_LOGIC;
           data_count : out STD_LOGIC_VECTOR;
           valid : out STD_LOGIC;
           data_out : out STD_LOGIC_VECTOR (WIDTH -1 downto 0); -- read data
           almost_full : out STD_LOGIC;
           almost_empty : out STD_LOGIC;
           full : out STD_LOGIC;
           empty : out STD_LOGIC);
end FIFO_gp;

architecture Behavioral of FIFO_gp is
 
    constant COUNT_WIDTH : natural := integer(ceil(log2(real(DEPTH+1))));
 
    -- 2D array: DEPTH words in the array, each WIDTH bits wide
    type FIFO_T is array (0 to DEPTH-1) of std_logic_vector(WIDTH-1 downto 0);
    signal FIFO_DATA : FIFO_T := (others => (others => '0'));
 
    -- Pointers are integers that wrap at DEPTH-1
    signal Write_Pointer : natural range 0 to DEPTH-1 := 0;
    signal Read_Pointer  : natural range 0 to DEPTH-1 := 0;
    signal Counter       : natural range 0 to DEPTH   := 0; --using this for the data_count
 
    -- Output pipeline: index 0 = baseline output register,
    -- indices 1..READ_LATENCY = additional stages
    type PIPE_T is array (0 to READ_LATENCY) of std_logic_vector(WIDTH-1 downto 0);
    signal data_pipe  : PIPE_T := (others => (others => '0'));
    signal valid_pipe : std_logic_vector(0 to READ_LATENCY) := (others => '0');
 
    signal full_i, empty_i : std_logic;
    signal do_write, do_read : std_logic;
 
begin
 
    -- Status flags (derived from registered count)
    full_i  <= '1' when Counter = DEPTH else '0';
    empty_i <= '1' when Counter = 0     else '0';
 
    -- Requests are ignored on overflow / underflow
    do_write <= write_enable and not full_i;
    do_read  <= read_enable  and not empty_i;
 
    full         <= full_i;
    empty        <= empty_i;
    almost_full  <= '1' when Counter >= ALMOST_FULL_THRESHOLD  else '0';
    almost_empty <= '1' when Counter <= ALMOST_EMPTY_THRESHOLD else '0';
    data_count   <= std_logic_vector(to_unsigned(Counter, COUNT_WIDTH));
 
    data_out <= data_pipe(READ_LATENCY);
    valid    <= valid_pipe(READ_LATENCY);
 
    process (clk)
    begin
        if rising_edge(clk) then
            if srst = '1' then
                Write_Pointer <= 0;
                Read_Pointer  <= 0;
                Counter       <= 0;
                valid_pipe    <= (others => '0');
            else
                -- WRITE
                if do_write = '1' then
                    FIFO_DATA(Write_Pointer) <= data_in;
                    if Write_Pointer = DEPTH-1 then
                        Write_Pointer <= 0;
                    else
                        Write_Pointer <= Write_Pointer + 1;
                    end if;
                end if;
 
                -- READ (baseline output register)
                valid_pipe(0) <= do_read;
                if do_read = '1' then
                    data_pipe(0) <= FIFO_DATA(Read_Pointer);
                    if Read_Pointer = DEPTH-1 then
                        Read_Pointer <= 0;
                    else
                        Read_Pointer <= Read_Pointer + 1;
                    end if;
                end if;
 
                -- Additional read-latency pipeline stages
                for i in 1 to READ_LATENCY loop
                    data_pipe(i)  <= data_pipe(i-1);
                    valid_pipe(i) <= valid_pipe(i-1);
                end loop;
 
                -- Word count (read + write together leaves it unchanged)
                if do_write = '1' and do_read = '0' then
                    Counter <= Counter + 1;
                elsif do_write = '0' and do_read = '1' then
                    Counter <= Counter - 1;
                end if;
            end if;
        end if;
    end process;
 
end Behavioral;
