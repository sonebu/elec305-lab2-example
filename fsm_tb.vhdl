library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm_tb is
end fsm_tb;

architecture Behavioral of fsm_tb is
    component fsm
       Port (clk  : in std_logic;
             seg  : out std_logic_vector(6 downto 0);
             an   : out std_logic_vector(3 downto 0);
             btnC : in std_logic_vector(0 downto 0)
             );
    end component;
    signal clk_tb  : std_logic;
    signal seg_tb  : std_logic_vector(6 downto 0);
    signal an_tb   : std_logic_vector(3 downto 0);
    signal btnC_tb : std_logic_vector(0 downto 0);
begin

    dut: entity work.fsm port map (clk => clk_tb, seg => seg_tb, an => an_tb, btnC => btnC_tb);
    
    clk_process :process
    begin
        clk_tb <= '0';
        wait for 5 ns;
        clk_tb <= '1';
        wait for 5 ns;
    end process;
    
    sim_process: process
    begin
        btnC_tb(0) <= '0';
        wait for 100 us;

        -- short pulse, shouldn't work
        btnC_tb(0) <= '1';
        wait for 200 us;
        btnC_tb(0) <= '0';
        wait for 500 us;

        -- short pulse, glitch, then another short pulse
        -- together they should have worked, but due to the glitch in between they shouldn't
        btnC_tb(0) <= '1';
        wait for 350 us;
        btnC_tb(0) <= '0';
        wait for 10 us;
        btnC_tb(0) <= '1';
        wait for 350 us;
        btnC_tb(0) <= '0';
        wait for 700 us;

        -- long pulse, should work, state should go from "zero" to "one"
        btnC_tb(0) <= '1';
        wait for 700 us;
        btnC_tb(0) <= '0';
        wait for 500 us;

        -- now state transition test
        btnC_tb(0) <= '1'; -- this will not work !! because the debouncing period works both ways, we should have waited approx. 150 ms more for this.
        wait for 1 ms;
        btnC_tb(0) <= '0';
        wait for 1 ms;
        
        btnC_tb(0) <= '1'; -- now this will work, state from "one" to "two" 
        wait for 1 ms;
        btnC_tb(0) <= '0';
        wait for 1 ms;
        btnC_tb(0) <= '1'; -- state from "two" to "three" 
        wait for 1 ms;
        btnC_tb(0) <= '0'; -- state from "three" to "zero"
        wait for 1 ms;
        btnC_tb(0) <= '1'; -- state from "zero" to "one"
        wait for 1 ms;
        btnC_tb(0) <= '0';
        wait for 1 ms;

        -- now long press test
        btnC_tb(0) <= '1'; -- state from "one" to "two"
        wait for 10 ms;
        btnC_tb(0) <= '0';        
        wait;
    end process;

end Behavioral;
