# 🔧 Adaptations Appliquées pour GNUCobol

> Documentation des modifications effectuées pour adapter les programmes z/OS vers GNUCobol

---

## 📊 Vue d'ensemble des Modifications

| Fichier | Modifications | Statut |
|---------|---------------|--------|
| **LOADKSDS.cbl** | Utilitaire de chargement KSDS créé | ✅ Nouveau |
| **PGMVSAM.cbl** | Chemins fichiers + LINE SEQUENTIAL | ✅ Adapté |
| **MAJASSU.cbl** | Chemin fichier ETATANO | ✅ Adapté |
| **PGMERR.cbl** | Aucune modification | ✅ Compatible |
| **Copybooks** | Aucune modification | ✅ Compatibles |
| **DATA/** | Fichiers pré-triés par matricule | ✅ Préparés |

---

## 1️⃣ LOADKSDS.cbl - Programme Utilitaire (NOUVEAU)

### Objectif
Charge les données initiales dans le fichier KSDS `WORK/ASSURES.dat` en simulant le comportement du REPRO mainframe.

### Caractéristiques

```cobol
* Fichier source (séquentiel avec retours ligne)
SELECT F-SOURCE ASSIGN TO "DATA/ASSURES"
    ORGANIZATION IS LINE SEQUENTIAL      ← Fichiers texte avec \n
    FILE STATUS IS FS-SOURCE.

* Fichier KSDS destination (indexed)
SELECT F-KSDS ASSIGN TO "WORK/ASSURES.dat"
    ORGANIZATION IS INDEXED
    ACCESS MODE IS SEQUENTIAL            ← Nécessite données triées
    RECORD KEY IS FS-KSDS-KEY
    FILE STATUS IS FS-KSDS.
```

**Points clés :**
- `ORGANIZATION IS LINE SEQUENTIAL` : Gère les fichiers texte avec retours à la ligne
- `ACCESS MODE IS SEQUENTIAL` : Impose que les données source soient triées par clé
- Crée automatiquement l'index GNUCobol

---

## 2️⃣ PGMVSAM.cbl - Adaptations Majeures

### Modification 1 : Chemins des Fichiers

```cobol
❌ AVANT (z/OS VSAM) :
SELECT F-ASSURES ASSIGN TO ASSURES
SELECT F-MVTS ASSIGN TO AS-MVTS

✅ APRÈS (GNUCobol) :
SELECT F-ASSURES ASSIGN TO "WORK/ASSURES.dat"
SELECT F-MVTS ASSIGN TO "WORK/MVTS.dat"
```

**Raison :** GNUCobol nécessite des chemins de fichiers explicites.

---

### Modification 2 : ORGANIZATION pour MVTS

```cobol
✅ APRÈS (GNUCobol) :
SELECT F-MVTS ASSIGN TO "WORK/MVTS.dat"
    ORGANIZATION IS LINE SEQUENTIAL      ← Ajouté pour fichiers avec \n
    ACCESS MODE IS SEQUENTIAL
    FILE STATUS IS FS-MVTS.
```

**Raison :** Le fichier `DATA/MVTS` contient des retours à la ligne (`\n`).

---

### Modification 3 : File Status Code '24'

```cobol
✅ AJOUTÉ (ligne ~290) :
WHEN '24'
    MOVE WS-RETOUR-NOTFOUND TO LS-CODE-RETOUR
```

**Raison :** GNUCobol peut retourner '24' (invalid key) en plus de '23' pour certaines opérations INDEXED.

---

## 3️⃣ MAJASSU.cbl - Adaptation Mineure

### Modification : Chemin Fichier Anomalies

```cobol
❌ AVANT (z/OS) :
SELECT F-ETAT-ANO ASSIGN TO ETATANO

✅ APRÈS (GNUCobol) :
SELECT F-ETAT-ANO ASSIGN TO "WORK/ETATANO.txt"
```

**Raison :** Chemin explicite vers répertoire de travail avec extension.

---

## 4️⃣ PGMERR.cbl - Aucune Modification

```
✅ Programme 100% standard COBOL
✅ Fonctionne tel quel sous GNUCobol
✅ Aucune adaptation nécessaire
```

---

## 5️⃣ Copybooks - Aucune Modification

Tous les copybooks (`WASSURE.cpy`, `WFMVTSE.cpy`, `CASSURES.cpy`, `CFMVTS.cpy`, `COMVSAM.cpy`, `COMERR.cpy`) sont **100% compatibles** avec GNUCobol sans aucune modification.

---

## 6️⃣ Fichiers de Données - Pré-Traitement

### ⚠️ Modification Critique : Tri des Données

**Fichiers concernés :**
- `DATA/ASSURES` (20 enregistrements)
- `DATA/MVTS` (11 enregistrements)

**Action effectuée :**
```bash
sort DATA/ASSURES -o DATA/ASSURES    # Tri par matricule (6 premiers caractères)
sort DATA/MVTS -o DATA/MVTS          # Tri par matricule (6 premiers caractères)
```

**Raison :**
Sur mainframe, les fichiers sont triés via JCL (`SORT FIELDS=(1,6,CH,A)`) avant le REPRO. Pour GNUCobol, les fichiers ont été **pré-triés dans le dépôt** pour simuler cette étape.

**Résultat :**
- `DATA/ASSURES` : Matricules de 000645 à 234563 (ordre croissant)
- `DATA/MVTS` : Matricules de 000346 à 300312 (ordre croissant)

---

## 7️⃣ Scripts Batch - Nouveaux Fichiers

### compile.bat
Compile les programmes COBOL pour Windows :
- `LOADKSDS.exe` : Utilitaire de chargement
- `MAJASSU.exe` : Programme principal (intègre PGMVSAM + PGMERR)

### init.bat
Initialise les données de test :
1. Copie `DATA/MVTS` → `WORK/MVTS.dat`
2. Exécute `LOADKSDS.exe` pour créer le KSDS

### run.bat
Exécute le programme principal `MAJASSU.exe`

### reset.bat
Remet à zéro l'environnement (supprime `WORK/*` et relance `init.bat`)

---

## 📋 Récapitulatif Technique

### Différences z/OS vs GNUCobol

| Aspect | z/OS | GNUCobol |
|--------|------|----------|
| **VSAM KSDS** | ORGANIZATION INDEXED | ORGANIZATION IS INDEXED ✅ |
| **VSAM ESDS** | ORGANIZATION SEQUENTIAL | ORGANIZATION IS LINE SEQUENTIAL |
| **File Status** | Standard | Codes peuvent différer (23 vs 24) |
| **ASSIGN TO** | Nom logique (DDNAME) | Chemin fichier physique |
| **Tri données** | JCL SORT | Fichiers pré-triés |
| **REPRO** | Utilitaire IDCAMS | Programme LOADKSDS.cbl |

---

## ✅ Validation

### Tests Réalisés

**Environnement :**
- GNUCobol 3.2.0
- Windows 10/11
- Fichiers source pré-triés

**Résultats :**
```
✅ LOADKSDS.exe : 20 assurés chargés avec succès
✅ MAJASSU.exe : Traitement complet réussi
   - 11 mouvements lus
   - 2 créations
   - 1 modification
   - 2 suppressions
   - 6 anomalies détectées
✅ WORK/ETATANO.txt : 6 anomalies correctement enregistrées
✅ Comportement conforme aux spécifications mainframe
```

---

## 🎯 Limitations Connues

### 1. Performances
- GNUCobol est plus lent que z/OS compilé natif
- Les fichiers INDEXED peuvent être 10-20x plus lents que VSAM KSDS réel

### 2. File Status Codes
- GNUCobol peut retourner des codes légèrement différents
- Nécessite gestion du code '24' en plus du '23'

### 3. Environnement
- Simulation locale uniquement (pas de connexion mainframe)
- Pas de JCL réel (scripts .bat)

### 4. Données
- Fichiers pré-triés dans le dépôt (pas de tri dynamique)
- ORGANIZATION IS LINE SEQUENTIAL au lieu de fichiers à enregistrements fixes

---

## 📝 Conclusion

L'adaptation des programmes z/OS vers GNUCobol a nécessité **des modifications minimales** :
- ✅ 3 programmes modifiés (LOADKSDS créé, PGMVSAM et MAJASSU adaptés)
- ✅ 1 programme compatible tel quel (PGMERR)
- ✅ Tous les copybooks compatibles sans modification
- ✅ Comportement fonctionnel validé et conforme

L'environnement GNUCobol permet de **développer et tester localement** sans accès mainframe, tout en conservant une **compatibilité maximale** avec le code z/OS original.

---

**Dernière mise à jour :** Février 2025
