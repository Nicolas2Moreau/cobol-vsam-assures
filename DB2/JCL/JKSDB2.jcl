//API12K   JOB (ACCT#),'KSDS TO DB2',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,10)
//*---------------------------------------------------------------*
//* JKSDB2 - Synchronisation table DB2 depuis etat actuel KSDS  *
//* STEP1 : Export KSDS ASSURES -> fichier temporaire &&KSDUMP  *
//* STEP2 : Chargement DB2 via KSTODB2 :                        *
//*         - Vide la table DB2 (PGMDB2 fonction 09)            *
//*         - Insert chaque enreg depuis &&KSDUMP (fonction 06) *
//*---------------------------------------------------------------*
//*
//*---------------------------------------------------------------*
//* STEP1 : Export KSDS ASSURES vers fichier sequentiel          *
//*---------------------------------------------------------------*
//EXPKSDS  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//KSDS     DD DSN=API12.KSDS.ASSURES,DISP=SHR
//KSDUMP   DD DSN=&&KSDUMP,
//            DISP=(NEW,PASS,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80)
//SYSIN    DD *
  REPRO INFILE(KSDS) OUTFILE(KSDUMP)
/*
//*
//*---------------------------------------------------------------*
//* STEP2 : Chargement table DB2 depuis &&KSDUMP                 *
//*---------------------------------------------------------------*
//LOADDB2  EXEC PGM=IKJEFT01,COND=(4,LT)
//STEPLIB  DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//*
//KSDUMP   DD DSN=&&KSDUMP,DISP=(OLD,DELETE,DELETE)
//*
//SYSTSIN  DD *
  DSN SYSTEM(DSN1)
  RUN PROGRAM(KSTODB2) PLAN(PGMDB2)
  END
/*
