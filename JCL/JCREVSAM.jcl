//API12V   JOB (ACCT#),'CREATION VSAM',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,10)
//*---------------------------------------------------------------*
//* INITIALISATION COMPLETE : CREATION ET CHARGEMENT VSAM        *
//* STEP1 : Definition base GDG pour ETATANO                     *
//* STEP2 : Tri ASSURES → fichier temporaire &&ASSUREST          *
//* STEP3 : Creation KSDS ASSURES depuis &&ASSUREST              *
//* STEP4 : Tri MVTS → fichier temporaire &&MVTST                *
//* STEP5 : Creation ESDS FMVTSE depuis &&MVTST                  *
//*---------------------------------------------------------------*
//*
//*---------------------------------------------------------------*
//* STEP1 : Definition base GDG pour ETATANO (reset si existant) *
//*---------------------------------------------------------------*
//DEFGDG   EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE (API12.GDG.ETATANO) GDG FORCE
  IF LASTCC LE 8 THEN SET MAXCC = 0
  DEFINE GDG(NAME(API12.GDG.ETATANO)  -
             LIMIT(10)                 -
             NOEMPTY                   -
             SCRATCH)
/*
//*
//*---------------------------------------------------------------*
//* STEP2 : Tri fichier ASSURES sur Matricule + Adresse          *
//*---------------------------------------------------------------*
//TRIASS   EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=API12.SEQ.ASSURES,DISP=SHR
//SORTOUT  DD DSN=&&ASSUREST,
//            DISP=(NEW,PASS,DELETE),
//            SPACE=(TRK,(1,1)),
//            DCB=(RECFM=FB,LRECL=80)
//SYSIN    DD *
  SORT FIELDS=(1,6,ZD,A,27,18,CH,D)
/*
//*
//*---------------------------------------------------------------*
//* STEP3 : Creation KSDS ASSURES depuis &&ASSUREST              *
//*---------------------------------------------------------------*
//CKSDS    EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//ASSUREST DD DSN=&&ASSUREST,DISP=(OLD,DELETE,DELETE)
//SYSIN    DD *
  DELETE (API12.KSDS.ASSURES) CLUSTER
  IF LASTCC LE 8 THEN SET MAXCC = 0
  DEFINE CLUSTER (NAME(API12.KSDS.ASSURES)               -
                  TRACKS(1 1)                            -
                  VOLUME(AJCWK1)                         -
                  INDEXED                                -
                  KEY(6 0)                               -
                  RECORDSIZE(80 80)                      -
                  FREESPACE(40 40))                      -
         DATA  (NAME(API12.KSDS.ASSURES.DATA))           -
         INDEX (NAME(API12.KSDS.ASSURES.INDEX))
  REPRO INFILE(ASSUREST)                                 -
        OUTDATASET(API12.KSDS.ASSURES)
/*
//*
//*---------------------------------------------------------------*
//* STEP4 : Tri fichier MVTS sur Matricule + Code mouvement      *
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
//* STEP5 : Creation ESDS FMVTSE depuis &&MVTST                  *
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
