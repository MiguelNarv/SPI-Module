library IEEE;
use IEEE.std_logic_1164.all;

entity Toggle is
	port(
	TOG: in std_logic; 
	RST: in std_logic;
	CLK: in std_logic;  
	TGS: out std_logic  
	);
end Toggle;

architecture Behavioral of Toggle is
signal Qn, Qp: std_logic:='0';

begin
	
	Combinational:process(TOG, Qp) is
	begin	  
		Qn<=Qp xor TOG;	
		TGS<=Qp;	
	end process Combinational;
	
	
	Sequential:process(CLK, RST) is
	begin
		if RST = '0' then
		Qp<='0';		
		elsif CLK'event and CLK='1' then
		Qp<=Qn;			  
		end if;
	end process Sequential;	
	
end Behavioral;