--------------------------------------------------------------
-- some related references:
--   https://www.kth.se/social/files/5458faeef276544021bdf437/codelockVHDL_eng.pdf
--   https://www.fpga4student.com/2017/09/seven-segment-led-display-controller-basys3-fpga.html
--   https://digilent.com/reference/programmable-logic/basys-3/demos/gpio
--   https://forum.digikey.com/t/debounce-logic-circuit-vhdl/12573
--   https://vhdlwhiz.com/finite-state-machine/
--   https://stackoverflow.com/questions/37035461/is-the-use-of-rising-edge-on-non-clock-signal-bad-practice-are-there-alternativ
--   https://www.fpga4student.com/2017/09/seven-segment-led-display-controller-basys3-fpga.html
--------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity fsm is
    Port (clk     : in std_logic;
          seg     : out std_logic_vector(6 downto 0);
          an      : out std_logic_vector(3 downto 0);
          btnC    : in std_logic_vector(0 downto 0) -- to match debouncer instantiation, which is a vector type
          );
end fsm;

architecture Behavioral of fsm is
    component debouncer
        Generic(
            DEBNC_CLOCKS : integer;
            PORT_WIDTH : integer);
        Port(
            SIGNAL_I : in std_logic_vector(0 downto 0); -- just 1 element, but it's a vector type
            CLK_I : in std_logic;          
            SIGNAL_O : out std_logic_vector(0 downto 0)); -- just 1 element, but it's a vector type
    end component;
    
    signal btn_d     : std_logic_vector(0 downto 0); -- to match debouncer instantiation
    signal btn_d_d   : std_logic := '0'; 
    signal btn_d_re  : std_logic;
    
    signal sevsegval : integer range 0 to 3 := 0;
    
    type tState is (zero, one, two, three); -- to show that the enumerated states can be arbitrary names
    signal state_t0, state_t1: tState;
begin
    -- 7-seg circuit here
    -- see mapping in: https://www.fpga4student.com/2017/09/seven-segment-led-display-controller-basys3-fpga.html
    an <= "1110"; -- just using one 7-seg, the rest are blanked (the anode being =1 blanks that 7-seg, see link above)
    
    -- these 7-bit arrangements on the left of the "when" statements correspond to lines (cathodes) on the display
    -- so by setting those values, you're drawing on the 7-segment display (7-seg --> 7-bits)
    -- 0 activates and 1 deactivates a line. See the fpga4student link above for an illustration
    with sevsegval select
        seg <= "1000000" when 0,
               "1111001" when 1,
               "0100100" when 2,
               "0110000" when 3,
               "1111111" when others;

    -- debounce the btn signal to btn_d here
    -- see the debouncer.vhd source file for more info
    debounce_module: debouncer 
        generic map(
            DEBNC_CLOCKS => (2**16), -- this number X the clock period (10 ns) makes approx. a 0.655 ms debouncing period
            PORT_WIDTH => 1) -- just 1 button
        port map(SIGNAL_I => btnC, CLK_I => clk, SIGNAL_O => btn_d);
    
    -- computing next state circuit here 
    -- note that the circuit state changes with the button rising edge, not button=1
    -- this is done for stability
    state_machine: process(state_t0, btn_d, clk)
    begin
        case state_t0 is
            when zero  => if btn_d_re = '1' then state_t1 <= one; else state_t1 <= zero; end if;
            when one   => if btn_d_re = '1' then state_t1 <= two; else state_t1 <= one; end if;
            when two   => if btn_d_re = '1' then state_t1 <= three; else state_t1 <= two; end if;
            when three => if btn_d_re = '1' then state_t1 <= zero; else state_t1 <= three; end if;
        end case;
    end process;
    
    -- circuit progressing states and sevent segment with clock tick here
    -- this is the clocked part, the button rising edge is also computed here
    -- see the stackoverflow link at the file header as to why we didn't use rising_edge() for this and manually computed it 
    state_change: process(clk)
    begin
        if rising_edge(clk) then
            btn_d_d <= btn_d(0);
            
            state_t0 <= state_t1;
            if(state_t0 = zero) then sevsegval <= 0;
            elsif (state_t0 = one) then sevsegval <= 1;
            elsif (state_t0 = two) then sevsegval <= 2;
            elsif (state_t0 = three) then sevsegval <= 3;
            end if;
        
        end if;
        btn_d_re <= not btn_d_d and btn_d(0);
    end process;

end Behavioral;
