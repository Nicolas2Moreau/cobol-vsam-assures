# TSTASSU — Comment fonctionnent les tests

## Principe

TSTASSU est un programme COBOL unique qui teste les deux accesseurs.
On lui dit lequel tester via le PARM JCL :

```
PARM='PGMVSAM'  →  teste l'accesseur VSAM
PARM='PGMDB2'   →  teste l'accesseur DB2
```

Le programme exécute 12 tests dans l'ordre, affiche une ligne par test,
et donne un verdict final OK/KO.

---

## Structure d'un test

Chaque test fait toujours trois choses :

```
1. Appeler l'accesseur
   CALL WS-NOM-ACCSR USING WS-COM
   → l'accesseur écrit son code retour dans WS-RETOUR

2. Déclarer ce qu'on attend
   MOVE 00 TO WS-RC-ATT   ← le témoin, écrit en dur

3. Comparer
   PERFORM CHECK-RC        ← WS-RETOUR vs WS-RC-ATT → OK ou KO
```

---

## Le témoin : déclaratif, pas calculé

Il n'y a pas de fichier de référence externe. Le développeur écrit simplement
ce que l'accesseur **doit** retourner dans chaque situation, parce que chaque
cas est déterministe à 100% :

| Test | Situation | Attendu | Pourquoi c'est certain |
|------|-----------|---------|------------------------|
| T01 | OPEN | 00 | toujours OK par définition |
| T02 | WRITE matricule 999999 | 00 | clé neuve, forcément OK |
| T03 | WRITE même matricule encore | 02 | vient d'être créé en T02 |
| T04 | READ 999999 | 00 | vient d'être créé en T02 |
| T05 | REWRITE 999999 | 00 | existe, forcément modifiable |
| T06 | READ 999999 post-modif | 00 | toujours là après un REWRITE |
| T07 | READ clé '000000' | 01 | n'existe pas et n'existera jamais |
| T08 | DELETE 999999 | 00 | existe encore, forcément supprimable |
| T09 | READ 999999 post-delete | 01 | vient d'être supprimé en T08 |
| T10 | STARTBR | 00 | des enreg existent en prod |
| T11 | READNEXT | 00 | idem |
| T12 | CLOSE | 00 | toujours OK par définition |

---

## Les données de test

Deux enregistrements sont définis en dur dans le working-storage :

- **WS-ENREG-T1** : matricule 999999, prime 100.00, BM=B, taux=10
- **WS-ENREG-T2** : matricule 999999, prime 200.00, BM=M, taux=20 *(version modifiée)*

Le matricule `999999` est choisi exprès car inexistant en production.
À la fin des tests (T08), il est supprimé — le KSDS et la table DB2
se retrouvent dans le même état qu'avant.

---

## Lancer les tests

```
JTSTVSM.jcl  →  compile TSTASSU + exécute avec PGMVSAM (DD ASSURES + MVTS requis)
JTSTDB2.jcl  →  compile TSTASSU + exécute avec PGMDB2  (sous IKJEFT01, pas de DD fichier)
```

## Sortie attendue

```
* TSTASSU - ACCESSEUR : PGMVSAM
*-----------------------------------------*
T01  OPEN ASSURES3              RC=00 ATT=00 OK
T02  WRITE 999999 (creation)    RC=00 ATT=00 OK
T03  WRITE 999999 (duplicate)   RC=02 ATT=02 OK
...
T12  CLOSE ASSURES3             RC=00 ATT=00 OK
*-----------------------------------------*
* TOTAL OK :  12
* TOTAL KO :   0
* VERDICT  : TOUS LES TESTS PASSENT
*-----------------------------------------*
```

Si les deux JCL donnent 12 OK / 0 KO, les deux accesseurs sont isométriques.

---

## Proposition V3 — Tests unitaires

Les tests actuels (TSTASSU) sont des **tests d'intégration** : ils nécessitent
un vrai cluster VSAM et une vraie table DB2 pour tourner.

Une V3 pourrait ajouter de vrais **tests unitaires** qui tournent sans
aucune ressource externe :

**1. Tester les mappers isolément**
Les paragraphes `MAPPER-FILE-STATUS` (V1) et `MAPPER-READ/WRITE/FETCH/OPEN`
(V2) sont de la logique pure — pas de fichier, pas de SQL. Un programme
dédié pourrait injecter directement un file-status ou un SQLCODE et vérifier
le code retour produit, sans jamais ouvrir un fichier.

**2. Tester MAJASSV2 avec un accesseur stub**
Remplacer PGMVSAM/PGMDB2 par un **faux accesseur** (stub) qui retourne
des codes retour prédéfinis. On pourrait alors tester toute la logique
métier de MAJASSV2 (gestion C/M/S, compteurs, anomalies) sans toucher
au VSAM ni à DB2.

**Outillage possible :** COBOL Check ou zUnit (IBM) — frameworks de test
unitaire COBOL, non disponibles dans l'environnement actuel mais standard
en contexte professionnel mainframe.

---

## Perspectives de modernisation — Proposition V3

Dans les grandes entreprises aujourd'hui, le COBOL mainframe se modernise
selon deux grandes approches.

La première est **l'étranglement progressif** (*Strangler Fig Pattern*) : on
n'arrache pas le COBOL, on l'entoure progressivement de services modernes
(APIs REST, microservices) qui absorbent chaque fonction métier une par une,
jusqu'à ce que le mainframe ne soit plus qu'un résidu. C'est la voie d'IBM,
Accenture, et la plupart des grandes banques — prudente, longue, coûteuse.

La seconde approche, plus récente, consiste à **ne pas toucher au COBOL mais
à ses données** : exposer les fichiers VSAM et tables DB2 via des pipelines
modernes, les rendre consommables proprement par des LLM ou outils d'analyse.
L'IA ne remplace pas le COBOL — elle se branche dessus et l'augmente.

**Dans notre contexte, une V3 cohérente ressemblerait à :**

Un workflow GitHub Actions qui se déclenche à chaque push sur `dev` ou `main` :

1. **Compilation GnuCOBOL automatique** — valide que le code source reste
   compilable hors mainframe à tout moment
2. **Lancement du golden file test** — garantit qu'aucune modification n'a
   cassé le comportement de référence
3. **Rapport de compatibilité** — si ça passe, le code est garanti testable
   sans mainframe

Le tout encadré par des **règles strictes pour les IA** (dans `CLAUDE.md` ou
équivalent) : colonnes COBOL respectées, pas de syntaxe spécifique z/OS dans
le code partagé, conventions de nommage imposées. Cela garantit que les
modifications générées ou assistées par IA restent automatiquement compatibles
GnuCOBOL — et donc testables en CI sans aucune infrastructure mainframe.

L'idée : le mainframe reste la référence d'exécution, GnuCOBOL devient le
**filet de sécurité automatisé** à chaque modification.
