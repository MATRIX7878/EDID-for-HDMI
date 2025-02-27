LIBRARY IEEE, WORK;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;
USE WORK.states.ALL;

ENTITY I2C IS
    PORT(clk, SDAin, enable : IN STD_LOGIC;
         instruction : IN state;
         byteSend : IN STD_LOGIC_VECTOR (7 DOWNTO 0);
         complete : OUT STD_LOGIC;
         SDAout, SCL : OUT STD_LOGIC := '1';
         isSend : OUT STD_LOGIC := '0';
         byteReceived : OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
         );
END ENTITY;

ARCHITECTURE Behavior OF I2C IS
SIGNAL currentState : state := IDLE;

SIGNAL bitSend : INTEGER := 0;
SIGNAL clockDiv : STD_LOGIC_VECTOR (6 DOWNTO 0) := (OTHERS => '0');

SIGNAL Din : STD_LOGIC;

BEGIN
    PROCESS(ALL)
        BEGIN
        IF RISING_EDGE(clk) THEN
            CASE currentState IS
            WHEN START => isSend <= '1';
                clockDiv <= clockDiv + '1';
                IF clockDiv(6 DOWNTO 5) = "00" THEN
                    SCL <= '1';
                    SDAout <= '1';
                ELSIF clockDiv(6 DOWNTO 5) = "01" THEN
                    SDAout <= '0';
                ELSIF clockDiv(6 DOWNTO 5) = "10" THEN
                    SCL <= '0';
                ELSIF clockDiv(6 DOWNTO 5) = "11" THEN
                    currentState <= DONE;
                END IF;
            WHEN STOP => isSend <= '1';
                clockDiv <= clockDiv + '1';
                IF clockDiv(6 DOWNTO 5) = "00" THEN
                    SCL <= '0';
                    SDAout <= '0';
                ELSIF clockDiv(6 DOWNTO 5) = "01" THEN
                    SCL <= '1';
                ELSIF clockDiv(6 DOWNTO 5) = "10" THEN
                    SDAout <= '1';
                ELSIF clockDiv(6 DOWNTO 5) = "11" THEN
                    currentState <= DONE;
                END IF;
            WHEN READ => isSend <= '0';
                clockDiv <= clockDiv + '1';
                Din <= '1' WHEN SDAin ELSE '0';
                IF clockDiv(6 DOWNTO 5) = "00" THEN
                    SCL <= '0';
                ELSIF clockDiv(6 DOWNTO 5) = "01" THEN
                    SCL <= '1';
                ELSIF clockDiv = "1000000" THEN
                    byteReceived <= byteReceived(6 DOWNTO 0) & Din;
                ELSIF clockDiv = "1111111" THEN
                    bitSend <= bitSend + 1;
                    IF bitSend = 7 THEN
                        currentState <= SEND;
                    END IF;
                ELSIF clockDiv(6 DOWNTO 5) = "11" THEN
                    SCL <= '0';
                END IF;
            WHEN WRITE => isSend <= '1';
                clockDiv <= clockDiv + '1';
                SDAout <= '1' WHEN byteSend(7 - bitSend) ELSE '0';
                IF clockDiv(6 DOWNTO 5) = "00" THEN
                    SCL <= '0';
                ELSIF clockDiv(6 DOWNTO 5) = "01" THEN
                    SCL <= '1';
                ELSIF clockDiv = "1111111" THEN
                    bitSend <= bitSend + 1;
                    IF bitSend = 7 THEN
                        currentState <= RCV;
                    END IF;
                ELSIF clockDiv(6 DOWNTO 5) = "11" THEN
                    SCL <= '0';
                END IF;
            WHEN IDLE => IF enable THEN
                complete <= '0';
                clockDiv <= (OTHERS => '0');
                bitSend <= 0;
                isSend <= '0';
                currentState <= instruction;
            END IF;
            WHEN DONE => complete <= '1';
                IF NOT enable THEN
                    currentState <= IDLE;
                END IF;
            WHEN SEND => isSend <= '1';
                SDAout <= '0';
                clockDiv <= clockDiv + '1';
                IF clockDiv(6 DOWNTO 5) = "01" THEN
                    SCL <= '1';
                ELSIF clockDiv = "1111111" THEN
                    currentState <= DONE;
                ELSIF clockDiv(6 DOWNTO 5) = "11" THEN
                    SCL <= '0';
                END IF;
            WHEN RCV => isSend <= '0';
                clockDiv <= clockDiv + '1';
                IF clockDiv(6 DOWNTO 5) = "01" THEN
                    SCL <= '1';
                ELSIF clockDiv = "1111111" THEN
                    currentState <= DONE;
                ELSIF clockDiv(6 DOWNTO 5) = "11" THEN
                    SCL <= '0';
                END IF;
            END CASE;
        END IF;
    END PROCESS;
END ARCHITECTURE;
