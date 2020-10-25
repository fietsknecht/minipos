REM ##############################
REM # MiniPOS
REM #
REM # QB64 versie 16/10/2020
REM # bugs: uitlijnen bedragen in startscherm
REM ##############################

'CLEAR
SCREEN 0
$RESIZE:STRETCH
i& = _LOADIMAGE("euro.bmp", 32) '<<<<<<< use your image file name here
IF i& < -1 THEN
    _ICON i&
    _FREEIMAGE i& ' release image handle after setting icon
END IF
$EXEICON:'euro.ico'
_ICON

COMMON dezemaand

_PALETTECOLOR 1, _RGB32(255, 255, 255) ' white
_PALETTECOLOR 2, _RGB32(168, 168, 168) ' light grey
_PALETTECOLOR 3, _RGB32(84, 84, 84) ' dark grey
f& = _LOADFONT("font\AtariST8x16SystemFont.ttf", 16, "monospace")
_MAPUNICODE 8364 TO 128 'map euro sign to ascii 128
_MAPUNICODE 169 TO 169 'map copyright sign to ascii 169
_FONT f&
COLOR 0, 1
CLS
_TITLE "MiniPOS"

DIM SHARED allLines$(100)
DIM SHARED billProducts$(10)
DIM SHARED montotal$(12)

DO
    CLEAR
    CALL gettotals
    CALL welcome
LOOP UNTIL INKEY$ = CHR$(27)
SYSTEM

SUB nieuwebon
    SHARED complete%, dezemaand, dezemaandoud, startover%
    CLS
    CALL readlast
    CALL header
    CALL getCustomer
    IF startover% = 1 THEN
        startover% = 0
        GOTO klaar
    END IF
    CALL wis
    CALL getProduct
    IF startover% = 1 THEN
        startover% = 0
        GOTO klaar
    END IF
    DO
        CALL wis
        CALL overview
        CALL addProduct
    LOOP UNTIL complete% = 1 OR startover% = 1
    IF startover% = 1 THEN
        startover% = 0
        GOTO klaar
    END IF
    CALL wis
    CALL payment
    IF startover% = 1 THEN
        startover% = 0
        GOTO klaar
    END IF
    CALL wis
    CALL opmerking
    CALL savelast
    CALL makeprint
    CALL wis
    CALL writetotals
    klaar:
END SUB

SUB opmerking
    SHARED last$, remark$
    CALL statusline("<Enter>: verder")
    LOCATE 2, 1
    INPUT "Opmerking: ", remark$
    IF remark$ <> "" THEN
        OPEN "data\opmerking.txt" FOR APPEND AS #1
        PRINT #1, "2020" + last$ + " " + remark$
        CLOSE #1
    END IF
END SUB

SUB zoekopmerking (bijdezebon$)
    OPEN "data\opmerking.txt" FOR INPUT AS #1
    opm$ = "Geen opmerking gevonden"
    WHILE NOT EOF(1)
        LINE INPUT #1, myLine$
        IF LEFT$(myLine$, 8) = bijdezebon$ THEN
            opm$ = myLine$
        END IF
    WEND
    LOCATE 10, 1
    FOR i% = 1 TO 14
        PRINT STRING$(80, " ")
    NEXT i%
    LOCATE 10, 1
    PRINT opm$
    statusline ("Druk een toets...")
    DO
        k$ = INKEY$
    LOOP UNTIL k$ <> ""
    CLOSE #1
END SUB

SUB sumup
    SHARED tot$
    statusline ("PIN activeren...")
    pinbedrag$ = LTRIM$(tot$)
    punt = INSTR(pinbedrag$, ".")
    pinbedrag$ = MID$(pinbedrag$, 1, punt - 1) + RIGHT$(pinbedrag$, 2)
    sumupbedrag$ = STRING$(5 - LEN(pinbedrag$), "-") + pinbedrag$
    pw$ = "Cuijk2018!"
    smstxt$ = CHR$(34) + sumupbedrag$ + CHR$(34)
    smscmd$ = "tools\mailsend.exe -to +31634308043@mail-sms.com -q -from info@fietsknecht.nl -ssl -port 465 -auth -smtp smtp.bhosted.nl -sub " + CHR$(34) + CHR$(34) + " -user info@fietsknecht.nl -pass " + pw$ + " -M " + smstxt$
    SHELL _HIDE smscmd$
END SUB

SUB gettotals
    SHARED dag$, jaar$, dbdate$, today$, thismonth$, month$, availablemonths%, mtotal, jaartotaal, gemiddeld, dezemaand, vorigemaand, dezemaandoud
    thisdate$ = DATE$
    dag$ = MID$(thisdate$, 4, 2)
    maand$ = MID$(thisdate$, 1, 2)
    jaar$ = MID$(thisdate$, 7, 4)
    today$ = dag$ + "-" + maand$ + "-" + jaar$
    monthnr% = VAL(maand$)
    dbdate$ = jaar$ + maand$ + dag$
    CALL getmonth(monthnr%)
    thismonth$ = month$
    OPEN "data\mtotal.txt" FOR INPUT AS #1
    WHILE NOT EOF(1)
        LINE INPUT #1, myLine$
        IF LEFT$(myLine$, 1) <> "#" THEN
            availablemonths% = availablemonths% + 1
            montotal$(availablemonths%) = myLine$
        END IF
    WEND
    CLOSE #1
    dezemaand = VAL(RIGHT$(myLine$, 4))
    dezemaandoud = dezemaand
    FOR i% = 1 TO availablemonths% - 1
        jaartotaal = jaartotaal + VAL(RIGHT$(montotal$(i%), 4))
    NEXT i%
    vorigemaand = VAL(RIGHT$(montotal$(availablemonths% - 1), 4))
    gemiddeld = jaartotaal / availablemonths% - 1
    jaartotaal = jaartotaal + dezemaand
END SUB

SUB writetotals
    SHARED thismonth$, availablemonths%, dezemaand, tot$, dezemaandoud
    IF dezemaand <> dezemaandoud THEN
        OPEN "data\mtotal.txt" FOR OUTPUT AS #1
        FOR i% = 1 TO availablemonths% - 1
            PRINT #1, montotal$(i%)
        NEXT i%
        PRINT #1, thismonth$ + " " + STR$(dezemaand)
        CLOSE #1
    END IF
END SUB

SUB getmonth (num%)
    SHARED month$
    SELECT CASE num%
        CASE 1: month$ = "januari"
        CASE 2: month$ = "februari"
        CASE 3: month$ = "maart"
        CASE 4: month$ = "april"
        CASE 5: month$ = "mei"
        CASE 6: month$ = "juni"
        CASE 7: month$ = "juli"
        CASE 8: month$ = "augustus"
        CASE 9: month$ = "september"
        CASE 10: month$ = "oktober"
        CASE 11: month$ = "november"
        CASE 12: month$ = "december"
    END SELECT
END SUB

SUB welcome
    SHARED dag$, jaar$, thismonth$, shoot%, jaartotaal, gemiddeld, vorigemaand, dezemaand, tot$
    CLS
    CALL header
    '            12345678901234567890123456789012345678901234567890123456789012345678901234567890
    statusline ("<N>ieuwe bon           <O>penstaand          <H>istorie              <ESC>: Stop")
    LOCATE 3, 1
    PRINT STRING$(20, " "); "KK  KK    AA     SSSSS   SSSSS    AA"
    PRINT STRING$(20, " "); "KK KK    A  A   SS      SS       A  A"
    PRINT STRING$(20, " "); "KKKK     A  A    SSSS    SSSS    A  A"
    PRINT STRING$(20, " "); "KK KK   AAAAAA      SS      SS  AAAAAA"
    PRINT STRING$(20, " "); "KK  KK  AA  AA  SSSSS   SSSSS   AA  AA"
    LOCATE 10, 1
    gemiddeld = _ROUND(gemiddeld)
    IF LEFT$(dag$, 1) = "0" THEN
        dag$ = RIGHT$(dag$, 1)
    END IF
    PRINT dag$; " "; thismonth$; " "; jaar$
    PRINT "Totale omzet dit jaar     :"; STRING$(6 - LEN(STR$(jaartotaal)), " "); jaartotaal
    PRINT "Gemiddelde omzet per maand:"; STRING$(6 - LEN(STR$(gemiddeld)), " "); gemiddeld
    PRINT "Omzet afgelopen maand     :"; STRING$(6 - LEN(STR$(vorigemaand)), " "); vorigemaand
    PRINT "Omzet deze maand          :"; STRING$(6 - LEN(STR$(dezemaand)), " "); dezemaand
    DO
        k$ = INKEY$
    LOOP UNTIL k$ <> ""
    k$ = LCASE$(k$)
    SELECT CASE k$
        CASE CHR$(27): SYSTEM
        CASE "o": parked
        CASE "n": nieuwebon
        CASE "h": history
    END SELECT
END SUB

SUB history
    SHARED selectedLine$, startover%
    LOCATE 10, 1
    FOR i% = 1 TO 13
        PRINT STRING$(80, " ");
    NEXT i%
    i% = 0
    CALL readAndSelect("database.csv", "Historie  ", 1, 78, "za")
    IF startover% = 1 GOTO klaar
    gekozenbon$ = MID$(selectedLine$, 10, 8)
    gekozennaam$ = MID$(selectedLine$, 19, 22)
    LOCATE 10, 1
    OPEN "bonnen\" + gekozenbon$ + ".rtf" FOR INPUT AS #1
    WHILE NOT EOF(1)
        i% = i% + 1
        LINE INPUT #1, myLine$
        IF i% > 290 AND LEFT$(myLine$, 3) <> "---" THEN
            IF LEFT$(myLine$, 7) <> "Bedankt" THEN
                PRINT LEFT$(myLine$, LEN(myLine$) - 4)
            END IF
        END IF
    WEND
    CLOSE #1
    '            12345678901234567890123456789012345678901234567890123456789012345678901234567890
    statusline ("<B>on printen                <F>actuur printen              <O>pmerking bekijken")
    DO
        k$ = INKEY$
        k$ = LCASE$(k$)
    LOOP UNTIL k$ = "b" OR k$ = "f" OR k$ = "o"
    IF k$ = "b" THEN
        SHELL _HIDE "tools\printwp.bat bonnen\" + gekozenbon$ + ".rtf"
    END IF
    IF k$ = "f" THEN
        CALL printfactuur(gekozenbon$, gekozennaam$)
    END IF
    IF k$ = "o" THEN
        CALL zoekopmerking(gekozenbon$)
    END IF
    klaar:
END SUB

SUB printfactuur (dezebon$, dezenaam$)
    SHARED today$
    ' naw van dezenaam$ lezen
    OPEN "data\customer.txt" FOR INPUT AS #1
    WHILE NOT EOF(1)
        LINE INPUT #1, myLine$
        IF LEFT$(myLine$, 22) = dezenaam$ THEN
            bedrijf$ = RTRIM$(MID$(myLine$, 150, 20))
            naam$ = RTRIM$(MID$(myLine$, 1, 22))
            straat$ = RTRIM$(MID$(myLine$, 70, 29))
            plaats$ = RTRIM$(MID$(myLine$, 100, 19))
            land$ = RTRIM$(MID$(myLine$, 120, 29))
        END IF
    WEND
    CLOSE #1
    ' producten van dezebon$ lezen
    OPEN "bonnen\" + dezebon$ + ".rtf" FOR INPUT AS #1
    WHILE NOT EOF(1)
        LINE INPUT #1, myLine$
        i% = i% + 1
        IF i% > 295 THEN
            IF LEFT$(myLine$, 6) = "Totaal" THEN
                factuurtotaal$ = MID$(myLine$, LEN(myLine$) - 10, 7)
                stopit% = 1
            END IF
            IF INSTR(myLine$, "BTW") THEN
                factuurbtw$ = MID$(myLine$, LEN(myLine$) - 10, 7)
                betaalregel% = i%
            END IF
            IF i% = betaalregel% + 1 THEN
                factuurbetaalwijze$ = MID$(myLine$, 1, LEN(myLine$) - 4)
            END IF
            IF stopit% <> 1 THEN
                art% = art% + 1
                SELECT CASE art%
                    CASE 1: artikel1$ = LEFT$(myLine$, 17) + STRING$(41, " ") + RIGHT$(myLine$, 7)
                    CASE 2: artikel2$ = myLine$
                    CASE 3: artikel3$ = myLine$
                    CASE 4: artikel4$ = myLine$
                    CASE 5: artikel5$ = myLine$
                    CASE 6: artikel6$ = myLine$
                    CASE 7: artikel7$ = myLine$
                    CASE 8: artikel8$ = myLine$
                    CASE 9: artikel9$ = myLine$
                    CASE 10: artikel10$ = myLine$
                END SELECT
            END IF
        END IF
    WEND
    CLOSE #1
    ' search and replace doen met factuursjabloon
    OPEN "factuursjabloon.rtf" FOR INPUT AS #1
    OPEN "fact" + dezebon$ + ".rtf" FOR OUTPUT AS #2
    WHILE NOT EOF(1)
        i% = i% + 1
        LINE INPUT #1, myLine$
        IF INSTR(myLine$, "<datum>") THEN
            myLine$ = strReplace$(myLine$, "<datum>", today$)
        END IF
        IF INSTR(myLine$, "<factuurnr>") THEN
            myLine$ = strReplace$(myLine$, "<factuurnr>", dezebon$)
        END IF
        IF INSTR(myLine$, "<bedrijf>") THEN
            myLine$ = strReplace$(myLine$, "<bedrijf>", bedrijf$)
        END IF
        IF INSTR(myLine$, "<naam>") THEN
            myLine$ = strReplace$(myLine$, "<naam>", naam$)
        END IF
        IF INSTR(myLine$, "<straat>") THEN
            myLine$ = strReplace$(myLine$, "<straat>", straat$)
        END IF
        IF INSTR(myLine$, "<plaats>") THEN
            myLine$ = strReplace$(myLine$, "<plaats>", plaats$)
        END IF
        IF INSTR(myLine$, "<land>") THEN
            myLine$ = strReplace$(myLine$, "<land>", land$)
        END IF
        IF INSTR(myLine$, "<artikel1>") THEN
            myLine$ = strReplace$(myLine$, "<artikel1>", artikel1$)
        END IF
        IF INSTR(myLine$, "<artikel2>") THEN
            myLine$ = strReplace$(myLine$, "<artikel2>", artikel2$)
        END IF
        IF INSTR(myLine$, "<artikel3>") THEN
            myLine$ = strReplace$(myLine$, "<artikel3>", artikel3$)
        END IF
        IF INSTR(myLine$, "<artikel4>") THEN
            myLine$ = strReplace$(myLine$, "<artikel4>", artikel4$)
        END IF
        IF INSTR(myLine$, "<artikel5>") THEN
            myLine$ = strReplace$(myLine$, "<artikel5>", artikel5$)
        END IF
        IF INSTR(myLine$, "<artikel6>") THEN
            myLine$ = strReplace$(myLine$, "<artikel6>", artikel6$)
        END IF
        IF INSTR(myLine$, "<artikel7>") THEN
            myLine$ = strReplace$(myLine$, "<artikel7>", artikel7$)
        END IF
        IF INSTR(myLine$, "<artikel8>") THEN
            myLine$ = strReplace$(myLine$, "<artikel8>", artikel8$)
        END IF
        IF INSTR(myLine$, "<artikel9>") THEN
            myLine$ = strReplace$(myLine$, "<artikel9>", artikel9$)
        END IF
        IF INSTR(myLine$, "<artikel10>") THEN
            myLine$ = strReplace$(myLine$, "<artikel10>", artikel10$)
        END IF
        IF INSTR(myLine$, "<totaal>") THEN
            myLine$ = strReplace$(myLine$, "<totaal>", factuurtotaal$)
        END IF
        IF INSTR(myLine$, "<btw>") THEN
            myLine$ = strReplace$(myLine$, "<btw>", factuurbtw$)
            bregel% = i%
        END IF
        IF i% = bregel% + 2 THEN
            'myLine$ = factuurbetaalwijze$ + RIGHT$(myLine$, 4)
            myLine$ = strReplace$(myLine$, "<betaalwijze>", factuurbetaalwijze$)
            ' factuurbetaalwijze$ = ""
        END IF
        PRINT #2, myLine$
    WEND
    CLOSE #1
    CLOSE #2
    SHELL _HIDE "tools\openwp.bat fact" + dezebon$ + ".rtf"
END SUB

SUB parked
    SHARED dbdate$, bedrag$, selectedLine$, today$, tot$, dezemaand, startover%
    CLS
    CALL header
    OPEN "data\park.txt" FOR INPUT AS #1
    le = LOF(1)
    CLOSE #1
    IF le >= 8 THEN
        CALL readAndSelect("park.txt", "Openstaand", 2, 39, "")
        IF startover% = 1 GOTO klaar
        selectedPark$ = selectedLine$
        paythis$ = LEFT$(selectedPark$, 8)
        naamplusbedrag$ = MID$(selectedPark$, 10, 29)
        tot$ = MID$(selectedPark$, 33, 6)
        LOCATE 10, 1
        OPEN "bonnen\" + paythis$ + ".prk.rtf" FOR INPUT AS #2
        OPEN "bon.rtf" FOR OUTPUT AS #3
        WHILE NOT EOF(2)
            i% = i% + 1
            LINE INPUT #2, myLine$
            IF i% <= 290 THEN
                PRINT #3, myLine$
            ELSE
                IF LEFT$(myLine$, 5) = "Datum" THEN
                    myLine$ = "Datum: " + today$ + "\par"
                END IF
                IF LEFT$(myLine$, 6) = "Totaal" THEN
                    bedrag$ = MID$(myLine$, 18, 6)
                END IF
                IF myLine$ = "In de wacht\par" THEN
                    x% = CSRLIN
                    CALL readAndSelect("payment.txt", "Betaalwijze", 1, 30, "")
                    IF startover% = 1 GOTO klaar
                    finalPay$ = selectedLine$
                    LOCATE x%, 1
                    PRINT finalPay$
                    PRINT #3, finalPay$ + "\par"
                ELSE
                    PRINT #3, myLine$
                    IF LEFT$(myLine$, 3) <> "---" THEN
                        PRINT LEFT$(myLine$, LEN(myLine$) - 4)
                    END IF
                END IF
            END IF
        WEND
        CLOSE #2
        CLOSE #3
        statusline ("Bon printen? (J/n)")
        DO
            k$ = INKEY$
        LOOP UNTIL k$ <> ""
        statusline ("Momentje...")
        IF finalPay$ = "Betaald met PIN" THEN
            CALL sumup
        END IF
        IF LCASE$(k$) <> "n" THEN
            SHELL _HIDE "tools\printwp.bat bon.rtf"
        END IF
        SHELL _HIDE "copy bon.rtf bonnen\" + paythis$ + ".rtf"
        SHELL _HIDE "del bonnen\" + paythis$ + ".prk.rtf"
        SHELL _HIDE "if exist data\parkbak.txt del data\parkbak.txt"
        SHELL _HIDE "ren data\park.txt parkbak.txt"
        OPEN "data\parkbak.txt" FOR INPUT AS #1
        OPEN "data\park.txt" FOR OUTPUT AS #2
        WHILE NOT EOF(1)
            LINE INPUT #1, myLine$
            IF LEFT$(myLine$, 8) <> paythis$ AND myLine$ <> "" THEN
                PRINT #2, myLine$
            END IF
        WEND
        CLOSE #1
        CLOSE #2
        SHELL _HIDE "if exist del data\database.bak"
        SHELL _HIDE "ren data\database.csv database.bak"
        OPEN "data\database.csv" FOR APPEND AS #1
        PRINT #1, dbdate$; " "; paythis$; " "; naamplusbedrag$; " "; finalPay$
        CLOSE #1
        dezemaand = dezemaand + VAL(bedrag$)
        CALL writetotals
    ELSE
        LOCATE 3, 1
        PRINT "Geen openstaande bonnen"
        statusline ("Druk een toets...")
        DO
        LOOP UNTIL INKEY$ <> ""
    END IF
    klaar:
END SUB

SUB readlast
    SHARED last%, last$
    OPEN "data\last.txt" FOR INPUT AS #1
    LINE INPUT #1, myLine$
    last% = VAL(myLine$)
    last% = last% + 1
    last$ = RIGHT$(STR$(last%), LEN(STR$(last%)) - 1)
    SELECT CASE LEN(last$)
        CASE 1
            last$ = "000" + last$
        CASE 2
            last$ = "00" + last$
        CASE 3
            last$ = "0" + last$
    END SELECT
    CLOSE #1
END SUB

SUB savelast
    SHARED last$
    OPEN "data\last.txt" FOR OUTPUT AS #1
    PRINT #1, last$
    CLOSE #1
END SUB

SUB writecsv
    SHARED dbdate$, tot$, btw$, last$, customer$, today$, pay$
    IF pay$ <> "In de wacht" THEN
        customer$ = LEFT$(customer$, 22)
        csvtxt$ = dbdate$ + " " + "2020" + last$ + " " + customer$ + " " + tot$ + " " + pay$
        OPEN "data\database.csv" FOR APPEND AS #1
        PRINT #1, csvtxt$
        CLOSE #1
    END IF
END SUB

SUB makeprint
    SHARED dezemaand, tel$, tot$, tottxt$, btwtxt$, pay$, nProducts%, last$, customer$, today$
    IF pay$ = "In de wacht" THEN
        smssent$ = "SMS-N"
        IF LEN(tel$) = 12 AND LEFT$(tel$, 1) = "+" THEN
            statusline ("SMS versturen naar " + tel$ + "? (j/N)")
            DO
                k$ = INKEY$
            LOOP UNTIL k$ <> ""
            IF LCASE$(k$) = "j" THEN 'stuur sms
                statusline ("Momentje...")
                pw$ = "Cuijk2018!"
                ' max 160 tekens
                smstxt$ = CHR$(34) + "Je fiets is klaar. Kosten EUR " + tot$ + ". Groet, Rob de Fietsknecht. T 0485-234500 E info@fietsknecht.nl (Dit is een automatisch bericht. Je kunt niet reageren.)" + CHR$(34)
                ' sms via CM Mail-SMS:
                smscmd$ = "tools\mailsend.exe -to +" + tel$ + "@mail-sms.com -q -from info@fietsknecht.nl -ssl -port 465 -auth -smtp smtp.bhosted.nl -sub " + CHR$(34) + CHR$(34) + " -user info@fietsknecht.nl -pass " + pw$ + " -M " + smstxt$
                SHELL _HIDE smscmd$
                smssent$ = "SMS-Y"
                '            12345678901234567890123456789012345678901234567890123456789012345678901234567890
                statusline ("SMS verstuurd")
                SLEEP 2
            END IF
        END IF
    END IF
    IF pay$ = "Betaald met PIN" THEN
        CALL sumup
    END IF
    OPEN "bon.rtf" FOR OUTPUT AS #1
    OPEN "data\kop.txt" FOR INPUT AS #2
    k$ = ""
    ' max 23    -----------------------
    WHILE NOT EOF(2)
        LINE INPUT #2, myLine$
        PRINT #1, myLine$
    WEND
    CLOSE #2
    PRINT #1, "Datum: "; today$; "\par"
    PRINT #1, "Bon  : 2020"; last$; "\par"
    PRINT #1, STRING$(23, "-"); "\par"
    PRINT #1, LEFT$(customer$, 22); "\par"
    PRINT #1, STRING$(23, "-"); "\par"
    FOR i% = 1 TO nProducts%
        PRINT #1, LEFT$(billProducts$(i%), 23); "\par"
    NEXT i%
    PRINT #1, tottxt$; "\par"
    PRINT #1, btwtxt$; "\par"
    PRINT #1, pay$; "\par"
    PRINT #1, STRING$(23, "-"); "\par"
    PRINT #1, "Bedankt en tot ziens!\par"
    PRINT #1, "}"
    CLOSE #1
    'CALL writecsv
    IF pay$ <> "In de wacht" THEN
        k$ = ""
        ' wil je printen?
        statusline ("Bon printen? (J/n)")
        DO
            k$ = INKEY$
        LOOP UNTIL k$ <> ""
        CALL statusline("Momentje...")
        IF LCASE$(k$) <> "n" THEN
            SHELL _HIDE "tools\printwp.bat bon.rtf"
        END IF
        SHELL _HIDE "copy bon.rtf bonnen\2020" + last$ + ".rtf"
        dezemaand = dezemaand + VAL(tot$)
    ELSE
        SHELL _HIDE "copy bon.rtf bonnen\2020" + last$ + ".prk.rtf"
        OPEN "data\park.txt" FOR APPEND AS #1
        PRINT #1, "2020" + last$ + " " + LEFT$(customer$, 22) + " " + tot$ + " " + smssent$ + " " + pay$
        CLOSE #1
        tot$ = ""
    END IF
    CALL writecsv
END SUB

SUB payment
    SHARED selectedLine$, pay$
    CALL readAndSelect("payment.txt", "Betaalwijze ", 0, 30, "")
    pay$ = selectedLine$
    CALL overview
END SUB

SUB overview
    SHARED complete%, tot$, tottxt$, btw$, btwtxt$, customer$, last$, nProducts%, pay$, amount, today$
    LOCATE 10, 1
    PRINT "Datum: " + today$
    PRINT "Bon  : 2020" + last$
    PRINT LEFT$(customer$, 22)
    FOR i% = 1 TO nProducts%
        PRINT LEFT$(billProducts$(i%), 23)
    NEXT i%
    IF complete% = 1 THEN
        amount100 = 100 * amount
        tot = _ROUND(amount100) / 100
        tot$ = STR$(tot)
        tot$ = LTRIM$(tot$)
        l% = LEN(tot$)
        IF LEFT$(RIGHT$(tot$, 2), 1) = "." THEN 'bijv. 7.5
            tot$ = tot$ + "0" 'wordt 7.50
        END IF
        IF INSTR(1, tot$, ".") = 0 THEN 'bijv. 5
            tot$ = tot$ + ".00" 'wordt 5.00
        END IF
        IF LEN(tot$) = 4 THEN
            tot$ = "  " + tot$
        END IF
        IF LEN(tot$) = 5 THEN
            tot$ = " " + tot$
        END IF
        tottxt$ = "Totaal : " + STRING$(12 - LEN(tot$), " ") + CHR$(128) + " " + tot$
        PRINT tottxt$
        exbtw = (amount / 1.21)
        exbtw100 = 100 * exbtw
        exbtw = _ROUND(exbtw100) / 100
        exbtw$ = STR$(exbtw)
        btw = (amount - exbtw)
        btw100 = 100 * btw
        btw = _ROUND(btw100) / 100
        btw$ = STR$(btw)
        btw$ = RIGHT$(btw$, LEN(btw$) - 1)
        IF LEFT$(btw$, 1) = "." THEN
            btw$ = "0" + btw$
        END IF
        IF LEFT$(RIGHT$(btw$, 2), 1) = "." THEN
            btw$ = btw$ + "0"
        END IF
        IF LEN(btw$) = 4 THEN
            btw$ = "  " + btw$
        END IF
        IF LEN(btw$) = 5 THEN
            btw$ = " " + btw$
        END IF
        btwtxt$ = "Incl. 21% BTW: " + CHR$(128) + " " + btw$
        PRINT btwtxt$
    END IF
    PRINT pay$
END SUB

SUB header
    LOCATE 1, 1
    COLOR 1, 0
    PRINT "                                    MiniPOS                   " + CHR$(169) + " Fietsknecht 2020";
    LOCATE 9, 1
    COLOR 1, 2
    PRINT STRING$(35, " "); "OVERZICHT"; STRING$(36, " ");
    COLOR 0, 1
END SUB

SUB wis
    LOCATE 2, 1
    FOR i% = 1 TO 7
        PRINT STRING$(80, " ");
    NEXT i%
END SUB

SUB statusline (sl$)
    LOCATE 25, 1
    COLOR 1, 0
    PRINT STRING$(80, " ");
    LOCATE 25, 1, 0
    PRINT sl$;
    COLOR 0, 1
END SUB


'------------------------------------------------------------
SUB getCustomer
    SHARED selectedLine$, customer$, tel$, addnew%
    CALL readAndSelect("customer.txt", "Zoek klant  ", 1, 38, "az")
    IF addnew% = 1 THEN
        CALL wis
        CALL statusline("Nieuwe klant toevoegen")
        LOCATE 2, 1
        PRINT "Nieuwe klant"
        INPUT "Naam: ", cname$
        INPUT "Tel. (incl. +31): ", tel$
        customer$ = cname$ + STRING$(26 - LEN(cname$), " ") + tel$
        IF customer$ <> "" THEN
            OPEN "data\customer.txt" FOR APPEND AS #1
            PRINT #1, customer$
            CLOSE #1
        END IF
        addnew% = 0
    ELSE
        customer$ = selectedLine$
        tel$ = MID$(customer$, 27, 12)
    END IF
    CALL overview
END SUB
'------------------------------------------------------------

'------------------------------------------------------------
SUB getProduct
    SHARED selectedLine$, product$, nProducts%, amount, addnew%
    CALL readAndSelect("product.txt", "Zoek product", 1, 23, "")
    IF addnew% = 1 THEN
        CALL wis
        LOCATE 2, 1
        PRINT "Nieuw product"
        INPUT "Naam : ", pname$
        INPUT "Prijs: ", pprice$
        product$ = pname$ + STRING$(22 - LEN(pname$), " ") + pprice$
        IF product$ <> "" THEN
            OPEN "data\product.txt" FOR APPEND AS #1
            PRINT #1, product$
            CLOSE #1
        END IF
        addnew% = 0
    ELSE
        product$ = selectedLine$
    END IF
    IF product$ <> "" THEN
        nProducts% = nProducts% + 1
        amount = amount + VAL(MID$(product$, 18, 6))
        billProducts$(nProducts%) = product$
    END IF
END SUB
'----------------------------------------------------

'----------------------------------------------------
SUB addProduct
    SHARED complete%
    '          12345678901234567890123456789012345678901234567890123456789012345678901234567890
    status$ = "<Spatie>: Product toevoegen                                      <Enter>: Verder"
    CALL statusline(status$)
    DO
        k$ = INKEY$
    LOOP UNTIL k$ = CHR$(32) OR k$ = CHR$(13)
    IF k$ = CHR$(32) THEN
        CALL getProduct
    ELSE
        complete% = 1
    END IF
    CALL overview
END SUB
'----------------------------------------------------

'------------------------------------------------------------
SUB readAndSelect (fileName$, st$, insallowed%, characters%, sort$)
    SHARED selectedLine$, addnew%, startover%
    'DIM allLines$(100)
    DIM matches%(100)
    i% = 0
    offset% = 1
    shift% = 0
    OPEN "data\" + fileName$ FOR INPUT AS #1
    i% = 0
    WHILE NOT EOF(1)
        LINE INPUT #1, myLine$
        IF LEFT$(myLine$, 1) <> "#" THEN
            myLine$ = LEFT$(myLine$, characters%) 'alleen de eerste <characters%> tekens worden getoond
            i% = i% + 1
            allLines$(i%) = myLine$
        END IF
    WEND
    CLOSE #1
    IF sort$ = "az" THEN
        CALL bubbleSortAZ(allLines$(), i%)
    END IF
    IF sort$ = "za" THEN
        CALL bubbleSortZA(allLines$(), i%)
    END IF
    s$ = " "
    olds$ = ""
    DO
        k$ = INKEY$
        IF k$ = CHR$(0) + CHR$(72) THEN
            IF offset% > 1 THEN
                offset% = offset% - 1
                pt% = 1
                shift% = shift% + 1
            END IF
        END IF
        IF k$ = CHR$(0) + CHR$(80) THEN
            IF offset% < match% THEN
                offset% = offset% + 1
                shift% = shift% - 1
                pt% = 1
            END IF
        END IF
        IF insallowed% = 1 THEN
            IF k$ = CHR$(0) + CHR$(82) THEN
                addnew% = 1
                EXIT DO
            END IF
        END IF
        ' IF insallowed% = 2 THEN
        IF k$ = CHR$(27) THEN
            startover% = 1
            EXIT DO
            'RUN 'geeft probleem met $EXEICON
        END IF
        ' END IF
        IF INSTR("ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", UCASE$(k$)) >= 1 THEN
            s$ = s$ + k$
        END IF
        IF k$ = CHR$(8) AND LEN(s$) >= 1 THEN
            s$ = LEFT$(s$, LEN(s$) - 1)
        END IF
        IF s$ <> olds$ OR pt% = 1 THEN
            IF s$ = " " THEN
                s$ = ""
            END IF
            match% = 0
            FOR j% = 1 TO i%
                IF INSTR(LCASE$(allLines$(j%)), LCASE$(s$)) >= 1 THEN
                    match% = match% + 1
                    matches%(match%) = j%
                END IF
            NEXT j%
            CALL wis
            printrow% = 2
            LOCATE 2, 1
            PRINT st$; ": ";
            COLOR 1, 3
            PRINT s$;
            COLOR 0, 1
            LOCATE 2, 68
            PRINT "Treffers:"; match%;
            IF shift% > -5 THEN
                visible% = offset% + shift%
            ELSE
                visible% = offset% - 5
                shift% = -5
            END IF
            IF shift% > 0 THEN
                visible% = offset%
                shift% = 0
            END IF
            'statusline (STR$(shift%) + " " + STR$(offset%) + " " + STR$(visible%))
            IF match% <= 6 THEN
                visible% = offset% + shift%
            END IF
            IF s$ <> old$ AND pt% = 0 THEN
                visible% = 1
                offset% = 1
            END IF
            IF match% <= 5 THEN
                lastvisible% = visible% + match%
            ELSE
                lastvisible% = visible% + 5
            END IF
            FOR m% = visible% TO lastvisible%
                printrow% = printrow% + 1
                LOCATE (printrow%), 1
                IF m% = offset% THEN
                    COLOR 1, 3
                ELSE
                    COLOR 0, 1
                END IF
                IF m% <= match% AND m% <> 0 THEN
                    PRINT allLines$(matches%(m%));
                    COLOR 0, 1
                END IF
            NEXT m%
            SELECT CASE insallowed%
                CASE 0
                    '               12345678901234567890123456789012345678901234567890123456789012345678901234567890
                    instruction$ = "Geef zoekterm    Scroll met pijltoetsen                      <Enter>: Selecteer"
                CASE 1
                    instruction$ = "Geef zoekterm    Scroll met pijltoetsen     <INS>: Nieuw     <Enter>: Selecteer"
                CASE 2
                    instruction$ = "Geef zoekterm    Scroll met pijltoetsen     <Enter>: Selecteer     <ESC>: Terug"
            END SELECT
            statusline (instruction$)
            LOCATE 2, 15 + LEN(s$), 1
        END IF
        'shift% = 0
        olds$ = s$
        pt% = 0
    LOOP UNTIL k$ = CHR$(13)
    selectedLine$ = allLines$(matches%(offset%))
END SUB
'------------------------------------------------------------

FUNCTION strReplace$ (s$, replace$, new$) 'case sensitive
    strReplace$ = s$
    p = INSTR(s$, replace$)
    WHILE p
        strReplace$ = MID$(strReplace$, 1, p - 1) + new$ + MID$(strReplace$, p + LEN(replace$))
        p = INSTR(p + LEN(new$), strReplace$, replace$)
    WEND
END FUNCTION

SUB bubbleSortAZ (myArray$(), n%)
    DO
        OutOfOrder = 0 'assume it's sorted
        FOR x = 1 TO n% - 1
            IF myArray$(x) > myArray$(x + 1) THEN 'Compare adjaccent elements
                SWAP myArray$(x), myArray$(x + 1) 'if we had to swap,
                OutOfOrder = 1 '   then we're not done yet.
            END IF
        NEXT
    LOOP WHILE OutOfOrder = 1
END SUB

SUB bubbleSortZA (myArray$(), n%)
    DO
        OutOfOrder = 0 'assume it's sorted
        FOR x = 1 TO n% - 1
            IF myArray$(x) < myArray$(x + 1) THEN 'Compare adjaccent elements
                SWAP myArray$(x), myArray$(x + 1) 'if we had to swap,
                OutOfOrder = 1 '   then we're not done yet.
            END IF
        NEXT
    LOOP WHILE OutOfOrder = 1
END SUB

