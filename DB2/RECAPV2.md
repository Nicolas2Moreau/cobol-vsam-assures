# RECAPV2 — Architecture MAJASSU Version Dynamique (V2)

## Principe

La V2 introduit un **accesseur dynamique** : MAJASSU ne hardcode plus l'appel à PGMVSAM.
Il lit un `PARM` JCL pour choisir à l'exécution entre l'accesseur VSAM ou DB2.
L'interface de communication reste identique (zone 120 octets, PDF p.16-17).

```
PARM='PGMVSAM'  →  MAJASSU  →  PGMVSAM  →  KSDS API12.KSDS.ASSURES
PARM='PGMDB2'   →  MAJASSU  →  PGMDB2   →  TABLE DB2 API12.ASSURES
                              (FMVTSE toujours via PGMVSAM/VSAM)
```

---

## Fichiers nouveaux

### SQL
| Fichier | Rôle |
|---------|------|
| `SQL/CREATAB.sql` | DDL : DROP + CREATE TABLE ASSURES + CREATE UNIQUE INDEX |

### COPY
| Fichier | Rôle |
|---------|------|
| `COPY/DCLASSU.cpy` | DCLGEN généré sur le mainframe depuis la table API12.ASSURES |

### COBOL
| Fichier | Rôle |
|---------|------|
| `COBOL/MAJASSU.cbl` | MAJASSU V2 — lit PARM JCL, CALL dynamique sur l'accesseur |
| `COBOL/PGMDB2.cbl` | Accesseur DB2 — fonctions 01 à 09, interface identique à PGMVSAM |
| `COBOL/KSTODB2.cbl` | Chargeur KSDS → DB2 — vide la table (f.09) puis INSERT en boucle (f.06) |

### JCL
| Fichier | Rôle |
|---------|------|
| `JCL/JCREGDG.jcl` | Création base GDG — **une seule fois** (DELETE FORCE + DEFINE + ALTER OWNER) |
| `JCL/JCREVSAM.jcl` | Init VSAM : charge KSDS et ESDS depuis SEQ (prérequis : GDG existe via JCREGDG) |
| `JCL/JCOMPDB2.jcl` | Compile PGMDB2 (COMPDB2) + compile KSTODB2 (COMPCOB) + BIND |
| `JCL/JKSDB2.jcl` | Sync KSDS → table DB2 (REPRO + KSTODB2) |
| `JCL/JMAJMV2.jcl` | Run V2 avec accesseur VSAM — `PARM='PGMVSAM'` |
| `JCL/JMAJDB2.jcl` | Run V2 avec accesseur DB2 — `PARM='PGMDB2'` |

---

## Ordre d'utilisation

### 1. Initialisation unique (à faire une seule fois)

```
[1] JCREGDG     → Crée la base GDG API12.GDGASU (une seule fois !)
[2] JCREVSAM    → Crée/charge KSDS et ESDS depuis les SEQ de référence
[3] SPUFI       → Exécuter CREATAB.sql  (CREATE TABLE + INDEX)
[4] DCLGEN      → Générer DCLASSU dans API12.COB.CPY
[5] JCOMPDB2    → Compiler PGMDB2 + MAJASSV2 + KSTODB2 + BIND
[6] JKSDB2      → Charger table DB2 depuis état actuel du KSDS
```

### 2. Exécution courante (rejouer avec un nouveau fichier MVTS)

```
Option A — Accesseur VSAM (V2, identique au résultat V1) :
    JMAJMV2   (PARM='PGMVSAM')

Option B — Accesseur DB2 :
    JMAJDB2   (PARM='PGMDB2')
```

> **Nota :** si le KSDS et la table DB2 contiennent les mêmes données,
> JMAJMV2 et JMAJDB2 produisent des statistiques identiques.

### 3. Resynchronisation DB2 ← KSDS (si besoin)

```
JKSDB2   → Vide la table DB2 + recharge depuis le KSDS courant
```

---

## Zones variables / paramètres

### MAJASSU V2 — PARM JCL
| Valeur PARM | Effet | Défaut si absent |
|-------------|-------|-----------------|
| `PGMVSAM` | Accesseur VSAM (KSDS) | ✓ oui |
| `PGMDB2` | Accesseur DB2 (table) | — |

### PGMDB2 — Codes fonction
| Code | Opération DB2 |
|------|--------------|
| 01 | OPEN (no-op en DB2) |
| 02 | CLOSE CURSOR |
| 03 | SELECT par clé (READ) |
| 04 | UPDATE par clé (REWRITE) |
| 05 | DELETE par clé |
| 06 | INSERT (WRITE) |
| 07 | OPEN CURSOR (STARTBR) |
| 08 | FETCH (READNEXT) |
| **09** | **DELETE FROM ASSURES sans WHERE (TRUNCATE)** |

### PGMDB2 — Codes retour
| Code | Signification |
|------|--------------|
| 00 | OK |
| 01 | NOT FOUND (SQLCODE +100) |
| 02 | DUPLICATE (SQLCODE -803 / -811) |
| 03 | I/O ERROR (SQLCODE -501) |
| 04 | FIN CURSEUR (SQLCODE +100 sur FETCH) |
| 99 | ERREUR INATTENDUE |

### BIND — Paramètres clés
| Paramètre | Valeur |
|-----------|--------|
| PLAN | PGMDB2 |
| QUALIFIER | API12 |
| SYSTEM | DSN1 |

> Le `QUALIFIER(API12)` résout les noms de table non qualifiés :
> `ASSURES` → `API12.ASSURES`

---

## Warnings connus à la compilation (CC=4 normal)

| Message | Step | Explication |
|---------|------|-------------|
| `DSNH204I W` — UNDECLARED TABLE ASSURES | COMPDB2/STEPDB2 | Le précompilateur ne rapproche pas `API12.ASSURES` (nom qualifié dans DCLASSU) avec `ASSURES` (non qualifié dans le SQL). Les host variables sont bien définies, la compilation réussit. Cosmétique. |
| `DSNH088I W` — WILL DELETE AN ENTIRE TABLE | COMPDB2/STEPDB2 | Warning automatique sur `DELETE FROM ASSURES` sans WHERE (fonction 09 TRUNCATE). Attendu et volontaire. |
| `DSNH050I I` — WARNINGS SUPPRESSED DUE TO LACK OF TABLE DECLARATIONS | COMPDB2/STEPDB2 | Conséquence du DSNH204I ci-dessus. Informatif uniquement. |
| `IEF686I` — DDNAME NOT RESOLVED | COMPMAJ / COMPKST | Warning de chaînage DDNAME dans la procédure cataloguée COMPCOB. Lié à la procédure, pas à notre code. |

> CC=4 sur JCOMPDB2 est **normal et attendu**. Tous les programmes sont compilés et linkés correctement.

---

## Comparatif V1 / V2

| | V1 (racine) | V2 (DB2/) |
|---|---|---|
| MAJASSU | CALL statique `'PGMVSAM'` | CALL dynamique via PARM |
| Accesseur ASSURES | PGMVSAM uniquement | PGMVSAM **ou** PGMDB2 |
| Accesseur FMVTSE | PGMVSAM | PGMVSAM (toujours) |
| JCL run | `JMAJMVT` | `JMAJMV2` / `JMAJDB2` |
| Stockage ASSURES | KSDS VSAM | KSDS VSAM ou table DB2 |
