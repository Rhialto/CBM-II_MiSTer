-- -----------------------------------------------------------------------
--
-- 6509 wrapper for T65
--
-- -----------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
use work.T65_Pack.T_t65_dbg;

-- -----------------------------------------------------------------------

entity cpu_6509 is
	port (
		widePO  : in  std_logic; -- 0= 4 bit PO, 1= 8 bit PO

		clk     : in  std_logic;
		enable  : in  std_logic;
		reset   : in  std_logic;
		nmi_n   : in  std_logic;
		nmi_ack : out std_logic;
		irq_n   : in  std_logic;
		rdy     : in  std_logic;

		din     : in  unsigned(7 downto 0);
		dout    : out unsigned(7 downto 0);
		addr    : out unsigned(15 downto 0);
		we      : out std_logic;

		pout    : out unsigned(7 downto 0)
	);
end cpu_6509;

-- -----------------------------------------------------------------------

architecture rtl of cpu_6509 is
	signal localA : std_logic_vector(23 downto 0);
	signal localDi : std_logic_vector(7 downto 0);
	signal localDo : std_logic_vector(7 downto 0);
	signal localWe : std_logic;
	signal VDA : std_logic;
	signal VPA : std_logic;
	signal DEBUG : T_t65_dbg;

	signal exeReg : std_logic_vector(7 downto 0);
	signal indReg : std_logic_vector(7 downto 0);

	signal localAccess : std_logic;
begin

	cpu: work.T65
	port map(
		Mode    => "00",
		Res_n   => not reset,
		Enable  => enable,
		Clk     => clk,
		Rdy     => rdy,
		Abort_n => '1',
		IRQ_n   => irq_n,
		NMI_n   => nmi_n,
		SO_n    => '1',
		R_W_n   => localWe,
		A       => localA,
		DI      => localDi,
		DO      => localDo,
		NMI_ack => nmi_ack,
		VDA     => VDA,
		VPA     => VPA,
		DEBUG   => DEBUG
	);

	localAccess <= '1' when localA(15 downto 1) = X"000"&"000" else '0';
	localDi     <= localDo when localWe = '0' else std_logic_vector(din) when localAccess = '0' else exeReg when localA(0) = '0' else indReg;

	process(clk)
	begin
		if rising_edge(clk) then
			if localAccess = '1' and localWe = '0' and enable = '1' then
				if localA(0) = '0' then
					exeReg <=localDo;
				else
					indReg <= localDo;
				end if;
			end if;

			if reset = '1' then
				exeReg <= (others => '1');
				indReg <= (others => '1');
			end if;

			if widePO = '0' then
				exeReg(7 downto 4) <= (others => '0');
				indReg(7 downto 4) <= (others => '0');
			end if;
		end if;
	end process;

	addr <= unsigned(localA(15 downto 0));
	dout <= unsigned(localDo) when localAccess = '0' or widePO = '1' else unsigned("0000" & localDo(3 downto 0));
	we <= not localWe;
	pout <= unsigned(exeReg) when VDA = '0' or VPA = '1' or (DEBUG.I /= X"91" and DEBUG.I /= X"B1") else unsigned(indReg);
end architecture;
