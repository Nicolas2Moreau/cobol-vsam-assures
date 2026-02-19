//API12D   JOB (ACCT#),'COMPILE DB2',
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
//* JCOMPDB2 - Compilation PGMDB2 (Accesseur DB2)               *
//* STEP1 : Precompilation DB2 + Compilation COBOL + Link-edit   *
//* STEP2 : BIND du DBRM dans le plan DB2                        *
//*---------------------------------------------------------------*
//*
//*---------------------------------------------------------------*
//* STEP1 : Precompilation + Compilation + Link-edit PGMDB2      *
//*---------------------------------------------------------------*
//         SET NOMPGM=PGMDB2
//COMPDB2  EXEC COMPDB2
//STEPDB2.SYSLIB   DD DSN=&SYSUID..COB.CPY,DISP=SHR
//STEPDB2.SYSIN    DD DSN=&SYSUID..COB.SRC(&NOMPGM),DISP=SHR
//STEPDB2.DBRMLIB  DD DSN=&SYSUID..COB.DBRM(&NOMPGM),DISP=SHR
//STEPCOB.SYSLIB   DD DSN=&SYSUID..COB.CPY,DISP=SHR
//STEPLNK.SYSLMOD  DD DSN=&SYSUID..COB.LOAD(&NOMPGM),DISP=SHR
//*
//*---------------------------------------------------------------*
//* STEP2 : BIND - Liaison DBRM -> Plan DB2                      *
//*---------------------------------------------------------------*
//BIND     EXEC PGM=IKJEFT01,COND=(4,LT)
//DBRMLIB  DD  DSN=&SYSUID..COB.DBRM,DISP=SHR
//SYSTSPRT DD  SYSOUT=*,OUTLIM=25000
//SYSTSIN  DD  *
  DSN SYSTEM (DSN1)
  BIND PLAN (PGMDB2) -
       QUALIFIER (API12) -
       ACTION    (REPLACE) -
       MEMBER    (PGMDB2) -
       VALIDATE  (BIND) -
       ISOLATION (CS) -
       ACQUIRE   (USE) -
       RELEASE   (COMMIT) -
       EXPLAIN   (NO)
  END
/*
