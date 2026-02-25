       IDENTIFICATION DIVISION.
       PROGRAM-ID. KSTODB2.

      *---------------------------------------------------------------*
      * KSTODB2 - Chargement table DB2 depuis export KSDS            *
      * 1. Vide la table DB2 (PGMDB2 fonction 09 - TRUNCATE)        *
      * 2. Insere chaque enreg du fichier sequentiel (fonction 06)   *
      * Usage : lancer apres JCREVSAM pour isometrie KSDS <-> DB2   *
      *---------------------------------------------------------------*

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT F-KSDUMP    ASSIGN TO KSDUMP
                              ORGANIZATION IS SEQUENTIAL
                              ACCESS MODE  IS SEQUENTIAL
                              FILE STATUS  IS FS-DUMP.

       DATA DIVISION.
       FILE SECTION.
       FD  F-KSDUMP
           RECORDING MODE F
           BLOCK CONTAINS 0 RECORDS
           RECORD CONTAINS 80 CHARACTERS.
       01  WS-ENREG-DUMP              PIC X(80).

       WORKING-STORAGE SECTION.

       01  FS-DUMP                    PIC XX.

      * Zone de communication accesseur (120 octets)
       01  WS-COM.
           05 WS-NOM-FICHIER          PIC X(8).
           05 WS-CODE-FONCTION        PIC 99.
           05 WS-CODE-RETOUR          PIC 99.
           05 WS-ENREG                PIC X(80).
           05 WS-FILLER               PIC X(28).

      * Nom programme appele dynamiquement
       01  WS-NOM-PGMDB2           PIC X(8) VALUE 'PGMDB2'.

      * Codes fonction
       01  WS-CODES-FONCTION.
           05 WS-FUNC-INSERT          PIC 99 VALUE 06.
           05 WS-FUNC-TRUNCATE        PIC 99 VALUE 09.

      * Codes retour
       01  WS-RET-OK                  PIC 99 VALUE 00.

      * Compteurs
       01  WS-NB-LUS                  PIC 9(6) VALUE 0.
       01  WS-NB-INSERTS              PIC 9(6) VALUE 0.
       01  WS-NB-ERREURS              PIC 9(6) VALUE 0.

       01  WS-FIN-FICHIER             PIC X VALUE 'N'.

       PROCEDURE DIVISION.

       0000-PRINCIPAL.
           PERFORM 10000-INIT
           PERFORM 20000-TRUNCATE
           PERFORM 30000-BOUCLE UNTIL WS-FIN-FICHIER = 'O'
           PERFORM 90000-FIN
           STOP RUN.

      *---------------------------------------------------------------*
       10000-INIT.
           OPEN INPUT F-KSDUMP
           IF FS-DUMP NOT = '00'
               DISPLAY 'ERREUR OUVERTURE KSDUMP : ' FS-DUMP
               STOP RUN
           END-IF
           MOVE 'ASSURES3' TO WS-NOM-FICHIER
           DISPLAY '================================================'
           DISPLAY 'CHARGEMENT TABLE DB2 ASSURES DEPUIS KSDS'
           DISPLAY '================================================'.

      *---------------------------------------------------------------*
       20000-TRUNCATE.
           MOVE WS-FUNC-TRUNCATE TO WS-CODE-FONCTION
           CALL WS-NOM-PGMDB2 USING WS-COM
           IF WS-CODE-RETOUR = WS-RET-OK
               DISPLAY 'TABLE ASSURES VIDEE AVEC SUCCES'
           ELSE
               DISPLAY 'ERREUR TRUNCATE CODE : ' WS-CODE-RETOUR
               STOP RUN
           END-IF.

      *---------------------------------------------------------------*
       30000-BOUCLE.
           READ F-KSDUMP INTO WS-ENREG
           IF FS-DUMP = '10'
               MOVE 'O' TO WS-FIN-FICHIER
           ELSE IF FS-DUMP NOT = '00'
               DISPLAY 'ERREUR LECTURE KSDUMP : ' FS-DUMP
               MOVE 'O' TO WS-FIN-FICHIER
           ELSE
               ADD 1 TO WS-NB-LUS
               MOVE WS-FUNC-INSERT TO WS-CODE-FONCTION
               CALL WS-NOM-PGMDB2 USING WS-COM
               IF WS-CODE-RETOUR = WS-RET-OK
                   ADD 1 TO WS-NB-INSERTS
               ELSE
                   ADD 1 TO WS-NB-ERREURS
                   DISPLAY 'ERREUR INSERT ENREG ' WS-NB-LUS
                           ' CODE : ' WS-CODE-RETOUR
               END-IF
           END-IF.

      *---------------------------------------------------------------*
       90000-FIN.
           CLOSE F-KSDUMP
           DISPLAY '================================================'
           DISPLAY 'STATISTIQUES CHARGEMENT'
           DISPLAY '================================================'
           DISPLAY 'ENREGISTREMENTS LUS     : ' WS-NB-LUS
           DISPLAY 'INSERTIONS REUSSIES     : ' WS-NB-INSERTS
           DISPLAY 'ERREURS                 : ' WS-NB-ERREURS.
