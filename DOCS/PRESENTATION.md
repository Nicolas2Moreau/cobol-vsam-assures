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

### Couche de traduction — les Mappers

Chaque accesseur reçoit des codes d'erreur natifs très différents selon la
technologie sous-jacente (VSAM ou DB2). Le rôle des **mappers** est de les
réduire aux 6 codes retour de l'interface, pour que l'appelant n'ait jamais
à se préoccuper de ce qui se passe en dessous.

**En V1 — PGMVSAM : un seul paragraphe `MAPPER-FILE-STATUS`**

VSAM retourne un file-status sur 2 caractères après chaque opération.
Un unique paragraphe traduit toutes les valeurs possibles :

```
File-status VSAM  →  Code retour interface
─────────────────────────────────────────
'00'              →  00  OK
'10'              →  04  EOF      (fin de fichier)
'22'              →  02  DUPLICATE (clé déjà existante)
'23'              →  01  NOTFOUND  (clé absente)
'11' à '49'       →  03  IOERROR   ('35' fichier inexistant tombe ici)
'90' à '99'       →  03  IOERROR
autres            →  99  ERROR
```

**En V2 — PGMDB2 : 4 mappers distincts selon l'opération**

DB2 retourne un SQLCODE (entier signé). Le même SQLCODE peut signifier des
choses différentes selon ce qu'on fait — par exemple `+100` veut dire
"pas trouvé" sur un READ, mais "fin de curseur" sur un FETCH. Il faut donc
4 mappers séparés :

```
Mapper          Utilisé par          Traductions clés
──────────────────────────────────────────────────────────────────
MAPPER-READ     READ (03), DELETE(05)  0→00  +100→01  -501→03
MAPPER-WRITE    WRITE(06), REWRITE(04) 0→00  -803/-811→02  -501→03
                TRUNCATE(09)
MAPPER-FETCH    READNEXT (08)          0→00  +100→04  -501→03
MAPPER-OPEN     STARTBR (07)           0→00  autres→99
```

> **SQLCODE -501** : DB2 signale qu'on opère sur un curseur qui n'a pas été
> ouvert. En pratique : appel de READNEXT (f08) sans STARTBR (f07) préalable,
> ou CLOSE (f02) alors que le curseur n'est pas actif. Traduit en RC=03 (IOERROR).

**D'où viennent ces SQLCODE ? La SQLCA.**

DB2 maintient une zone mémoire standardisée appelée **SQLCA** (SQL Communication
Area), injectée dans le working-storage via :

```cobol
EXEC SQL
    INCLUDE SQLCA
END-EXEC.
```

Après chaque instruction `EXEC SQL ... END-EXEC`, DB2 remplit automatiquement
cette zone. Le champ clé est `SQLCODE`. Dans PGMDB2, on le récupère
systématiquement après chaque appel SQL :

```cobol
MOVE SQLCODE TO WS-SQLCODE   ← copie locale (PIC S9(9) COMP)
PERFORM MAPPER-xxx
```

La copie dans `WS-SQLCODE` protège la valeur d'un éventuel écrasement par
une instruction SQL implicite. La chaîne complète est donc :

```
DB2 exécute le SQL
  → remplit SQLCA.SQLCODE automatiquement
    → MOVE SQLCODE TO WS-SQLCODE
      → MAPPER-xxx traduit en RC 00/01/02/03/04/99
        → l'appelant ne voit que ces 6 codes
```

La SQLCA contient aussi d'autres champs (`SQLERRM`, `SQLSTATE`, `SQLERRD`...)
qui donnent des détails sur l'erreur, mais dans notre code le SQLCODE seul
suffit pour alimenter les mappers.

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

## PGMERR — Le gestionnaire de messages

### Rôle

PGMERR est un sous-programme autonome dont le seul travail est de transformer
un **code numérique à 3 chiffres** en un **libellé de 60 caractères**, utilisé
par MAJASSU pour rédiger les lignes du fichier d'anomalies ETATANO.

### Comment ça fonctionne

`MESSAGES.cpy` définit une zone fixe de **30 × 60 = 1 800 octets** initialisée
en dur dans le working-storage. PGMERR la redéfinit aussitôt avec un `OCCURS 30`
pour pouvoir la parcourir par index — même bloc mémoire, deux lectures différentes.

```
Appel depuis MAJASSU :

  MOVE '002' TO WS-CODE-ERREUR
  CALL 'PGMERR' USING WS-CODE-ERREUR    ← code 3 chars en entrée
                      WS-LIBELLE-ERREUR ← libellé 60 chars en sortie

PGMERR parcourt la table (recherche séquentielle, 1 à 30) :
  → compare les 3 premiers chars de chaque entrée au code reçu
  → premier trouvé : retourne le libellé complet
  → aucun trouvé   : retourne 'ERREUR INCONNUE - CODE : XXX'

MAJASSU construit ensuite la ligne anomalie :
  STRING 'ERREUR : ' '002' ' - ' WS-LIBELLE-ERREUR INTO WS-ANO-TEXTE
  WRITE  WS-LIGNE-ANO → ETATANO
```

### Ce que MAJASSU utilise réellement

Sur 30 messages définis, **4 seulement sont appelés via PGMERR** — les anomalies métier :

| Code | Libellé | Déclencheur |
|------|---------|-------------|
| 001 | CODE MOUVEMENT INVALIDE | F-CODE ≠ C / M / S |
| 002 | CREATION SUR ENREGISTREMENT EXISTANT | WRITE sur clé existante |
| 003 | MISE A JOUR SUR ENREGISTREMENT INEXISTANT | REWRITE sur clé absente |
| 004 | SUPPRESSION SUR ENREGISTREMENT INEXISTANT | DELETE sur clé absente |

### Pourquoi 26 messages inutilisés ?

La table a été conçue pour deux usages :

- **Anomalies (001–004)** → via PGMERR → ETATANO — **implémenté**
- **Statistiques (005–018)** → libellés des compteurs (nb mouvements lus, nb créations...) — **abandonné**

Dans l'implémentation finale, les statistiques sont affichées avec des `DISPLAY`
écrits en dur dans `23000-AFFICHER-STATS`. PGMERR a été court-circuité pour tout
ce qui n'est pas une anomalie. Les messages 005–018 sont définis mais orphelins :
**une évolution de conception abandonnée à mi-chemin.**

### Bug latent sur les codes 012–015

Ces quatre entrées ont 6 espaces avant leur code dans la table :

```
'      012 - ANOMALIE DE CODE MOUVEMENT'   ← position 1:3 = '   ' (espaces)
```

Si MAJASSU appelait PGMERR avec `'012'`, la recherche comparerait des espaces
au lieu de `'012'` → jamais trouvé → retournerait `'ERREUR INCONNUE'`.

**Impact fonctionnel réel : zéro.** MAJASSU ne les appelle pas.
C'est un bug de données dans la table — sans effet en production.

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
