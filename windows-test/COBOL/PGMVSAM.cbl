       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMVSAM.
     
      * ACCESSEUR VSAM - GESTION KSDS (ASSURES3) ET ESDS (FMVTSE)    *
     

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

      * Fichier KSDS - Assurés (accès direct et séquentiel)
           SELECT F-ASSURES ASSIGN TO "WORK/ASSURES.dat"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS FS-ASSURES-KEY
               FILE STATUS IS FS-ASSURES.

      * Fichier ESDS - Mouvements (accès séquentiel uniquement)
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

      * Indicateurs ouverture
       01  WS-OPEN-FLAGS.
           05 WS-ASSURES-OPEN      PIC X VALUE 'N'.
           05 WS-MVTS-OPEN         PIC X VALUE 'N'.

      * Codes fonction (conformes PDF page 17)
       01  WS-CODES-FONCTION.
           05 WS-CODE-OPEN         PIC 99 VALUE 01.
           05 WS-CODE-CLOSE        PIC 99 VALUE 02.
           05 WS-CODE-READ         PIC 99 VALUE 03.
           05 WS-CODE-REWRITE      PIC 99 VALUE 04.
           05 WS-CODE-DELETE       PIC 99 VALUE 05.
           05 WS-CODE-WRITE        PIC 99 VALUE 06.
           05 WS-CODE-START        PIC 99 VALUE 07.
           05 WS-CODE-READNEXT     PIC 99 VALUE 08.

      * Codes retour (conformes PDF page 17)
       01  WS-CODES-RETOUR.
           05 WS-RETOUR-OK         PIC 99 VALUE 00.
           05 WS-RETOUR-EOF        PIC 99 VALUE 01.
           05 WS-RETOUR-NOTFOUND   PIC 99 VALUE 02.
           05 WS-RETOUR-DUPLICATE  PIC 99 VALUE 03.
           05 WS-RETOUR-NOTOPEN    PIC 99 VALUE 04.
           05 WS-RETOUR-ERROR      PIC 99 VALUE 99.

       01  WS-FILE-STATUS          PIC XX.

       LINKAGE SECTION.

      * Zone de communication 120 octets
       01  LS-COM.
           05 LS-NOM-FICHIER       PIC X(8).
           05 LS-CODE-FONCTION     PIC 99.
           05 LS-CODE-RETOUR       PIC 99.
           05 LS-ENREG             PIC X(80).
           05 LS-FILLER            PIC X(20).

       PROCEDURE DIVISION USING LS-COM.

       MAIN-PGMVSAM.
           MOVE WS-RETOUR-OK TO LS-CODE-RETOUR

           EVALUATE LS-CODE-FONCTION
               WHEN WS-CODE-OPEN
                   PERFORM OPEN-FILE
               WHEN WS-CODE-CLOSE
                   PERFORM CLOSE-FILE
               WHEN WS-CODE-READ
                   PERFORM READ-FILE
               WHEN WS-CODE-REWRITE
                   PERFORM REWRITE-FILE
               WHEN WS-CODE-DELETE
                   PERFORM DELETE-FILE
               WHEN WS-CODE-WRITE
                   PERFORM WRITE-FILE
               WHEN WS-CODE-START
                   PERFORM START-FILE
               WHEN WS-CODE-READNEXT
                   PERFORM READNEXT-FILE
               WHEN OTHER
                   MOVE WS-RETOUR-ERROR TO LS-CODE-RETOUR
           END-EVALUATE

           GOBACK.

     
      * OPEN - Ouverture fichier                                      *
     
       OPEN-FILE.
           EVALUATE LS-NOM-FICHIER
               WHEN 'ASSURES3'
                   IF WS-ASSURES-OPEN = 'N'
                       OPEN I-O F-ASSURES
                       MOVE FS-ASSURES TO WS-FILE-STATUS
                       MOVE 'O' TO WS-ASSURES-OPEN
                   ELSE
                       MOVE '00' TO WS-FILE-STATUS
                   END-IF
               WHEN 'FMVTSE'
                   IF WS-MVTS-OPEN = 'N'
                       OPEN INPUT F-MVTS
                       MOVE FS-MVTS TO WS-FILE-STATUS
                       MOVE 'O' TO WS-MVTS-OPEN
                   ELSE
                       MOVE '00' TO WS-FILE-STATUS
                   END-IF
               WHEN OTHER
                   MOVE '99' TO WS-FILE-STATUS
           END-EVALUATE

           PERFORM MAPPER-FILE-STATUS.

     
      * CLOSE - Fermeture fichier                                     *
     
       CLOSE-FILE.
           EVALUATE LS-NOM-FICHIER
               WHEN 'ASSURES3'
                   IF WS-ASSURES-OPEN = 'O'
                       CLOSE F-ASSURES
                       MOVE FS-ASSURES TO WS-FILE-STATUS
                       MOVE 'N' TO WS-ASSURES-OPEN
                   ELSE
                       MOVE '00' TO WS-FILE-STATUS
                   END-IF
               WHEN 'FMVTSE'
                   IF WS-MVTS-OPEN = 'O'
                       CLOSE F-MVTS
                       MOVE FS-MVTS TO WS-FILE-STATUS
                       MOVE 'N' TO WS-MVTS-OPEN
                   ELSE
                       MOVE '00' TO WS-FILE-STATUS
                   END-IF
               WHEN OTHER
                   MOVE '99' TO WS-FILE-STATUS
           END-EVALUATE

           PERFORM MAPPER-FILE-STATUS.

     
      * READ - Lecture directe par clé (KSDS uniquement)              *
     
       READ-FILE.
           IF LS-NOM-FICHIER = 'ASSURES3'
               MOVE LS-ENREG(1:6) TO FS-ASSURES-KEY
               READ F-ASSURES
                   INVALID KEY
                       MOVE '23' TO WS-FILE-STATUS
                   NOT INVALID KEY
                       MOVE FS-ASSURES TO WS-FILE-STATUS
                       MOVE FS-ASSURES-REC TO LS-ENREG
               END-READ
           ELSE
               MOVE '99' TO WS-FILE-STATUS
           END-IF

           PERFORM MAPPER-FILE-STATUS.

     
      * REWRITE - Mise à jour enregistrement (KSDS uniquement)        *
     
       REWRITE-FILE.
           IF LS-NOM-FICHIER = 'ASSURES3'
               MOVE LS-ENREG TO FS-ASSURES-REC
               REWRITE FS-ASSURES-REC
                   INVALID KEY
                       MOVE '23' TO WS-FILE-STATUS
                   NOT INVALID KEY
                       MOVE FS-ASSURES TO WS-FILE-STATUS
               END-REWRITE
           ELSE
               MOVE '99' TO WS-FILE-STATUS
           END-IF

           PERFORM MAPPER-FILE-STATUS.

     
      * DELETE - Suppression enregistrement (KSDS uniquement)         *
     
       DELETE-FILE.
           IF LS-NOM-FICHIER = 'ASSURES3'
               MOVE LS-ENREG(1:6) TO FS-ASSURES-KEY
               DELETE F-ASSURES
                   INVALID KEY
                       MOVE '23' TO WS-FILE-STATUS
                   NOT INVALID KEY
                       MOVE FS-ASSURES TO WS-FILE-STATUS
               END-DELETE
           ELSE
               MOVE '99' TO WS-FILE-STATUS
           END-IF

           PERFORM MAPPER-FILE-STATUS.

     
      * WRITE - Création enregistrement (KSDS uniquement)             *
     
       WRITE-FILE.
           IF LS-NOM-FICHIER = 'ASSURES3'
               MOVE LS-ENREG TO FS-ASSURES-REC
               WRITE FS-ASSURES-REC
                   INVALID KEY
                       MOVE '22' TO WS-FILE-STATUS
                   NOT INVALID KEY
                       MOVE FS-ASSURES TO WS-FILE-STATUS
               END-WRITE
           ELSE
               MOVE '99' TO WS-FILE-STATUS
           END-IF

           PERFORM MAPPER-FILE-STATUS.

     
      * START - Positionnement début fichier (KSDS uniquement)        *
     
       START-FILE.
           IF LS-NOM-FICHIER = 'ASSURES3'
               MOVE LOW-VALUES TO FS-ASSURES-KEY
               START F-ASSURES KEY >= FS-ASSURES-KEY
                   INVALID KEY
                       MOVE '23' TO WS-FILE-STATUS
                   NOT INVALID KEY
                       MOVE FS-ASSURES TO WS-FILE-STATUS
               END-START
           ELSE
               MOVE '00' TO WS-FILE-STATUS
           END-IF

           PERFORM MAPPER-FILE-STATUS.

     
      * READNEXT - Lecture séquentielle                               *
     
       READNEXT-FILE.
           MOVE SPACES TO LS-ENREG

           EVALUATE LS-NOM-FICHIER
               WHEN 'ASSURES3'
                   READ F-ASSURES NEXT
                       AT END
                           MOVE '10' TO WS-FILE-STATUS
                       NOT AT END
                           MOVE FS-ASSURES TO WS-FILE-STATUS
                           MOVE FS-ASSURES-REC TO LS-ENREG
                   END-READ
               WHEN 'FMVTSE'
                   READ F-MVTS
                       AT END
                           MOVE '10' TO WS-FILE-STATUS
                       NOT AT END
                           MOVE FS-MVTS TO WS-FILE-STATUS
                           MOVE FS-MVTS-REC TO LS-ENREG
                   END-READ
               WHEN OTHER
                   MOVE '99' TO WS-FILE-STATUS
           END-EVALUATE

           PERFORM MAPPER-FILE-STATUS.

     
      * MAPPER-FILE-STATUS - Conversion File-Status -> Code retour    *
     
       MAPPER-FILE-STATUS.
           EVALUATE WS-FILE-STATUS
               WHEN '00'
                   MOVE WS-RETOUR-OK TO LS-CODE-RETOUR
               WHEN '10'
                   MOVE WS-RETOUR-EOF TO LS-CODE-RETOUR
               WHEN '23'
                   MOVE WS-RETOUR-NOTFOUND TO LS-CODE-RETOUR
               WHEN '24'
                   MOVE WS-RETOUR-NOTFOUND TO LS-CODE-RETOUR
               WHEN '22'
                   MOVE WS-RETOUR-DUPLICATE TO LS-CODE-RETOUR
               WHEN '90' THRU '99'
                   MOVE WS-RETOUR-NOTOPEN TO LS-CODE-RETOUR
               WHEN OTHER
                   MOVE WS-RETOUR-ERROR TO LS-CODE-RETOUR
           END-EVALUATE.
