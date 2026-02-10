# 🔧 Guide des Adaptations GNUCobol

> Documentation détaillée des modifications nécessaires pour adapter les programmes z/OS vers GNUCobol

---

## 📊 Vue d'ensemble

| Fichier | Complexité | Modifications | Risque |
|---------|------------|---------------|--------|
| **PGMVSAM.cbl** | ⚠️ ÉLEVÉE | Nombreuses (VSAM → Indexed) | MOYEN |
| **MAJASSU.cbl** | ✅ FAIBLE | Aucune ou minimes | FAIBLE |
| **PGMERR.cbl** | ✅ FAIBLE | Aucune | FAIBLE |
| **Copybooks** | ✅ AUCUNE | Aucune | AUCUN |

---

## 1️⃣ PGMVSAM.cbl - Adaptations Majeures

### 🔴 Problème 1 : Fichier KSDS (ASSURES)

**Ligne 12 - ASSIGN TO**
```cobol
❌ AVANT (z/OS VSAM) :
SELECT F-ASSURES ASSIGN TO ASSURES

✅ APRÈS (GNUCobol) :
SELECT F-ASSURES ASSIGN TO "ASSURES.dat"
```
**Raison :** GNUCobol nécessite un nom de fichier physique avec extension

---

**Lignes 13-16 - ORGANIZATION INDEXED**
```cobol
✅ OK (pas de changement nécessaire) :
ORGANIZATION IS INDEXED
ACCESS MODE IS DYNAMIC
RECORD KEY IS FS-ASSURES-KEY
FILE STATUS IS FS-ASSURES
```
**Raison :** GNUCobol supporte ORGANIZATION IS INDEXED nativement

---

### 🔴 Problème 2 : Fichier ESDS (MVTS)

**Ligne 19 - ASSIGN TO avec préfixe AS-**
```cobol
❌ AVANT (z/OS VSAM) :
SELECT F-MVTS ASSIGN TO AS-MVTS

✅ APRÈS (GNUCobol) :
SELECT F-MVTS ASSIGN TO "MVTS.dat"
```
**Raison :**
- Le préfixe `AS-` est spécifique z/OS pour ESDS
- GNUCobol utilise des noms de fichiers standards

---

**Lignes 20-22 - ORGANIZATION SEQUENTIAL**
```cobol
✅ OK (pas de changement) :
ORGANIZATION IS SEQUENTIAL
ACCESS MODE IS SEQUENTIAL
FILE STATUS IS FS-MVTS
```

---

### 🟡 Problème 3 : File Status Codes

**Lignes 168, 186, 205, 223 - File Status '23' (Invalid Key)**
```cobol
⚠️ ATTENTION :
MOVE '23' TO WS-FILE-STATUS

⚠️ GNUCobol peut retourner '23' OU '24' selon le contexte
```

**Solution recommandée :**
```cobol
✅ MODIFIER (ligne 290 - MAPPER-FILE-STATUS) :
WHEN '23'
    MOVE WS-RETOUR-NOTFOUND TO LS-CODE-RETOUR
WHEN '24'                              ← AJOUTER
    MOVE WS-RETOUR-NOTFOUND TO LS-CODE-RETOUR   ← AJOUTER
```

---

### 🟢 Problème 4 : CALL GOBACK

**Ligne 104 - GOBACK**
```cobol
✅ OK (supporté par GNUCobol) :
GOBACK
```

---

## 2️⃣ MAJASSU.cbl - Adaptations Mineures

### 🟢 Fichier ETAT-ANO

**Ligne 12 - ASSIGN TO**
```cobol
❌ AVANT :
SELECT F-ETAT-ANO ASSIGN TO ETATANO

✅ APRÈS :
SELECT F-ETAT-ANO ASSIGN TO "ETATANO.txt"
```

---

### 🟢 CALL vers PGMVSAM et PGMERR

**Lignes 98, 107, etc. - CALL 'PGMVSAM'**
```cobol
⚠️ ATTENTION :
CALL 'PGMVSAM' USING WS-COM-VSAM

✅ Deux options GNUCobol :

Option A - CALL statique (recommandé) :
CALL 'PGMVSAM' USING WS-COM-VSAM

Option B - CALL dynamique :
CALL 'PGMVSAM.exe' USING WS-COM-VSAM
```

**Recommandation :** Option A (compile tout ensemble)

---

## 3️⃣ PGMERR.cbl - Aucune Adaptation

```
✅ Ce programme est 100% standard COBOL
✅ Aucune modification nécessaire
✅ Fonctionne tel quel sous GNUCobol
```

---

## 4️⃣ Copybooks - Aucune Adaptation

```
✅ Tous les copybooks sont standard COBOL
✅ Structures de données compatibles
✅ Aucune modification nécessaire
```

---

## 📝 Récapitulatif des Modifications

### PGMVSAM.cbl (6 modifications)

```cobol
1. Ligne 12  : ASSIGN TO "ASSURES.dat"
2. Ligne 19  : ASSIGN TO "MVTS.dat"
3. Ligne 290 : Ajouter WHEN '24' (file status)
```

### MAJASSU.cbl (1 modification)

```cobol
1. Ligne 12 : ASSIGN TO "ETATANO.txt"
```

### PGMERR.cbl (0 modification)
```
✅ Aucune
```

---

## 🎯 Stratégie de Test

### Phase 1 : Compilation
```cmd
cd windows-test
compile.bat
```

**Erreurs attendues :**
- ❌ File not found (normal, fichiers .dat pas encore créés)
- ✅ Pas d'erreurs de syntaxe

### Phase 2 : Création des fichiers de données

**ASSURES.dat (INDEXED) :**
```bash
# Sera créé automatiquement par GNUCobol au premier WRITE
# Index dans ASSURES.idx
```

**MVTS.dat (SEQUENTIAL) :**
```bash
# Copier depuis DATA/MVTS
cp DATA/MVTS DATA/MVTS.dat
```

### Phase 3 : Exécution
```cmd
run.bat
```

---

## ⚠️ Limitations Connues GNUCobol

### 1. Performances
- ❌ Plus lent que z/OS (interprété vs compilé natif)
- ⚠️ INDEXED peut être 10-20x plus lent que VSAM KSDS

### 2. File Status
- ⚠️ Codes peuvent différer légèrement de z/OS
- ⚠️ Toujours tester les cas d'erreur

### 3. CALL
- ⚠️ Pas de load module comme z/OS
- ✅ Utiliser compilation statique (recommandé)

### 4. Fichiers INDEXED
- ❌ Pas de support ALTERNATE KEY dans toutes les versions
- ⚠️ Vérifier votre version GNUCobol

---

## 🚀 Prochaines Étapes

**Option A : Modifications Minimales (recommandé pour débuter)**
1. ✅ Modifier ASSIGN TO (3 lignes)
2. ✅ Ajouter WHEN '24' (1 ligne)
3. ✅ Tester compilation

**Option B : Modifications Complètes**
1. ✅ Option A +
2. ✅ Adapter scripts .bat
3. ✅ Créer données de test
4. ✅ Tests fonctionnels complets

---

**Que voulez-vous faire ?**
- **Appliquer les modifications maintenant ?**
- **D'abord tester compilation sans modif ?**
- **Autre approche ?**
