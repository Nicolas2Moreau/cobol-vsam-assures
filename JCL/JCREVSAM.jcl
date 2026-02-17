//API12V   JOB (ACCT#),'CREATION VSAM',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,10)
//*---------------------------------------------------------------*
//* CREATION ET CHARGEMENT DES FICHIERS VSAM                     *
//* STEP1 : Tri ASSURES                                          *
//* STEP2 : Création KSDS ASSURES3                               *
//* STEP3 : Tri MVTS                                             *
//* STEP4 : Création ESDS FMVTSE                                 *
//*---------------------------------------------------------------*
//*
//*---------------------------------------------------------------*
//* STEP1 : Tri fichier ASSURES sur Matricule + Adresse          *
//*---------------------------------------------------------------*
//DELTEMP  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE API12.SEQ.ASSUREST
  IF LASTCC LE 8 THEN SET MAXCC = 0
/*
//TRIASS   EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=API12.SEQ.ASSURES,DISP=SHR
//SORTOUT  DD DSN=API12.SEQ.ASSUREST,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(5,2)),
//            DCB=(RECFM=FB,LRECL=80)
//SYSIN    DD *
  SORT FIELDS=(1,6,ZD,A,27,18,CH,D)
/*
//*
//*---------------------------------------------------------------*
//* STEP2 : Création KSDS ASSURES3                               *
//*---------------------------------------------------------------*
//CKSDS    EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
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
  REPRO INDATASET(API12.SEQ.ASSUREST)                    -
        OUTDATASET(API12.KSDS.ASSURES)
/*
//*
//*---------------------------------------------------------------*
//* STEP3 : Tri fichier MVTS sur Matricule + Code mouvement      *
//*---------------------------------------------------------------*
//DELTMVT  EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  DELETE API12.SEQ.MVTST
  IF LASTCC LE 8 THEN SET MAXCC = 0
/*
//TRIMVT   EXEC PGM=SORT
//SYSOUT   DD SYSOUT=*
//SORTIN   DD DSN=API12.SEQ.MVTS,DISP=SHR
//SORTOUT  DD DSN=API12.SEQ.MVTST,
//            DISP=(NEW,CATLG,DELETE),
//            SPACE=(CYL,(5,2)),
//            DCB=(RECFM=FB,LRECL=80)
//SYSIN    DD *
  SORT FIELDS=(1,6,ZD,A,62,1,CH,A)
/*
//*
//*---------------------------------------------------------------*
//* STEP4 : Création ESDS FMVTSE                                 *
//*---------------------------------------------------------------*
//CESDS    EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//MVTST    DD DSN=API12.SEQ.MVTST,DISP=SHR
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
