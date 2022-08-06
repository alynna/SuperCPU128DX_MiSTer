-- -----------------------------------------------------------------------
--
--                                 FPGA 64
--
--     A fully functional commodore 64 implementation in a single FPGA
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
-- -----------------------------------------------------------------------
--
-- 6510 wrapper for 65xx core
-- Adds 8 bit I/O port mapped at addresses $0000 to $0001
--
-- -----------------------------------------------------------------------
--
-- Alynna Note: Additional logic added to allow 65816 mode to work.
-- Expected memory map:

-- Address       : Desc
-- 000000-000001 : 8502 I/O
-- 000002-00CFFF : RAM bank 0 / ROM / etc
-- 00D000-00DFFF : I/O
-- 00E000-00FFFF : RAM bank 0 / ROM
-- 010000-03FFFF : RAM banks 1-3
-- 040000-0FFFFF : RAM banks 4-15 (the programmers reference says the MMU could do this)
-- 100000-FDFFFF : ~15 MB Fast RAM (only the CPU sees it)
-- FE0000-FEFFFF : VDC RAM direct access
-- FF0000-FFFFFF : Reserved (16 bit vectors must also go here...)

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;


-- -----------------------------------------------------------------------

entity cpu_6510 is
	port (
		clk     : in  std_logic;
		enable  : in  std_logic;
		reset   : in  std_logic;
		nmi_n   : in  std_logic;
		irq_n   : in  std_logic;
		rdy     : in  std_logic;
		di      : in  unsigned(7 downto 0);
		do      : out unsigned(7 downto 0);
		
		addr    : out unsigned(15 downto 0);
		page    : out unsigned(7 downto 0);
		we      : out std_logic;

		diIO    : in  unsigned(7 downto 0);
		doIO    : out unsigned(7 downto 0)
	);
end cpu_6510;

-- -----------------------------------------------------------------------

architecture rtl of cpu_6510 is
	signal localA : std_logic_vector(23 downto 0);
	signal localDi : std_logic_vector(7 downto 0);
	signal localDo : std_logic_vector(7 downto 0);
	signal db : std_logic_vector(7 downto 0);
	signal localWe : std_logic;

	signal currentIO : std_logic_vector(7 downto 0);
	signal ioDir : std_logic_vector(7 downto 0);
	signal ioData : std_logic_vector(7 downto 0);
	
	signal accessIO : std_logic;

	signal vpa : std_logic;
	signal vda : std_logic;

-- module FT832(corenum, rst, clk, clko, cyc, phi11, phi12, phi81, phi82, nmi, irq1, irq2, irq3, abort, e, mx, rdy, be, vpa, vda, mlb, vpb, rw, ad, db, err_i, rty_i);	

component FT816 is
 port(
	rst : in std_logic;
	clk : in std_logic;
	--clko : out std_logic;
	--cyc : buffer std_logic_vector(4 downto 0);
	--phi11 : out std_logic;
	--phi12 : out std_logic;
	--phi81 : out std_logic;
	--phi82 : out std_logic;
	nmi : in std_logic;
	irq1 : in std_logic;
	abort : in std_logic;
	--e : out std_logic;
	--mx : out std_logic;
	rdy : in std_logic;
	--be : in std_logic;
	vpa : out std_logic;
	vda : out std_logic;
	--mlb : out std_logic;
	--vpb : out std_logic;
	rw : out std_logic;
	ad : out std_logic_vector(23 downto 0);
	db : buffer std_logic_vector(7 downto 0)
	--err_i: in std_logic;
	--rty_i: in std_logic
 );
end component;

begin
	cpu: FT816
	port map(
    clk => clk,
	 rst => reset,
	 rdy => rdy,
    nmi => not nmi_n,
	 irq1 => not irq_n,
	 abort => '0',
	 db => db,
    ad => localA,
    rw => localWe,
	 vpa => vpa,
	 vda => vda
	);

	db <= std_logic_vector(di) when localWe = '1' else std_logic_vector(d);
	localDo <= db when localWe = '0' else std_logic_vector(di);
	
	accessIO <= '1' when (localA(23 downto 16) = "00000000") and (localA(15 downto 1) = X"000"&"000") else '0'; 	
	localDi  <= localDo when localWe = '0' else std_logic_vector(di) when accessIO = '0' else ioDir when localA(0) = '0' else currentIO;
	

	process(clk)
	begin
		if (rising_edge(clk) or reset='1') then
			if accessIO = '1' then
				if localWe = '0' and enable = '1' then
					if localA(0) = '0' then
						ioDir <= localDo;
					else
						ioData <= localDo;
					end if;
				end if;
			end if;
			
			currentIO <= (ioData and ioDir) or (std_logic_vector(diIO) and not ioDir);

			if reset = '1' then
				ioDir <= (others => '0');
				ioData <= (others => '1');
				currentIO <= (others => '1');
			end if;
		end if;
	end process;
	
	-- Cunnect zee wires
	addr <= unsigned(localA(15 downto 0));
	page <= unsigned(localA(23 downto 16));
	do <= unsigned(localDo);
	we <= not localWe;
	doIO <= unsigned(currentIO);
end architecture;
