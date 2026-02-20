       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMDB2.

      *---------------------------------------------------------------*
      * PGMDB2 - Sous-programme accesseur DB2                        *
      * Interface identique a PGMVSAM (zone 120 octets, PDF p.16-17) *
      * Table cible : ASSURES                                   *
      * DB2 Version 8 / Enterprise COBOL 3.1.1 / z/OS                *
      *---------------------------------------------------------------*

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      * Zone communication SQL
           EXEC SQL
               INCLUDE SQLCA
           END-EXEC.

      * DCLGEN table ASSURES
           EXEC SQL
               INCLUDE DCLASSU
           END-EXEC.

      * Curseur lecture sequentielle (STARTBR/READNEXT)
           EXEC SQL
               DECLARE CSR-ASSURES CURSOR FOR
               SELECT MATASS, NOMPRE, RUESS, CPASS,
                      VILLSS, CODVEH, PRIMSS, BONMAL, TAUXSS
               FROM ASSURES
               ORDER BY MATASS
           END-EXEC.

      * Copie locale SQLCODE (PIC S9(9) COMP pour comparaisons)
       01  WS-SQLCODE              PIC S9(9) COMP.

      * Codes retour (conformes PDF page 17)
       01  WS-CODES-RETOUR.
           05 WS-RETOUR-OK         PIC 99 VALUE 00.
           05 WS-RETOUR-NOTFOUND   PIC 99 VALUE 01.
           05 WS-RETOUR-DUPLICATE  PIC 99 VALUE 02.
           05 WS-RETOUR-IOERROR    PIC 99 VALUE 03.
           05 WS-RETOUR-EOF        PIC 99 VALUE 04.
           05 WS-RETOUR-ERROR      PIC 99 VALUE 99.

      * Codes fonction (conformes PDF page 17)
       01  WS-CODES-FONCTION.
           05 WS-FUNC-OPEN         PIC 99 VALUE 01.
           05 WS-FUNC-CLOSE        PIC 99 VALUE 02.
           05 WS-FUNC-READ         PIC 99 VALUE 03.
           05 WS-FUNC-REWRITE      PIC 99 VALUE 04.
           05 WS-FUNC-DELETE       PIC 99 VALUE 05.
           05 WS-FUNC-WRITE        PIC 99 VALUE 06.
           05 WS-FUNC-START        PIC 99 VALUE 07.
           05 WS-FUNC-READNEXT     PIC 99 VALUE 08.
           05 WS-FUNC-TRUNCATE     PIC 99 VALUE 09.

      * Zone enregistrement en format DISPLAY (miroir de WASSURE)
       01  WS-ENREG-DISP.
           05 WS-ED-MAT            PIC 9(6).
           05 WS-ED-NOMPRE         PIC X(20).
           05 WS-ED-RUE            PIC X(18).
           05 WS-ED-CP             PIC 9(5).
           05 WS-ED-VILLE          PIC X(12).
           05 WS-ED-CODE           PIC X(1).
           05 WS-ED-PRIME          PIC 9(4)V99.
           05 WS-ED-BM             PIC X(1).
           05 WS-ED-TAUX           PIC 99.
           05 FILLER               PIC X(9).

       LINKAGE SECTION.

      * Zone de communication 120 octets (conforme PDF page 16)
       01  LS-COM.
           05 LS-NOM-FICHIER       PIC X(8).
           05 LS-CODE-FONCTION     PIC 99.
           05 LS-CODE-RETOUR       PIC 99.
           05 LS-ENREG             PIC X(80).
           05 LS-FILLER            PIC X(28).

       PROCEDURE DIVISION USING LS-COM.

      *---------------------------------------------------------------*
      * POINT D ENTREE PRINCIPAL                                      *
      *---------------------------------------------------------------*
       MAIN-PARA.
           EVALUATE LS-CODE-FONCTION
               WHEN WS-FUNC-OPEN
                   PERFORM FUNC-OPEN
               WHEN WS-FUNC-CLOSE
                   PERFORM FUNC-CLOSE
               WHEN WS-FUNC-READ
                   PERFORM FUNC-READ
               WHEN WS-FUNC-REWRITE
                   PERFORM FUNC-REWRITE
               WHEN WS-FUNC-DELETE
                   PERFORM FUNC-DELETE
               WHEN WS-FUNC-WRITE
                   PERFORM FUNC-WRITE
               WHEN WS-FUNC-START
                   PERFORM FUNC-START
               WHEN WS-FUNC-READNEXT
                   PERFORM FUNC-READNEXT
               WHEN WS-FUNC-TRUNCATE
                   PERFORM FUNC-TRUNCATE
               WHEN OTHER
                   MOVE WS-RETOUR-ERROR TO LS-CODE-RETOUR
           END-EVALUATE
           GOBACK.

      *---------------------------------------------------------------*
      * FUNC-OPEN (01) : pas d ouverture physique en DB2              *
      *---------------------------------------------------------------*
       FUNC-OPEN.
           MOVE WS-RETOUR-OK TO LS-CODE-RETOUR.

      *---------------------------------------------------------------*
      * FUNC-CLOSE (02) : fermeture curseur                           *
      *---------------------------------------------------------------*
       FUNC-CLOSE.
           EXEC SQL
               CLOSE CSR-ASSURES
           END-EXEC
           MOVE WS-RETOUR-OK TO LS-CODE-RETOUR.

      *---------------------------------------------------------------*
      * FUNC-READ (03) : SELECT par cle primaire MATASS               *
      *---------------------------------------------------------------*
       FUNC-READ.
           MOVE LS-ENREG(1:6) TO WS-MATASS
           EXEC SQL
               SELECT MATASS, NOMPRE, RUESS, CPASS,
                      VILLSS, CODVEH, PRIMSS, BONMAL, TAUXSS
               INTO :WS-MATASS, :WS-NOMPRE, :WS-RUESS, :WS-CPASS,
                    :WS-VILLSS, :WS-CODVEH, :WS-PRIMSS, :WS-BONMAL,
                    :WS-TAUXSS
               FROM ASSURES
               WHERE MATASS = :WS-MATASS
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           PERFORM MAPPER-READ
           IF LS-CODE-RETOUR = WS-RETOUR-OK
               PERFORM MOVE-WS-TO-LS.

      *---------------------------------------------------------------*
      * FUNC-REWRITE (04) : UPDATE par cle primaire MATASS            *
      *---------------------------------------------------------------*
       FUNC-REWRITE.
           PERFORM MOVE-LS-TO-WS
           EXEC SQL
               UPDATE ASSURES
                  SET NOMPRE = :WS-NOMPRE,
                      RUESS  = :WS-RUESS,
                      CPASS  = :WS-CPASS,
                      VILLSS = :WS-VILLSS,
                      CODVEH = :WS-CODVEH,
                      PRIMSS = :WS-PRIMSS,
                      BONMAL = :WS-BONMAL,
                      TAUXSS = :WS-TAUXSS
               WHERE MATASS = :WS-MATASS
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           PERFORM MAPPER-WRITE.

      *---------------------------------------------------------------*
      * FUNC-DELETE (05) : DELETE par cle primaire MATASS             *
      *---------------------------------------------------------------*
       FUNC-DELETE.
           MOVE LS-ENREG(1:6) TO WS-MATASS
           EXEC SQL
               DELETE FROM ASSURES
               WHERE MATASS = :WS-MATASS
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           PERFORM MAPPER-READ.

      *---------------------------------------------------------------*
      * FUNC-WRITE (06) : INSERT                                      *
      *---------------------------------------------------------------*
       FUNC-WRITE.
           PERFORM MOVE-LS-TO-WS
           EXEC SQL
               INSERT INTO ASSURES
                 (MATASS, NOMPRE, RUESS, CPASS,
                  VILLSS, CODVEH, PRIMSS, BONMAL, TAUXSS)
               VALUES
                 (:WS-MATASS, :WS-NOMPRE, :WS-RUESS, :WS-CPASS,
                  :WS-VILLSS, :WS-CODVEH, :WS-PRIMSS, :WS-BONMAL,
                  :WS-TAUXSS)
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           PERFORM MAPPER-WRITE.

      *---------------------------------------------------------------*
      * FUNC-START (07) : OPEN CURSOR (debut lecture sequentielle)    *
      *---------------------------------------------------------------*
       FUNC-START.
           EXEC SQL
               OPEN CSR-ASSURES
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           PERFORM MAPPER-OPEN.

      *---------------------------------------------------------------*
      * FUNC-READNEXT (08) : FETCH enregistrement suivant             *
      *---------------------------------------------------------------*
       FUNC-READNEXT.
           EXEC SQL
               FETCH CSR-ASSURES
               INTO :WS-MATASS, :WS-NOMPRE, :WS-RUESS, :WS-CPASS,
                    :WS-VILLSS, :WS-CODVEH, :WS-PRIMSS, :WS-BONMAL,
                    :WS-TAUXSS
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           PERFORM MAPPER-FETCH
           IF LS-CODE-RETOUR = WS-RETOUR-OK
               PERFORM MOVE-WS-TO-LS.

      *---------------------------------------------------------------*
      * FUNC-TRUNCATE (09) : DELETE FROM ASSURES sans WHERE          *
      *---------------------------------------------------------------*
       FUNC-TRUNCATE.
           EXEC SQL
               DELETE FROM ASSURES
           END-EXEC
           MOVE SQLCODE TO WS-SQLCODE
           PERFORM MAPPER-WRITE.

      *---------------------------------------------------------------*
      * MOVE-LS-TO-WS : LS-ENREG (DISPLAY) -> DCLGEN (COMP-3/COMP)  *
      *---------------------------------------------------------------*
       MOVE-LS-TO-WS.
           MOVE LS-ENREG TO WS-ENREG-DISP
           MOVE WS-ED-MAT   TO WS-MATASS
           MOVE WS-ED-NOMPRE TO WS-NOMPRE
           MOVE WS-ED-RUE   TO WS-RUESS
           MOVE WS-ED-CP    TO WS-CPASS
           MOVE WS-ED-VILLE TO WS-VILLSS
           MOVE WS-ED-CODE  TO WS-CODVEH
           MOVE WS-ED-PRIME TO WS-PRIMSS
           MOVE WS-ED-BM    TO WS-BONMAL
           MOVE WS-ED-TAUX  TO WS-TAUXSS.

      *---------------------------------------------------------------*
      * MOVE-WS-TO-LS : DCLGEN (COMP-3/COMP) -> LS-ENREG (DISPLAY)  *
      *---------------------------------------------------------------*
       MOVE-WS-TO-LS.
           MOVE WS-MATASS TO WS-ED-MAT
           MOVE WS-NOMPRE TO WS-ED-NOMPRE
           MOVE WS-RUESS  TO WS-ED-RUE
           MOVE WS-CPASS  TO WS-ED-CP
           MOVE WS-VILLSS TO WS-ED-VILLE
           MOVE WS-CODVEH TO WS-ED-CODE
           MOVE WS-PRIMSS TO WS-ED-PRIME
           MOVE WS-BONMAL TO WS-ED-BM
           MOVE WS-TAUXSS TO WS-ED-TAUX
           MOVE WS-ENREG-DISP TO LS-ENREG.

      *---------------------------------------------------------------*
      * MAPPER-READ : SQLCODE -> code retour (READ / DELETE)         *
      * +100 = not found (01)                                         *
      *---------------------------------------------------------------*
       MAPPER-READ.
           EVALUATE TRUE
               WHEN WS-SQLCODE = 0
                   MOVE WS-RETOUR-OK TO LS-CODE-RETOUR
               WHEN WS-SQLCODE = +100
                   MOVE WS-RETOUR-NOTFOUND TO LS-CODE-RETOUR
               WHEN WS-SQLCODE = -501
                   MOVE WS-RETOUR-IOERROR TO LS-CODE-RETOUR
               WHEN OTHER
                   MOVE WS-RETOUR-ERROR TO LS-CODE-RETOUR
           END-EVALUATE.

      *---------------------------------------------------------------*
      * MAPPER-WRITE : SQLCODE -> code retour (INSERT / UPDATE)      *
      * -803 ou -811 = duplicate (02)                                 *
      *---------------------------------------------------------------*
       MAPPER-WRITE.
           EVALUATE TRUE
               WHEN WS-SQLCODE = 0
                   MOVE WS-RETOUR-OK TO LS-CODE-RETOUR
               WHEN WS-SQLCODE = -803 OR WS-SQLCODE = -811
                   MOVE WS-RETOUR-DUPLICATE TO LS-CODE-RETOUR
               WHEN WS-SQLCODE = -501
                   MOVE WS-RETOUR-IOERROR TO LS-CODE-RETOUR
               WHEN OTHER
                   MOVE WS-RETOUR-ERROR TO LS-CODE-RETOUR
           END-EVALUATE.

      *---------------------------------------------------------------*
      * MAPPER-FETCH : SQLCODE -> code retour (FETCH)                *
      * +100 = fin curseur (04)                                       *
      *---------------------------------------------------------------*
       MAPPER-FETCH.
           EVALUATE TRUE
               WHEN WS-SQLCODE = 0
                   MOVE WS-RETOUR-OK TO LS-CODE-RETOUR
               WHEN WS-SQLCODE = +100
                   MOVE WS-RETOUR-EOF TO LS-CODE-RETOUR
               WHEN WS-SQLCODE = -501
                   MOVE WS-RETOUR-IOERROR TO LS-CODE-RETOUR
               WHEN OTHER
                   MOVE WS-RETOUR-ERROR TO LS-CODE-RETOUR
           END-EVALUATE.

      *---------------------------------------------------------------*
      * MAPPER-OPEN : SQLCODE -> code retour (OPEN CURSOR)           *
      *---------------------------------------------------------------*
       MAPPER-OPEN.
           EVALUATE TRUE
               WHEN WS-SQLCODE = 0
                   MOVE WS-RETOUR-OK TO LS-CODE-RETOUR
               WHEN OTHER
                   MOVE WS-RETOUR-ERROR TO LS-CODE-RETOUR
           END-EVALUATE.
