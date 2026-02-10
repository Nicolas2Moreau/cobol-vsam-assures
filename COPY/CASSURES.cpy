      *----------------------------------------------------------*
      *    DESCRIPTION DE L'ENREGISTREMENT DU FICHIER ASSURE3    *
      *     (FICHIER VSAM KSDS: LONG ENGT = 80  (LONG CLE = 6)   *
      *                                         (POSITION = 1)   *
      *----------------------------------------------------------*
      *--------------------------------------------- MATRICULE
           02 MAT-A4             PIC 9(6).
           02 MAT-X4  REDEFINES MAT-A4   PIC X(6).
      *------------------------------------------ NOM-PRENOM
           02 NOM-PRE-A4         PIC X(20).
      *------------------------------------------ RUE
           02 RUE-A4             PIC X(18).
      *------------------------------------------ CODE POSTAL
           02 CP-A4              PIC 9(5).
      *------------------------------------------ VILLE
           02 VILLE-A4           PIC X(12).
      *------------------------------------------ TYPE VEHICULE
           02 TYPE-V-A4          PIC X.
      *------------------------------------------ PRIME D'ASSURANCE
           02 PRIME-A4           PIC 9(4)V99.
      *------------------------------------------ CODE BONUS/MALUS
      *                                           B : BONUS
      *                                           M : MALUS
           02 BM-A4              PIC X.
      *--------------------------------------------- TAUX BONUS/MALUS
           02 TAUX-A4            PIC 99.
      *--------------------------------------------- RESTE ENGT
           02                    PIC X(9).
      *
      *----------------  FIN DE DESCRIPTION ASSURE4 --------------*
