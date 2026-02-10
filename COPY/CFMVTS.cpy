      *---------------DEFINITION DU FICHIER FMVTSE----------------
      *----------------------------------------------------------*
      *    DESCRIPTION DE L'ENREGISTREMENT DU FICHIER MOUVEMENT  *
      *     (FICHIER VSAM ESDS: LONG ENGT = 80                   *
      *----------------------------------------------------------*
      *--------------------------------------------- MATRICULE
           02 MAT-MVT            PIC X(6).
      *------------------------------------------ NOM-PRENOM
           02 NOM-PRE-MVT        PIC X(20).
      *------------------------------------------ RUE
           02 RUE-MVT            PIC X(18).
      *------------------------------------------ CODE POSTAL
           02 CP-MVT             PIC 9(5).
      *------------------------------------------ VILLE
           02 VILLE-MVT          PIC X(12).
      *------------------------------------------ CODE MOUVEMENT
           02 CODE-MVT           PIC X.
      *------------------------------------------ PRIME D'ASSURANCE
           02 PRIME-MVT          PIC 9(4)V99.
      *------------------------------------------ CODE BONUS/MALUS
      *                                           B : BONUS
      *                                           M : MALUS
           02 BM-MVT             PIC X.
      *--------------------------------------------- TAUX BONUS/MALUS
           02 TAUX-MVT           PIC 99.
      *--------------------------------------------- RESTE ENGT
           02                    PIC X(9).
      *
      *----------------  FIN DE DESCRIPTION MOUVEMENT ------------*
