//API12TD  JOB (ACCT#),'TEST PGMDB2',
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
//* JTSTDB2 - Compilation + Test TSTASSU avec accesseur PGMDB2   *
//* STEP1 : Compilation COBOL standard TSTASSU                   *
//* STEP2 : Execution TSTASSU via IKJEFT01 PLAN(PGMDB2)          *
//*         -> 12 tests sur PGMDB2 (table DB2 API12.ASSURES)     *
//*         -> Pas de DD ASSURES : table geree par DB2           *
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
//* STEP2 : Execution TSTASSU accesseur DB2                      *
//*         PLAN(PGMDB2) : TSTASSU appelle PGMDB2 via CALL dyn.  *
//*---------------------------------------------------------------*
//EXECTDB  EXEC PGM=IKJEFT01,COND=(4,LT)
//STEPLIB  DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*
//SYSPRINT DD SYSOUT=*
//SYSOUT   DD SYSOUT=*
//SYSTSPRT DD SYSOUT=*
//*
//SYSTSIN  DD *
  DSN SYSTEM(DSN1)
  RUN PROGRAM(TSTASSU) PLAN(PGMDB2) PARM('PGMDB2')
  END
/*
//*
