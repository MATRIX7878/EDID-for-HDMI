LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.states.ALL;

ENTITY EDIDFull IS
    PORT(clk, enable, compI2C : IN STD_LOGIC;
         byteRCV : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         ready : OUT STD_LOGIC := '0';
         enableI2C : OUT STD_LOGIC := '0';
         instructionI2C : OUT state;
         byteSend : OUT STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
         horPixel, vertPixel, refreshRate : OUT STD_LOGIC_VECTOR (11 DOWNTO 0) := (OTHERS => '0');
         screenName : OUT STD_LOGIC_VECTOR (103 DOWNTO 0) := (OTHERS => '0')
        );
END ENTITY;

ARCHITECTURE behavior OF EDIDFull IS
TYPE FSM IS (IDLE, STARTI2C, SENDADDR, SENDEDID, RESTARTI2C, SENDREAD, READBYTE, WAITI2C, STOPI2C, HANDLE, READNAME, REFRESHRATE1, REFRESHRATE2, REFRESHRATE3, REFRESHRATE4, DONE);
SIGNAL currentFSM, returnFSM : FSM := IDLE;

SIGNAL counter : INTEGER RANGE 0 TO 256 := 0;

SIGNAL processStart : STD_LOGIC := '0';

SIGNAL nameCount : INTEGER RANGE 0 TO 13 := 0;

SIGNAL horBlank, verBlank : STD_LOGIC_VECTOR (11 DOWNTO 0) := (OTHERS => '0');
SIGNAL pixelClock : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');

SIGNAL foundPrefix : STD_LOGIC_VECTOR (2 DOWNTO 0) := (OTHERS => '0');

SIGNAL refreshTop, refreshBot : STD_LOGIC_VECTOR (19 DOWNTO 0) := (OTHERS => '0');

SIGNAL cache : STD_LOGIC_VECTOR (39 DOWNTO 0) := (OTHERS => '0');
SIGNAL hor : STD_LOGIC_VECTOR(12 DOWNTO 0) := (OTHERS => '0');


BEGIN
    PROCESS(ALL)
    BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentFSM IS
            WHEN IDLE => IF enable THEN
                currentFSM <= STARTI2C;
                counter <= 0;
                nameCount <= 0;
            END IF;
            WHEN STARTI2C => instructionI2C <= START;
                enableI2C <= '1';
                currentFSM <= WAITI2C;
                returnFSM <= SENDADDR;
            WHEN SENDADDR => instructionI2C <= WRITE;
                byteSend <= x"A0";
                enableI2C <= '1';
                currentFSM <= WAITI2C;
                returnFSM <= SENDEDID;
            WHEN SENDEDID => instructionI2C <= WRITE;
                byteSend <= (OTHERS => '0');
                enableI2C <= '1';
                currentFSM <= WAITI2C;
                returnFSM <= RESTARTI2C;
            WHEN RESTARTI2C => instructionI2C <= START;
                enableI2C <= '1';
                currentFSM <= WAITI2C;
                returnFSM <= SENDREAD;
            WHEN SENDREAD => instructionI2C <= WRITE;
                byteSend <= x"A1";
                enableI2C <= '1';
                currentFSM <= WAITI2C;
                returnFSM <= HANDLE;
            WHEN READBYTE => instructionI2C <= READ;
                enableI2C <= '1';
                currentFSM <= WAITI2C;
                returnFSM <= READNAME;
            WHEN WAITI2C => IF NOT processStart AND NOT compI2C THEN
                processStart <= '1';
            ELSIF compI2C AND processStart THEN
                currentFSM <= returnFSM;
                processStart <= '0';
                enableI2C <= '0';
            END IF;
            WHEN STOPI2C => instructionI2C <= STOP;
                enableI2C <= '1';
                currentFSM <= WAITI2C;
                returnFSM <= REFRESHRATE1;
            WHEN HANDLE => counter <= counter + 1;
                instructionI2C <= READ;
                enableI2C <= '1';
                currentFSM <= WAITI2C;
                returnFSM <= HANDLE;
                CASE counter IS
                WHEN 1 => IF byteRCV /= x"00" THEN
                    enableI2C <= '0';
                    currentFSM <= IDLE;
                END IF;
                WHEN 8 => IF byteRCV /= x"00" THEN
                    enableI2C <= '0';
                    currentFSM <= IDLE;
                END IF;
                WHEN 55 => pixelClock(7 DOWNTO 0) <= byteRCV;
                WHEN 56 => pixelClock(15 DOWNTO 8) <= byteRCV;
                WHEN 57 => horPixel(7 DOWNTO 0) <= byteRCV;
                WHEN 58 => horBlank(7 DOWNTO 0) <= byteRCV;
                WHEN 59 => horPixel(11 DOWNTO 8) <= byteRCV(7 DOWNTO 4);
                    horBlank(11 DOWNTO 8) <= byteRCV(3 DOWNTO 0);
                WHEN 60 => vertPixel(7 DOWNTO 0) <= byteRCV;
                WHEN 61 => verBlank(7 DOWNTO 0) <= byteRCV;
                WHEN 62 => vertPixel(11 DOWNTO 8) <= byteRCV(7 DOWNTO 4);
                    verBlank(11 DOWNTO 8) <= byteRCV(3 DOWNTO 0);
                WHEN 73 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
                WHEN 74 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
                WHEN 75 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
                WHEN 91 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
                WHEN 92 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
                WHEN 93 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
                WHEN 109 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
                WHEN 110 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
                WHEN 111 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"00" ELSE (OTHERS => '0');
                WHEN 76 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"FC" ELSE (OTHERS => '0');
                WHEN 94 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"FC" ELSE (OTHERS => '0');
                WHEN 112 => foundPrefix <= foundPrefix + '1' WHEN  byteRCV = x"FC" ELSE (OTHERS => '0');
                WHEN 77 => IF byteRCV = x"00" AND foundPrefix = d"4" THEN
                    returnFSM <= READNAME;
                ELSE
                    foundPrefix <= (OTHERS => '0');
                END IF;
                WHEN 95 => IF byteRCV = x"00" AND foundPrefix = d"4" THEN
                    returnFSM <= READNAME;
                ELSE
                    foundPrefix <= (OTHERS => '0');
                END IF;
                WHEN 113 => IF byteRCV = x"00" AND foundPrefix = d"4" THEN
                    returnFSM <= READNAME;
                ELSE
                    foundPrefix <= (OTHERS => '0');
                END IF;
                WHEN OTHERS => NULL;
                END CASE;
            WHEN READNAME => nameCount <= nameCount + 1;
                IF nameCount = 0 THEN
                    screenName(103 DOWNTO 96) <= byteRCV;
                ELSIF nameCount = 1 THEN
                    screenName(95 DOWNTO 88) <= byteRCV;
                ELSIF nameCount = 2 THEN
                    screenName(87 DOWNTO 80) <= byteRCV;
                ELSIF nameCount = 3 THEN
                    screenName(79 DOWNTO 72) <= byteRCV;
                ELSIF nameCount = 4 THEN
                    screenName(71 DOWNTO 64) <= byteRCV;
                ELSIF nameCount = 5 THEN
                    screenName(63 DOWNTO 56) <= byteRCV;
                ELSIF nameCount = 6 THEN
                    screenName(55 DOWNTO 48) <= byteRCV;
                ELSIF nameCount = 7 THEN
                    screenName(47 DOWNTO 40) <= byteRCV;
                ELSIF nameCount = 8 THEN
                    screenName(39 DOWNTO 32) <= byteRCV;
                ELSIF nameCount = 9 THEN
                    screenName(31 DOWNTO 24) <= byteRCV;
                ELSIF nameCount = 10 THEN
                    screenName(23 DOWNTO 16) <= byteRCV;
                ELSIF nameCount = 11 THEN
                    screenName(15 DOWNTO 8) <= byteRCV;
                ELSIF nameCount = 12 THEN
                    screenName(7 DOWNTO 0) <= byteRCV;
                    IF horPixel > 2560 THEN
                        hor <= TO_STDLOGICVECTOR(TO_INTEGER(UNSIGNED(horPixel)), 13) + TO_STDLOGICVECTOR(TO_INTEGER(UNSIGNED(horBlank)), 13);
                    ELSIF horPixel <= 2560 THEN
                        hor <= "0" & (horPixel + horBlank);
                    END IF;
                END IF;
                currentFSM <= STOPI2C WHEN nameCount = 12 ELSE READBYTE;
            WHEN REFRESHRATE1 => refreshTop <= pixelClock * TO_STDLOGICVECTOR(10, 4);
                refreshBot <= TO_STDLOGICVECTOR(0, 20) OR TO_STDLOGICVECTOR(TO_INTEGER(UNSIGNED(hor)), 20);
                currentFSM <= REFRESHRATE2;
            WHEN REFRESHRATE2 => IF refreshTop >= refreshBot THEN
                refreshTop <= refreshTop - refreshBot;
                refreshRate <= refreshRate + '1';
            ELSE
                refreshBot <= TO_STDLOGICVECTOR(0, 8) & (vertPixel + verBlank);
                cache <= (TO_STDLOGICVECTOR(0, 8) & refreshRate) * TO_STDLOGICVECTOR(1000, 20);
                currentFSM <= REFRESHRATE3;
            END IF;
            WHEN REFRESHRATE3 => refreshTop <= TO_STDLOGICVECTOR(TO_INTEGER(UNSIGNED(cache)), 20);
                refreshRate <= (OTHERS => '0');
                currentFSM <= REFRESHRATE4;
            WHEN REFRESHRATE4 => IF refreshTop >= refreshBot THEN
                refreshTop <= refreshTop - refreshBot;
                refreshRate <= refreshRate + '1';
            ELSE
                IF refreshTop > 0 THEN
                    refreshRate <= refreshRate + '1';
                END IF;
                currentFSM <= DONE;
            END IF;
            WHEN DONE => ready <= '1';
            END CASE;
        END IF;
    END PROCESS;
END ARCHITECTURE;