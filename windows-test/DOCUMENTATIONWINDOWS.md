# ![VSAM](https://img.shields.io/badge/Windows-OS-green) Documentation Technique - Environnement Windows GNUCobol

> **Documentation technique complète** de l'environnement de test GNUCobol
>
> 📖 **Guide de démarrage rapide** : [`README.md`](README.md)
>
> **Note :** Cette branche (`gnucobol`) est dédiée aux tests locaux avec GNUCobol sur Windows. Elle permet de développer et tester sans accès constant au mainframe z/OS.

---

## 📋 Prérequis

### Installation GNUCobol

1. **Télécharger GNUCobol pour Windows :**
   - Site officiel : https://gnucobol.sourceforge.io/
   - Ou Arnold Trembley builds : https://www.arnoldtrembley.com/GnuCOBOL.htm

2. **Installer :**
   - Extraire l'archive dans `C:\GnuCOBOL\`
   - Ajouter `C:\GnuCOBOL\bin` au PATH Windows

3. **Vérifier l'installation :**
   ```cmd
   cobc --version
   ```

---

## 🗂️ Structure du Répertoire

```
windows-test/
├── README.md           (ce fichier)
├── QUICKSTART.md       (guide de démarrage rapide)
├── ADAPTATIONS.md      (modifications appliquées)
├── compile.bat         (compilation des programmes)
├── init.bat            (initialisation données)
├── run.bat             (exécution MAJASSU)
├── reset.bat           (remise à zéro)
├── COBOL/              (programmes COBOL adaptés)
├── COPY/               (copybooks)
├── DATA/               (données source - pré-triées par matricule)
├── WORK/               (fichiers de travail - ignoré par git)
└── bin/                (exécutables - ignoré par git)
```

---

## 🔧 Différences GNUCobol vs Enterprise COBOL

### Limitations connues :
- ❌ Pas de support VSAM natif (utiliser fichiers séquentiels ou indexed)
- ❌ Certaines syntaxes z/OS non supportées
- ⚠️ File status codes peuvent différer
- ⚠️ CALL dynamique peut nécessiter des adaptations

### Adaptations nécessaires :
1. **Fichiers VSAM → Fichiers indexed/séquentiels**
   - KSDS → ORGANIZATION IS INDEXED
   - ESDS → ORGANIZATION IS SEQUENTIAL

2. **JCL → Scripts batch (.bat)**
   - Pas de JCL sous Windows
   - Utiliser les scripts fournis

3. **SYSOUT → Fichiers texte**
   - Rediriger les DISPLAY vers des fichiers

---

## 🚀 Utilisation

### 1. Compilation

```cmd
cd windows-test
compile.bat
```

Compile tous les programmes COBOL et génère les exécutables.

### 2. Exécution

```cmd
run.bat
```

Lance le traitement de mise à jour des assurés.

### 3. Vérification des résultats

- **Anomalies :** `WORK/ETATANO.txt`
- **Statistiques :** Affichées dans la console
- **Fichiers générés :** `WORK/ASSURES.dat` (KSDS modifié)

---

## 📝 Notes Importantes

### ⚠️ Fichiers DATA Pré-Triés

**Pour les besoins des tests GNUCobol**, les fichiers `DATA/ASSURES` et `DATA/MVTS` ont été **pré-triés par matricule** (ordre croissant). Cette étape simule le tri mainframe qui serait normalement effectué par JCL avant le REPRO.

- Sur mainframe : Tri via `SORT` dans le JCL
- Sur Windows : Fichiers déjà triés dans le dépôt

### Autres Notes

- Les programmes ont été adaptés pour GNUCobol (voir `ADAPTATIONS.md`)
- Les performances ne sont pas représentatives du mainframe
- Cet environnement est uniquement pour le développement/tests locaux
- Ne pas merger cette branche dans `main` (mainframe pur)

---

## 🔗 Liens Utiles

- [GNUCobol Documentation](https://gnucobol.sourceforge.io/doc/gnucobol.html)
- [COBOL Programming Guide](https://open-cobol.sourceforge.io/guides/OpenCOBOL%20Programmers%20Guide.pdf)
- [Mainframe → GNUCobol Migration](https://gnucobol.sourceforge.io/faq/index.html)

---

**Dernière mise à jour :** Février 2025
