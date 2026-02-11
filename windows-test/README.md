# 🚀 Environnement de Test Windows - Guide de Démarrage Rapide

> 📖 **Documentation technique complète** : [`DOCUMENTATIONWINDOWS.md`](DOCUMENTATIONWINDOWS.md)
> 🔧 **Adaptations GNUCobol** : [`ADAPTATIONS.md`](ADAPTATIONS.md)

---

## 📋 Prérequis

- GNUCobol installé et dans le PATH
- Windows (scripts .bat)

## 🎯 Utilisation

### Première utilisation

```cmd
1. compile.bat    → Compile tous les programmes
2. init.bat       → Initialise les données (KSDS + ESDS)
3. run.bat        → Execute MAJASSU (mise à jour)
```

### Tests suivants

```cmd
reset.bat         → Remet à zéro les données
run.bat           → Execute MAJASSU
read.bat          → Affiche le contenu des fichiers .dat (avant/après)
```

---

## 📁 Structure

```
windows-test/
├── compile.bat      ← Compile LOADKSDS + MAJASSU
├── init.bat         ← Charge les 20 assurés + 11 mouvements
├── run.bat          ← Execute MAJASSU
├── reset.bat        ← Remet à zéro
├── read.bat         ← Affiche contenu .dat (avant/après)
│
├── COBOL/
│   ├── LOADKSDS.cbl ← Utilitaire : charge le KSDS initial
│   ├── READDATA.cbl ← Utilitaire : lit et affiche KSDS + ESDS
│   ├── MAJASSU.cbl  ← Programme principal (mise à jour)
│   ├── PGMVSAM.cbl  ← Accesseur VSAM (KSDS + ESDS)
│   └── PGMERR.cbl   ← Gestion messages erreur
│
├── COPY/            ← Copybooks
│
├── DATA/            ← Données SOURCE (pré-triées par matricule)
│   ├── ASSURES      ← 20 assurés (source, triés)
│   └── MVTS         ← 11 mouvements (source, triés)
│
└── WORK/            ← Fichiers de TRAVAIL (modifiés par programmes)
    ├── ASSURES.dat  ← KSDS données (créé par init)
    ├── ASSURES.idx  ← KSDS index (créé auto)
    ├── MVTS.dat     ← ESDS données (créé par init)
    └── ETATANO.txt  ← Anomalies (créé par run)
```

---

## 🔄 Workflow Détaillé

### 1. compile.bat

Compile 2 executables :
- **LOADKSDS.exe** : Lit DATA/ASSURES et crée WORK/ASSURES.dat (KSDS)
- **MAJASSU.exe** : Programme principal (intègre PGMVSAM + PGMERR)

### 2. init.bat

Initialise les données :
1. Copie DATA/MVTS → WORK/MVTS.dat (ESDS)
2. Lance LOADKSDS.exe qui :
   - Lit DATA/ASSURES (séquentiel)
   - Crée WORK/ASSURES.dat (KSDS)
   - GNUCobol crée WORK/ASSURES.idx (index)

**Résultat :** État initial prêt (20 assurés dans KSDS, 11 mouvements dans ESDS)

### 3. run.bat

Execute le traitement :
1. Lance MAJASSU.exe qui :
   - Ouvre WORK/ASSURES.dat (KSDS - lecture/écriture)
   - Ouvre WORK/MVTS.dat (ESDS - lecture)
   - Pour chaque mouvement :
     - **C** (création) : WRITE nouvel assuré
     - **M** (modification) : REWRITE assuré existant
     - **S** (suppression) : DELETE assuré
   - Génère WORK/ETATANO.txt (anomalies)
2. Affiche les statistiques
3. Affiche le fichier anomalies

### 4. reset.bat

Remet à zéro :
1. Supprime WORK/*.*
2. Relance init.bat

### 5. read.bat

Affiche le contenu des fichiers .dat :
1. Compile READDATA.cbl (utilitaire de lecture)
2. Affiche tous les enregistrements du KSDS (ASSURES)
3. Affiche tous les enregistrements de l'ESDS (MVTS)
4. Affiche le nombre total d'enregistrements

**Utilisation typique :**
```cmd
read.bat              → Voir l'état actuel
run.bat               → Exécuter MAJASSU
read.bat              → Voir l'état après traitement (avant/après)
```

---

## 📊 Résultats Attendus

### Statistiques (affichées dans run.bat)

```
================================================
TRAITEMENT DE MISE A JOUR DES ASSURES
================================================
STATISTIQUES
================================================
MOUVEMENTS LUS       : 000011
CREATIONS            : 000002
MODIFICATIONS        : 000001
SUPPRESSIONS         : 000002
ANOMALIES            : 000006
================================================
```

### Fichier ETATANO.txt

```
000346 ERREUR : 003 - 003 - MISE A JOUR SUR ENREGISTREMENT INEXISTANT
000347 ERREUR : 004 - 004 - SUPPRESSION SUR ENREGISTREMENT INEXISTANT
222203 ERREUR : 001 - 001 - CODE MOUVEMENT INVALIDE
300003 ERREUR : 003 - 003 - MISE A JOUR SUR ENREGISTREMENT INEXISTANT
300012 ERREUR : 001 - 001 - CODE MOUVEMENT INVALIDE
300312 ERREUR : 001 - 001 - CODE MOUVEMENT INVALIDE
```

---

## 🎓 Notes

- **KSDS** : Fichier indexé (ORGANIZATION IS INDEXED)
  - Accès direct par clé (matricule)
  - Accès séquentiel (READ NEXT)
  - Index créé automatiquement par GNUCobol

- **ESDS** : Fichier séquentiel (ORGANIZATION IS SEQUENTIAL)
  - Accès séquentiel uniquement
  - Pas d'index

- **DATA/** : Jamais modifié (source)
- **WORK/** : Modifié par les programmes (gitignore)

- **Fichiers DATA pré-triés** : Les fichiers `DATA/ASSURES` et `DATA/MVTS` sont pré-triés par matricule (ordre croissant). Cela simule l'étape de tri mainframe (JCL SORT) qui précède normalement le REPRO.

- **LINE SEQUENTIAL** : Les programmes utilisent `ORGANIZATION IS LINE SEQUENTIAL` pour lire les fichiers source avec retours à la ligne (`\n`), simulant ainsi la transition entre fichiers texte et fichiers VSAM.

---

**Dernière mise à jour :** Février 2025
