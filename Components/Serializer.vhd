LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;


ENTITY Serializer IS  
	GENERIC(
		BUSWIDTH: integer:=8	 
		);
	PORT (
		RST: IN std_logic;
		CLK: IN std_logic;
		LDR: IN std_logic;
		SHF: IN std_logic;
        DIN: IN std_logic_vector(BUSWIDTH-1 DOWNTO 0);
		BOUT: OUT std_logic_vector(BUSWIDTH-1 DOWNTO 0)
		);
END Serializer;

ARCHITECTURE Behavioral OF Serializer IS	 
SIGNAL Qn, Qp: std_logic_vector(BUSWIDTH-1 DOWNTO 0);
BEGIN 	
	
	
	Combinational:PROCESS(Qp, LDR, DIN, SHF)
	BEGIN
		
		IF LDR='1' THEN
			Qn<=DIN;
		ELSIF SHF ='1' THEN
			Qn<= Qp(BUSWIDTH-2 DOWNTO 0) & '0';
		ELSE
			Qn<=Qp;
		END IF;
		
		BOUT<=Qp;  
		
	END PROCESS;
	
	
	Sequential:PROCESS(CLK,RST)	
	
	BEGIN	  
		
		IF RST='0' THEN
		
			Qp<=(others=>'0');	 
		
		ELSIF CLK'event AND CLK='1' THEN   
			
			Qp<=Qn;
		
		END IF;
		
	END PROCESS Sequential;

	
	
END Behavioral;	  

