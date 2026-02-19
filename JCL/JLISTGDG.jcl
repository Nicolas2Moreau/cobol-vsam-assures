//API12L   JOB (ACCT#),'FIX GDG OWNER',MSGCLASS=H,CLASS=A
//*---------------------------------------------------------------*
//* FIX OWNER GDG : Assigne API12 comme proprietaire du GDG      *
//*---------------------------------------------------------------*
//FIXOWNER EXEC PGM=IDCAMS
//SYSPRINT DD SYSOUT=*
//SYSIN    DD *
  ALTER 'API12.GDGASU' OWNER(API12)
/*
