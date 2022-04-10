LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;  
USE IEEE.NUMERIC_STD.ALL;


ENTITY Counter IS
	GENERIC(
	BUSWIDTH: integer :=15;
	INITIALVALUE: integer:=12000
	);
	PORT (
	INC: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic;
	CNT: OUT std_logic_vector(BusWidth-1 DOWNTO 0));
END Counter;	  

ARCHITECTURE Behavioral OF Counter IS
SIGNAL Cn, Cp: integer:=INITIALVALUE;
BEGIN 
	
	Combinational:PROCESS(Cp, INC)
	BEGIN 	   
		
		IF INC='1' THEN
			Cn<=Cp+1;	
		ELSE 
			Cn<=Cp;	
		END IF;
		CNT<=std_logic_vector(to_unsigned(Cp,CNT'LENGTH));	
		
	END PROCESS Combinational;
	
	
	Sequential:PROCESS(CLK,RST)
	BEGIN
		IF RST='0' THEN 
			Cp<=INITIALVALUE;
		ELSIF CLK'event AND CLK='1' THEN
			Cp<=Cn;
		END IF;
	END PROCESS Sequential;

END Behavioral;
