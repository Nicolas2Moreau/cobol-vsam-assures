# PROJET COBOL VSAM/DB2 — RÉFÉRENCE DES ACCESSEURS

## Interface commune (zone de communication 120 octets)

Les deux accesseurs (PGMVSAM et PGMDB2) partagent **exactement la même interface** :
l'appelant (MAJASSU / MAJASSV2) n'a pas à savoir lequel il appelle.

```
Offset  Long  Champ           Contenu
──────────────────────────────────────────────────────────────
  0       8   LS-NOM-FICHIER  'ASSURES3' ou 'FMVTSE'
  8       2   LS-CODE-FONCTION code fonction (01-09)
 10       2   LS-CODE-RETOUR  code retour (positionné par l'accesseur)
 12      80   LS-ENREG        données enregistrement (DISPLAY 80 octets)
 92      28   LS-FILLER       réservé
                              TOTAL = 120 octets
```

### Structure de LS-ENREG (80 octets DISPLAY)

```
Offset  Long  Champ      Type COBOL
──────────────────────────────────────────────────────────────
  0       6   MATASS     PIC 9(6)       matricule (clé primaire)
  6      20   NOMPRE     PIC X(20)      nom + prénom
 26      18   RUESS      PIC X(18)      rue
 44       5   CPASS      PIC 9(5)       code postal
 49      12   VILLSS     PIC X(12)      ville
 61       1   CODVEH     PIC X(1)       code véhicule
 62       6   PRIMSS     PIC 9(4)V99    prime (ex: '010050' = 100.50)
 68       1   BONMAL     PIC X(1)       bonus/malus (B ou M)
 69       2   TAUXSS     PIC 99         taux
 71       9   FILLER     PIC X(9)       non utilisé
```

### Codes retour

| Code | Constante       | Signification                            |
|------|-----------------|------------------------------------------|
| 00   | OK              | succès                                   |
| 01   | NOTFOUND        | clé absente (READ, DELETE)               |
| 02   | DUPLICATE       | clé déjà existante (WRITE)               |
| 03   | IOERROR         | erreur d'entrée/sortie                   |
| 04   | EOF             | fin de fichier / fin de curseur          |
| 99   | ERROR           | code fonction inconnu ou erreur fatale   |

---

## Fonctions par version

---

### Fonction 01 — OPEN

**Rôle :** initialise l'accès à la ressource avant toute opération.

**V1 — PGMVSAM**
- Ouvre le fichier VSAM physiquement selon `LS-NOM-FICHIER` :
  - `ASSURES3` → `OPEN I-O F-ASSURES` (lecture + écriture)
  - `FMVTSE`   → `OPEN INPUT F-MVTS` (lecture seule)
- Garde un flag interne (`WS-ASSURES-OPEN`, `WS-MVTS-OPEN`).
  Si déjà ouvert, retourne RC=00 sans rien faire (idempotent).
- Un OPEN raté (fichier absent sur le volume) donne RC=03 (IOERROR).

**V2 — PGMDB2**
- **No-op pur** : retourne RC=00 immédiatement.
- DB2 n'a pas de notion de fichier à ouvrir ; la connexion est établie
  par IKJEFT01 au niveau du step JCL, pas par le programme.
- Le NOM-FICHIER est ignoré.

---

### Fonction 02 — CLOSE

**Rôle :** libère la ressource proprement en fin de traitement.

**V1 — PGMVSAM**
- Ferme le fichier VSAM selon `LS-NOM-FICHIER` :
  - `ASSURES3` → `CLOSE F-ASSURES`
  - `FMVTSE`   → `CLOSE F-MVTS`
- Si déjà fermé, retourne RC=00 sans rien faire (idempotent).
- **Critique en VSAM :** sans CLOSE, le fichier reste verrouillé
  (SHAREOPTIONS) et bloque les autres jobs.

**V2 — PGMDB2**
- Exécute `CLOSE CSR-ASSURES` (ferme le curseur de lecture séquentielle).
- Retourne toujours RC=00 (même si le curseur n'était pas ouvert).
- Le NOM-FICHIER est ignoré (un seul curseur déclaré sur ASSURES).

---

### Fonction 03 — READ

**Rôle :** lecture directe d'un enregistrement par sa clé.

**V1 — PGMVSAM**
- Cible : `ASSURES3` uniquement (ESDS FMVTSE ne supporte pas l'accès direct).
- Prend `LS-ENREG(1:6)` comme clé → positionné dans `FS-ASSURES-KEY`.
- `READ F-ASSURES` : si trouvé, copie `FS-ASSURES-REC` dans `LS-ENREG` → RC=00.
- File-status `23` (INVALID KEY) → RC=01 (NOTFOUND).

**V2 — PGMDB2**
- `SELECT ... FROM ASSURES WHERE MATASS = :WS-MATASS`
- SQLCODE=0 → données copiées dans `LS-ENREG` via `MOVE-WS-TO-LS`
  (conversion COMP-3/COMP → DISPLAY) → RC=00.
- SQLCODE=+100 → RC=01 (NOTFOUND).
- La conversion de type est transparente pour l'appelant.

---

### Fonction 04 — REWRITE

**Rôle :** mise à jour d'un enregistrement existant (tous les champs sauf la clé).

**V1 — PGMVSAM**
- **Contrainte VSAM :** un `READ` sur la clé cible doit précéder le REWRITE
  dans la même ouverture (requis par COBOL VSAM ACCESS DYNAMIC).
- Copie `LS-ENREG` dans `FS-ASSURES-REC` puis `REWRITE FS-ASSURES-REC`.
- File-status `23` (clé non trouvée au moment du REWRITE) → RC=01.

**V2 — PGMDB2**
- `UPDATE ASSURES SET nompre=, ruess=, ... WHERE MATASS=:WS-MATASS`
- La clé primaire (MATASS) n'est pas modifiable (absente du SET).
- **Pas de READ préalable nécessaire** : l'UPDATE est autonome.
- SQLCODE=0 → RC=00. SQLCODE=-803/-811 → RC=02 (DUPLICATE, cas théorique).

---

### Fonction 05 — DELETE

**Rôle :** suppression d'un enregistrement par sa clé.

**V1 — PGMVSAM**
- Cible : `ASSURES3` uniquement.
- Prend `LS-ENREG(1:6)` comme clé → `FS-ASSURES-KEY`.
- `DELETE F-ASSURES` : INVALID KEY → RC=01 (NOTFOUND).

**V2 — PGMDB2**
- `DELETE FROM ASSURES WHERE MATASS = :WS-MATASS`
- SQLCODE=0 → RC=00. SQLCODE=+100 → RC=01 (NOTFOUND).
- Utilise `MAPPER-READ` (même mapping que la fonction 03).

---

### Fonction 06 — WRITE

**Rôle :** création d'un nouvel enregistrement (clé inexistante obligatoire).

**V1 — PGMVSAM**
- Cible : `ASSURES3` uniquement.
- Copie `LS-ENREG` dans `FS-ASSURES-REC` puis `WRITE FS-ASSURES-REC`.
- File-status `22` (duplicate key) → RC=02 (DUPLICATE).

**V2 — PGMDB2**
- `INSERT INTO ASSURES (MATASS, NOMPRE, ...) VALUES (:WS-MATASS, ...)`
- Les données sont converties DISPLAY → COMP-3/COMP via `MOVE-LS-TO-WS`
  avant l'INSERT.
- SQLCODE=-803 (unique index violation) ou -811 → RC=02 (DUPLICATE).

---

### Fonction 07 — STARTBR

**Rôle :** initialise un parcours séquentiel (doit précéder les READNEXT).

**V1 — PGMVSAM**
- `ASSURES3` : `START F-ASSURES KEY >= LOW-VALUES`
  → se positionne avant le 1er enregistrement du KSDS (ordre clé croissant).
- `FMVTSE` : retourne RC=00 sans rien faire. L'ESDS est naturellement
  séquentiel ; l'ordre de lecture suit l'ordre d'insertion.
- INVALID KEY → RC=01 (fichier vide ou autre).

**V2 — PGMDB2**
- `OPEN CSR-ASSURES`
  (curseur déclaré `SELECT ... FROM ASSURES ORDER BY MATASS`)
- Ouvre le curseur ; les FETCH suivants liront dans l'ordre MATASS croissant.
- SQLCODE=0 → RC=00 via `MAPPER-OPEN`.

---

### Fonction 08 — READNEXT

**Rôle :** lit l'enregistrement suivant dans un parcours séquentiel.
Doit être précédée d'un STARTBR (07).

**V1 — PGMVSAM**
- `ASSURES3` : `READ F-ASSURES NEXT` → enreg retourné dans `LS-ENREG`.
- `FMVTSE`   : `READ F-MVTS` → enreg retourné dans `LS-ENREG`.
- AT END (file-status `10`) → RC=04 (EOF).
- Fonctionne sur les **deux** fichiers (seule fonction bi-fichier active en V1).

**V2 — PGMDB2**
- `FETCH CSR-ASSURES INTO :WS-MATASS, :WS-NOMPRE, ...`
- Si SQLCODE=0 : données converties COMP-3/COMP → DISPLAY via `MOVE-WS-TO-LS`,
  puis copiées dans `LS-ENREG` → RC=00.
- SQLCODE=+100 → RC=04 (EOF, curseur épuisé).
- SQLCODE=-501 (curseur non ouvert, STARTBR oublié) → RC=03 (IOERROR).

---

### Fonction 09 — TRUNCATE *(V2 uniquement)*

**Rôle :** vide entièrement la table DB2 ASSURES (équivalent d'un TRUNCATE TABLE).
Utilisée exclusivement par KSTODB2 avant de recharger la table depuis le KSDS.

**V1 — PGMVSAM**
- **Non implémentée.** Code fonction 09 → branche WHEN OTHER → RC=99 (ERROR).

**V2 — PGMDB2**
- `DELETE FROM ASSURES` (sans clause WHERE → supprime toutes les lignes).
- SQLCODE=0 → RC=00 via `MAPPER-WRITE`.
- Opération irréversible sans COMMIT/ROLLBACK explicite dans le job.
- **Ne jamais appeler depuis MAJASSV2** ; réservée à KSTODB2 (rechargement KSDS→DB2).

---

## Différences comportementales notables

| Aspect                  | V1 PGMVSAM                          | V2 PGMDB2                            |
|-------------------------|--------------------------------------|--------------------------------------|
| OPEN réel               | Oui (OPEN I-O / INPUT)               | Non (no-op)                          |
| REWRITE sans READ       | Interdit (VSAM COBOL)                | Autorisé (UPDATE direct)             |
| FMVTSE (mouvements)     | OPEN / CLOSE / READNEXT              | Non supporté                         |
| Ordre séquentiel        | Ordre physique KSDS (clé croissante) | ORDER BY MATASS (curseur SQL)        |
| Conversion types        | Aucune (tout DISPLAY)                | DISPLAY ↔ COMP-3/COMP via mapper     |
| TRUNCATE (09)           | Non (RC=99)                          | Oui (DELETE sans WHERE)              |
| Gestion double OPEN     | Idempotent (flag interne)            | Toujours RC=00 (no-op)               |
| CLOSE curseur non ouvert| Idempotent (flag interne)            | RC=00 (SQLCODE=-501 ignoré)          |

---

## Comportement en cas d'absence du fichier FMVTSE

### Deux cas bien distincts

---

### Cas 1 — Fichier FMVTSE absent (DSN inexistant ou DD MVTS manquant dans le JCL)

L'OPEN échoue dans `10000-INIT`. Voici l'ordre exact d'exécution :

```
1. OPEN ASSURES3  → RC=00  ✓  F-ASSURES est ouvert
2. OPEN FMVTSE    → RC=03  ✗  file-status='35' (fichier inexistant)
   → DISPLAY 'ERREUR OUVERTURE FMVTSE'
   → STOP RUN  ← on quitte ici
3. OPEN ETATANO   ← jamais atteint
```

État du programme au moment du `STOP RUN` :

| Ressource      | État                                               |
|----------------|----------------------------------------------------|
| ASSURES3       | Ouvert — aucun CLOSE explicite avant de quitter    |
| FMVTSE         | Non ouvert — l'OPEN a échoué                       |
| ETATANO        | Non ouvert — ligne jamais atteinte                 |
| Statistiques   | Non affichées — `23000-AFFICHER-STATS` non appelé  |
| `30000-FIN`    | Non exécuté — les CLOSE du programme ne tournent pas |

**Est-ce vraiment "propre" ?**

Pas au sens programme — mais pas catastrophique non plus.
Quand `STOP RUN` s'exécute, **z/OS ferme automatiquement tous les fichiers
encore ouverts** à la fin du step. C'est le système qui nettoie, pas le
programme. ASSURES3 est donc fermé par l'OS : pas de corruption, pas de
verrou résiduel sur le cluster VSAM.

**Le vrai problème : le `RETURN-CODE` n'est pas positionné.**
Le programme affiche le message d'erreur puis quitte avec `CC=00`.
Le JCL ne sait pas qu'il y a eu un problème. Les steps suivants
s'exécutent normalement si leurs `COND=` sont basés sur `CC=0`, ce qui
peut faire passer une exécution ratée pour un succès.

---

### Cas 2 — Fichier FMVTSE vide (existe mais 0 enregistrements)

L'OPEN réussit (un ESDS vide s'ouvre normalement, file-status='00' → RC=00).
Le comportement particulier apparaît dans `21000-LIRE-PREMIER-MVT` :

```
READNEXT(08) sur 'FMVTSE'
  → PGMVSAM : READ F-MVTS AT END
  → file-status = '10' → RC=04 (EOF)
  → DISPLAY 'FICHIER MOUVEMENTS VIDE'
  → WS-FIN-MVTS = 'O'
```

La boucle `PERFORM UNTIL WS-FIN-MVTS = 'O'` ne s'exécute pas du tout
(condition déjà vraie dès l'entrée). Le programme enchaîne directement
`23000-AFFICHER-STATS` puis `30000-FIN` avec fermeture propre de tous
les fichiers.

**Résultat : terminaison normale**, stats toutes à zéro, ETATANO créé
mais vide, `30000-FIN` bien exécuté.

---

### Synthèse

| Situation | Où ça bloque | RC PGMVSAM | `30000-FIN` appelé ? | CC final |
|-----------|-------------|------------|----------------------|----------|
| DD MVTS absent dans JCL | OPEN FMVTSE | 03 IOERROR | **Non** | **00 (trompeur)** |
| DSN FMVTSE inexistant | OPEN FMVTSE | 03 IOERROR | **Non** | **00 (trompeur)** |
| Fichier FMVTSE vide | 1er READNEXT | 04 EOF | Oui | 00 (normal) |

**Note V2 :** dans MAJASSV2, FMVTSE est **toujours** géré via PGMVSAM
(hardcodé `WS-NOM-PGMVSAM`), même quand l'accesseur ASSURES est PGMDB2.
C'est volontaire : le fichier de mouvements reste VSAM dans les deux
versions. Le comportement décrit ci-dessus est donc identique en V1 et V2.

---

## Programmes du projet

| Programme  | Version | Rôle                                                  |
|------------|---------|-------------------------------------------------------|
| PGMVSAM    | V1      | Accesseur VSAM (KSDS ASSURES3 + ESDS FMVTSE)         |
| PGMDB2     | V2      | Accesseur DB2 (table API12.ASSURES)                   |
| MAJASSU    | V1      | Programme principal — appelle PGMVSAM en statique     |
| MAJASSV2   | V2      | Programme principal — choisit l'accesseur via PARM    |
| KSTODB2    | V2      | Chargeur KSDS → DB2 (TRUNCATE puis INSERT en masse)   |
| PGMERR     | V1/V2   | Sous-programme d'affichage des messages d'erreur      |
| TSTASSU    | TEST    | Harness de test (12 cas, PARM='PGMVSAM' ou 'PGMDB2') |
