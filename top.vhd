LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.states.ALL;

ENTITY top IS
    PORT(clk, RST : IN STD_LOGIC;
         SCL, TX : OUT STD_LOGIC := '1';
         SDA : INOUT STD_LOGIC := '1'
         );
END ENTITY;

ARCHITECTURE behavior OF top IS
TYPE display IS (HOLD, CRLF, NAME, MANU, RESO, DIME, IDLE);
SIGNAL currentDisplay, returnDisplay : display := HOLD;

CONSTANT CR : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"0D"; --Carriage Return
CONSTANT LF : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"0A"; --Line Feed
CONSTANT BS : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"08"; --Backspace
CONSTANT ESC : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"1B"; --Escape
CONSTANT SP : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"20"; --Space
CONSTANT DEL  : STD_LOGIC_VECTOR (7 DOWNTO 0) := x"7F"; --Delete

--State variables--
SIGNAL counter : INTEGER RANGE 0 TO 20 := 0;
SIGNAL dataCounter : INTEGER RANGE 1 TO 257 := 1;

--I2C checking--
SIGNAL isSend, SDAIn, SDAOut : STD_LOGIC := '0';

--I2C variables--
SIGNAL I2CComp, I2CEnable : STD_LOGIC := '0';
SIGNAL byteSend, byteRCV : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL I2CInstruc : state;

--EDID variables--
SIGNAL enableEDID : STD_LOGIC := '1';
SIGNAL horThou, horHund, horTens, horOnes : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL vertThou, vertHund, vertTens, vertOnes : STD_LOGIC_VECTOR (7 DOWNTO 0);
SIGNAL refreshThou, refreshHund, refreshTens, refreshOnes : STD_LOGIC_VECTOR (7 DOWNTO 0);

--EDID data--
SIGNAL printReady : STD_LOGIC := '0';
SIGNAL horPixel, vertPixel, refreshRate : STD_LOGIC_VECTOR (11 DOWNTO 0);
SIGNAL manufacturer : STD_LOGIC_VECTOR (103 DOWNTO 0) := (OTHERS => '0');

--UART variables--
SIGNAL tx_valid, tx_ready : STD_LOGIC := '0';
SIGNAL tx_data, tx_str : STD_LOGIC_VECTOR (7 DOWNTO 0);

--UART strings--
SIGNAL SPACEDATA : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
SIGNAL nameString : STRING (6 DOWNTO 1);
SIGNAL nameLogic : STD_LOGIC_VECTOR (47 DOWNTO 0) := (OTHERS => '0');
SIGNAL resoString : STRING (12 DOWNTO 1);
SIGNAL resoLogic : STD_LOGIC_VECTOR (95 DOWNTO 0) := (OTHERS => '0');

COMPONENT conv IS
    PORT(clk : IN STD_LOGIC;
         char : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
         thou, hund, tens, ones : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')
        );
END COMPONENT;

COMPONENT UART_TX IS
    PORT (clk : IN  STD_LOGIC;
          reset : IN  STD_LOGIC;
          tx_valid : IN STD_LOGIC;
          tx_data : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
          tx_ready : OUT STD_LOGIC;
          tx_OUT : OUT STD_LOGIC);
END COMPONENT;

COMPONENT I2C IS
    PORT(clk, SDAin, enable : IN STD_LOGIC;
         instruction : IN state;
         byteSend : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         complete : OUT STD_LOGIC;
         SDAout, SCL : OUT STD_LOGIC := '1';
         isSend : OUT STD_LOGIC := '0';
         byteReceived : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
         );
END COMPONENT;

COMPONENT EDIDfull IS
    PORT(clk, enable, compI2C : IN STD_LOGIC;
         byteRCV : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         ready : OUT STD_LOGIC := '0';
         enableI2C : OUT STD_LOGIC := '0';
         instructionI2C : OUT state;
         byteSend : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
         horPixel, vertPixel, refreshRate : OUT STD_LOGIC_VECTOR (11 DOWNTO 0) := (OTHERS => '0');
         screenName : OUT STD_LOGIC_VECTOR (103 DOWNTO 0) := (OTHERS => '0')
        );
END COMPONENT;

IMPURE FUNCTION STR2SLV (str : STRING; size : STD_LOGIC_VECTOR) RETURN STD_LOGIC_VECTOR IS
    VARIABLE data : STD_LOGIC_VECTOR(0 TO size'LENGTH - 1);
    BEGIN
    FOR i IN str'RANGE LOOP
        data(i * 8 - 8 TO i * 8 - 1) := STD_LOGIC_VECTOR(TO_UNSIGNED(CHARACTER'POS(str(i)), 8));
    END LOOP;
    RETURN data;
END FUNCTION;

BEGIN
    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            SDA <= '0' WHEN (isSend AND NOT SDAOut) ELSE 'Z';
            SDAIn <= '1' WHEN SDA ELSE '0';
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentDisplay IS
            WHEN HOLD => enableEDID <= '1';
                IF printReady THEN
                    currentDisplay <= NAME;
                END IF;
            WHEN CRLF => SPACEDATA(15 DOWNTO 0) <= CR & LF;
                tx_data <= tx_str;
                IF tx_valid = '1' AND tx_ready = '1' AND counter < 1 THEN
                    counter <= counter + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    counter <= 0;
                    currentDisplay <= returnDisplay;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN NAME => nameString <= "Name: ";
                nameLogic <= STR2SLV(nameString, nameLogic);
                tx_data <= tx_str;
                IF tx_valid = '1' AND tx_ready = '1' AND counter < 5 THEN
                    counter <= counter + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    counter <= 0;
                    currentDisplay <= MANU;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN MANU => tx_data <= tx_str;
            IF tx_valid = '1' AND tx_ready = '1' AND counter < 12 THEN
                counter <= counter + 1;
            ELSIF tx_valid AND tx_ready THEN
                tx_valid <= '0';
                counter <= 0;
                currentDisplay <= CRLF;
                returnDisplay <= RESO;
            ELSIF NOT tx_valid THEN
                tx_valid <= '1';
            END IF;
            WHEN RESO => resoString <= "Resolution: ";
                resoLogic <= STR2SLV(resoString, resoLogic);
                tx_data <= tx_str;
                IF tx_valid = '1' AND tx_ready = '1' AND counter < 11 THEN
                    counter <= counter + 1;
                ELSIF tx_valid AND tx_ready THEN
                    tx_valid <= '0';
                    counter <= 0;
                    currentDisplay <= DIME;
                ELSIF NOT tx_valid THEN
                    tx_valid <= '1';
                END IF;
            WHEN DIME => tx_data <= tx_str;
            IF tx_valid = '1' AND tx_ready = '1' AND counter < 16 THEN
                counter <= counter + 1;
            ELSIF tx_valid AND tx_ready THEN
                tx_valid <= '0';
                counter <= 0;
                currentDisplay <= IDLE;
           ELSIF NOT tx_valid THEN
                tx_valid <= '1';
            END IF;
            WHEN IDLE => 
            END CASE;
        END IF;
    END PROCESS;

    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            IF currentDisplay = CRLF THEN
                IF counter = 0 THEN
                    tx_str <= SPACEDATA(7 DOWNTO 0);
                ELSIF counter = 1 THEN
                    tx_str <= SPACEDATA(15 DOWNTO 8);
                END IF;
            END IF;

            IF currentDisplay = NAME THEN
                IF counter = 0 THEN
                    tx_str <= nameLogic(7 DOWNTO 0);
                ELSIF counter = 1 THEN
                    tx_str <= nameLogic(15 DOWNTO 8);
                ELSIF counter = 2 THEN
                    tx_str <= nameLogic(23 DOWNTO 16);
                ELSIF counter = 3 THEN
                    tx_str <= nameLogic(31 DOWNTO 24);
                ELSIF counter = 4 THEN
                    tx_str <= nameLogic(39 DOWNTO 32);
                ELSIF counter = 5 THEN
                    tx_str <= nameLogic (47 DOWNTO 40);
                END IF;
            END IF;

            IF currentDisplay = MANU THEN
                IF counter = 0 THEN
                    tx_str <= manufacturer(103 DOWNTO 96);
                ELSIF counter = 1 THEN
                    tx_str <= manufacturer(95 DOWNTO 88);
                ELSIF counter = 2 THEN
                    tx_str <= manufacturer(87 DOWNTO 80);
                ELSIF counter = 3 THEN
                    tx_str <= manufacturer(79 DOWNTO 72);
                ELSIF counter = 4 THEN
                    tx_str <= manufacturer(71 DOWNTO 64);
                ELSIF counter = 5 THEN
                    tx_str <= manufacturer(63 DOWNTO 56);
                ELSIF counter = 6 THEN
                    tx_str <= manufacturer(55 DOWNTO 48);
                ELSIF counter = 7 THEN
                    tx_str <= manufacturer(47 DOWNTO 40);
                ELSIF counter = 8 THEN
                    tx_str <= manufacturer(39 DOWNTO 32);
                ELSIF counter = 9 THEN
                    tx_str <= manufacturer(31 DOWNTO 24);
                ELSIF counter = 10 THEN
                    tx_str <= manufacturer(23 DOWNTO 16);
                ELSIF counter = 11 THEN
                    tx_str <= manufacturer(15 DOWNTO 8);
                ELSIF counter = 12 THEN
                    tx_str <= manufacturer(7 DOWNTO 0);
                END IF;
            END IF;

            IF currentDisplay = RESO THEN
                IF counter = 11 THEN
                    tx_str <= resoLogic(95 DOWNTO 88);
                ELSIF counter = 10 THEN
                    tx_str <= resoLogic(87 DOWNTO 80);
                ELSIF counter = 9 THEN
                    tx_str <= resoLogic(79 DOWNTO 72);
                ELSIF counter = 8 THEN
                    tx_str <= resoLogic(71 DOWNTO 64);
                ELSIF counter = 7 THEN
                    tx_str <= resoLogic(63 DOWNTO 56);
                ELSIF counter = 6 THEN
                    tx_str <= resoLogic(55 DOWNTO 48);
                ELSIF counter = 5 THEN
                    tx_str <= resoLogic(47 DOWNTO 40);
                ELSIF counter = 4 THEN
                    tx_str <= resoLogic(39 DOWNTO 32);
                ELSIF counter = 3 THEN
                    tx_str <= resoLogic(31 DOWNTO 24);
                ELSIF counter = 2 THEN
                    tx_str <= resoLogic(23 DOWNTO 16);
                ELSIF counter = 1 THEN
                    tx_str <= resoLogic(15 DOWNTO 8);
                ELSIF counter = 0 THEN
                    tx_str <= resoLogic(7 DOWNTO 0);
                END IF;
            END IF;

            IF currentDisplay = DIME THEN
                CASE counter IS
                WHEN 0 => tx_str <= horThou;
                WHEN 1 => tx_str <= horHund;
                WHEN 2 => tx_str <= horTens;
                WHEN 3 => tx_str <= horOnes;
                WHEN 4 => tx_str <= SP;
                WHEN 5 => tx_str <= x"78";
                WHEN 6 => tx_str <= SP;
                WHEN 7 => tx_str <= vertThou;
                WHEN 8 => tx_str <= vertHund;
                WHEN 9 => tx_str <= vertTens;
                WHEN 10 => tx_str <= vertOnes;
                WHEN 11 => tx_str <= SP; 
                WHEN 12 => tx_str <= x"40";
                WHEN 13 => tx_str <= refreshTens;
                WHEN 14 => tx_str <= refreshOnes;
                WHEN 15 => tx_str <= x"48";
                WHEN 16 => tx_str <= x"7A";
                WHEN OTHERS => NULL;
                END CASE;
            END IF;
        END IF;
    END PROCESS;

UARTTX : UART_TX PORT MAP(clk => clk, reset => RST, tx_valid => tx_valid, tx_data => tx_data, tx_ready => tx_ready, tx_OUT => TX);
COM : I2C PORT MAP(clk => clk, SDAin => SDAIn, enable => I2CEnable, instruction => I2CInstruc, byteSend => byteSend, complete => I2CComp, SDAout => SDAOut, SCL => SCL, isSend => isSend, byteReceived => byteRCV);
INFO : EDIDFull PORT MAP(clk => clk, enable => enableEDID, compI2C => I2CComp, byteRCV => byteRCV, ready => printReady, enableI2C => I2CEnable, instructionI2C => I2CInstruc, byteSend => byteSend,  horPixel => horPixel, vertPixel => vertPixel, refreshRate => refreshRate, screenName => manufacturer);
HOR : conv PORT MAP(clk => clk, char => horPixel, thou => horThou, hund => horHund, tens => horTens, ones => horOnes);
VERT : conv PORT MAP(clk => clk, char => vertPixel, thou => vertThou, hund => vertHund, tens => vertTens, ones => vertOnes);
REF : conv PORT MAP(clk => clk, char => refreshRate, thou => refreshThou, hund => refreshHund, tens => refreshTens, ones => refreshOnes);
END ARCHITECTURE;