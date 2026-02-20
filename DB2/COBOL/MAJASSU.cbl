       IDENTIFICATION DIVISION.
       PROGRAM-ID. MAJASSV2.

      * MISE A JOUR ASSURES - Programme Principal (version dynamique) *
      * Accesseur ASSURES selectionne via PARM JCL :                  *
      *   PARM='PGMVSAM' -> Accesseur VSAM (defaut si PARM absent)    *
      *   PARM='PGMDB2'  -> Accesseur DB2                             *
      * FMVTSE toujours via PGMVSAM (fichier VSAM)                    *

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.

      * Fichier anomalies (gestion directe)
           SELECT F-ETAT-ANO ASSIGN TO ETATANO
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS FS-ANO.

       DATA DIVISION.
       FILE SECTION.

       FD  F-ETAT-ANO.
       01  FS-ANO-REC              PIC X(80).

       WORKING-STORAGE SECTION.

      * Copy books structures
           COPY WASSURE.
           COPY WFMVTSE.

      * File Status
       01  FS-ANO                  PIC XX.

      * Zone de communication accesseur (120 octets)
       01  WS-COM-VSAM.
           05 WS-NOM-FICHIER       PIC X(8).
           05 WS-CODE-FONCTION     PIC 99.
           05 WS-CODE-RETOUR       PIC 99.
           05 WS-ENREG             PIC X(80).
           05 WS-FILLER            PIC X(28).

      * Nom dynamique de l'accesseur ASSURES (depuis PARM JCL)
       01  WS-NOM-ACC-ASSURES      PIC X(8) VALUE 'PGMVSAM'.
      * Noms programmes appeles dynamiquement
       01  WS-NOM-PGMVSAM          PIC X(8) VALUE 'PGMVSAM'.
       01  WS-NOM-PGMERR           PIC X(8) VALUE 'PGMERR'.

      * Codes fonction
       01  WS-CODES-FONCTION.
           05 WS-FUNC-OPEN         PIC 99 VALUE 01.
           05 WS-FUNC-CLOSE        PIC 99 VALUE 02.
           05 WS-FUNC-READ         PIC 99 VALUE 03.
           05 WS-FUNC-REWRITE      PIC 99 VALUE 04.
           05 WS-FUNC-DELETE       PIC 99 VALUE 05.
           05 WS-FUNC-WRITE        PIC 99 VALUE 06.
           05 WS-FUNC-START        PIC 99 VALUE 07.
           05 WS-FUNC-READNEXT     PIC 99 VALUE 08.

      * Codes retour
       01  WS-CODES-RETOUR.
           05 WS-RET-OK            PIC 99 VALUE 00.
           05 WS-RET-NOTFOUND      PIC 99 VALUE 01.
           05 WS-RET-DUPLICATE     PIC 99 VALUE 02.
           05 WS-RET-IOERROR       PIC 99 VALUE 03.
           05 WS-RET-EOF           PIC 99 VALUE 04.
           05 WS-RET-ERROR         PIC 99 VALUE 99.

      * Indicateurs
       01  WS-FLAGS.
           05 WS-FIN-MVTS          PIC X VALUE 'N'.
           05 WS-ASSURE-TROUVE     PIC X VALUE 'N'.

      * Compteurs statistiques
       01  WS-COMPTEURS.
           05 WS-CPT-MVT-LUS       PIC 9(6) VALUE 0.
           05 WS-CPT-ANOMALIES     PIC 9(6) VALUE 0.
           05 WS-CPT-CREES         PIC 9(6) VALUE 0.
           05 WS-CPT-MODIFIES      PIC 9(6) VALUE 0.
           05 WS-CPT-SUPPRIMES     PIC 9(6) VALUE 0.

      * Ligne anomalie
       01  WS-LIGNE-ANO.
           05 WS-ANO-MATRICULE     PIC X(6).
           05 FILLER               PIC X VALUE SPACE.
           05 WS-ANO-TEXTE         PIC X(73).

      * Codes erreur pour PGMERR
       01  WS-CODE-ERREUR          PIC X(3).
       01  WS-LIBELLE-ERREUR       PIC X(60).

       LINKAGE SECTION.

      * PARM JCL : nom de l'accesseur ASSURES (PGMVSAM ou PGMDB2)
       01  LS-PARM.
           05 LS-PARM-LEN          PIC S9(4) COMP.
           05 LS-PARM-DATA         PIC X(8).

       PROCEDURE DIVISION USING LS-PARM.

      * Programme principal                                           *

       00000-DEBUT.
           PERFORM 10000-INIT
           PERFORM 20000-TRAITEMENT
           PERFORM 30000-FIN
           STOP RUN.

      * Initialisation                                                *

       10000-INIT.
      * Lecture PARM : nom de l'accesseur ASSURES
           IF LS-PARM-LEN > 0
               MOVE LS-PARM-DATA(1:LS-PARM-LEN) TO WS-NOM-ACC-ASSURES
           END-IF
           DISPLAY 'ACCESSEUR ASSURES : ' WS-NOM-ACC-ASSURES

      * Ouverture ASSURES3 via accesseur dynamique
           MOVE 'ASSURES3' TO WS-NOM-FICHIER
           MOVE WS-FUNC-OPEN TO WS-CODE-FONCTION
           CALL WS-NOM-ACC-ASSURES USING WS-COM-VSAM
           IF WS-CODE-RETOUR NOT = WS-RET-OK
               DISPLAY 'ERREUR OUVERTURE ASSURES3'
               STOP RUN
           END-IF

      * Ouverture FMVTSE via PGMVSAM (toujours VSAM)
           MOVE 'FMVTSE' TO WS-NOM-FICHIER
           MOVE WS-FUNC-OPEN TO WS-CODE-FONCTION
           CALL WS-NOM-PGMVSAM USING WS-COM-VSAM
           IF WS-CODE-RETOUR NOT = WS-RET-OK
               DISPLAY 'ERREUR OUVERTURE FMVTSE'
               STOP RUN
           END-IF

      * Ouverture fichier anomalies
           OPEN OUTPUT F-ETAT-ANO
           IF FS-ANO NOT = '00'
               DISPLAY 'ERREUR OUVERTURE ETAT-ANO'
               STOP RUN
           END-IF

      * Affichage entête
           DISPLAY '================================================'
           DISPLAY 'TRAITEMENT DE MISE A JOUR DES ASSURES'
           DISPLAY '================================================'
           .

      * Traitement principal                                          *

       20000-TRAITEMENT.
           PERFORM 21000-LIRE-PREMIER-MVT

           PERFORM UNTIL WS-FIN-MVTS = 'O'
               PERFORM 22000-TRAITER-MOUVEMENT
               PERFORM 21000-LIRE-MVT-SUIVANT
           END-PERFORM

           PERFORM 23000-AFFICHER-STATS
           .

      * Lire premier mouvement                                        *

       21000-LIRE-PREMIER-MVT.
           MOVE 'FMVTSE' TO WS-NOM-FICHIER
           MOVE WS-FUNC-READNEXT TO WS-CODE-FONCTION
           CALL WS-NOM-PGMVSAM USING WS-COM-VSAM

           EVALUATE WS-CODE-RETOUR
               WHEN WS-RET-OK
                   MOVE WS-ENREG TO W-FMVTSE
                   ADD 1 TO WS-CPT-MVT-LUS
               WHEN WS-RET-EOF
                   MOVE 'O' TO WS-FIN-MVTS
                   DISPLAY 'FICHIER MOUVEMENTS VIDE'
               WHEN OTHER
                   DISPLAY 'ERREUR LECTURE FMVTSE'
                   PERFORM 30000-FIN
                   STOP RUN
           END-EVALUATE
           .

      * Lire mouvement suivant                                        *

       21000-LIRE-MVT-SUIVANT.
           MOVE 'FMVTSE' TO WS-NOM-FICHIER
           MOVE WS-FUNC-READNEXT TO WS-CODE-FONCTION
           CALL WS-NOM-PGMVSAM USING WS-COM-VSAM

           EVALUATE WS-CODE-RETOUR
               WHEN WS-RET-OK
                   MOVE WS-ENREG TO W-FMVTSE
                   ADD 1 TO WS-CPT-MVT-LUS
               WHEN WS-RET-EOF
                   MOVE 'O' TO WS-FIN-MVTS
               WHEN OTHER
                   DISPLAY 'ERREUR LECTURE FMVTSE'
                   PERFORM 30000-FIN
                   STOP RUN
           END-EVALUATE
           .

      * Traiter un mouvement                                          *

       22000-TRAITER-MOUVEMENT.
           PERFORM 41000-CHERCHER-ASSURE

           EVALUATE F-CODE
               WHEN 'C'
                   PERFORM 43000-TRAITER-CREATION
               WHEN 'M'
                   PERFORM 44000-TRAITER-MODIFICATION
               WHEN 'S'
                   PERFORM 45000-TRAITER-SUPPRESSION
               WHEN OTHER
                   PERFORM 80000-ANO-CODE-INVALIDE
           END-EVALUATE
           .

      * Chercher assuré dans ASSURES3                                 *

       41000-CHERCHER-ASSURE.
           MOVE 'ASSURES3' TO WS-NOM-FICHIER
           MOVE WS-FUNC-READ TO WS-CODE-FONCTION
           MOVE F-MAT TO WS-ENREG(1:6)
           CALL WS-NOM-ACC-ASSURES USING WS-COM-VSAM

           EVALUATE WS-CODE-RETOUR
               WHEN WS-RET-OK
                   MOVE 'O' TO WS-ASSURE-TROUVE
                   MOVE WS-ENREG TO W-ASSURE
               WHEN WS-RET-NOTFOUND
                   MOVE 'N' TO WS-ASSURE-TROUVE
               WHEN OTHER
                   DISPLAY 'ERREUR LECTURE ASSURES3'
                   PERFORM 30000-FIN
                   STOP RUN
           END-EVALUATE
           .

      * Traiter création                                              *

       43000-TRAITER-CREATION.
           IF WS-ASSURE-TROUVE = 'O'
               PERFORM 81000-ANO-CREAT-EXISTANT
           ELSE
               MOVE 'ASSURES3' TO WS-NOM-FICHIER
               MOVE WS-FUNC-WRITE TO WS-CODE-FONCTION
               MOVE W-FMVTSE TO WS-ENREG
               CALL WS-NOM-ACC-ASSURES USING WS-COM-VSAM
               IF WS-CODE-RETOUR = WS-RET-OK
                   ADD 1 TO WS-CPT-CREES
               ELSE
                   DISPLAY 'ERREUR CREATION ASSURE'
               END-IF
           END-IF
           .

      * Traiter modification                                          *

       44000-TRAITER-MODIFICATION.
           IF WS-ASSURE-TROUVE = 'N'
               PERFORM 82000-ANO-MODIF-INEXIST
           ELSE
               MOVE 'ASSURES3' TO WS-NOM-FICHIER
               MOVE WS-FUNC-REWRITE TO WS-CODE-FONCTION
               MOVE W-FMVTSE TO WS-ENREG
               CALL WS-NOM-ACC-ASSURES USING WS-COM-VSAM
               IF WS-CODE-RETOUR = WS-RET-OK
                   ADD 1 TO WS-CPT-MODIFIES
               ELSE
                   DISPLAY 'ERREUR MODIFICATION ASSURE'
               END-IF
           END-IF
           .

      * Traiter suppression                                           *

       45000-TRAITER-SUPPRESSION.
           IF WS-ASSURE-TROUVE = 'N'
               PERFORM 83000-ANO-SUPPR-INEXIST
           ELSE
               MOVE 'ASSURES3' TO WS-NOM-FICHIER
               MOVE WS-FUNC-DELETE TO WS-CODE-FONCTION
               MOVE F-MAT TO WS-ENREG(1:6)
               CALL WS-NOM-ACC-ASSURES USING WS-COM-VSAM
               IF WS-CODE-RETOUR = WS-RET-OK
                   ADD 1 TO WS-CPT-SUPPRIMES
               ELSE
                   DISPLAY 'ERREUR SUPPRESSION ASSURE'
               END-IF
           END-IF
           .

      * Anomalie - Code mouvement invalide                            *

       80000-ANO-CODE-INVALIDE.
           MOVE '001' TO WS-CODE-ERREUR
           CALL WS-NOM-PGMERR USING WS-CODE-ERREUR WS-LIBELLE-ERREUR
           MOVE F-MAT TO WS-ANO-MATRICULE
           STRING 'ERREUR : ' DELIMITED BY SIZE
                  WS-CODE-ERREUR DELIMITED BY SIZE
                  ' - ' DELIMITED BY SIZE
                  WS-LIBELLE-ERREUR DELIMITED BY SIZE
               INTO WS-ANO-TEXTE
           END-STRING
           WRITE FS-ANO-REC FROM WS-LIGNE-ANO
           ADD 1 TO WS-CPT-ANOMALIES
           .

      * Anomalie - Création sur existant                              *

       81000-ANO-CREAT-EXISTANT.
           MOVE '002' TO WS-CODE-ERREUR
           CALL WS-NOM-PGMERR USING WS-CODE-ERREUR WS-LIBELLE-ERREUR
           MOVE F-MAT TO WS-ANO-MATRICULE
           STRING 'ERREUR : ' DELIMITED BY SIZE
                  WS-CODE-ERREUR DELIMITED BY SIZE
                  ' - ' DELIMITED BY SIZE
                  WS-LIBELLE-ERREUR DELIMITED BY SIZE
               INTO WS-ANO-TEXTE
           END-STRING
           WRITE FS-ANO-REC FROM WS-LIGNE-ANO
           ADD 1 TO WS-CPT-ANOMALIES
           .

      * Anomalie - Modification sur inexistant                        *

       82000-ANO-MODIF-INEXIST.
           MOVE '003' TO WS-CODE-ERREUR
           CALL WS-NOM-PGMERR USING WS-CODE-ERREUR WS-LIBELLE-ERREUR
           MOVE F-MAT TO WS-ANO-MATRICULE
           STRING 'ERREUR : ' DELIMITED BY SIZE
                  WS-CODE-ERREUR DELIMITED BY SIZE
                  ' - ' DELIMITED BY SIZE
                  WS-LIBELLE-ERREUR DELIMITED BY SIZE
               INTO WS-ANO-TEXTE
           END-STRING
           WRITE FS-ANO-REC FROM WS-LIGNE-ANO
           ADD 1 TO WS-CPT-ANOMALIES
           .

      * Anomalie - Suppression sur inexistant                         *

       83000-ANO-SUPPR-INEXIST.
           MOVE '004' TO WS-CODE-ERREUR
           CALL WS-NOM-PGMERR USING WS-CODE-ERREUR WS-LIBELLE-ERREUR
           MOVE F-MAT TO WS-ANO-MATRICULE
           STRING 'ERREUR : ' DELIMITED BY SIZE
                  WS-CODE-ERREUR DELIMITED BY SIZE
                  ' - ' DELIMITED BY SIZE
                  WS-LIBELLE-ERREUR DELIMITED BY SIZE
               INTO WS-ANO-TEXTE
           END-STRING
           WRITE FS-ANO-REC FROM WS-LIGNE-ANO
           ADD 1 TO WS-CPT-ANOMALIES
           .

      * Afficher statistiques                                         *

       23000-AFFICHER-STATS.
           DISPLAY '================================================'
           DISPLAY 'STATISTIQUES'
           DISPLAY '================================================'
           DISPLAY 'MOUVEMENTS LUS       : ' WS-CPT-MVT-LUS
           DISPLAY 'CREATIONS            : ' WS-CPT-CREES
           DISPLAY 'MODIFICATIONS        : ' WS-CPT-MODIFIES
           DISPLAY 'SUPPRESSIONS         : ' WS-CPT-SUPPRIMES
           DISPLAY 'ANOMALIES            : ' WS-CPT-ANOMALIES
           DISPLAY '================================================'
           .

      * Fin de traitement                                             *

       30000-FIN.
      * Fermeture ASSURES3 via accesseur dynamique
           MOVE 'ASSURES3' TO WS-NOM-FICHIER
           MOVE WS-FUNC-CLOSE TO WS-CODE-FONCTION
           CALL WS-NOM-ACC-ASSURES USING WS-COM-VSAM

      * Fermeture FMVTSE via PGMVSAM (toujours VSAM)
           MOVE 'FMVTSE' TO WS-NOM-FICHIER
           MOVE WS-FUNC-CLOSE TO WS-CODE-FONCTION
           CALL WS-NOM-PGMVSAM USING WS-COM-VSAM

      * Fermeture fichier anomalies
           CLOSE F-ETAT-ANO
           .
