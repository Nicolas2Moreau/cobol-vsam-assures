      ******************************************************************
      * DCLGEN TABLE(API12.ASSURES)                                    *
      *        LIBRARY(API12.COB.CPY(DCLASSU))                         *
      *        ACTION(REPLACE)                                         *
      *        LANGUAGE(COBOL)                                         *
      *        NAMES(WS-)                                              *
      *        STRUCTURE(WS-ASSURE)                                    *
      *        QUOTE                                                   *
      *        DBCSDELIM(NO)                                           *
      *        COLSUFFIX(YES)                                          *
      * ... IS THE DCLGEN COMMAND THAT MADE THE FOLLOWING STATEMENTS   *
      ******************************************************************
           EXEC SQL DECLARE API12.ASSURES TABLE
           ( MATASS                         CHAR(6) NOT NULL,
             NOMPRE                         CHAR(20) NOT NULL,
             RUESS                          CHAR(18) NOT NULL,
             CPASS                          CHAR(5) NOT NULL,
             VILLSS                         CHAR(12) NOT NULL,
             CODVEH                         CHAR(1) NOT NULL,
             PRIMSS                         DECIMAL(6, 2) NOT NULL,
             BONMAL                         CHAR(1) NOT NULL,
             TAUXSS                         SMALLINT NOT NULL
           ) END-EXEC.
      ******************************************************************
      * COBOL DECLARATION FOR TABLE API12.ASSURES                      *
      ******************************************************************
       01  WS-ASSURE.
      *                       MATASS
           10 WS-MATASS            PIC X(6).
      *                       NOMPRE
           10 WS-NOMPRE            PIC X(20).
      *                       RUESS
           10 WS-RUESS             PIC X(18).
      *                       CPASS
           10 WS-CPASS             PIC X(5).
      *                       VILLSS
           10 WS-VILLSS            PIC X(12).
      *                       CODVEH
           10 WS-CODVEH            PIC X(1).
      *                       PRIMSS
           10 WS-PRIMSS            PIC S9(4)V9(2) USAGE COMP-3.
      *                       BONMAL
           10 WS-BONMAL            PIC X(1).
      *                       TAUXSS
           10 WS-TAUXSS            PIC S9(4) USAGE COMP.
      ******************************************************************
      * THE NUMBER OF COLUMNS DESCRIBED BY THIS DECLARATION IS 9       *
      ******************************************************************
