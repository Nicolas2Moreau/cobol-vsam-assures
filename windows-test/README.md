# 🪟 Environnement de Test Local GNUCobol

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
├── compile.bat         (compilation des programmes)
├── run.bat             (exécution MAJASSU)
├── COBOL/              (programmes COBOL adaptés pour GNUCobol)
├── COPY/               (copybooks - symlink ou copie depuis ../COPY)
├── DATA/               (fichiers de données de test)
└── logs/               (logs d'exécution - ignoré par git)
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

- **Logs :** `logs/execution.log`
- **Anomalies :** `DATA/ETATANO.txt`
- **Statistiques :** Affichées dans la console

---

## 📝 Notes

- Les programmes peuvent nécessiter des adaptations syntaxiques
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
