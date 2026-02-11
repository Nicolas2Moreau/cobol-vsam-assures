       IDENTIFICATION DIVISION.
       PROGRAM-ID. READDATA.

      * UTILITAIRE - LECTURE ET AFFICHAGE DES FICHIERS KSDS ET ESDS *

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

      * Fichier KSDS - Assures
           SELECT F-ASSURES ASSIGN TO "WORK/ASSURES.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS FS-ASSURES-KEY
               FILE STATUS IS FS-ASSURES.

      * Fichier ESDS - Mouvements
           SELECT F-MVTS ASSIGN TO "WORK/MVTS.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS FS-MVTS.

       DATA DIVISION.
       FILE SECTION.

       FD  F-ASSURES.
       01  FS-ASSURES-REC.
           05 FS-ASSURES-KEY       PIC 9(6).
           05 FS-ASSURES-DATA      PIC X(74).

       FD  F-MVTS.
       01  FS-MVTS-REC             PIC X(80).

       WORKING-STORAGE SECTION.

      * File status
       01  FS-ASSURES              PIC XX.
       01  FS-MVTS                 PIC XX.

      * Compteurs
       01  WS-COMPTEURS.
           05 WS-NB-ASSURES        PIC 9(5) VALUE 0.
           05 WS-NB-MVTS           PIC 9(5) VALUE 0.

      * Decomposition enregistrement assure (pour affichage)
       01  WS-ASSURE.
           05 WS-MATR              PIC 9(6).
           05 WS-NOM               PIC X(20).
           05 WS-PRENOM            PIC X(15).
           05 WS-ADRESSE           PIC X(30).
           05 WS-RESTE             PIC X(9).

      * Decomposition enregistrement mouvement (pour affichage)
       01  WS-MVT.
           05 WS-MVT-MATR          PIC 9(6).
           05 WS-MVT-CODE          PIC X.
           05 WS-MVT-NOM           PIC X(20).
           05 WS-MVT-PRENOM        PIC X(15).
           05 WS-MVT-ADRESSE       PIC X(30).
           05 WS-MVT-RESTE         PIC X(8).

       PROCEDURE DIVISION.

       DEBUT.
           DISPLAY "========================================"
           DISPLAY "LECTURE FICHIERS KSDS ET ESDS"
           DISPLAY "========================================"
           DISPLAY " "

           PERFORM LIRE-KSDS
           DISPLAY " "
           PERFORM LIRE-ESDS

           DISPLAY " "
           DISPLAY "========================================"
           DISPLAY "KSDS ASSURES : " WS-NB-ASSURES
                   " enregistrement(s)"
           DISPLAY "ESDS MVTS    : " WS-NB-MVTS
                   " enregistrement(s)"
           DISPLAY "========================================"

           STOP RUN.

       LIRE-KSDS.
           DISPLAY "--- KSDS ASSURES (WORK/ASSURES.dat) ---"
           DISPLAY " "

           OPEN INPUT F-ASSURES

           IF FS-ASSURES NOT = '00'
               DISPLAY "ERREUR OUVERTURE KSDS : " FS-ASSURES
               DISPLAY "(Fichier inexistant? Lancer init.bat)"
               GO TO FIN-LIRE-KSDS
           END-IF

           PERFORM UNTIL FS-ASSURES = '10'
               READ F-ASSURES
                   AT END
                       CONTINUE
                   NOT AT END
                       ADD 1 TO WS-NB-ASSURES
                       MOVE FS-ASSURES-REC TO WS-ASSURE
                       DISPLAY WS-MATR " | " WS-NOM " | "
                               WS-PRENOM " | " WS-ADRESSE
               END-READ
           END-PERFORM

           CLOSE F-ASSURES.

       FIN-LIRE-KSDS.
           EXIT.

       LIRE-ESDS.
           DISPLAY "--- ESDS MOUVEMENTS (WORK/MVTS.dat) ---"
           DISPLAY " "

           OPEN INPUT F-MVTS

           IF FS-MVTS NOT = '00'
               DISPLAY "ERREUR OUVERTURE ESDS : " FS-MVTS
               DISPLAY "(Fichier inexistant? Lancer init.bat)"
               GO TO FIN-LIRE-ESDS
           END-IF

           PERFORM UNTIL FS-MVTS = '10'
               READ F-MVTS
                   AT END
                       CONTINUE
                   NOT AT END
                       ADD 1 TO WS-NB-MVTS
                       MOVE FS-MVTS-REC TO WS-MVT
                       DISPLAY WS-MVT-MATR " | " WS-MVT-CODE " | "
                               WS-MVT-NOM " | " WS-MVT-PRENOM
               END-READ
           END-PERFORM

           CLOSE F-MVTS.

       FIN-LIRE-ESDS.
           EXIT.
