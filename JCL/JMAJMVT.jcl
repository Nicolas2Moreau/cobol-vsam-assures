//API12M   JOB (ACCT#),'RELOAD MVTS AND RUN',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,10)
//*---------------------------------------------------------------*
//* RUN OPERATIONNEL : RECHARGEMENT ESDS MVTS + EXECUTION MAJASSU*
//* STEP1 : Tri MVTS → fichier temporaire &&MVTST               *
//* STEP2 : Suppression et recreation ESDS FMVTSE               *
//* STEP3 : Execution MAJASSU                                    *
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
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80)
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
//* STEP3 : Execution MAJASSU                                    *
//*---------------------------------------------------------------*
//EXECMAJ  EXEC PGM=MAJASSU
//STEPLIB  DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//ASSURES  DD DSN=API12.KSDS.ASSURES,
//            DISP=OLD
//MVTS     DD DSN=API12.ESDS.MVTS,
//            DISP=SHR
//ETATANO  DD DSN=API12.GDG.ETATANO(+1),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80)
//*
