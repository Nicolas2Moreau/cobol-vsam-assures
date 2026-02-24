       IDENTIFICATION DIVISION.
       PROGRAM-ID. TSTASSU.

      *---------------------------------------------------------------*
      * TSTASSU - Test harness accesseurs ASSURES                    *
      * Invocation : PARM='PGMVSAM' ou PARM='PGMDB2'                *
      *                                                               *
      * 12 tests couvrant les fonctions 01 a 08 :                   *
      *   T01 OPEN      T02 WRITE (creation)   T03 WRITE (duplicate) *
      *   T04 READ      T05 REWRITE            T06 READ (post-modif) *
      *   T07 NOT FOUND T08 DELETE (nettoyage) T09 READ (post-delete)*
      *   T10 STARTBR   T11 READNEXT           T12 CLOSE             *
      *                                                               *
      * Matricule test : 999999 (non existant en production)        *
      * Nettoyage : DELETE 999999 en T08 avant STARTBR               *
      *---------------------------------------------------------------*

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      * Nom du module accesseur (depuis PARM JCL)
       01  WS-NOM-ACCSR            PIC X(8) VALUE SPACES.
       01  WS-PARM-LEN             PIC S9(4) COMP VALUE 0.

      * Zone de communication 120 octets (conforme PDF p.16)
       01  WS-COM.
           05 WS-NOM-FICHIER       PIC X(8).
           05 WS-FONCTION          PIC 99.
           05 WS-RETOUR            PIC 99.
           05 WS-ENREG             PIC X(80).
           05 WS-COM-FILL          PIC X(28).

      * Enregistrement test principal : mat=999999, prime=100.00,
      *   BM=B, taux=10
       01  WS-ENREG-T1.
           05 FILLER               PIC 9(6)    VALUE 999999.
           05 FILLER               PIC X(20)   VALUE 'TEST TSTASSU        '.
           05 FILLER               PIC X(18)   VALUE '1 RUE DU TEST     '.
           05 FILLER               PIC 9(5)    VALUE 99000.
           05 FILLER               PIC X(12)   VALUE 'TESTVILLE   '.
           05 FILLER               PIC X(1)    VALUE 'A'.
           05 FILLER               PIC 9(4)V99 VALUE 010000.
           05 FILLER               PIC X(1)    VALUE 'B'.
           05 FILLER               PIC 99      VALUE 10.
           05 FILLER               PIC X(9)    VALUE SPACES.

      * Enregistrement modifie : prime=200.00, BM=M, taux=20
       01  WS-ENREG-T2.
           05 FILLER               PIC 9(6)    VALUE 999999.
           05 FILLER               PIC X(20)   VALUE 'TEST TSTASSU        '.
           05 FILLER               PIC X(18)   VALUE '1 RUE DU TEST     '.
           05 FILLER               PIC 9(5)    VALUE 99000.
           05 FILLER               PIC X(12)   VALUE 'TESTVILLE   '.
           05 FILLER               PIC X(1)    VALUE 'A'.
           05 FILLER               PIC 9(4)V99 VALUE 020000.
           05 FILLER               PIC X(1)    VALUE 'M'.
           05 FILLER               PIC 99      VALUE 20.
           05 FILLER               PIC X(9)    VALUE SPACES.

      * Zones de passage pour CHECK-RC
       01  WS-TST-NUM              PIC X(4).
       01  WS-TST-LABEL            PIC X(26).
       01  WS-RC-ATT               PIC 99.

      * Compteurs
       01  WS-NB-OK                PIC 999 VALUE 0.
       01  WS-NB-KO                PIC 999 VALUE 0.

      * Ligne de trace (une par test)
       01  WS-LIGNE.
           05 WS-LIG-NUM           PIC X(4).
           05 FILLER               PIC X(1) VALUE SPACE.
           05 WS-LIG-LABEL         PIC X(26).
           05 FILLER               PIC X(1) VALUE SPACE.
           05 FILLER               PIC X(3) VALUE 'RC='.
           05 WS-LIG-RC-OBT        PIC 99.
           05 FILLER               PIC X(1) VALUE SPACE.
           05 FILLER               PIC X(4) VALUE 'ATT='.
           05 WS-LIG-RC-ATT        PIC 99.
           05 FILLER               PIC X(1) VALUE SPACE.
           05 WS-LIG-RESULT        PIC X(3).

       LINKAGE SECTION.
       01  LS-PARM.
           05 LS-PARM-LEN          PIC S9(4) COMP.
           05 LS-PARM-DATA         PIC X(100).

       PROCEDURE DIVISION USING LS-PARM.

      *---------------------------------------------------------------*
      * PROGRAMME PRINCIPAL                                           *
      *---------------------------------------------------------------*
       MAIN-PARA.
           PERFORM INIT-PARM
           PERFORM RUN-TESTS
           PERFORM BILAN
           GOBACK.

      *---------------------------------------------------------------*
      * INIT-PARM : lecture PARM JCL -> nom accesseur                *
      *---------------------------------------------------------------*
       INIT-PARM.
           MOVE SPACES TO WS-NOM-ACCSR
           MOVE LS-PARM-LEN TO WS-PARM-LEN
           IF WS-PARM-LEN > 0
               IF WS-PARM-LEN > 8
                   MOVE 8 TO WS-PARM-LEN
               END-IF
               MOVE LS-PARM-DATA(1:WS-PARM-LEN) TO WS-NOM-ACCSR
           ELSE
               MOVE 'PGMVSAM ' TO WS-NOM-ACCSR
           END-IF
           DISPLAY '* TSTASSU - ACCESSEUR : ' WS-NOM-ACCSR
           DISPLAY '*-----------------------------------------*'.

      *---------------------------------------------------------------*
      * RUN-TESTS : execution des 12 tests                           *
      *---------------------------------------------------------------*
       RUN-TESTS.

      * T01 : OPEN ASSURES3
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 01          TO WS-FONCTION
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T01 '      TO WS-TST-NUM
           MOVE 'OPEN ASSURES3             '
                            TO WS-TST-LABEL
           MOVE 00          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T02 : WRITE 999999 (creation)
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 06          TO WS-FONCTION
           MOVE WS-ENREG-T1 TO WS-ENREG
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T02 '      TO WS-TST-NUM
           MOVE 'WRITE 999999 (creation)   '
                            TO WS-TST-LABEL
           MOVE 00          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T03 : WRITE 999999 (duplicate attendu)
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 06          TO WS-FONCTION
           MOVE WS-ENREG-T1 TO WS-ENREG
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T03 '      TO WS-TST-NUM
           MOVE 'WRITE 999999 (duplicate)  '
                            TO WS-TST-LABEL
           MOVE 02          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T04 : READ 999999 (found)
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 03          TO WS-FONCTION
           MOVE SPACES      TO WS-ENREG
           MOVE '999999'    TO WS-ENREG(1:6)
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T04 '      TO WS-TST-NUM
           MOVE 'READ  999999 (found)      '
                            TO WS-TST-LABEL
           MOVE 00          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T05 : REWRITE 999999 (prime=200.00, BM=M, taux=20)
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 04          TO WS-FONCTION
           MOVE WS-ENREG-T2 TO WS-ENREG
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T05 '      TO WS-TST-NUM
           MOVE 'REWRITE 999999 (modif)    '
                            TO WS-TST-LABEL
           MOVE 00          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T06 : READ 999999 (post-modif)
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 03          TO WS-FONCTION
           MOVE SPACES      TO WS-ENREG
           MOVE '999999'    TO WS-ENREG(1:6)
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T06 '      TO WS-TST-NUM
           MOVE 'READ  999999 (post-modif) '
                            TO WS-TST-LABEL
           MOVE 00          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T07 : READ 000000 (not found)
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 03          TO WS-FONCTION
           MOVE SPACES      TO WS-ENREG
           MOVE '000000'    TO WS-ENREG(1:6)
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T07 '      TO WS-TST-NUM
           MOVE 'READ  000000 (not found)  '
                            TO WS-TST-LABEL
           MOVE 01          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T08 : DELETE 999999 (nettoyage avant STARTBR)
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 05          TO WS-FONCTION
           MOVE SPACES      TO WS-ENREG
           MOVE '999999'    TO WS-ENREG(1:6)
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T08 '      TO WS-TST-NUM
           MOVE 'DELETE 999999 (nettoyage) '
                            TO WS-TST-LABEL
           MOVE 00          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T09 : READ 999999 (post-delete, not found)
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 03          TO WS-FONCTION
           MOVE SPACES      TO WS-ENREG
           MOVE '999999'    TO WS-ENREG(1:6)
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T09 '      TO WS-TST-NUM
           MOVE 'READ  999999 (post-delete)'
                            TO WS-TST-LABEL
           MOVE 01          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T10 : STARTBR ASSURES3
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 07          TO WS-FONCTION
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T10 '      TO WS-TST-NUM
           MOVE 'STARTBR ASSURES3          '
                            TO WS-TST-LABEL
           MOVE 00          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T11 : READNEXT (1er enregistrement)
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 08          TO WS-FONCTION
           MOVE SPACES      TO WS-ENREG
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T11 '      TO WS-TST-NUM
           MOVE 'READNEXT (1er enreg)      '
                            TO WS-TST-LABEL
           MOVE 00          TO WS-RC-ATT
           PERFORM CHECK-RC

      * T12 : CLOSE ASSURES3
           MOVE 'ASSURES3'  TO WS-NOM-FICHIER
           MOVE 02          TO WS-FONCTION
           CALL WS-NOM-ACCSR USING WS-COM
           MOVE 'T12 '      TO WS-TST-NUM
           MOVE 'CLOSE ASSURES3            '
                            TO WS-TST-LABEL
           MOVE 00          TO WS-RC-ATT
           PERFORM CHECK-RC.

      *---------------------------------------------------------------*
      * CHECK-RC : compare RC obtenu vs RC attendu, affiche resultat  *
      *---------------------------------------------------------------*
       CHECK-RC.
           MOVE WS-TST-NUM   TO WS-LIG-NUM
           MOVE WS-TST-LABEL TO WS-LIG-LABEL
           MOVE WS-RETOUR    TO WS-LIG-RC-OBT
           MOVE WS-RC-ATT    TO WS-LIG-RC-ATT
           IF WS-RETOUR = WS-RC-ATT
               ADD 1 TO WS-NB-OK
               MOVE 'OK ' TO WS-LIG-RESULT
           ELSE
               ADD 1 TO WS-NB-KO
               MOVE 'KO!' TO WS-LIG-RESULT
           END-IF
           DISPLAY WS-LIGNE.

      *---------------------------------------------------------------*
      * BILAN : affichage du resultat global                         *
      *---------------------------------------------------------------*
       BILAN.
           DISPLAY '*-----------------------------------------*'
           DISPLAY '* TOTAL OK : ' WS-NB-OK
           DISPLAY '* TOTAL KO : ' WS-NB-KO
           IF WS-NB-KO = 0
               DISPLAY '* VERDICT  : TOUS LES TESTS PASSENT'
           ELSE
               DISPLAY '* VERDICT  : ECHECS DETECTES'
           END-IF
           DISPLAY '*-----------------------------------------*'.
