# 🏥 Système de Gestion d'Assurances VSAM en COBOL

> Projet de soutenance - Mise à jour de fichiers VSAM avec traitement de mouvements (Création, Modification, Suppression)

[![COBOL](https://img.shields.io/badge/COBOL-Enterprise-blue)](https://www.ibm.com/products/cobol-compiler-zos)
[![VSAM](https://img.shields.io/badge/VSAM-z%2FOS-green)](https://www.ibm.com/docs/en/zos)
[![License](https://img.shields.io/badge/License-Educational-orange)](LICENSE)

---

## 📋 Sommaire

- [Présentation du Projet](#-présentation-du-projet)
- [Architecture](#-architecture)
  - [Programmes Principaux](#programmes-principaux)
  - [Sous-programmes](#sous-programmes)
  - [Copybooks](#copybooks)
- [Installation](#-installation)
  - [Prérequis](#prérequis)
  - [Étapes d'Installation](#étapes-dinstallation)
- [Utilisation](#-utilisation)
- [Structure du Projet](#-structure-du-projet)
- [Sources et Références](#-sources-et-références)

---

## 🎯 Présentation du Projet

Ce projet implémente un **système de mise à jour d'un fichier d'assurés** sur mainframe z/OS en utilisant des fichiers VSAM (Virtual Storage Access Method). Il s'agit d'un projet de soutenance démontrant la maîtrise de :

- La programmation COBOL Enterprise
- La gestion de fichiers VSAM (KSDS indexé + ESDS séquentiel)
- L'architecture modulaire avec sous-programmes réutilisables
- Le traitement de mouvements batch (C/M/S)
- La gestion robuste des erreurs avec fichier d'anomalies

### Objectif Métier

Le programme traite un fichier de **mouvements** (créations, modifications, suppressions) pour mettre à jour un fichier maître d'**assurés** stocké en VSAM, tout en détectant et journalisant les anomalies.

### Cas d'Usage

- **Création (C)** : Ajouter un nouvel assuré au fichier VSAM
- **Modification (M)** : Modifier les données d'un assuré existant
- **Suppression (S)** : Supprimer un assuré du fichier

**Gestion des anomalies** : Code mouvement invalide, enregistrement inexistant, doublon, etc.

---

## 🏗️ Architecture

Le système est composé de **3 programmes COBOL** fonctionnant de manière modulaire :

### Programmes Principaux

#### 1. **MAJASSU** (355 lignes) - Programme Principal
- **Rôle** : Orchestrateur du traitement de mise à jour
- **Fonctionnalités** :
  - Lit le fichier de mouvements (VSAM ESDS) via l'accesseur PGMVSAM
  - Valide les codes mouvements (C/M/S)
  - Appelle PGMVSAM pour effectuer les opérations CRUD sur le fichier assurés
  - Gère le fichier d'anomalies
  - Affiche les statistiques de traitement (compteurs)
- **Fichiers manipulés** :
  - Lecture : FMVTSE (mouvements) via PGMVSAM
  - Mise à jour : ASSURES3 (assurés) via PGMVSAM
  - Écriture : ETATANO (anomalies)

#### 2. **PGMVSAM** (290 lignes) - Accesseur VSAM Réutilisable
- **Rôle** : Sous-programme technique d'accès aux fichiers VSAM
- **Fonctionnalités** :
  - Interface standardisée avec 8 fonctions (OPEN, CLOSE, READ, WRITE, REWRITE, DELETE, START, READNEXT)
  - Gère 2 fichiers VSAM :
    - **ASSURES3** (KSDS) : accès DYNAMIC (direct + séquentiel)
    - **FMVTSE** (ESDS) : accès séquentiel uniquement
  - Retourne des codes retour normalisés (00=OK, 01=EOF, 99=Erreur)
- **Avantages** :
  - Réutilisable pour d'autres programmes
  - Centralise la logique d'accès VSAM
  - Facilite la maintenance

### Sous-programmes

#### 3. **PGMERR** (50 lignes) - Gestionnaire de Messages
- **Rôle** : Retourne le libellé d'erreur à partir d'un code
- **Fonctionnalités** :
  - Table de 30 messages d'erreur
  - Recherche du libellé correspondant au code erreur
  - Interface simple : code en entrée, libellé en sortie

### Copybooks

Les structures de données sont définies dans des copybooks réutilisables :

| Copybook | Description |
|----------|-------------|
| **WASSURE.cpy** | Structure Working Storage pour les assurés (80 octets) |
| **WFMVTSE.cpy** | Structure Working Storage pour les mouvements (80 octets) |
| **CASSURES.cpy** | Structure FD pour le fichier KSDS assurés |
| **CFMVTS.cpy** | Structure FD pour le fichier ESDS mouvements |
| **MESSAGES.cpy** | Table des 30 messages d'erreur (60 caractères chacun) |

---

## 📦 Installation

### Prérequis

- **Environnement** : Mainframe z/OS avec TSO/ISPF
- **Accès** : Bibliothèques PDS disponibles
- **Volumes** : Volume DASD pour VSAM (ex: AJCWK1)

### Bibliothèques nécessaires

```
&SYSUID..COB.SOURCE  - Programmes COBOL
&SYSUID..COB.CPY     - Copy books
&SYSUID..COB.LOAD    - Load modules
API12.SEQ            - Fichiers séquentiels
```

### Étapes d'Installation

#### 1. Upload des Copybooks

```
TSO/ISPF Option 3.4
Dataset: &SYSUID..COB.CPY

Uploader les 5 copybooks :
├── WASSURE.cpy
├── WFMVTSE.cpy
├── CASSURES.cpy
├── CFMVTS.cpy
└── MESSAGES.cpy
```

#### 2. Upload des Programmes COBOL

```
TSO/ISPF Option 2 (EDIT)
Dataset: &SYSUID..COB.SOURCE

Créer 3 membres :
├── PGMVSAM  (accesseur VSAM)
├── MAJASSU  (programme principal)
└── PGMERR   (gestion erreurs)
```

#### 3. Upload des Données de Test

```
Upload dans API12.SEQ :
├── ASSURES (20 assurés - FB LRECL=80)
└── MVTS    (11 mouvements - FB LRECL=80)
```

#### 4. Adapter les JCL

Éditer les JCL et personnaliser :
- Remplacer `API12` par votre UserID si différent
- Vérifier le volume DASD (ex: AJCWK1)
- `&SYSUID` est automatiquement remplacé par le système

#### 5. Compilation

Soumettre le JCL **JCOMPIL.jcl** :
```jcl
//API12C   JOB ...
// STEP1 : Compilation PGMVSAM
// STEP2 : Compilation PGMERR
// STEP3 : Compilation MAJASSU
```

**Résultat attendu** : MAXCC=0 et 3 load modules dans `&SYSUID..COB.LOAD`

#### 6. Exécution

**Première exécution** : Soumettre **JEXEC.jcl** (chaîne complète)
- Tri des fichiers
- Création des clusters VSAM
- Chargement des données
- Exécution du traitement

**Exécutions suivantes** : Soumettre **JRUN.jcl** (exécution seule)

---

## 🚀 Utilisation

### Exécution de la Chaîne Complète

```bash
# Sur TSO/ISPF
# 1. Éditer JEXEC.jcl
# 2. Commande: SUB
# 3. Vérifier MAXCC=0 dans le SYSOUT
```

### Résultats Attendus

**Statistiques dans SYSOUT** :
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

**Fichier d'anomalies (ETATANO)** :
```
200006 ERREUR : 004 - SUPPRESSION SUR ENREGISTREMENT INEXISTANT
000346 ERREUR : 003 - MISE A JOUR SUR ENREGISTREMENT INEXISTANT
222203 ERREUR : 001 - CODE MOUVEMENT INVALIDE
```

---

## 📁 Structure du Projet

```
cobol-vsam-assures/
├── COBOL/              # Programmes sources
│   ├── MAJASSU.cbl     # Programme principal (355 lignes)
│   ├── PGMVSAM.cbl     # Accesseur VSAM (290 lignes)
│   └── PGMERR.cbl      # Gestion erreurs (50 lignes)
├── COPY/               # Copybooks
│   ├── WASSURE.cpy     # WS Assurés
│   ├── WFMVTSE.cpy     # WS Mouvements
│   ├── CASSURES.cpy    # FD Assurés
│   ├── CFMVTS.cpy      # FD Mouvements
│   └── MESSAGES.cpy    # Table messages
├── DATA/               # Données de test
│   ├── ASSURES         # 20 assurés
│   └── MVTS            # 11 mouvements
├── JCL/                # Scripts JCL
│   ├── JCOMPIL.jcl     # Compilation des 3 programmes
│   ├── JEXEC.jcl       # Chaîne complète (tri + VSAM + exec)
│   └── JRUN.jcl        # Exécution seule
├── DOCS/               # Documentation détaillée (ignoré par git)
├── .gitignore
└── README.md           # Ce fichier
```

---

## 📚 Sources et Références

### Contexte du Projet

- **Type** : Projet de soutenance - Formation COBOL Mainframe
- **Organisme** : AJC Formation - Consultant M. BENSOUSSAN
- **Date** : Février 2025
- **Environnement** : z/OS, TSO/ISPF, Enterprise COBOL

### Technologies Utilisées

- **Langage** : COBOL Enterprise (z/OS)
- **Fichiers** : VSAM (KSDS + ESDS)
- **Utilitaires** : SORT, IDCAMS
- **JCL** : Job Control Language

### Documentation Technique

- IBM Enterprise COBOL for z/OS - Language Reference
- IBM DFSMS Access Method Services for Catalogs
- z/OS V2R5 Documentation

### Auteur

**Nicolas MOREAU**
Projet académique - Formation Mainframe COBOL

---

## 📝 Licence

Ce projet est à usage éducatif dans le cadre d'une formation professionnelle.

---

**Dernière mise à jour** : Février 2025
