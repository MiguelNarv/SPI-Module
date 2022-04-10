LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;	
use IEEE.NUMERIC_STD.ALL;

ENTITY SPISCK IS
	GENERIC(   
	CLKF: integer:=100000000; --[Hz]
	SCKF: integer:=1000000; --[Hz]
	POL: integer:=1;	-- 0,1 
	CICLES: integer:=13
	);
	PORT(
	STR: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic;
	RDY: OUT std_logic;
	SCK: OUT std_logic
	);
	
END ENTITY SPISCK;


ARCHITECTURE Structural OF SPISCK IS

COMPONENT LatchSR IS
	PORT (
	SET: IN std_logic;
	CLR: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic;
    SOUT: OUT std_logic );
END COMPONENT;

COMPONENT Timer IS
	GENERIC(
	TICKS: integer:=10;
	BUSWIDTH: integer:=4
	);
	PORT(
	RST: IN std_logic;
	CLK: IN std_logic;
	SYN: OUT std_logic
	);
END COMPONENT;

COMPONENT Toggle IS
	PORT(
	TOG: in std_logic; 
	RST: in std_logic;
	CLK: in std_logic;  
	TGS: out std_logic  
	);
END COMPONENT;

COMPONENT Counter IS 
	GENERIC(
	BUSWIDTH: integer :=15;
	INITIALVALUE: integer:=12000
	);
	PORT (
	INC: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic;
	CNT: OUT std_logic_vector(BusWidth-1 DOWNTO 0));
END COMPONENT;

SIGNAL START, Pus, CLR, SCKs: std_logic:='0';  
SIGNAL CNT: std_logic_vector(integer(log2(real(CICLES)))+1 DOWNTO 0):=(OTHERS=>'0');
BEGIN	
	
	SCK<= SCKs WHEN POL=0 ELSE
		  NOT SCKs;
	
	CLR<= '1' WHEN CNT=std_logic_vector(to_unsigned(CICLES*2, CNT'LENGTH)) ELSE
		'0';		
	
	RDY<= CLR;
 	
	U1: LatchSR PORT MAP(SET=>STR, CLR=>CLR, RST=>RST, CLK=>CLK, SOUT=>START);
	U2: Timer GENERIC MAP(TICKS=>(CLKF/(2*SCKF))-1, BUSWIDTH=>integer(log2(real(CLKF/SCKF)))+1) PORT MAP(RST=>START, CLK=>CLK, SYN=>Pus);
	U3: Counter GENERIC MAP(BUSWIDTH=>integer(log2(real(CICLES)))+2, INITIALVALUE=>0) PORT MAP(INC=>Pus, RST=>START, CLK=>CLK, CNT=>CNT);
	U4: Toggle PORT MAP(TOG=>Pus, RST=>START, CLK=>CLK, TGS=>SCKs);
	
END ARCHITECTURE Structural;
