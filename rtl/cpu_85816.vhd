-- -----------------------------------------------------------------------
-- K85816 - 65816 based 85xx compatible CPU core
-- (C) 2022 Alynna Kelly
-- -----------------------------------------------------------------------
-- Based on FPGA 64
-- A fully functional commodore 64 implementation in a single FPGA
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
-- -----------------------------------------------------------------------
-- 8502 wrapper for 65xx core
-- Adds 8 bit I/O port mapped at addresses $0000 to $0001
-- -----------------------------------------------------------------------
-- Expected memory map
-- Address       : Desc
-- 000000-000001 : 8502 I/O
-- 000002-00CFFF : RAM bank 0 / ROM / etc
-- 00D000-00DFFF : I/O
-- 00E000-00FFFF : RAM bank 0 / ROM
-- 010000-03FFFF : RAM banks 1-3
-- 040000-0FFFFF : RAM banks 4-15 (the programmers reference says the MMU could do this)
-- 100000-FDFFFF : ~15 MB Fast RAM (Banks 16-253)
-- FE0000-FEFFFF : VDC RAM direct access
-- FF0000-FFFFFF : Reserved (16 bit vectors must also go here...)

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

-- -----------------------------------------------------------------------

entity cpu_85816 is
	port (
		clk     : in  std_logic;
		enable  : in  std_logic;
		reset   : in  std_logic;
		nmi_n   : in  std_logic;
		irq_n   : in  std_logic;
		rdy     : in  std_logic;
		di      : in  unsigned(7 downto 0);
		do      : out unsigned(7 downto 0);
		nmi_ack : out std_logic;
		addr    : out unsigned(15 downto 0);
		page    : out unsigned(7 downto 0);
		we      : out std_logic;

		diIO    : in  unsigned(7 downto 0);
		doIO    : out unsigned(7 downto 0)
	);
end cpu_85816;

-- -----------------------------------------------------------------------

architecture rtl of cpu_85816 is
	signal localA : std_logic_vector(23 downto 0);
	signal localDi : std_logic_vector(7 downto 0);
	signal localDo : std_logic_vector(7 downto 0);
	signal localWe : std_logic;
	signal currentIO : std_logic_vector(7 downto 0);
	signal ioDir : std_logic_vector(7 downto 0);
	signal ioData : std_logic_vector(7 downto 0);	
	signal accessIO : std_logic;
	signal vpa : std_logic;
	signal vda : std_logic;
	signal rdyo : std_logic;
	
begin
	cpu: work.P65c816
	port map(
		CLK => clk,
		RST_N => not reset,
		CE => enable,
		RDY_IN => rdy,
		RDY_OUT => rdyo,
		NMI_N => nmi_n,
		IRQ_N => irq_n,
		ABORT_N => '1',
		D_IN => localDi,
		D_OUT => localDo,
		A_OUT => localA,
		WE => localWe,
		VPA => vpa,
		VDA => vda
	);

nmi_ack <= not nmi_n;  -- fake it till you make it ...

-- Altered for 65816 support.  65816 mode only sees IO ports at 000000-000001
	accessIO <= '1' when (localA(23 downto 16) = "00000000") and (localA(15 downto 1) = X"000"&"000") else '0'; 
	localDi  <= localDo when localWe = '0' else std_logic_vector(di) when accessIO = '0' else ioDir when localA(0) = '0' else currentIO;

	process(clk, reset, vda, vpa)
	begin
		if rising_edge(clk) and (vda = '1' or vpa = '1') then
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

	-- Connect zhe wires
	process(clk, vpa, vda)
	begin
	if (vda = '1' or vpa = '1') then
		addr <= unsigned(localA(15 downto 0));
		page <= unsigned(localA(23 downto 16));
		do <= unsigned(localDo);
		we <= not localWe;
		doIO <= unsigned(currentIO);
	end if;
	end process;
end architecture;