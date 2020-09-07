library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;

entity Processor is
	port(clk:in std_logic;
		 switch:in std_logic;
		 an:out std_logic_vector(3 downto 0);
		 seg:out std_logic_vector(6 downto 0));
end Processor;

architecture Behavioral of Processor is

	type reg_type is array(0 to 31)of std_logic_vector(31 downto 0);
	signal reg:reg_type:=(others=>(others=>'0'));

    signal ena:std_logic:='1';
    signal wea:std_logic_vector(0 downto 0):="0";
    signal addra:std_logic_vector(11 downto 0):=(others=>'0');
    signal dina:std_logic_vector(31 downto 0):=(others=>'0');
    signal douta:std_logic_vector(31 downto 0):=(others=>'0');

	component blk_mem_gen_0 is
      port(
        clka:in std_logic;
        ena:in std_logic;
        wea:in std_logic_vector(0 downto 0);
        addra:in std_logic_vector(11 downto 0);
        dina:in std_logic_vector(31 downto 0);
        douta:out std_logic_vector(31 downto 0));
	end component;

	signal rt_copy:std_logic_vector(4 downto 0):=(others=>'0');
    signal rd_copy:std_logic_vector(4 downto 0):=(others=>'0');
	signal state:integer:=0;
    signal i:integer:=0;
    signal k:integer:=0;
	signal value:std_logic_vector(15 downto 0):=(others=>'0');
	signal counter:std_logic_vector(19 downto 0):=(others=>'0');
	signal position:std_logic_vector(1 downto 0):=(others=>'0');
	signal digit:std_logic_vector(3 downto 0):=(others=>'0');

begin

    mem:blk_mem_gen_0 port map(clka=>clk,ena=>ena,wea=>wea,addra=>addra,dina=>dina,douta=>douta);
	position<=counter(19 downto 18);
	addra<=std_logic_vector(to_unsigned(i,12))when(state=0)else
	       std_logic_vector(to_unsigned(i-1,12))when((state=1) and (douta="00000000000000000000000000000000"))else
           std_logic_vector(to_unsigned(i,12))when((state=1) and (douta(31 downto 26)="000000") and (douta(5 downto 0)="100000"))else--add
           std_logic_vector(to_unsigned(i,12))when((state=1) and (douta(31 downto 26)="000000") and (douta(5 downto 0)="100010"))else--sub
           std_logic_vector(to_unsigned(i,12))when((state=1) and (douta(31 downto 26)="000000") and (douta(25 downto 6)/="00000000000000000000") and (douta(5 downto 0)="000000"))else--sll
           std_logic_vector(to_unsigned(i,12))when((state=1) and (douta(31 downto 26)="000000") and (douta(5 downto 0)="000010"))else--srl
           reg(to_integer(unsigned(douta(25 downto 21))))(11 downto 0)when((state=1) and (douta(31 downto 26)="000000") and (douta(5 downto 0)="001000"))else--jr
           std_logic_vector(to_unsigned(((to_integer(unsigned(reg(to_integer(unsigned(douta(25 downto 21)))))))+(to_integer(signed(douta(15 downto 0))))),12))when((state=1) and (douta(31 downto 26)="100011"))else--lw
           std_logic_vector(to_unsigned(((to_integer(unsigned(reg(to_integer(unsigned(douta(25 downto 21)))))))+(to_integer(signed(douta(15 downto 0))))),12))when((state=1) and (douta(31 downto 26)="101011"))else--sw
           douta(11 downto 0)when((state=1) and (douta(31 downto 26)="000010"))else--j
           douta(11 downto 0)when((state=1) and (douta(31 downto 26)="000011"))else--jal
           douta(11 downto 0)when((state=1) and (douta(31 downto 26)="000100") and (reg(to_integer(unsigned(douta(25 downto 21))))=reg(to_integer(unsigned(douta(20 downto 16))))))else--beq
           douta(11 downto 0)when((state=1) and (douta(31 downto 26)="000101") and (reg(to_integer(unsigned(douta(25 downto 21))))/=reg(to_integer(unsigned(douta(20 downto 16))))))else--bne
           douta(11 downto 0)when((state=1) and (douta(31 downto 26)="000110") and (reg(to_integer(unsigned(douta(25 downto 21))))(31)='1' or reg(to_integer(unsigned(douta(25 downto 21))))=reg(0)))else--blez
           douta(11 downto 0)when((state=1) and (douta(31 downto 26)="000111") and (reg(to_integer(unsigned(douta(25 downto 21))))(31)='0' and reg(to_integer(unsigned(douta(25 downto 21))))/=reg(0)))else--bgtz
           std_logic_vector(to_unsigned(i,12))when(state=2)else
           std_logic_vector(to_unsigned(i-1,12))when(state=3)else
           std_logic_vector(to_unsigned(i,12));
    wea<="1"when((state=1) and (douta(31 downto 26)="101011"))else--sw
         "0";
    dina<=reg(to_integer(unsigned(douta(20 downto 16))))when((state=1) and (douta(31 downto 26)="101011"))else--sw
          "00000000000000000000000000000000";

	process(clk)
		variable j:integer:=0;
	begin
		if(clk='1')and clk'event then
			if(state=0)then
    	        k<=k+1;
    	        reg(29)<="00000000000000000001000000000000";
				i<=i+1;
				state<=1;
   			elsif(state=1)then
    	        k<=k+1;
				rt_copy<=douta(20 downto 16);
				rd_copy<=douta(15 downto 11);
				if(douta(31 downto 0)="00000000000000000000000000000000")then
					state<=3;
					k<=k;
					if(j=2)then
						value<=reg(to_integer(unsigned(rd_copy)))(15 downto 0);
					else
						value<=reg(to_integer(unsigned(rt_copy)))(15 downto 0);
					end if;
				elsif(douta(31 downto 26)="000000")then
					if(douta(5 downto 0)="100000")then--add
						j:=2;
                        reg(to_integer(unsigned(douta(15 downto 11))))<=std_logic_vector(signed(reg(to_integer(unsigned(douta(25 downto 21)))))+signed(reg(to_integer(unsigned(douta(20 downto 16))))));
                        i<=i+1;
					elsif(douta(5 downto 0)="100010")then--sub
						j:=2;
                        reg(to_integer(unsigned(douta(15 downto 11))))<=std_logic_vector(signed(reg(to_integer(unsigned(douta(25 downto 21)))))-signed(reg(to_integer(unsigned(douta(20 downto 16))))));
                        i<=i+1;
					elsif(douta(5 downto 0)="000000")then--sll
						j:=2;
                        reg(to_integer(unsigned(douta(15 downto 11))))<=std_logic_vector(shift_left(unsigned(reg(to_integer(unsigned(douta(20 downto 16))))),to_integer(unsigned(douta(10 downto 6)))));
                        i<=i+1;
					elsif(douta(5 downto 0)="000010")then--srl
						j:=2;
                        reg(to_integer(unsigned(douta(15 downto 11))))<=std_logic_vector(shift_right(unsigned(reg(to_integer(unsigned(douta(20 downto 16))))),to_integer(unsigned(douta(10 downto 6)))));
                        i<=i+1;
                    elsif(douta(5 downto 0)="001000")then--jr
                        i<=to_integer(signed(reg(to_integer(unsigned(douta(25 downto 21))))))+1;
					end if;
 				elsif(douta(31 downto 26)="100011")then--lw
					j:=0;
 				    state<=2;
				elsif(douta(31 downto 26)="101011")then--sw
					j:=1;
				    state<=2;
                elsif(douta(31 downto 26)="000010")then--j
                    i<=to_integer(unsigned(douta(11 downto 0)))+1;
                elsif(douta(31 downto 26)="000011")then--jal
                    i<=to_integer(unsigned(douta(11 downto 0)))+1;
                    reg(31)<=std_logic_vector(to_unsigned(i,32));
                elsif(douta(31 downto 26)="000100")then--beq
                    if(reg(to_integer(unsigned(douta(25 downto 21))))=reg(to_integer(unsigned(douta(20 downto 16)))))then
                        i<=to_integer(unsigned(douta(11 downto 0)))+1;
                    else i<=i+1;
                    end if;
                elsif(douta(31 downto 26)="000101")then--bne
                    if (reg(to_integer(unsigned(douta(25 downto 21))))=reg(to_integer(unsigned(douta(20 downto 16))))) then
                        i<=i+1;
                    else
                        i<=to_integer(unsigned(douta(11 downto 0)))+1;
                    end if;
                elsif(douta(31 downto 26)="000110")then--blez
                    if (reg(to_integer(unsigned(douta(25 downto 21))))(31)='1' or reg(to_integer(unsigned(douta(25 downto 21))))=reg(0)) then
                        i<=to_integer(unsigned(douta(11 downto 0)))+1;
                    else i<=i+1;
                    end if;
                elsif(douta(31 downto 26)="000111")then--bgtz
                    if (reg(to_integer(unsigned(douta(25 downto 21))))(31)='0' and reg(to_integer(unsigned(douta(25 downto 21))))/=reg(0)) then
                        i<=to_integer(unsigned(douta(11 downto 0)))+1;
                    else i<=i+1;
                    end if;
                end if;
			elsif(state=2)then
				k<=k+1;
				if(j=0)then--lw
                    reg(to_integer(unsigned(rt_copy)))<=douta;
				end if;
				i<=i+1;
				state<=1;
			end if;
		end if;
	end process;

	process(digit)
    begin
        case digit is
			when"0000"=>seg<="0000001";--"0"
	        when"0001"=>seg<="1001111";--"1"
	        when"0010"=>seg<="0010010";--"2"
	        when"0011"=>seg<="0000110";--"3"
	        when"0100"=>seg<="1001100";--"4"
	        when"0101"=>seg<="0100100";--"5"
	        when"0110"=>seg<="0100000";--"6"
	        when"0111"=>seg<="0001111";--"7"
	        when"1000"=>seg<="0000000";--"8"
	        when"1001"=>seg<="0000100";--"9"
	        when"1010"=>seg<="0001000";--"A"
	        when"1011"=>seg<="1100000";--"B"
	        when"1100"=>seg<="0110001";--"C"
	        when"1101"=>seg<="1000010";--"D"
	        when"1110"=>seg<="0110000";--"E"
	        when others=>seg<="0111000";--"F"
        end case;
    end process;

    process(clk)
    begin
        if(clk='1')and clk'event then
            counter<=std_logic_vector(to_unsigned(to_integer(unsigned(counter)+1),20));-- counter+1;
        end if;
    end process;

    process(position)
        variable key: std_logic_vector(15 downto 0):=std_logic_vector(to_unsigned(k,16));
    begin
        case position is
	        when"11"=>
	            an<="0111";
				if(switch='0')then
	            	digit<=value(15 downto 12);
				else
					digit<=key(15 downto 12);
				end if;
	        when"10"=>
	            an<="1011";
				if(switch='0')then
	            	digit<=value(11 downto 8);
				else
					digit<=key(11 downto 8);
				end if;
	        when"01"=>
	            an<="1101";
				if(switch='0')then
	            	digit<=value(7 downto 4);
				else
					digit<=key(7 downto 4);
				end if;
	        when others=>
	            an<="1110";
				if(switch='0')then
	            	digit<=value(3 downto 0);
				else
					digit<=key(3 downto 0);
				end if;
        end case;
    end process;

end Behavioral;
