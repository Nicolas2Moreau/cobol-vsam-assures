# PGMDB2 - Accesseur DB2 pour la table ASSURES

## Contexte

Ce dossier contient le sous-programme accesseur DB2 (`PGMDB2`) qui remplace ou complète
l'accesseur VSAM (`PGMVSAM`). Les deux accesseurs exposent **la même interface** définie
dans le cahier des charges (PDF pages 16-17).

Environnement cible : **Enterprise COBOL 3.1.1 / DB2 Version 8 / z/OS**

---

## Interface commune (identique à PGMVSAM)

### Zone de communication - 120 octets obligatoires

```cobol
01  LS-COM.
    05 LS-NOM-FICHIER       PIC X(8).   -- Nom logique du fichier/table
    05 LS-CODE-FONCTION     PIC 99.     -- Code fonction (01 à 08)
    05 LS-CODE-RETOUR       PIC 99.     -- Code retour renvoyé au programme appelant
    05 LS-ENREG             PIC X(80).  -- Enregistrement (entrée ou sortie)
    05 LS-FILLER            PIC X(28).  -- Réservé - compléter à 120 octets
```

**IMPERATIF** : La zone fait exactement 8+2+2+80+28 = **120 octets**.
Ne jamais modifier cette structure sans mettre à jour PGMVSAM en même temps.

### Table des codes fonction

| Code | VSAM        | DB2              | Description                  |
|------|-------------|------------------|------------------------------|
| 01   | OPEN        | (init curseur)   | Ouverture / initialisation   |
| 02   | CLOSE       | (close curseur)  | Fermeture                    |
| 03   | READ        | SELECT           | Lecture par clé              |
| 04   | REWRITE     | UPDATE           | Mise à jour                  |
| 05   | DELETE      | DELETE           | Suppression                  |
| 06   | WRITE       | INSERT           | Création                     |
| 07   | START       | OPEN CURSOR      | Positionnement début lecture séq. |
| 08   | READ NEXT   | FETCH            | Lecture séquentielle suivante |

### Table des codes retour (PDF page 17)

| Code | VSAM (File Status) | DB2 (SQLCODE)   | Signification               |
|------|--------------------|-----------------|-----------------------------|
| 00   | 00                 | 0               | OK                          |
| 01   | 23                 | +100            | Enregistrement non trouvé   |
| 02   | 22                 | -803 / -811     | Enregistrement déjà existant|
| 03   | 9x                 | -501 / autres   | Erreur I/O / fichier fermé  |
| 04   | 10                 | +100 (fin fetch)| Fin de fichier / fin curseur|
| 99   | autres             | autres négatifs | Erreur inattendue           |

---

## Structure de la table DB2

La table DB2 cible est `API12.ASSURES`. Elle correspond au fichier VSAM `API12.KSDS.ASSURES`
et au copybook `COPY/WASSURE.cpy`.

### Correspondance types COBOL/DB2

| Champ COBOL (DISPLAY)  | Colonne DB2 | Type DB2       | Type COBOL DCLGEN         |
|------------------------|-------------|----------------|---------------------------|
| A-MAT    PIC 9(6)      | MATASS      | CHAR(6)        | PIC X(6)                  |
| A-NOM-PRE PIC X(20)    | NOMPRE      | CHAR(20)       | PIC X(20)                 |
| A-RUE    PIC X(18)     | RUESS       | CHAR(18)       | PIC X(18)                 |
| A-CP     PIC 9(5)      | CPASS       | CHAR(5)        | PIC X(5)                  |
| A-VILLE  PIC X(12)     | VILLSS      | CHAR(12)       | PIC X(12)                 |
| A-CODE   PIC X(1)      | CODVEH      | CHAR(1)        | PIC X(1)                  |
| A-PRIME  PIC 9(4)V99   | PRIMSS      | DECIMAL(6,2)   | PIC S9(4)V9(2) COMP-3     |
| A-BM     PIC X(1)      | BONMAL      | CHAR(1)        | PIC X(1)                  |
| A-TAUX   PIC 99        | TAUXSS      | SMALLINT       | PIC S9(4) COMP            |

**IMPERATIF** : Les champs numériques DISPLAY du copybook WASSURE doivent être convertis
via MOVE vers les types COMP-3/COMP de la DCLGEN avant INSERT/UPDATE.
La conversion inverse (COMP-3 → DISPLAY) est nécessaire après SELECT/FETCH.

---

## Architecture PGMDB2

### Fichiers à créer

```
DB2/
├── COBOL/
│   └── PGMDB2.cbl       -- Sous-programme accesseur DB2
├── COPY/
│   └── ASSURE.cpy       -- DCLGEN de la table API12.ASSURES
├── SQL/
│   └── CREATAB.sql      -- DDL création table API12.ASSURES
├── JCL/
│   └── JCOMPDB2.jcl     -- JCL compilation avec précompilateur DB2
└── DB2.md               -- Ce fichier
```

### Structure PGMDB2.cbl

```cobol
IDENTIFICATION DIVISION.
PROGRAM-ID. PGMDB2.

ENVIRONMENT DIVISION.

DATA DIVISION.
WORKING-STORAGE SECTION.
    EXEC SQL INCLUDE SQLCA END-EXEC.       -- Zone communication SQL
    EXEC SQL INCLUDE ASSURE END-EXEC.      -- DCLGEN table ASSURES
    EXEC SQL DECLARE CSR-ASSURES CURSOR    -- Curseur lecture séquentielle
        FOR SELECT ... FROM API12.ASSURES
        ORDER BY MATASS
    END-EXEC.
    01 WS-SQLCODE    PIC S9(9) COMP.       -- Copie locale SQLCODE
    ... (codes retour identiques PGMVSAM)

LINKAGE SECTION.
    01 LS-COM.                             -- Zone 120 octets identique PGMVSAM
        05 LS-NOM-FICHIER   PIC X(8).
        05 LS-CODE-FONCTION PIC 99.
        05 LS-CODE-RETOUR   PIC 99.
        05 LS-ENREG         PIC X(80).
        05 LS-FILLER        PIC X(28).

PROCEDURE DIVISION USING LS-COM.
    MOVE SQLCODE TO WS-SQLCODE
    EVALUATE LS-CODE-FONCTION
        WHEN 01  PERFORM FUNC-OPEN
        WHEN 02  PERFORM FUNC-CLOSE
        WHEN 03  PERFORM FUNC-READ
        WHEN 04  PERFORM FUNC-REWRITE
        WHEN 05  PERFORM FUNC-DELETE
        WHEN 06  PERFORM FUNC-WRITE
        WHEN 07  PERFORM FUNC-START
        WHEN 08  PERFORM FUNC-READNEXT
        WHEN OTHER MOVE WS-RETOUR-ERROR TO LS-CODE-RETOUR
    END-EVALUATE.
    GOBACK.
```

---

## Impératifs DB2 Version 8 / Enterprise COBOL 3.1.1

### Précompilation obligatoire
Le source COBOL contenant des `EXEC SQL` doit passer par le **précompilateur DB2**
avant la compilation COBOL standard. Le JCL de compilation (JCOMPDB2) doit inclure :
1. STEP DSNHPC  → Précompilateur DB2 (génère le .cbl sans EXEC SQL)
2. STEP COBOL   → Compilation COBOL standard
3. STEP LKED    → Link-edit avec DSNELI (interface DB2 runtime)

### SQLCA obligatoire
```cobol
EXEC SQL INCLUDE SQLCA END-EXEC.
```
Donne accès à `SQLCODE`, `SQLERRM`, `SQLSTATE` après chaque ordre SQL.

### Codes SQLCODE à gérer

| SQLCODE | Signification              | Code retour à renvoyer |
|---------|----------------------------|------------------------|
| 0       | Succès                     | 00                     |
| +100    | Pas de ligne trouvée / EOF | 01 (READ) ou 04 (FETCH)|
| -803    | Doublon clé unique         | 02                     |
| -811    | SELECT retourne > 1 ligne  | 02                     |
| -501    | Curseur non ouvert         | 03                     |
| autres négatifs | Erreur SQL          | 99                     |

### Pattern curseur (lecture séquentielle)

```cobol
* FUNC-START (fonction 07) : ouvre le curseur
FUNC-START.
    EXEC SQL OPEN CSR-ASSURES END-EXEC
    PERFORM MAPPER-SQLCODE.

* FUNC-READNEXT (fonction 08) : fetch suivant
FUNC-READNEXT.
    EXEC SQL FETCH CSR-ASSURES INTO :DCL-MATASS, ... END-EXEC
    PERFORM MAPPER-SQLCODE
    IF LS-CODE-RETOUR = WS-RETOUR-OK
        PERFORM MOVE-DCLTOWS.   -- Convertir DCLGEN -> WS -> LS-ENREG

* FUNC-CLOSE (fonction 02) : ferme le curseur
FUNC-CLOSE.
    EXEC SQL CLOSE CSR-ASSURES END-EXEC
    PERFORM MAPPER-SQLCODE.
```

### Conversion des types avant INSERT/UPDATE
```cobol
* Avant INSERT ou UPDATE, convertir depuis LS-ENREG (DISPLAY)
* vers les variables DCLGEN (COMP-3 / COMP)
MOVE WS-PRIME  TO DCL-PRIME    -- PIC 9(4)V99 -> PIC S9(4)V9(2) COMP-3
MOVE WS-BM     TO DCL-BM       -- PIC 99      -> PIC S9(4) COMP
MOVE WS-TAUX   TO DCL-TAUX     -- PIC 99      -> PIC S9(4) COMP
```

### COMMIT / ROLLBACK
- **COMMIT** après chaque opération réussie (INSERT, UPDATE, DELETE)
- **PAS de COMMIT** dans le sous-programme si le programme appelant gère les transactions
- À décider avec le programme principal MAJASSU : qui gère le COMMIT ?

---

## Différences VSAM vs DB2 à gérer

| Aspect         | PGMVSAM                    | PGMDB2                          |
|----------------|----------------------------|---------------------------------|
| Lecture seq.   | READ NEXT + AT END         | FETCH + SQLCODE +100            |
| Clé dupliquée  | File Status 22             | SQLCODE -803                    |
| Non trouvé     | File Status 23             | SQLCODE +100                    |
| Ouverture      | OPEN INPUT/OUTPUT          | (pas d'open physique)           |
| Fermeture      | CLOSE                      | CLOSE CURSOR                    |
| Erreur I/O     | File Status 9x             | SQLCODE négatif                 |

---

## TODO - Ordre de développement

1. [ ] Créer `SQL/CREATAB.sql` - DDL table API12.ASSURES
2. [ ] Exécuter le DDL sur le mainframe (SPUFI ou DSNTEP2)
3. [ ] Lancer DCLGEN sur mainframe : génère automatiquement `COPY/ASSURE.cpy`
         → DSNHPCK ou via ISPF DB2I Option 2 (DCLGEN)
         → Récupérer le fichier généré et le placer dans DB2/COPY/
4. [ ] Coder `COBOL/PGMDB2.cbl` - Accesseur DB2
5. [ ] Créer `JCL/JCOMPDB2.jcl` - JCL précompilation DB2 + compilation COBOL
6. [ ] Adapter `COBOL/MAJASSU.cbl` - Appel PGMDB2 au lieu de PGMVSAM
7. [ ] Tests de validation
