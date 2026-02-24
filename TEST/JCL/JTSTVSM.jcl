//API12TV  JOB (ACCT#),'TEST PGMVSAM',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,10)
//PROCLIB  JCLLIB ORDER=SDJ.FORM.PROCLIB
//*
//         SET SYSUID=API12
//*---------------------------------------------------------------*
//* JTSTVSM - Compilation + Test TSTASSU avec accesseur PGMVSAM  *
//* STEP1 : Compilation COBOL standard TSTASSU                   *
//* STEP2 : Execution TSTASSU PARM='PGMVSAM'                     *
//*         -> 12 tests sur PGMVSAM (KSDS API12.KSDS.ASSURES)   *
//*         -> DD ASSURES et MVTS requis (lecture/ecriture VSAM) *
//*---------------------------------------------------------------*
//*
//*---------------------------------------------------------------*
//* STEP1 : Compilation TSTASSU                                  *
//*---------------------------------------------------------------*
//         SET NOMPGM=TSTASSU
//COMPTST  EXEC COMPCOB
//STEPCOB.SYSLIB   DD DSN=&SYSUID..COB.CPY,DISP=SHR
//STEPCOB.SYSIN    DD DSN=&SYSUID..COB.SRC(&NOMPGM),DISP=SHR
//STEPLNK.SYSLMOD  DD DSN=&SYSUID..COB.LOAD(&NOMPGM),DISP=SHR
//*
//*---------------------------------------------------------------*
//* STEP2 : Execution TSTASSU accesseur VSAM                     *
//*---------------------------------------------------------------*
//EXECTST  EXEC PGM=TSTASSU,PARM='PGMVSAM',COND=(4,LT)
//STEPLIB  DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//*
//ASSURES  DD DSN=API12.KSDS.ASSURES,DISP=OLD
//MVTS     DD DSN=API12.ESDS.MVTS,DISP=SHR
//*
