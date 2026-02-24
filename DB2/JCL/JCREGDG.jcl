//API12G   JOB (ACCT#),'CREATION GDG',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,5)
//*---------------------------------------------------------------*
//* JCREGDG - Creation base GDG pour ETATANO                    *
//* A lancer UNE SEULE FOIS (ou si la base GDG est perdue)      *
//* STEP1 : DELETE FORCE + DEFINE GDG + ALTER OWNER             *
//*---------------------------------------------------------------*
//DEFGDG   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE (API12.GDGASU) GDG FORCE
  IF LASTCC LE 8 THEN SET MAXCC = 0
  DEFINE GDG(NAME(API12.GDGASU)        -
             LIMIT(10)                 -
             NOEMPTY                   -
             SCRATCH)
  ALTER 'API12.GDGASU' OWNER(API12)
/*
