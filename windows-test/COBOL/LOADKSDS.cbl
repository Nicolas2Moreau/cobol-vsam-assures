       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOADKSDS.

      * CHARGEMENT KSDS - Charge les assures depuis fichier source *
      * Lit DATA/ASSURES et cree WORK/ASSURES.dat (indexed)        *

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

      * Fichier source (sequentiel avec retours ligne)
           SELECT F-SOURCE ASSIGN TO "DATA/ASSURES"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS FS-SOURCE.

      * Fichier KSDS destination (indexed)
           SELECT F-KSDS ASSIGN TO "WORK/ASSURES.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS FS-KSDS-KEY
               FILE STATUS IS FS-KSDS.

       DATA DIVISION.
       FILE SECTION.

       FD  F-SOURCE.
       01  FS-SOURCE-REC           PIC X(80).

       FD  F-KSDS.
       01  FS-KSDS-REC.
           05 FS-KSDS-KEY          PIC 9(6).
           05 FS-KSDS-DATA         PIC X(74).

       WORKING-STORAGE SECTION.

       01  FS-SOURCE               PIC XX.
       01  FS-KSDS                 PIC XX.
       01  WS-COMPTEUR             PIC 9(6) VALUE 0.
       01  WS-FIN                  PIC X VALUE 'N'.

       PROCEDURE DIVISION.

      * Programme principal                                         *

       00000-DEBUT.
           DISPLAY '========================================'
           DISPLAY 'CHARGEMENT KSDS ASSURES'
           DISPLAY '========================================'
           PERFORM 10000-INIT
           PERFORM 20000-TRAITEMENT
           PERFORM 30000-FIN
           STOP RUN.

      * Initialisation                                              *

       10000-INIT.
           OPEN INPUT F-SOURCE
           IF FS-SOURCE NOT = '00'
               DISPLAY 'ERREUR OUVERTURE FICHIER SOURCE'
               DISPLAY 'FILE STATUS : ' FS-SOURCE
               STOP RUN
           END-IF

           OPEN OUTPUT F-KSDS
           IF FS-KSDS NOT = '00'
               DISPLAY 'ERREUR OUVERTURE KSDS'
               DISPLAY 'FILE STATUS : ' FS-KSDS
               STOP RUN
           END-IF
           .

      * Traitement                                                  *

       20000-TRAITEMENT.
           PERFORM UNTIL WS-FIN = 'O'
               PERFORM 21000-LIRE-SOURCE
               IF WS-FIN = 'N'
                   PERFORM 22000-ECRIRE-KSDS
               END-IF
           END-PERFORM

           DISPLAY '========================================'
           DISPLAY 'CHARGEMENT TERMINE'
           DISPLAY 'ENREGISTREMENTS CHARGES : ' WS-COMPTEUR
           DISPLAY '========================================'
           .

      * Lire enregistrement source                                 *

       21000-LIRE-SOURCE.
           READ F-SOURCE
               AT END
                   MOVE 'O' TO WS-FIN
               NOT AT END
                   CONTINUE
           END-READ

           IF FS-SOURCE NOT = '00' AND FS-SOURCE NOT = '10'
               DISPLAY 'ERREUR LECTURE SOURCE'
               DISPLAY 'FILE STATUS : ' FS-SOURCE
               STOP RUN
           END-IF
           .

      * Ecrire dans KSDS                                           *

       22000-ECRIRE-KSDS.
           MOVE FS-SOURCE-REC TO FS-KSDS-REC

           WRITE FS-KSDS-REC
               INVALID KEY
                   DISPLAY 'ERREUR ECRITURE KSDS (CLE DUPLIQUEE ?)'
                   DISPLAY 'MATRICULE : ' FS-KSDS-KEY
                   DISPLAY 'FILE STATUS : ' FS-KSDS
               NOT INVALID KEY
                   ADD 1 TO WS-COMPTEUR
           END-WRITE
           .

      * Fin de traitement                                          *

       30000-FIN.
           CLOSE F-SOURCE
           CLOSE F-KSDS
           .
