       IDENTIFICATION DIVISION.
       PROGRAM-ID. PGMERR.
     
      * GESTION MESSAGES ERREUR - Retourne libellé depuis table      *
     

       DATA DIVISION.
       WORKING-STORAGE SECTION.

      * Table des messages (30 messages de 60 car)
           COPY MESSAGES.

      * Redéfinition pour accès indexé
       01  TABLE-MESSAGES-R REDEFINES TABLE-MESSAGE.
           05 WS-MESSAGE OCCURS 30 TIMES PIC X(60).

       01  WS-INDEX                PIC 99.
       01  WS-CODE-CHERCHE         PIC X(3).

       LINKAGE SECTION.

       01  LS-CODE-ERREUR          PIC X(3).
       01  LS-LIBELLE-ERREUR       PIC X(60).

       PROCEDURE DIVISION USING LS-CODE-ERREUR LS-LIBELLE-ERREUR.

      * Programme principal                                           *
       MAIN-PGMERR.
           PERFORM CHERCHER-MESSAGE
           GOBACK.

      * Chercher message dans la table                                *
       CHERCHER-MESSAGE.
      * Initialisation
           MOVE SPACES TO LS-LIBELLE-ERREUR
           MOVE LS-CODE-ERREUR TO WS-CODE-CHERCHE

      * Recherche dans la table
           PERFORM VARYING WS-INDEX FROM 1 BY 1
               UNTIL WS-INDEX > 30
               IF WS-MESSAGE(WS-INDEX)(1:3) = WS-CODE-CHERCHE
                   MOVE WS-MESSAGE(WS-INDEX) TO LS-LIBELLE-ERREUR
                   EXIT PERFORM
               END-IF
           END-PERFORM

      * Si non trouvé, message par défaut
           IF LS-LIBELLE-ERREUR = SPACES
               STRING 'ERREUR INCONNUE - CODE : ' DELIMITED BY SIZE
                      WS-CODE-CHERCHE DELIMITED BY SIZE
                   INTO LS-LIBELLE-ERREUR
               END-STRING
           END-IF
           .
