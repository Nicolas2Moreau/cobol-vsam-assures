//API12B   JOB (ACCT#),'MAJ DB2',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,10)
//*---------------------------------------------------------------*
//* JMAJDB2 - Rechargement ESDS MVTS + Execution MAJASSU DB2    *
//* STEP1 : Tri MVTS -> fichier temporaire &&MVTST              *
//* STEP2 : Suppression et recreation ESDS FMVTSE               *
//* STEP3 : Execution MAJASSU via IKJEFT01 avec PGMDB2          *
//*         PARM='PGMDB2' -> MAJASSU appelle l accesseur DB2    *
//*         ASSURES : pas de DD (DB2 gere la table API12.ASSURES)*
//*         MVTS    : DD pour FMVTSE (toujours VSAM via PGMVSAM)*
//*---------------------------------------------------------------*
//*
//*---------------------------------------------------------------*
//* STEP1 : Tri fichier MVTS sur Matricule + Code mouvement      *
//*---------------------------------------------------------------*
//TRIMVT   EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=API12.SEQ.MVTS,DISP=SHR
//SORTOUT  DD DSN=&&MVTST,
//            DISP=(NEW,PASS,DELETE),
//            SPACE=(TRK,(1,1))
//SYSIN    DD *
  SORT FIELDS=(1,6,ZD,A,62,1,CH,A)
/*
//*
//*---------------------------------------------------------------*
//* STEP2 : Suppression et recreation ESDS FMVTSE depuis &&MVTST *
//*---------------------------------------------------------------*
//CESDS    EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//MVTST    DD DSN=&&MVTST,DISP=(OLD,DELETE,DELETE)
//SYSIN    DD *
  DELETE  (API12.ESDS.MVTS) CLUSTER PURGE
  SET MAXCC = 0
  DEFINE  CLUSTER  (NAME(API12.ESDS.MVTS)   -
                 TRACKS   (1,1)             -
                 NONINDEXED                 -
                 RECSZ (80,80))
  REPRO INFILE(MVTST)                       -
        OUTDATASET(API12.ESDS.MVTS)
/*
//*
//*---------------------------------------------------------------*
//* STEP3 : Execution MAJASSU via IKJEFT01 + DB2                *
//*         PARM='PGMDB2' -> accesseur DB2 selectionne          *
//*         MAJASSU appelle PGMDB2 (DB2) pour ASSURES3          *
//*         MAJASSU appelle PGMVSAM (VSAM) pour FMVTSE          *
//*---------------------------------------------------------------*
//EXECMAJ  EXEC PGM=IKJEFT01,COND=(4,LT)
//STEPLIB  DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//*
//MVTS     DD DSN=API12.ESDS.MVTS,
//            DISP=SHR
//ETATANO  DD DSN=API12.GDGASU(+1),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80)
//*
//SYSTSIN  DD *
  DSN SYSTEM(DSN1)
  RUN PROGRAM(MAJASSU) PLAN(PGMDB2) PARM('PGMDB2')
  END
/*
