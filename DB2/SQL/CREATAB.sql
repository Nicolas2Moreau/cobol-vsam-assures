------------------------------------------------------------------
-- CREATAB.sql - Creation table DB2 API12.ASSURES
-- Environnement : DB2 Version 8 / z/OS
-- Correspond au fichier VSAM API12.KSDS.ASSURES
-- Copybook source : COPY/WASSURE.cpy
------------------------------------------------------------------

------------------------------------------------------------------
-- STEP 1 : Suppression si existante
------------------------------------------------------------------
DROP TABLE API12.ASSURES;

------------------------------------------------------------------
-- STEP 2 : Creation de la table
--
-- Correspondance COBOL DISPLAY -> DB2 :
--   A-MAT     PIC 9(6)    -> CHAR(6)      cle primaire
--   A-NOM-PRE PIC X(20)   -> CHAR(20)
--   A-RUE     PIC X(18)   -> CHAR(18)
--   A-CP      PIC 9(5)    -> CHAR(5)      code postal conserve en CHAR
--   A-VILLE   PIC X(12)   -> CHAR(12)
--   A-CODE    PIC X(1)    -> CHAR(1)      type vehicule
--   A-PRIME   PIC 9(4)V99 -> DECIMAL(6,2) conversion COMP-3 necessaire
--   A-BM      PIC X(1)    -> CHAR(1)      bonus/malus
--   A-TAUX    PIC 99      -> SMALLINT     conversion COMP necessaire
--   FILLER    PIC X(9)    -> (non stocke)
------------------------------------------------------------------
CREATE TABLE API12.ASSURES
  (MATASS   CHAR(6)       NOT NULL,
   NOMPRE   CHAR(20)      NOT NULL WITH DEFAULT ' ',
   RUESS    CHAR(18)      NOT NULL WITH DEFAULT ' ',
   CPASS    CHAR(5)       NOT NULL WITH DEFAULT '00000',
   VILLSS   CHAR(12)      NOT NULL WITH DEFAULT ' ',
   CODVEH   CHAR(1)       NOT NULL WITH DEFAULT ' ',
   PRIMSS   DECIMAL(6,2)  NOT NULL WITH DEFAULT 0,
   BONMAL   CHAR(1)       NOT NULL WITH DEFAULT ' ',
   TAUXSS   SMALLINT      NOT NULL WITH DEFAULT 0,
   PRIMARY KEY (MATASS));

------------------------------------------------------------------
-- STEP 3 : Index (cree automatiquement via PRIMARY KEY,
--          mais on peut en ajouter un explicite)
------------------------------------------------------------------
-- CREATE UNIQUE INDEX API12.IXASSURES
--   ON API12.ASSURES (MATASS ASC);

------------------------------------------------------------------
-- Notes :
-- - Le TABLESPACE est alloue dans DATABASE API12DB
--   (a creer par l admin si inexistant)
-- - MATASS est en CHAR(6) pour compatibilite avec les donnees
--   DISPLAY du fichier VSAM source (ex: '000001')
-- - CPASS en CHAR(5) pour les codes postaux avec zero initial
-- - Apres CREATE : lancer DCLGEN pour generer COPY/ASSURE.cpy
------------------------------------------------------------------
