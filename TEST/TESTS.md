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
