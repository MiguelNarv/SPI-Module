-----------------------------------------------------------------------------------------------------------------------	 

-- SPI module.
-- Miguel Gerardo Narváez González.
-- 10/04/22.	 

-- This file contains the SPI module. It includes SCK, MOSI, MISO and CS in a full duplex configuration.
-- If a new CS line is needed, it must be implemented independently of the module considering the STR input.
-- SPI parameters such as polarity, phase, SCK frequency, cicles and datawidth can be set in GENERIC.	
-- The components used in this file must be included in the project's folder.  

-----------------------------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
use IEEE.MATH_REAL.ALL;	
use IEEE.NUMERIC_STD.ALL;

ENTITY SPIModule IS
	GENERIC(   
	CLKF: integer:=100000000;		-- FPGA clock frequency [Hz].
	CLKT: integer:=10;			-- FPGA clock period [ns].
	SCKF: integer:=1000000; 		-- SCK desired frequency [Hz].
	POL: integer:=1;			-- Polarity 0, 1. 	 
	PHA: integer:=1;		  	-- Phase 0, 1.
	CICLES: integer:=8;			-- Number of cicles of SCK.
	DATAWIDTH: integer:=8			-- Datawidth of MISO and MOSI.
	);
	PORT(
	STR: IN std_logic;										-- Triggers the module (active high). 
	RST: IN std_logic;										-- Controls reset of the module (active low).
	CLK: IN std_logic; 										-- Clock net.
	RCVDATA: OUT std_logic_vector(DATAWIDTH-1 DOWNTO 0);						-- Data to receive from slave.
	MISO: IN std_logic;												
	RDY: OUT std_logic;										-- If low, SPI module is bussy.
	SCK: OUT std_logic;	 								
	Cs: OUT std_logic;	  									-- Chip select (active low).
	SNDDATA: IN std_logic_vector(DATAWIDTH-1 DOWNTO 0);						-- Data to send from master.
	MOSI: OUT std_logic 									
	);												  
	
END ENTITY SPIModule;


ARCHITECTURE Structural OF SPIModule IS

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

COMPONENT SPISCK IS
	GENERIC(   
	CLKF: integer:=100000000; 
	SCKF: integer:=1000000; 
	POL: integer:=0;	
	CICLES: integer:=8
	);
	PORT(
	STR: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic; 
	RDY: OUT std_logic;
	SCK: OUT std_logic
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

COMPONENT DelayFlipFlops IS
	GENERIC(
	DELAY: integer:= 332;	
	TCLK: integer:= 83	 
	);
	PORT (
	D: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic;
  	Q: OUT std_logic;
	Qn: OUT std_logic
	);
END COMPONENT; 

COMPONENT FallingEdgeDetector IS
	PORT (
	XIN: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic;
	XRE: OUT std_logic );
END COMPONENT;

COMPONENT RisingEdge IS
	PORT (
	XIN: IN std_logic;
	RST: IN std_logic;
	CLK: IN std_logic;
    XRE: OUT std_logic );
END COMPONENT; 

COMPONENT Serializer IS
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
END COMPONENT;	  

COMPONENT Deserializer IS
	GENERIC(
	BUSWIDTH: integer:=8	 
	);
	PORT (
	RST: IN std_logic;
	CLK: IN std_logic;
	SHF: IN std_logic;
    BIN: IN std_logic;
	DOUT: OUT std_logic_vector(BUSWIDTH-1 DOWNTO 0)
	);
END COMPONENT;

COMPONENT LoadFlipFlop IS
	GENERIC(
	BUSWIDTH: integer:=8	
	);
	PORT (
	RST: IN std_logic;
	CLK: IN std_logic;
	LDR: IN std_logic;
    DIN: IN std_logic_vector(BUSWIDTH-1 DOWNTO 0);
	DOUT: OUT std_logic_vector(BUSWIDTH-1 DOWNTO 0)
	);
END COMPONENT;

SIGNAL EA, STRDelayed, SCKs, FESCK, RESCK, Css, RDYCicles, Flips, Flip, RDYCiclesDelayed, Sample, LOAD, ILs: std_logic:='0'; 
SIGNAL BOUTs, DOUTs: std_logic_vector(DATAWIDTH-1 DOWNTO 0):=(OTHERS=>'0');


BEGIN	

	-- Demux control structures.
	EA <= FESCK WHEN POL=1 ELSE
		 RESCK;
	Flips <= FESCK WHEN PHA=POL ELSE		
		RESCK;
	Sample <= RESCK WHEN PHA=POL ELSE	 
		FESCK;	  
		

	-- Signal logic operations.
	Cs <= NOT Css;
	RDY <= NOT Css; 
	Flip <= Flips AND ILs;


	MOSI <= BOUTs((DATAWIDTH-1));
	SCK <= SCKs;
	

	

	-- STR start signal gets delayed 10 times the clock frequency, while activates U3 Latch at the same time.	
	U1: DelayFlipFlops GENERIC MAP(DELAY=>CLKT*10, TCLK=>CLKT) PORT MAP(D=>STR, RST=>RST, CLK=>CLK, Q=>STRDelayed, Qn=>OPEN);	
	
	-- STRDelayed activates the SCK generator. It outputs the pulses through SCKs. 
	-- Once the desired number of pulses has been achieved, RDYCicles is set to high.
	U2: SPISCK GENERIC MAP(CLKF=>CLKF, SCKF=>SCKF, POL=>POL, CICLES=>CICLES) PORT MAP(STR=>STRDelayed, RST=>RST, CLK=>CLK, RDY=>RDYCicles, SCK=>SCKs);--1
	
	-- One clock cicle after STR is high, Css is set to high. U3 controls Cs. 
	U3: LatchSR PORT MAP(SET=>STR, CLR=>RDYCiclesDelayed, RST=>RST, CLK=>CLK, SOUT=>Css);  --1
	
	-- U4 shifts the output data depending on the POL/PHA selection.
	U4: FallingEdgeDetector PORT MAP(XIN=>SCKs, RST=>RST, CLK=>CLK, XRE=>FESCK);  
	
	-- U5 reads the input data depending on the POL/PHA selection.
	U5: RisingEdge PORT MAP(XIN=>SCKs, RST=>RST, CLK=>CLK, XRE=>RESCK);	   
	
	-- U6 gets the control of Flip through ILs depending on Css.
	U6: LatchSR PORT MAP(SET=>EA, CLR=>'0', RST=>Css, CLK=>CLK, SOUT=>ILs);	
	
	-- The serializer outputs the data serialy on MOSI.
	U7: Serializer GENERIC MAP (BUSWIDTH=>DATAWIDTH) PORT MAP(LDR=>LOAD, SHF=>Flip, RST=>Css, CLK=>CLK, DIN=>SNDDATA, BOUT=>BOUTs);  
	
	-- Every time Css goes from low to high, U8 loads the data into U7.
	U8: RisingEdge PORT MAP(XIN=>Css, RST=>RST, CLK=>CLK, XRE=>LOAD);
	
	-- U9 puts MISO data into DOUTs depending on Sample.
	U9: Deserializer GENERIC MAP (BUSWIDTH=>DATAWIDTH) PORT MAP(BIN=>MISO, SHF=>Sample, RST=>Css, CLK=>CLK, DOUT=>DOUTs);  
	
	-- Once the SCK cicles are done, U10 delays RDYCicles 10 times the clock frequency.
	-- RDYCiclesDelayed clears U3.
	U10: DelayFlipFlops GENERIC MAP(DELAY=>CLKT*10, TCLK=>CLKT) PORT MAP(D=>RDYCicles, RST=>Css, CLK=>CLK, Q=>RDYCiclesDelayed, Qn=>OPEN);	
	
	-- RDYCiclesDelayed from U10 loads the MISO data in RCV data every time a transaction is made.
	U11: LoadFlipFlop GENERIC MAP(BUSWIDTH=>DATAWIDTH) PORT MAP(DIN=>DOUTs, LDR=>RDYCiclesDelayed, RST=>RST, CLK=>CLK, DOUT=>RCVDATA);
	
	
END ARCHITECTURE Structural;
