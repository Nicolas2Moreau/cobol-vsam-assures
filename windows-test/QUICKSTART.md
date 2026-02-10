# 🚀 Guide de Démarrage Rapide

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
```

---

## 📁 Structure

```
windows-test/
├── compile.bat      ← Compile LOADKSDS + MAJASSU
├── init.bat         ← Charge les 20 assurés + 11 mouvements
├── run.bat          ← Execute MAJASSU
├── reset.bat        ← Remet à zéro
│
├── COBOL/
│   ├── LOADKSDS.cbl ← Utilitaire : charge le KSDS initial
│   ├── MAJASSU.cbl  ← Programme principal (mise à jour)
│   ├── PGMVSAM.cbl  ← Accesseur VSAM (KSDS + ESDS)
│   └── PGMERR.cbl   ← Gestion messages erreur
│
├── COPY/            ← Copybooks
│
├── DATA/            ← Données SOURCE (jamais modifiées)
│   ├── ASSURES      ← 20 assurés (source)
│   └── MVTS         ← 11 mouvements (source)
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
200006 ERREUR : 004 - SUPPRESSION SUR ENREGISTREMENT INEXISTANT
000346 ERREUR : 003 - MISE A JOUR SUR ENREGISTREMENT INEXISTANT
000347 ERREUR : 004 - SUPPRESSION SUR ENREGISTREMENT INEXISTANT
300003 ERREUR : 003 - MISE A JOUR SUR ENREGISTREMENT INEXISTANT
222203 ERREUR : 001 - CODE MOUVEMENT INVALIDE
300012 ERREUR : 001 - CODE MOUVEMENT INVALIDE
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

---

**Dernière mise à jour :** Février 2025
