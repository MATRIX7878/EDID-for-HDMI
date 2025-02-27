LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD_UNSIGNED.ALL;

ENTITY conv IS
    PORT(clk : IN STD_LOGIC;
         char : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
         thou, hund, tens, ones : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0')
        );
END ENTITY;

ARCHITECTURE behavior OF conv IS
TYPE part IS (INTS, BASE, THO, HUN, TEN, ONE);
SIGNAL currentPart, nextPart : part := INTS;

TYPE bits IS ARRAY (11 DOWNTO 0) OF INTEGER RANGE 0 TO 1;
SIGNAL int, newInt : bits := (OTHERS => 0);

SIGNAL newThou, newHund, newTens, newOnes, placeOne, placeTwo, placeThree, placeFour : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

SIGNAL cache, newCache : INTEGER RANGE 0 TO 8096 := 0;

BEGIN
    thou <= placeOne;
    hund <= placeTwo;
    tens <= placeThree;
    ones <= placeFour;

    PROCESS(ALL)
    BEGIN
        nextPart <= currentPart;
        newInt <= int;
        newCache <= cache;
        newThou <= placeOne;
        newHund <= placeTwo;
        newTens <= placeThree;
        newOnes <= placeFour;

        CASE currentPart IS
        WHEN INTS => FOR i IN 0 TO 11 LOOP
            newInt(i) <= 1 WHEN char(i) ELSE 0;
        END LOOP;
            nextPart <= BASE;
        WHEN BASE => newCache <= int(11) * 2048 + int(10) * 1024 + int(9) * 512 + int(8) * 256 + int(7) * 128 + int(6) * 64 + int(5) * 32 + int(4) * 16 + int(3) * 8 + int(2) * 4 + int(1) * 2 + int(0) * 1;
            nextPart <= THO;
        WHEN THO => IF cache >= 8000 THEN
            newThou <= TO_STDLOGICVECTOR(48, 8) + d"8";
            newCache <= cache - 8000;
        ELSIF cache >= 7000 AND cache <= 7999 THEN
            newThou <= TO_STDLOGICVECTOR(48, 8) + d"7";
            newCache <= cache - 7000;
        ELSIF cache >= 6000 AND cache <= 6999 THEN
            newThou <= TO_STDLOGICVECTOR(48, 8) + d"6";
            newCache <= cache - 6000;
        ELSIF cache >= 5000 AND cache <= 5999 THEN
            newThou <= TO_STDLOGICVECTOR(48, 8) + d"5";
            newCache <= cache - 5000;
        ELSIF cache >= 4000 AND cache <= 4999 THEN
            newThou <= TO_STDLOGICVECTOR(48, 8) + d"4";
            newCache <= cache - 4000;
        ELSIF cache >= 3000 AND cache <= 3999 THEN
            newThou <= TO_STDLOGICVECTOR(48, 8) + d"3";
            newCache <= cache - 3000;
        ELSIF cache >= 2000 AND cache <= 2999 THEN
            newThou <= TO_STDLOGICVECTOR(48, 8) + d"2";
            newCache <= cache - 2000;
        ELSIF cache >= 1000 AND cache <= 1999 THEN
            newThou <= TO_STDLOGICVECTOR(48, 8) + "1";
            newCache <= cache - 1000;
        ELSE
            newThou <= TO_STDLOGICVECTOR(48, 8);
        END IF;
            nextPart <= HUN;
        WHEN HUN => IF cache >= 900 AND cache <= 999 THEN
            newHund <= TO_STDLOGICVECTOR(48, 8) + d"9";
            newCache <= cache - 900;
        ELSIF cache >= 800 AND cache <= 899 THEN
            newHund <= TO_STDLOGICVECTOR(48, 8) + d"8";
            newCache <= cache - 800;
        ELSIF cache >= 700 AND cache <= 799 THEN
            newHund <= TO_STDLOGICVECTOR(48, 8) + d"7";
            newCache <= cache - 700;
        ELSIF cache >= 600 AND cache <= 699 THEN
            newHund <= TO_STDLOGICVECTOR(48, 8) + d"6";
            newCache <= cache - 600;
        ELSIF cache >= 500 AND cache <= 599 THEN
            newHund <= TO_STDLOGICVECTOR(48, 8) + d"5";
            newCache <= cache - 500;
        ELSIF cache >= 400 AND cache <= 499 THEN
            newHund <= TO_STDLOGICVECTOR(48, 8) + d"4";
            newCache <= cache - 400;
        ELSIF cache >= 300 AND cache <= 399 THEN
            newHund <= TO_STDLOGICVECTOR(48, 8) + d"3";
            newCache <= cache - 300;
        ELSIF cache >= 200 AND cache <= 299 THEN
            newHund <= TO_STDLOGICVECTOR(48, 8) + d"2";
            newCache <= cache - 200;
        ELSIF cache >= 100 AND cache <= 199 THEN
            newHund <= TO_STDLOGICVECTOR(48, 8) + "1";
            newCache <= cache - 100;
        ELSE
            newHund <= TO_STDLOGICVECTOR(48, 8);
        END IF;
            nextPart <= TEN;
        WHEN TEN => IF cache >= 90 AND cache <= 99 THEN
            newTens <= TO_STDLOGICVECTOR(48, 8) + d"9";
            newCache <= cache - 90;
        ELSIF cache >= 80 AND cache <= 89 THEN
            newTens <= TO_STDLOGICVECTOR(48, 8) + d"8";
            newCache <= cache - 80;
        ELSIF cache >= 70 AND cache <= 79 THEN
            newTens <= TO_STDLOGICVECTOR(48, 8) + d"7";
            newCache <= cache - 70;
        ELSIF cache >= 60 AND cache <= 69 THEN
            newTens <= TO_STDLOGICVECTOR(48, 8) + d"6";
            newCache <= cache - 60;
        ELSIF cache >= 50 AND cache <= 59 THEN
            newTens <= TO_STDLOGICVECTOR(48, 8) + d"5";
            newCache <= cache - 50;
        ELSIF cache >= 40 AND cache <= 49 THEN
            newTens <= TO_STDLOGICVECTOR(48, 8) + d"4";
            newCache <= cache - 40;
        ELSIF cache >= 30 AND cache <= 39 THEN
            newTens <= TO_STDLOGICVECTOR(48, 8) + d"3";
            newCache <= cache - 30;
        ELSIF cache >= 20 AND cache <= 29 THEN
            newTens <= TO_STDLOGICVECTOR(48, 8) + d"2";
            newCache <= cache - 20;
        ELSIF cache >= 10 AND cache <= 19 THEN
            newTens <= TO_STDLOGICVECTOR(48, 8) + "1";
            newCache <= cache - 10;
        ELSE
            newTens <= TO_STDLOGICVECTOR(48, 8);
        END IF;
            nextPart <= ONE;
        WHEN ONE =>	newOnes <= TO_STDLOGICVECTOR(48, 8) + TO_STDLOGICVECTOR(cache, 4);
            nextPart <= INTS;
        END CASE;
    END PROCESS;

    PROCESS(clk)
    BEGIN
        IF RISING_EDGE(clk) THEN
            currentPart <= nextPart;
            int <= newInt;
            cache <= newCache;
            placeOne <= newThou;
            placeTwo <= newHund;
            placeThree <= newTens;
            placeFour <= newOnes;
        END IF;
    END PROCESS;
END ARCHITECTURE;
