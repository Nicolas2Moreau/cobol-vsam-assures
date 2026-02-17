//API12R   JOB (ACCT#),'RUN MAJASSU',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,5)
//*---------------------------------------------------------------*
//* EXECUTION PROGRAMME MAJASSU UNIQUEMENT                       *
//* (Fichiers VSAM doivent déjà exister)                         *
//*---------------------------------------------------------------*
//STEP01   EXEC PGM=MAJASSU
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
