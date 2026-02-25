# Système de Gestion d'Assurances — COBOL VSAM + DB2

> Projet de soutenance — Mise à jour de fichiers VSAM avec accesseurs dynamiques VSAM et DB2

[![COBOL](https://img.shields.io/badge/COBOL-Enterprise-blue)](https://www.ibm.com/products/cobol-compiler-zos)
[![VSAM](https://img.shields.io/badge/VSAM-z%2FOS-green)](https://www.ibm.com/docs/en/zos)
[![DB2](https://img.shields.io/badge/DB2-z%2FOS-orange)](https://www.ibm.com/docs/en/db2-for-zos)
[![License](https://img.shields.io/badge/License-Educational-lightgrey)](LICENSE)

---

> **Tester sous Windows avec GnuCOBOL ?** Rendez-vous sur la branche **[`gnucobol`](../../tree/gnucobol)**.

---

## Sommaire

- [Présentation](#présentation)
- [Versions du projet](#versions-du-projet)
- [Structure du repo](#structure-du-repo)
- [Mode d'emploi rapide](#mode-demploi-rapide)
  - [V1 — VSAM pur](#v1--vsam-pur)
  - [V2 — Accesseur dynamique DB2](#v2--accesseur-dynamique-db2)
  - [Tests](#tests)
- [Documentation](#documentation)
- [Auteur](#auteur)

---

## Présentation

Ce projet implémente un système de **mise à jour d'un fichier d'assurés** sur mainframe z/OS.
Un programme principal lit un fichier de mouvements (C/M/S), appelle un accesseur VSAM pour effectuer les opérations CRUD sur le fichier KSDS, et journalise les anomalies dans une GDG.
Le projet a évolué vers une **architecture V2** où l'accesseur devient dynamique : le même programme principal peut appeler indifféremment PGMVSAM (VSAM) ou PGMDB2 (DB2) via un simple paramètre JCL, sans recompilation.

---

## Versions du projet

| | V1 — VSAM pur | V2 — Accesseur dynamique |
|---|---|---|
| Programme principal | `MAJASSU` | `MAJASSV2` |
| Accesseur | `PGMVSAM` (statique) | `PGMVSAM` ou `PGMDB2` (dynamique via PARM) |
| Stockage | VSAM KSDS uniquement | VSAM KSDS **et** table DB2 `API12.ASSURES` |
| Loader DB2 | — | `KSTODB2` (chargement KSDS → DB2) |
| Interface | 120 octets partagés | identique |

> Architecture V2 détaillée : [DB2/RECAPV2.md](DB2/RECAPV2.md)

---

## Structure du repo

```
cobol-vsam-assures/
├── COBOL/                  # V1 — programmes VSAM pur
│   ├── MAJASSU.cbl         # Orchestrateur : lit FMVTSE, met à jour ASSURES3
│   ├── PGMVSAM.cbl         # Accesseur VSAM (fonctions 01–08)
│   └── PGMERR.cbl          # Gestion des libellés d'erreur
│
├── COPY/                   # Copybooks V1
│   ├── WASSURE.cpy         # WS structure assuré (80 octets)
│   ├── WFMVTSE.cpy         # WS structure mouvement (80 octets)
│   ├── CASSURES.cpy        # FD fichier KSDS assurés
│   ├── CFMVTS.cpy          # FD fichier ESDS mouvements
│   ├── DCLASSU.cpy         # DCLGEN table DB2 API12.ASSURES
│   └── MESSAGES.cpy        # Table 30 messages d'erreur
│
├── DATA/                   # Données de test V1
│   ├── ASSURES             # 20 assurés (RECFM=FB, LRECL=80)
│   └── MVTS                # 11 mouvements (RECFM=FB, LRECL=80)
│
├── DB2/                    # V2 — extension DB2
│   ├── COBOL/
│   │   ├── PGMVSAM.cbl     # Accesseur VSAM (copie V2, identique V1)
│   │   ├── PGMDB2.cbl      # Accesseur DB2 (isométrique PGMVSAM)
│   │   ├── MAJASSU.cbl     # MAJASSV2 (appel dynamique via PARM)
│   │   ├── KSTODB2.cbl     # Loader KSDS → table DB2
│   │   └── PGMERR.cbl
│   ├── COPY/               # Copybooks V2 (même contenu que COPY/)
│   ├── DATA/               # Données de test V2
│   ├── JCL/
│   │   ├── JCOMPIL.jcl     # Compilation V1 (PGMVSAM + MAJASSU + PGMERR)
│   │   ├── JCOMPDB2.jcl    # Compilation V2 (PGMDB2 + MAJASSV2 + KSTODB2 + BIND)
│   │   ├── JCREGDG.jcl     # Création GDG ETATANO (1 fois)
│   │   ├── JCREVSAM.jcl    # Init VSAM : KSDS + ESDS + chargement données
│   │   ├── JMAJMVT.jcl     # Run V1 : recharge ESDS + exécute MAJASSU
│   │   ├── JMAJMV2.jcl     # Run V2 : MAJASSV2 PARM='PGMVSAM' ou 'PGMDB2'
│   │   ├── JMAJDB2.jcl     # Run V2 complet avec accesseur DB2
│   │   ├── JKSDB2.jcl      # Chargement KSDS → DB2 via KSTODB2
│   │   └── JRERUN.jcl      # Rejouer sans recharger
│   ├── SQL/
│   │   └── CREATAB.sql     # CREATE TABLE API12.ASSURES
│   ├── RECAPV2.md          # Architecture V2 — référence technique
│   └── DB2.md
│
├── JCL/                    # JCL V1 (chaîne principale)
│   ├── JCOMPIL.jcl         # Compilation V1
│   ├── JCREGDG.jcl         # Création GDG ETATANO (prérequis JCREVSAM)
│   ├── JCREVSAM.jcl        # Init VSAM complète (utilise JCREGDG en prérequis)
│   ├── JMAJMVT.jcl         # Run opérationnel standard
│   └── JRERUN.jcl          # Rejouer le même lot
│
├── TEST/                   # Harness de test
│   ├── COBOL/
│   │   └── TSTASSU.cbl     # 12 tests intégration (PARM='PGMVSAM' ou 'PGMDB2')
│   ├── JCL/
│   │   ├── JTSTVSM.jcl     # Compile + lance TSTASSU contre PGMVSAM
│   │   └── JTSTDB2.jcl     # Compile + lance TSTASSU contre PGMDB2
│   └── TESTS.md            # Explication des tests
│
├── DOCS/                   # Documentation technique
│   └── PRESENTATION.md     # Référence complète : interface, codes, mappers, SQLCA
│
├── .github/workflows/      # CI GnuCOBOL (syntax check)
└── README.md
```

---

## Mode d'emploi rapide

> Prérequis : bibliothèques PDS créées (`&SYSUID..COB.SRC`, `.CPY`, `.LOAD`), volume DASD disponible.

### V1 — VSAM pur

```
1ère fois    →  JCOMPIL  →  JCREGDG  →  JCREVSAM  →  JMAJMVT
Nouveau lot  →  JMAJMVT
Rejouer      →  JRERUN
Reset total  →  JCREVSAM  →  JMAJMVT
```

| JCL | Rôle |
|-----|------|
| `JCOMPIL.jcl` | Compile MAJASSU + PGMVSAM + PGMERR |
| `JCREGDG.jcl` | Crée la base GDG `API12.GDGASU` (1 fois) |
| `JCREVSAM.jcl` | Définit + charge KSDS ASSURES3 et ESDS FMVTSE |
| `JMAJMVT.jcl` | Recharge ESDS + exécute MAJASSU, produit une génération ETATANO |
| `JRERUN.jcl` | Rejoue MAJASSU sans recharger l'ESDS |

### V2 — Accesseur dynamique DB2

```
1ère fois    →  JCOMPDB2  →  JCREGDG  →  JCREVSAM  →  JKSDB2  →  JMAJMV2
Nouveau lot  →  JMAJMV2
Accesseur    →  modifier PARM='PGMVSAM' ou PARM='PGMDB2' dans JMAJMV2
```

| JCL | Rôle |
|-----|------|
| `JCOMPDB2.jcl` | Précompile DB2 + compile PGMDB2, MAJASSV2, KSTODB2 + BIND |
| `JKSDB2.jcl` | Charge la table DB2 depuis le KSDS ASSURES3 (via KSTODB2) |
| `JMAJMV2.jcl` | Exécute MAJASSV2, accesseur choisi via PARM JCL |
| `JMAJDB2.jcl` | Variante JMAJMV2 préconfigurée pour PGMDB2 |

### Tests

```
VSAM  →  JTSTVSM.jcl  (compile TSTASSU + PARM='PGMVSAM')
DB2   →  JTSTDB2.jcl  (compile TSTASSU + PARM='PGMDB2', sous IKJEFT01)
```

12 tests couvrent OPEN / WRITE / duplicate / READ / REWRITE / DELETE / STARTBR / READNEXT / CLOSE.
Résultat attendu : **12 OK / 0 KO** — voir [TEST/TESTS.md](TEST/TESTS.md).

---

## Documentation

| Fichier | Contenu |
|---------|---------|
| [DOCS/PRESENTATION.md](DOCS/PRESENTATION.md) | Référence technique complète : interface 120 octets, codes fonction/retour, mappers, SQLCA, comportements limites |
| [DB2/RECAPV2.md](DB2/RECAPV2.md) | Architecture V2 : accesseur dynamique, PARM JCL, isométrie VSAM/DB2 |
| [TEST/TESTS.md](TEST/TESTS.md) | Harness TSTASSU : structure des tests, données de référence, sortie attendue |

---

## Auteur

**Nicolas MOREAU**
Formation COBOL Mainframe — AJC Formation
Formateur : Marc BENSOUSSAN
Février 2026
