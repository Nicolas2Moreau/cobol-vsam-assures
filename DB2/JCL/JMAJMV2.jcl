//API12V   JOB (ACCT#),'MAJ MVTS V2',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,10)
//*---------------------------------------------------------------*
//* JMAJMV2 - Version dynamique avec accesseur VSAM             *
//* Identique a JMAJMVT mais utilise MAJASSU version dynamique  *
//* PARM='PGMVSAM' -> accesseur VSAM selectionne via PARM JCL   *
//* STEP1 : Tri MVTS -> fichier temporaire &&MVTST              *
//* STEP2 : Suppression et recreation ESDS FMVTSE               *
//* STEP3 : Execution MAJASSU V2 avec PARM='PGMVSAM'            *
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
//* STEP3 : Execution MAJASSU V2 (dynamique) PARM='PGMVSAM'     *
//*         Accesseur VSAM selectionne via PARM JCL             *
//*         Resultat identique a JMAJMVT (version statique)     *
//*---------------------------------------------------------------*
//EXECMAJ  EXEC PGM=MAJASSV2,PARM='PGMVSAM',COND=(4,LT)
//STEPLIB  DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//ASSURES  DD DSN=API12.KSDS.ASSURES,
//            DISP=OLD
//MVTS     DD DSN=API12.ESDS.MVTS,
//            DISP=SHR
//ETATANO  DD DSN=API12.GDGASU(+1),
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80)
//*
