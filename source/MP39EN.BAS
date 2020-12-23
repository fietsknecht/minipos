'###################################################
'#     MiniPOS - minimal Point Of Sale
'#
'#      in HiSoft Basic for Atari-ST 
'#       version 39EN    23/12/2020
'#
'# - fixed rounding in tax calculation
'#
'###################################################


' These are NOT remarks but compiler directives!
REM $DYNAMIC              ' Define arrays as dynamic
REM $OPTION k70           ' Use only 70k of memory and leave the rest to the system
REM $INCLUDE networld.bas ' Include the HiSoft BASIC TCP library

DEFINT a-z                ' All variables are integers unless otherwise specified

DIM SHARED logo$(5), allLines$(200), billProducts$(10), montotal$(12), matches(200), myArray$(200), comstr$(10)

' Start with an all black screen because position 25,80 needs to be black
' HBASIC won't do LOCATE 25,80: PRINT " "; without scrolling 
COLOR 0,1
CLS

' Main loop
DO
    CLEAR
    CALL init
    CALL gettotals
    CALL welcome
LOOP UNTIL INKEY$ = CHR$(27)

SYSTEM

'-----------------------------------------------------------
' SUBS

SUB init
  SHARED vat$, curpr$, taxpr$, datpr$, totpr$, recpr$, cuspr$, thapr$, smstxt$
  STATIC i, j, mline$
  OPEN "data\logo.txt" FOR INPUT AS #1
    FOR i = 1 TO 5
      LINE INPUT #1, mline$
      logo$(i) = mline$
    NEXT i
  CLOSE #1
  OPEN "data\minipos.cfg" FOR INPUT AS #2
      LINE INPUT #2, vat$
      LINE INPUT #2, curpr$
      LINE INPUT #2, taxpr$
      LINE INPUT #2, datpr$
      LINE INPUT #2, totpr$
      LINE INPUT #2, recpr$
      LINE INPUT #2, cuspr$
      LINE INPUT #2, thapr$
      LINE INPUT #2, smstxt$
  CLOSE #2
END SUB

SUB nieuwebon
    SHARED complete, dezemaand, dezemaandoud, startover
    CALL readlast
    CALL getCustomer
    IF startover = 1 THEN
        startover = 0
        GOTO klaar
    END IF
    CALL getProduct
    IF startover = 1 THEN
        startover = 0
        GOTO klaar
    END IF
    DO
        CALL addProduct
    LOOP UNTIL complete = 1 OR startover = 1
    IF startover = 1 THEN
        startover = 0
        GOTO klaar
    END IF
    CALL payment
    IF startover = 1 THEN
        startover = 0
        GOTO klaar
    END IF
    CALL opmerking
    CALL savelast
    CALL makeprint
    CALL writetotals
    klaar:
END SUB

SUB opmerking
    SHARED last$, remark$, jaar$
    STATIC i
    CALL statusline(" <Enter>: Continue")
    LOCATE 2,1
    FOR i = 2 TO 8
        LOCATE i,1
        PRINT SPACE$(80);
    NEXT i
    LOCATE 2, 1
    INPUT "Remark: ", remark$
    IF remark$ <> "" THEN
        OPEN "data\remark.txt" FOR APPEND AS #1
        PRINT #1, jaar$ + last$ + " " + remark$
        CLOSE #1
    END IF
END SUB

SUB zoekopmerking (bijdezebon$)
    STATIC opm$, myLine$, i, k$
    OPEN "data\remark.txt" FOR INPUT AS #1
    opm$ = "No remark found"
    WHILE NOT EOF(1)
        LINE INPUT #1, myLine$
        IF LEFT$(myLine$, 8) = bijdezebon$ THEN
            opm$ = myLine$
        END IF
    WEND
    LOCATE 10, 1
    FOR i = 10 TO 23
        LOCATE i,1
        PRINT SPACE$(80);
    NEXT i
    LOCATE 10, 1
    PRINT opm$;
    CALL statusline (" Press any key...")
    DO
        k$ = INKEY$
    LOOP UNTIL k$ <> ""
    CLOSE #1
END SUB

SUB gettotals
    SHARED availablemonths, dag$, jaar$, dbdate$, today$, thismonth$, month$, mtotal, jaartotaal, gemiddeld, dezemaand, vorigemaand, dezemaandoud
    STATIC k$, thisdate$, maand$, monthnr, myLine$, i
    availablemonths = 0
    thisdate$ = DATE$
    dag$ = MID$(thisdate$, 4, 2)
    maand$ = MID$(thisdate$, 1, 2)
' HiSoft Basic thinks 2020 is 20>0, so we have to correct this. Will it work for 2021? Surely not for 2030!
    jaar$ = MID$(thisdate$, 7, 2) + "2" + RIGHT$(thisdate$,1)
    today$ = dag$ + "-" + maand$ + "-" + jaar$
    monthnr = VAL(maand$)
    dbdate$ = jaar$ + maand$ + dag$
    CALL getmonth(monthnr)
    thismonth$ = month$
    OPEN "data\mtotal.txt" FOR INPUT AS #1
    WHILE NOT EOF(1)
        LINE INPUT #1, myLine$
        availablemonths = availablemonths + 1
        montotal$(availablemonths) = myLine$
    WEND
    CLOSE #1
    dezemaand = VAL(RIGHT$(myLine$, 4))
    dezemaandoud = dezemaand
    FOR i = 1 TO availablemonths - 1
        jaartotaal = jaartotaal + VAL(RIGHT$(montotal$(i), 4))
    NEXT i
    vorigemaand = VAL(RIGHT$(montotal$(availablemonths - 1), 4))
    gemiddeld = jaartotaal / (availablemonths - 1)
    jaartotaal = jaartotaal + dezemaand
END SUB

SUB writetotals
    SHARED thismonth$, availablemonths, dezemaand, tot$, dezemaandoud
    STATIC i
    IF dezemaand <> dezemaandoud THEN
        OPEN "data\mtotal.txt" FOR OUTPUT AS #1
        FOR i = 1 TO availablemonths - 1
            PRINT #1, montotal$(i)
        NEXT i
        PRINT #1, thismonth$ + " " + STR$(dezemaand)
        CLOSE #1
    END IF
END SUB

SUB getmonth (num)
    SHARED month$
    SELECT CASE num
        CASE 1: month$ = "january"
        CASE 2: month$ = "february"
        CASE 3: month$ = "march"
        CASE 4: month$ = "april"
        CASE 5: month$ = "may"
        CASE 6: month$ = "june"
        CASE 7: month$ = "july"
        CASE 8: month$ = "august"
        CASE 9: month$ = "september"
        CASE 10: month$ = "october"
        CASE 11: month$ = "november"
        CASE 12: month$ = "december"
    END SELECT
END SUB

SUB welcome
    SHARED dag$, jaar$, thismonth$, shoot, jaartotaal, gemiddeld, vorigemaand, dezemaand, tot$, lingo$
    STATIC k$, gemiddelde, mline$, i
    CALL wis
    '                 12345678901234567890123456789012345678901234567890123456789012345678901234567890
    CALL statusline (" <N>ew sale            <P>arked              <H>istory              <ESC>: Quit")
    CALL header
    LOCATE 3,1,0
    FOR i = 1 TO 5
        PRINT logo$(i)
    NEXT i
    LOCATE 10,1,0    
    gemiddelde = CINT(gemiddeld)
    IF LEFT$(dag$, 1) = "0" THEN
        dag$ = RIGHT$(dag$, 1)
    END IF
    PRINT dag$; " "; thismonth$; " "; jaar$
    PRINT "Total sales this year: "; STRING$(6 - LEN(STR$(jaartotaal)), " "); jaartotaal
    PRINT "Average monthly sales: "; STRING$(6 - LEN(STR$(gemiddeld)), " "); gemiddelde
    PRINT "Last month's sales   : "; STRING$(6 - LEN(STR$(vorigemaand)), " "); vorigemaand
    PRINT "This month's sales   : "; STRING$(6 - LEN(STR$(dezemaand)), " "); dezemaand
    DO
        k$ = INKEY$
    LOOP UNTIL k$ <> ""
    k$ = LCASE$(k$)
    SELECT CASE k$
        CASE CHR$(27): SYSTEM
        CASE "p": parked
        CASE "n": nieuwebon
        CASE "h": history
    END SELECT
END SUB

SUB history
    SHARED selectedLine$, startover
    STATIC i, k$, gekozenbon$, gekozennaam$, myLine$
    i = 0
    CALL readAndSelect("database.txt", "Historie  ", 2, 78, "za")
    IF startover <> 1 THEN
      gekozenbon$ = MID$(selectedLine$, 10, 8)
      gekozennaam$ = MID$(selectedLine$, 19, 22)
      LOCATE 10, 1
      OPEN "receipts\" + gekozenbon$ + ".txt" FOR INPUT AS #1
      WHILE NOT EOF(1)
        i = i + 1
        LINE INPUT #1, myLine$
        IF i > 6 AND LEFT$(myLine$, 3) <> "---" THEN
            IF LEFT$(myLine$, 5) <> "Thank" THEN
                PRINT myLine$
            END IF
        END IF
      WEND
      CLOSE #1
      '            12345678901234567890123456789012345678901234567890123456789012345678901234567890
      CALL statusline (" <P>rint receipt        <V>iew remark")
      DO
        k$ = INKEY$
        k$ = LCASE$(k$)
      LOOP UNTIL k$ = "p" OR k$ = "v"
      IF k$ = "p" THEN
          CALL pleaseprint ("receipts\" + gekozenbon$ + ".txt")
      END IF
      IF k$ = "v" THEN
        CALL zoekopmerking(gekozenbon$)
      END IF
    END IF
END SUB

SUB parked
    SHARED dbdate$, bedrag$, selectedLine$, today$, tot$, dezemaand, startover, datpr$, totpr$
    STATIC le, selectedPark$, paythis$, naamplusbedrag$, i, myLine$, x, finalPay$, k$
    OPEN "data\park.txt" FOR INPUT AS #1
    le = LOF(1)
    CLOSE #1
    IF le >= 8 THEN
      CALL readAndSelect("park.txt", "Parked sales", 2, 39, "")
      IF startover <> 1 THEN
        selectedPark$ = selectedLine$
        paythis$ = LEFT$(selectedPark$, 8)
        naamplusbedrag$ = MID$(selectedPark$, 10, 29)
        tot$ = MID$(selectedPark$, 33, 6)
        LOCATE 10, 1
        OPEN "receipts\" + paythis$ + ".prk" FOR INPUT AS #2
        OPEN "receipt.txt" FOR OUTPUT AS #3
        WHILE NOT EOF(2)
            i = i + 1
            LINE INPUT #2, myLine$
            IF i <= 6 THEN
                PRINT #3, myLine$
            ELSE
                IF LEFT$(myLine$, 4) = LEFT$(datpr$,4) THEN
                    myLine$ = datpr$ + ": " + today$
                END IF
                IF LEFT$(myLine$, 4) = LEFT$(totpr$,4) THEN
                    bedrag$ = MID$(myLine$, 18, 6)
                END IF
                IF myLine$ = "Park sale" THEN
                    x = CSRLIN
                    CALL readAndSelect("payment.txt", "Payment method", 1, 30, "")
                    IF startover = 1 GOTO klaar
                    finalPay$ = selectedLine$
                    LOCATE x, 1
                    PRINT finalPay$
                    PRINT #3, finalPay$
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
        CALL statusline (" Print receipt? (Y\n)")
        DO
            k$ = INKEY$
        LOOP UNTIL k$ <> ""
        CALL statusline (" Just a moment...")
        IF LCASE$(k$) <> "n" THEN
            CALL pleaseprint ("receipt.txt")
        END IF
        CALL copyfile ("receipt.txt", "receipts\" + paythis$ + ".txt")        
        KILL "receipts\" + paythis$ + ".prk"
        IF FEXISTS("data\park.bak") THEN
            KILL "data\park.bak"
        END IF        
        NAME "data\park.txt" AS "data\park.bak"
        OPEN "data\park.bak" FOR INPUT AS #1
        OPEN "data\park.txt" FOR OUTPUT AS #2
        WHILE NOT EOF(1)
            LINE INPUT #1, myLine$
            IF LEFT$(myLine$, 8) <> paythis$ AND myLine$ <> "" THEN
                PRINT #2, myLine$
            END IF
        WEND
        CLOSE #1
        CLOSE #2
        IF FEXISTS("data\database.bak") THEN
            KILL "data\database.bak"
        END IF
        CALL copyfile ("data\database.txt", "data\database.bak")
        OPEN "data\database.txt" FOR APPEND AS #1
        PRINT #1, dbdate$; " "; paythis$; " "; naamplusbedrag$; " "; finalPay$
        CLOSE #1
        dezemaand = dezemaand + VAL(bedrag$)
        CALL writetotals
      END IF
    ELSE
        LOCATE 3, 1
        PRINT "No parked sales"
        CALL statusline (" Press any key...")
        DO
        LOOP UNTIL INKEY$ <> ""
    END IF
END SUB

SUB readlast
    SHARED last, last$
    STATIC myLine$, le
    OPEN "data\last.txt" FOR INPUT AS #1
    LINE INPUT #1, myLine$
    last = VAL(myLine$)
    last = last + 1
    last$ = RIGHT$(STR$(last), LEN(STR$(last)) - 1)
    le = LEN(last$)
    SELECT CASE le
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
    SHARED dbdate$, tot$, btw$, last$, customer$, today$, pay$, jaar$
    STATIC csvtxt$
    IF pay$ <> "Park sale" THEN
        customer$ = LEFT$(customer$, 22)
        csvtxt$ = dbdate$ + " " + jaar$ + last$ + " " + customer$ + " " + tot$ + " " + pay$
        OPEN "data\database.txt" FOR APPEND AS #1
        PRINT #1, csvtxt$
        CLOSE #1
    END IF
END SUB

SUB makeprint
    SHARED dezemaand, tel$, tot$, tottxt$, btwtxt$, pay$, nProducts, last$, customer$, today$, jaar$
    SHARED datpr$, recpr$, cuspr$, thapr$, smstxt$
    STATIC k$, i, smssent$, myLine$, p
    IF INSTR(smstxt$,"/c") > 0 THEN
        p = INSTR(smstxt$,"/c")
        smstxt$ = LEFT$(smstxt$,p-1) + customer$ + RIGHT$(smstxt$,LEN(smstxt$)-p-1)
    END IF
    IF INSTR(smstxt$,"/p") > 0 THEN
        p = INSTR(smstxt$,"/p")
        smstxt$ = LEFT$(smstxt$,p-1) + tot$ + RIGHT$(smstxt$,LEN(smstxt$)-p-1)
    END IF
    IF pay$ = "Park sale" THEN
        smssent$ = "SMS-N"
        IF LEN(tel$) = 12 AND LEFT$(tel$, 1) = "+" THEN
            CALL statusline (" Send SMS to " + tel$ + "? (y/N)")
            DO
                k$ = INKEY$
            LOOP UNTIL k$ <> ""
            IF LCASE$(k$) = "y" THEN     'send sms            
                ' max 160 chars
                'smstxt$ = "Je fiets is klaar. Kosten EUR " + tot$ + ". Groet, Rob de Fietsknecht. T 0485-234500 E info@fietsknecht.nl (Dit is een automatisch bericht. Je kunt niet reageren.)"
                CALL sendsms (tel$, smstxt$)
                smssent$ = "SMS-Y"
                CALL wait(2)                
            END IF
        END IF
    END IF
    OPEN "receipt.txt" FOR OUTPUT AS #1
    OPEN "data\header.txt" FOR INPUT AS #2 
    k$ = ""
    ' max 30 chars on each line
    WHILE NOT EOF(2)
        LINE INPUT #2, myLine$
        PRINT #1, myLine$
    WEND
    CLOSE #2
    PRINT #1, STRING$(30, "-")
    PRINT #1, datpr$; ": "; today$
    PRINT #1, recpr$;": "; jaar$; last$
    PRINT #1, STRING$(30, "-")
    PRINT #1, cuspr$; ": "
    PRINT #1, LEFT$(customer$, 22)
    PRINT #1, STRING$(30, "-")
    FOR i = 1 TO nProducts
        PRINT #1, LEFT$(billProducts$(i), 30)
    NEXT i
    PRINT #1, tottxt$
    PRINT #1, btwtxt$
    PRINT #1, pay$
    PRINT #1, STRING$(30, "-")
    PRINT #1, thapr$
    CLOSE #1
    IF pay$ <> "Park sale" THEN
        k$ = ""
        ' wil je printen?
        CALL statusline (" Print receipt? (Y/n)")
        DO
            k$ = INKEY$
        LOOP UNTIL k$ <> ""
        CALL statusline("Just a moment...")
        IF LCASE$(k$) <> "n" THEN
            CALL pleaseprint ("receipt.txt")
        END IF
        CALL copyfile ("receipt.txt", "receipts\2020" + last$ + ".txt")
        dezemaand = dezemaand + VAL(tot$)
    ELSE
        CALL copyfile ("receipt.txt", "receipts\2020" + last$ + ".prk")
        OPEN "data\park.txt" FOR APPEND AS #1
        PRINT #1, "2020" + last$ + " " + LEFT$(customer$, 22) + " " + tot$ + " " + smssent$ + " " + pay$
        CLOSE #1
        tot$ = ""
    END IF
    CALL writecsv
END SUB

SUB payment
    SHARED selectedLine$, pay$
    CALL readAndSelect("payment.txt", "Payment method", 0, 30, "")
    pay$ = selectedLine$
    CALL overview
END SUB

SUB overview
    SHARED complete, tot$, tottxt$, btw$, btwtxt$, customer$, last$, nProducts, pay$, amount!, today$, jaar$
    SHARED datpr$, recpr$, totpr$, curpr$, vat$, taxpr$
    STATIC i, amount100!, tot!, exbtw!, exbtw$, exbtw100!, btw!, btw100!, vat!
    LOCATE 10, 1
    PRINT datpr$ +  ": " + today$
    PRINT recpr$ + ": " + jaar$ + last$
    PRINT LEFT$(customer$, 22)
    FOR i = 1 TO nProducts
        PRINT LEFT$(billProducts$(i), 30)
    NEXT i
    IF complete = 1 THEN 
        amount100! = 100 * amount!
        tot! = FIX(amount100!) / 100
        tot$ = STR$(tot!)
        tot$ = LTRIM$(tot$)
        IF LEFT$(RIGHT$(tot$, 2), 1) = "." THEN   'bijv. 7.5
            tot$ = tot$ + "0"                     'wordt 7.50
        END IF
        IF INSTR(1, tot$, ".") = 0 THEN           'bijv. 5
            tot$ = tot$ + ".00"                   'wordt 5.00
        END IF
        IF LEN(tot$) = 4 THEN
            tot$ = "  " + tot$
        END IF
        IF LEN(tot$) = 5 THEN
            tot$ = " " + tot$
        END IF
        tottxt$ = totpr$ + ": " + SPACE$(17 - LEN(tot$)) + " " + curpr$ + " " + tot$
        PRINT tottxt$
        vat! = (100 + VAL(vat$)) / 100
        exbtw! = amount! / vat!
        exbtw100! = 100 * exbtw!
        exbtw! = FIX(exbtw100!) / 100
        exbtw$ = STR$(exbtw!)
        btw! = (amount! - exbtw!)
        btw100! = 100 * btw!
        btw! = btw100! / 100
        btw$ = STR$(btw!)
        btw$ = RIGHT$(btw$, LEN(btw$) - 1)
        IF LEFT$(btw$, 1) = "." THEN
            btw$ = "0" + btw$
        END IF
        IF LEFT$(RIGHT$(btw$, 2), 1) = "." THEN
            btw$ = btw$ + "0"
        END IF
        IF INSTR(1, btw$, ".") = 0 THEN           'bijv. 5
            btw$ = btw$ + ".00"                   'wordt 5.00
        END IF
        IF LEN(btw$) = 4 THEN
            btw$ = "  " + btw$
        END IF
        IF LEN(btw$) = 5 THEN
            btw$ = " " + btw$
        END IF
        btwtxt$ = "Incl. " + vat$ + "% " + taxpr$ + ":      " + curpr$ + " " + btw$
        PRINT btwtxt$
    END IF
    PRINT pay$
END SUB

SUB header
    LOCATE 1, 1
    COLOR 0,1
    '      12345678901234567890123456789012345678901234567890123456789012345678901234567890
    PRINT "   MiniPOS for Atari ST                                            " + CHR$(189) + " GPL 2020   ";
    LOCATE 9, 1
    COLOR 0,9
    PRINT SPACE$(36); "OVERVIEW"; SPACE$(36);
    COLOR 1,0
END SUB

SUB wis
    COLOR 1,0
    STATIC i
    FOR i = 2 TO 8
        LOCATE i,1
        PRINT SPACE$(80);
    NEXT i
    FOR i = 10 TO 24
        LOCATE i,1
        PRINT SPACE$(80);
    NEXT i
END SUB

SUB statusline (sl$)
    LOCATE 25,1
    COLOR 0,1
    PRINT SPACE$(79);    'not 80 otherwise HBASIC will scroll one line up
    LOCATE 25,1
    PRINT sl$;
    COLOR 1,0
END SUB

SUB getCustomer
    SHARED selectedLine$, customer$, tel$, addnew
    STATIC cname$
    CALL readAndSelect("customer.txt", "Find customer ", 1, 38, "az")
    IF addnew = 1 THEN
        CALL wis
        CALL statusline("Add new customer")
        LOCATE 2, 1
        PRINT "New customer"
        INPUT "Name: ", cname$
        INPUT "Tel. (incl. country code +xx): ", tel$
        customer$ = cname$ + STRING$(26 - LEN(cname$), " ") + tel$
        IF customer$ <> "" THEN
            OPEN "data\customer.txt" FOR APPEND AS #1
            PRINT #1, customer$
            CLOSE #1
        END IF
        addnew = 0
    ELSE
        customer$ = selectedLine$
        tel$ = MID$(customer$, 27, 12)
    END IF
    CALL overview
END SUB

SUB getProduct
    SHARED selectedLine$, product$, nProducts, amount!, addnew
    STATIC pname$, pprice$
    CALL readAndSelect("product.txt", "Find product", 1, 30, "")
    IF addnew = 1 THEN
        CALL wis
        CALL statusline("Add new product")
        LOCATE 2, 1
        PRINT "New product"
        INPUT "Name : ", pname$
        INPUT "Price (incl. tax):", pprice$
        product$ = pname$ + STRING$(27 - LEN(pname$), " ") + pprice$
        IF product$ <> "" THEN
            OPEN "data\product.txt" FOR APPEND AS #1
            PRINT #1, product$
            CLOSE #1
        END IF
        addnew = 0
    ELSE
        product$ = selectedLine$
    END IF
    IF product$ <> "" THEN
        nProducts = nProducts + 1
        amount! = amount! + VAL(RIGHT$(product$, 6))
        billProducts$(nProducts) = product$
    END IF
    CALL overview
END SUB

SUB addProduct
    SHARED complete
    STATIC status$, k$
    '          12345678901234567890123456789012345678901234567890123456789012345678901234567890
    status$ = " <Space>: Add product to this sale                            <Enter>: Continue"
    CALL statusline(status$)
    DO
        k$ = INKEY$
    LOOP UNTIL k$ = CHR$(32) OR k$ = CHR$(13)
    IF k$ = CHR$(32) THEN
        CALL getProduct
    ELSE
        complete = 1
    END IF
    CALL overview
END SUB

' This is the nasty one
SUB readAndSelect (fileName$, st$, insallowed, characters, sort$)
    SHARED selectedLine$, addnew, startover
    STATIC myLine$, i, j, t, t2, t3, s$, olds$, offset, pt, shift, match, k$, printrow, st$, visible, lastvisible, m, instruction$
    REDIM myArray$(200), matches(200)
    i = 0
    offset = 1
    shift = 0
    OPEN "data\" + fileName$ FOR INPUT AS #1
    i = 0
    WHILE NOT EOF(1)
        LINE INPUT #1, myLine$
        IF LEFT$(myLine$, 1) <> "#" THEN
            myLine$ = LEFT$(myLine$, characters) 
            i = i + 1
            allLines$(i) = myLine$
        END IF
    WEND
    CLOSE #1
    IF sort$ = "az" THEN
        CALL bubbleSortAZ(allLines$(), i)
    END IF
    IF sort$ = "za" THEN
        CALL bubbleSortZA(allLines$(), i)
    END IF
    s$ = " "     ' find anything with a space in it, make sure every line has one
    olds$ = ""
    CALL wis
    IF insallowed <> 2 THEN
        CALL overview
    END IF
    DO
        k$ = INKEY$
        IF k$ = CHR$(0) + CHR$(72) THEN
            IF offset > 1 THEN
                offset = offset - 1
                pt = 1
                shift = shift + 1
            END IF
        END IF
        IF k$ = CHR$(0) + CHR$(80) THEN
            IF offset < match THEN
                offset = offset + 1
                shift = shift - 1
                pt = 1
            END IF
        END IF
        IF insallowed = 1 THEN
            IF k$ = CHR$(0) + CHR$(82) THEN
                addnew = 1
                EXIT DO
            END IF
        END IF
        IF k$ = CHR$(27) THEN
            startover = 1
            EXIT DO
        END IF
        IF INSTR("ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", UCASE$(k$)) >= 1 THEN
            s$ = s$ + k$
        END IF
        IF k$ = CHR$(8) AND LEN(s$) >= 1 THEN
            ' backspace 
            s$ = LEFT$(s$, LEN(s$) - 1)
            IF LEN(s$) = 0 THEN
                s$ = ""
            END IF 
        END IF
        IF s$ <> olds$ OR pt = 1 THEN
            IF s$ = " " THEN
                s$ = ""
            END IF
  
            match = 0
            FOR j = 1 TO i
                IF INSTR(LCASE$(allLines$(j)), LCASE$(s$)) >= 1 THEN
                    match = match + 1
                    matches(match) = j
                END IF
            NEXT j
            
            printrow = 2
            LOCATE 2,1,1
            COLOR 1,0
            PRINT st$; ": ";
            COLOR 0, 9
            PRINT s$;
            COLOR 1, 0
            PRINT SPACE$(66-LEN(s$));
            LOCATE 2, 67
            PRINT "Matches:"; match;
            IF shift > -5 THEN
                visible = offset + shift
            ELSE
                visible = offset - 5
                shift = -5
            END IF
            IF shift > 0 THEN
                visible = offset
                shift = 0
            END IF
            IF match <= 6 THEN
                visible = offset + shift
            END IF
            IF s$ <> olds$ AND pt = 0 THEN
                visible = 1
                offset = 1
            END IF
            IF match <= 5 THEN
                lastvisible = visible + match
            ELSE
                lastvisible = visible + 5
            END IF
            'for testing purposes
            'CALL statusline (" shift"+STR$(shift)+ " offset " + STR$(offset) + " visible " + STR$(visible)+"lastvisible"+STR$(lastvisible))
            
            IF match > 0 THEN            
              FOR m = visible TO lastvisible
                printrow = printrow + 1
                LOCATE printrow, 1
                IF m = offset THEN
                    COLOR 1, 8
                ELSE
                    COLOR 1, 0
                END IF
                ' here's a subscript out of range if you mess with backspace too much
                PRINT allLines$(matches(m));SPACE$(80-LEN(allLines$(matches(m))));
                COLOR 1, 0
              NEXT m
              ' if there are less than 6 matches we fill up the remaining lines with spaces
              IF match < 6 THEN
                t2 = 6 - match
                t3 = match + 3
                FOR t = 1 TO t2 
                    LOCATE t3, 1
                    PRINT SPACE$(80);
                    t3 = t3 + 1
                NEXT t
              END IF
            END IF
          
            SELECT CASE insallowed
                CASE 0
                    '               12345678901234567890123456789012345678901234567890123456789012345678901234567890
                    instruction$ = " Type or scroll up/down                                         <Enter>: Select"
                CASE 1                  
                    instruction$ = " Type or scroll up/down              <INS>: New                 <Enter>: Select"
                CASE 2
                    instruction$ = " Type or scroll up/down              <Enter>: Select                <ESC>: Back"
            END SELECT
            CALL statusline (instruction$)
            LOCATE 2, 15 + LEN(s$), 1
        END IF
        olds$ = s$
        pt = 0
    LOOP UNTIL k$ = CHR$(13)
    selectedLine$ = allLines$(matches(offset))
END SUB

SUB bubbleSortAZ (myArray$(), n)
    STATIC OutOfOrder, x
    DO
        OutOfOrder = 0 'assume it's sorted
        FOR x = 1 TO n - 1
            IF myArray$(x) > myArray$(x + 1) THEN 'Compare adjaccent elements
                SWAP myArray$(x), myArray$(x + 1) 'if we had to swap,
                OutOfOrder = 1 '   then we're not done yet.
            END IF
        NEXT
    LOOP WHILE OutOfOrder = 1
END SUB

SUB bubbleSortZA (myArray$(), n)
    STATIC OutOfOrder, x
    DO
        OutOfOrder = 0 'assume it's sorted
        FOR x = 1 TO n - 1
            IF myArray$(x) < myArray$(x + 1) THEN 'Compare adjaccent elements
                SWAP myArray$(x), myArray$(x + 1) 'if we had to swap,
                OutOfOrder = 1 '   then we're not done yet.
            END IF
        NEXT
    LOOP WHILE OutOfOrder = 1
END SUB

SUB wait (sec!)
    STATIC starttime!, waiting!
    waiting! = 0
    starttime! = TIMER
    WHILE waiting! <= sec!
        waiting! = TIMER - starttime!  
    WEND
END SUB

SUB copyfile (from$, to$)
    STATIC myline$
    OPEN from$ FOR INPUT AS #1
    OPEN to$ FOR OUTPUT AS #2
    WHILE NOT EOF(1)
        LINE INPUT #1, myline$
        PRINT #2, myline$  
    WEND
    CLOSE #1
    CLOSE #2
END SUB

SUB pleaseprint (thisfile$)
    STATIC myline$
    OPEN thisfile$ FOR INPUT AS #1
    LPRINT
    WHILE NOT EOF(1)
        LINE INPUT #1, myline$
        LPRINT myline$
    WEND
    LPRINT
    LPRINT
    LPRINT
    CLOSE #1
END SUB

SUB sendsms (tel$, smstxt$)
    REDIM comstr$(10)
    STATIC name$, port, i, cn, tos, x
    CALL statusline (" Busy sending SMS, this may take a few seconds...")
    name$ = "mail.atari-st.faith"                       'name of the SMTP server
    port = 587                                          'port number
    comstr$(1) = "HELO " + name$
    comstr$(2) = "AUTH LOGIN"
    comstr$(3) = "c21zQGF0YXJpLXN0LmZhaXRo"             'login BASE64 encoded
    comstr$(4) = "bTNRdzs2Y1V0eQ=="                     'password BASE64 encoded
    comstr$(5) = "MAIL FROM:<sms@atari-st.faith>"       'sender address
    comstr$(6) = "RCPT TO:<" + tel$ + "@mail-sms.com>"  'sms gateway
    comstr$(7) = "DATA"
    comstr$(8) = smstxt$
    comstr$(9) = "."
    comstr$(10) = "QUIT"
    ' make the connection
    cn = tcp_connect (name$,port,tos,2000)
    ' talk to the smtp server, no checks at this point
    ' works with my atari-st.faith server, takes a few minutes for the sms to arrive
    FOR i = 1 TO 10
        CALL wait(1)
        IF cn > -1 THEN 
            x = tcpsend (cn,comstr$(i))
        END IF
        CALL wait(1)
    NEXT i
    CALL statusline (" SMS has been sent")
END SUB
