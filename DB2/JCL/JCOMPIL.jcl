//API12C   JOB (ACCT#),'COMPILE PROJET',
//             MSGCLASS=H,
//             CLASS=A,
//             REGION=4M,
//             MSGLEVEL=(1,1),
//             NOTIFY=&SYSUID,
//             TIME=(0,10)
//*---------------------------------------------------------------*
//* COMPILATION DES 3 PROGRAMMES DU PROJET                       *
//* - PGMVSAM : Accesseur VSAM                                   *
//* - PGMERR  : Sous-programme erreur                            *
//* - MAJASSU : Programme principal                              *
//*---------------------------------------------------------------*
//         JCLLIB ORDER=(SDJ.FORM.PROCLIB)
//*
//*---------------------------------------------------------------*
//* STEP1 : Compilation PGMVSAM (Accesseur VSAM)                 *
//*---------------------------------------------------------------*
//COMPVSAM EXEC COMPCOB,NOMPGM=PGMVSAM
//STEPCOB.SYSLIB DD DSN=CEE.SCEESAMP,DISP=SHR
//               DD DSN=&SYSUID..COB.CPY,DISP=SHR
//STEPLNK.SYSLIB DD DSN=CEE.SCEELKED,DISP=SHR
//               DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*
//*---------------------------------------------------------------*
//* STEP2 : Compilation PGMERR (Sous-programme erreur)           *
//*---------------------------------------------------------------*
//COMPERR  EXEC COMPCOB,NOMPGM=PGMERR
//STEPCOB.SYSLIB DD DSN=CEE.SCEESAMP,DISP=SHR
//               DD DSN=&SYSUID..COB.CPY,DISP=SHR
//STEPLNK.SYSLIB DD DSN=CEE.SCEELKED,DISP=SHR
//               DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*
//*---------------------------------------------------------------*
//* STEP3 : Compilation MAJASSU (Programme principal)            *
//*---------------------------------------------------------------*
//COMPMAJ  EXEC COMPCOB,NOMPGM=MAJASSU
//STEPCOB.SYSLIB DD DSN=CEE.SCEESAMP,DISP=SHR
//               DD DSN=&SYSUID..COB.CPY,DISP=SHR
//STEPLNK.SYSLIB DD DSN=CEE.SCEELKED,DISP=SHR
//               DD DSN=&SYSUID..COB.LOAD,DISP=SHR
//*
