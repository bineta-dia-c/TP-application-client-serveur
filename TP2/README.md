# TP 2 — Architectures 2-tiers et 3-tiers comparées

**UCAD — École Supérieure Polytechnique de Dakar — Département Génie Informatique**
Applications Client-Serveur et Web (ACSW) — Licence 2 Réseaux et Télécommunications
Enseignant : Dr Keba GUEYE — Année universitaire 2026-2027

Réalisé par : **Serigne Fallou NIANE** et **Fatoumata Bineta DIA**

> Les valeurs mesurées (moyennes, nombre d'admis, octets, temps) dépendent de nos captures et sont signalées par `À COMPLÉTER`. Toutes les autres réponses sont rédigées.

---

## Sommaire

1. [Environnement](#1-environnement)
2. [Partie 1 — 2-tiers (client lourd) : Q1 à Q3](#2-partie-1--lapplication-en-2-tiers-client-lourd)
3. [Partie 2 — 3-tiers : Q4 à Q8](#3-partie-2--la-même-application-en-3-tiers)
4. [Partie 3 — Évolution d'une règle métier : Q9 à Q11](#4-partie-3--faire-évoluer-une-règle-métier)
5. [Partie 4 — Volume et réseau : Q12, Q13](#5-partie-4--volume-de-données-et-réseau)
6. [Partie 5 — Sécurité : Q14, Q15](#6-partie-5--sécurité--fermer-laccès-direct-à-la-base)
7. [Synthèse et Q16](#7-synthèse)
8. [Annexe — IP fixe des VM](#annexe--adresse-ip-fixe-des-vm)

---

## 1. Environnement

Une application se décompose en trois couches logiques : **présentation** (ce que voit l'utilisateur), **logique métier** (moyenne pondérée, décision admis/ajourné, classement) et **données** (stockage dans MariaDB).

| Architecture | Tier 1 : poste client | Tier 2 | Tier 3 |
|---|---|---|---|
| 2-tiers (client lourd) | Présentation + logique métier | Serveur de données (MariaDB) | — |
| 3-tiers | Présentation seule (navigateur) | Serveur d'application (Apache + PHP) | Serveur de données (MariaDB) |

### Machines

| Machine | Adresse | Système | Rôle |
|---|---|---|---|
| Hôte Windows | 192.168.56.1 | Windows + VirtualBox | Tier 1 : `client_lourd.py` (2-tiers), puis navigateur (3-tiers) |
| VM1 | 192.168.56.11 | Ubuntu Server 24.04 LTS | Serveur de données MariaDB (base `scolarite`) |
| VM2 | 192.168.56.12 | Ubuntu Server 24.04 LTS | Serveur d'application Apache + PHP, et second poste client en 2-tiers |

Chaque VM a une carte NAT (Internet) et une carte réseau privé hôte sur `192.168.56.0/24`. VM1 avait reçu `192.168.56.101` par DHCP ; nous lui avons attribué l'adresse fixe `192.168.56.11` (voir l'annexe).

### Les deux architectures du TP

```
2-tiers :
  [Windows ou VM2]                         [VM1 192.168.56.11]
  client_lourd.py  ⇄── SQL, port 3306 ──⇄  MariaDB
  (présentation + logique métier)          (données)

3-tiers :
  [Windows]                    [VM2 192.168.56.12]                     [VM1 192.168.56.11]
  Navigateur ⇄─ HTTP, port 80 ─⇄ Apache + PHP ⇄─ SQL, port 3306 ─⇄ MariaDB
  (présentation)               (logique métier)                       (données)
```

### Fichiers utilisés

| Fichier | Rôle | Machine |
|---|---|---|
| `client_lourd.py` | Client lourd Python (2-tiers) | Windows + VM2 |
| `inc/config.php` | Paramètres de connexion à la base | VM2 |
| `inc/metier.php` | Règles de gestion et requêtes SQL | VM2 |
| `inc/gabarit.php` | Gabarit HTML commun | VM2 |
| `index.php`, `releve.php`, `classement.php` | Une page par écran | VM2 |
| `utilisateurs_tp2.sql` | Création du compte `app_scolarite` | VM1 |
| `volume.sql` / `volume_annuler.sql` | Ajout / retrait des données de volume | VM1 |

---

## 2. Partie 1 — L'application en 2-tiers (client lourd)

### Manipulations

```powershell
# Windows
py -m pip install pymysql
py client_lourd.py        # liste, relevé de ESP260001, classement
```

```bash
# VM2 (second poste client)
sudo apt install python3-pymysql
python3 client_lourd.py
```

### Q1. Présentation, logique métier et accès aux données dans `client_lourd.py`

Les trois couches sont mélangées dans un seul programme :

| Couche | Ce qu'on trouve dans le code |
|---|---|
| **Présentation** | Le menu, les `input()` qui demandent le choix ou le matricule, les `print()` qui affichent la liste, le relevé et le classement. |
| **Logique métier** | Le calcul de la moyenne pondérée par les crédits (`Σ note × crédit / Σ crédits`), la décision admis / ajourné (moyenne ≥ 10), le tri pour le classement et le décompte des admis. |
| **Accès aux données** | La constante `SERVEUR_BDD`, l'identifiant et le mot de passe, `pymysql.connect(...)`, les requêtes SQL, `cursor.execute(...)` et `fetchall()`. |

**Toutes ces lignes s'exécutent sur le poste client** (Windows ou VM2). Le serveur VM1 ne fait que stocker les données et renvoyer les lignes demandées.

### Q2. Ce qu'obtient un étudiant qui récupère `client_lourd.py`

Le fichier contient en clair tout ce qu'il faut pour se connecter à la base :
- l'adresse du serveur (`192.168.56.11`) et le port `3306` ;
- le nom de la base (`scolarite`) ;
- le nom du compte et **son mot de passe** ;
- la structure des tables (noms des tables et colonnes visibles dans les requêtes SQL).

En dehors du programme, il peut se connecter directement à MariaDB avec un autre outil (client `mariadb`, DBeaver, un script Python) et exécuter **n'importe quelle requête autorisée pour ce compte** : lire les notes de tous les étudiants et, si le compte a les droits d'écriture, modifier ses propres notes. Les règles de gestion du programme ne le protègent plus du tout.

### Q3. Installation sur les 300 postes d'une salle

Sur **chacun** des 300 postes :
1. l'interpréteur Python 3 ;
2. le module `pymysql` ;
3. le fichier `client_lourd.py`, configuré avec l'adresse du serveur ;
4. un accès réseau du poste vers VM1 sur le port 3306.

Et chaque nouvelle version du programme devra être recopiée sur les 300 postes.

---

## 3. Partie 2 — La même application en 3-tiers

### Manipulations

```bash
# VM2 : serveur web + PHP, puis copie de l'application
sudo apt install apache2 php libapache2-mod-php php-mysql
sudo cp -r tp2/app3tiers /var/www/html/scolarite

# VM1 : compte de l'application
sudo mariadb < tp2/utilisateurs_tp2.sql
```

Le script crée le compte `app_scolarite@'192.168.56.12'` : il ne peut se connecter **que depuis VM2**, le serveur d'application.

Sur Windows : ouverture de `http://192.168.56.12/scolarite/`, du relevé de ESP260001 et du classement, puis :

```powershell
curl.exe -i http://192.168.56.12/scolarite/inc/config.php
```

### Q4. Même moyenne pour ESP260001 et même nombre d'admis ?

| Résultat | 2-tiers (client lourd) | 3-tiers (web) |
|---|---|---|
| Moyenne de ESP260001 | `À COMPLÉTER` | `À COMPLÉTER` (identique) |
| Décision ESP260001 | `À COMPLÉTER` | `À COMPLÉTER` (identique) |
| Nombre d'admis | `À COMPLÉTER` | `À COMPLÉTER` (identique) |

**Oui**, les deux architectures donnent exactement les mêmes résultats : elles lisent les mêmes données et appliquent la même règle (version 1.0).

C'est indispensable pour l'expérience : on veut que **seule l'architecture varie**. Si les résultats différaient, on ne pourrait plus savoir si un écart de temps, de volume ou de comportement vient de l'architecture ou d'un calcul différent ; la comparaison n'aurait plus de sens.

### Q5. Installation nécessaire sur le poste Windows en 3-tiers

**Rien** : le navigateur web déjà présent suffit. Ni Python, ni pilote, ni programme à copier.

Comparaison avec Q3 : pour 300 postes, l'installation est **nulle** en 3-tiers, contre quatre éléments par poste en 2-tiers. Tout est installé **une seule fois, sur VM2**.

### Q6. Ce que renvoie la requête vers `config.php`

Le serveur répond `HTTP/1.1 200 OK` avec un **corps vide** (`Content-Length: 0`). Réponse exacte observée : `À COMPLÉTER selon la capture`.

**Pourquoi le mot de passe n'est jamais envoyé :** Apache ne renvoie jamais le texte source d'un fichier `.php`. Il le confie à l'interpréteur PHP, qui l'**exécute sur VM2**. `config.php` ne fait que définir des constantes (hôte, base, compte, mot de passe) sans rien afficher (aucun `echo`), donc son exécution ne produit aucun texte. Le navigateur ne reçoit que ce que PHP affiche : le mot de passe reste sur le serveur.

### Q7. Nombre de comptes MariaDB nécessaires

- **3-tiers : un seul compte**, `app_scolarite@'192.168.56.12'`, quel que soit le nombre d'utilisateurs. Seul le serveur d'application parle à la base ; les utilisateurs se connectent à l'application web, pas à MariaDB.
- **2-tiers :** chaque poste se connecte lui-même à la base. Il faut :
  - soit **un compte par utilisateur** (300 comptes à créer et gérer) ;
  - soit **un compte partagé**, dont le mot de passe est copié sur tous les postes et qui doit être autorisé depuis toutes les adresses clientes (par exemple `'192.168.56.%'`).

### Q8. Code source de la page (Ctrl+U)

On ne trouve **aucune trace de SQL ni de la règle de calcul**. Le navigateur reçoit uniquement du **HTML (et du CSS)** contenant les résultats déjà calculés : noms, notes, moyenne et décision, mis en forme par `gabarit.php`. La logique métier et l'accès aux données sont restés sur VM2.

---

## 4. Partie 3 — Faire évoluer une règle métier

**Nouvelle règle (version 1.1) :** une note strictement inférieure à 8 dans un EC empêche la validation, quelle que soit la moyenne (`NOTE_ELIMINATOIRE = 8`).

### Modification en 2-tiers (VM2 seulement)

Dans `client_lourd.py` sur VM2 : ajout de la constante, modification de la décision dans le relevé **et** dans le décompte des admis, `VERSION = "1.1"`. Le poste Windows garde la v1.0, comme un poste non mis à jour.

```python
VERSION = "1.1"
NOTE_ELIMINATOIRE = 8

admis = moyenne >= 10 and min(notes) >= NOTE_ELIMINATOIRE
```

### Modification en 3-tiers

Dans `/var/www/html/scolarite/inc/metier.php` sur VM2 : ajout de la constante, modification du relevé et du classement, `VERSION_APPLI = '1.1'`.

```php
const VERSION_APPLI = '1.1';
const NOTE_ELIMINATOIRE = 8;

// Dans la requête du classement, on récupère aussi la plus petite note :
//   SELECT ..., SUM(n.note * e.credits) / SUM(e.credits) AS moyenne,
//               MIN(n.note) AS note_min ...
// Puis :
$admis = ($ligne['moyenne'] >= 10 && $ligne['note_min'] >= NOTE_ELIMINATOIRE);
```

### Q9. Décision pour ESP260011 et nombre d'admis en 2-tiers

| Résultat (2-tiers) | Windows (v1.0) | VM2 (v1.1) |
|---|---|---|
| Moyenne de ESP260011 | `À COMPLÉTER` | `À COMPLÉTER` (identique) |
| Décision ESP260011 | **Admis** | **Ajourné** |
| Nombre d'admis | `À COMPLÉTER` | `À COMPLÉTER` (plus faible) |

ESP260011 a une moyenne ≥ 10 mais au moins une note < 8. Le poste Windows (v1.0) le déclare admis, VM2 (v1.1) le déclare ajourné.

**Constat :** la **même base** donne **deux résultats différents** selon le poste utilisé.

**Conséquences réelles pour un service de scolarité :**
- des relevés contradictoires pour un même étudiant ;
- des délibérations et des listes d'admis fausses ;
- des contestations, voire des recours ;
- une perte de confiance dans les documents officiels ;
- l'obligation de vérifier la version de chaque poste avant chaque édition.

### Q10. Fichiers et machines modifiés en 3-tiers

**Un seul fichier** (`metier.php`) sur **une seule machine** (VM2). **Tous les utilisateurs** ont bénéficié de la nouvelle règle **immédiatement**, au prochain chargement de la page, sans aucune intervention sur les postes clients. Windows et VM2 affichent le même résultat.

### Q11. Où intervenir pour la règle éliminatoire ?

- **2-tiers :** la moyenne est calculée en Python sur le poste. La règle est ajoutée dans le code Python (décision du relevé et décompte des admis), en utilisant les notes déjà reçues (`min(notes)`). Il faudrait refaire cette modification **sur chaque poste**.
- **3-tiers :** la moyenne est calculée par le SGBD (`SUM(note × crédit) / SUM(crédit)`) ; PHP ne reçoit que la moyenne, pas les notes individuelles. Il a donc fallu **modifier la requête SQL** dans `metier.php` pour récupérer aussi la plus petite note (`MIN(note)`), puis appliquer la condition en PHP.

Dans les deux cas, la modification reste dans la logique métier ; mais en 3-tiers elle se fait **une seule fois, côté serveur**.

---

## 5. Partie 4 — Volume de données et réseau

```bash
# VM1 : ajout de 20 000 étudiants fictifs et 120 000 notes
sudo mariadb scolarite < tp2/volume.sql
# ... mesures ...
sudo mariadb scolarite < tp2/volume_annuler.sql   # retour à l'état initial
```

Mesure 2-tiers : valeurs affichées par le client lourd (lignes, `Bytes_sent`, temps). Mesure 3-tiers : outils développeur du navigateur (F12, onglet Réseau : taille transférée et temps).

### Q12. Tableau des mesures et analyse

| Mesure | 2-tiers | 3-tiers |
|---|---|---|
| Lignes ou octets reçus par le poste client | `À COMPLÉTER` (≈ 120 000 lignes, plusieurs Mo) | `À COMPLÉTER` (taille de la page HTML) |
| Temps de calcul du classement | `À COMPLÉTER` | `À COMPLÉTER` |
| Machine qui a effectué le calcul | Le poste client (Python) | VM1 (le SGBD), à la demande de VM2 |

**Origine de l'écart :** en 2-tiers, le client lourd doit recevoir **toutes les notes brutes** (de l'ordre de 120 000 lignes) pour calculer lui-même les moyennes et le classement. En 3-tiers, le calcul est fait côté serveur (agrégation SQL sur VM1) et le navigateur ne reçoit que la **page HTML finale**. Le volume reçu par le client est donc beaucoup plus faible en 3-tiers.

**Pour 300 postes reliés par une liaison à 10 Mbit/s :** le trafic est multiplié par 300 et partage la même liaison.

```
temps ≈ (300 × volume par poste en Mo × 8) / 10   secondes
```

Exemple avec 5 Mo par poste (valeur d'illustration) : 300 × 5 × 8 / 10 = **1 200 s, soit 20 minutes** de liaison saturée pour un seul affichage du classement par chaque poste. Avec notre valeur mesurée : `À COMPLÉTER`.

**Sur une connexion mobile :** le client lourd serait très lent et consommerait beaucoup de données (forfait), alors que la version web ne transfère que quelques pages légères.

### Q13. Que mesure `Bytes_sent` ?

`Bytes_sent` est un compteur de MariaDB qui donne le **nombre d'octets envoyés par le serveur au client sur la connexion** (variable de session, lue avec `SHOW SESSION STATUS LIKE 'Bytes_sent'`). La différence entre la valeur lue avant et après la requête donne le nombre d'octets transmis pour cette requête (à la petite réponse du premier `SHOW STATUS` près, négligeable).

**C'est une mesure honnête** car elle compte le **trafic réel au niveau du serveur, protocole compris** : en-têtes des paquets, description des colonnes et toutes les lignes, et pas seulement le nombre de lignes ou la taille des données « utiles ». Elle ne dépend pas de la façon dont le client affiche ou stocke les résultats.

---

## 6. Partie 5 — Sécurité : fermer l'accès direct à la base

Sur VM1, le port 3306 n'est autorisé que depuis VM2 :

```bash
sudo ufw allow OpenSSH          # d'abord SSH, pour ne pas perdre l'accès à la VM
sudo ufw allow 80/tcp
sudo ufw allow from 192.168.56.12 to any port 3306 proto tcp
sudo ufw deny 3306/tcp
sudo ufw enable && sudo ufw status numbered
```

L'ordre compte : ufw applique **la première règle qui correspond**, donc l'autorisation de VM2 doit précéder le refus général.

### Q14. Que se passe-t-il pour chaque architecture ?

| Architecture | Résultat |
|---|---|
| **2-tiers (Windows)** | Échec : le client ne peut plus joindre MariaDB, erreur du type `2003 (HY000): Can't connect to MySQL server on '192.168.56.11'` (connexion expirée ou refusée). Résultat observé : `À COMPLÉTER` |
| **3-tiers (navigateur Windows)** | L'application fonctionne normalement : le navigateur parle à VM2 sur le port 80, et seul VM2 parle à VM1 sur le port 3306, ce qui est autorisé. |

**Pourquoi on ne peut pas appliquer cette protection en 2-tiers :** chaque poste client doit joindre **directement** le port 3306 de VM1. Fermer ce port aux postes revient à arrêter l'application. Il faudrait au contraire l'ouvrir à toutes les machines du réseau, ce qui expose la base à tous.

### Q15. Deux autres risques propres au client lourd

| Risque du client lourd | Explication | Réponse du 3-tiers |
|---|---|---|
| Mot de passe et SQL en clair dans le programme distribué | Toute personne qui copie `client_lourd.py` obtient les identifiants et peut interroger la base directement. | Les identifiants sont dans `config.php`, sur VM2 uniquement ; le navigateur ne les reçoit jamais. |
| Règles métier modifiables sur le poste | L'utilisateur peut modifier le script pour contourner une règle ou exécuter d'autres requêtes. | Les règles s'exécutent sur le serveur ; l'utilisateur n'envoie que des paramètres (matricule, page). |
| Trafic SQL non chiffré sur tout le réseau | Les notes et identifiants circulent en clair entre chaque poste et VM1 (capturables avec Wireshark). | Le SQL ne circule qu'entre VM2 et VM1 ; côté client on peut activer HTTPS. |

**Après le TP :** retour à l'état du TP 1 en supprimant les deux dernières règles (`sudo ufw status numbered`, puis `sudo ufw delete <numéro>`) ou en désactivant le pare-feu (`sudo ufw disable`).

---

## 7. Synthèse

| Critère | 2-tiers | 3-tiers |
|---|---|---|
| Logiciel à installer sur chaque poste | Python, pymysql, `client_lourd.py` configuré | Aucun (navigateur déjà présent) |
| Déploiement d'une nouvelle règle | Sur chaque poste, un par un | Un seul fichier sur le serveur d'application |
| Cohérence entre utilisateurs | Non garantie : versions différentes selon les postes | Garantie : tout le monde utilise la même version |
| Trafic réseau côté client | Élevé : toutes les données brutes | Faible : seulement la page de résultat |
| Exposition du SGBD et des mots de passe | Port 3306 ouvert à tous les postes, mot de passe dans le programme | Port 3306 ouvert à VM2 seulement, mot de passe sur le serveur |
| Charge des serveurs | Faible : les postes font les calculs | Plus élevée : calculs côté serveur (à dimensionner) |
| Simplicité de développement | Plus simple : un seul programme, pas de serveur web | Plus de composants (Apache, PHP, HTML), mais code mieux séparé |

### Q16. Quand le 2-tiers reste-t-il acceptable ?

Le 2-tiers reste acceptable lorsque :
- le **nombre de postes est faible et connu** (une caisse de boutique, un poste de saisie de laboratoire) ;
- le **réseau est local et de confiance**, sans accès depuis l'extérieur ;
- les **utilisateurs sont peu nombreux et contrôlés** (par exemple l'administrateur de la base avec son outil d'administration) ;
- les **règles changent rarement** et la mise à jour des postes est facile ;
- on a besoin d'une **interface très réactive** ou de **fonctions propres au poste** (imprimante de tickets, lecteur de code-barres, fonctionnement hors ligne).

**Pour un service de scolarité utilisé par toute l'université, le 3-tiers s'impose :**
- des **milliers d'utilisateurs** sur des postes variés (salles, bureaux, téléphones) : rien à installer ;
- des **règles de délibération identiques pour tous** et appliquées au même moment : une seule copie de la logique métier ;
- des **données sensibles** (notes) qui ne doivent pas être exposées : la base reste derrière le serveur d'application, le port 3306 est fermé aux clients ;
- des **accès depuis des connexions lentes** : seules les pages de résultat circulent.

---

## Conclusion

Ce TP montre que le choix d'architecture **ne change pas ce que fait l'application, mais où elle s'exécute** — et donc son déploiement, sa cohérence, son trafic réseau et sa sécurité. Le 2-tiers est simple mais difficile à maintenir et à sécuriser à grande échelle ; le 3-tiers demande un serveur de plus, mais centralise les règles, réduit le trafic côté client et permet de fermer l'accès direct à la base.

---

## Annexe — Adresse IP fixe des VM

VM1 avait reçu `192.168.56.101` par DHCP. Pour lui donner l'adresse fixe `192.168.56.11` sur la carte réseau privé hôte (`enp0s8`), création de `/etc/netplan/60-hostonly.yaml` :

```yaml
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: false
      addresses: [192.168.56.11/24]
```

```bash
sudo chmod 600 /etc/netplan/60-hostonly.yaml
sudo netplan apply
ip -br address
```

Même procédure sur VM2 avec `192.168.56.12/24`.

Pour que MariaDB accepte les connexions réseau, `bind-address` doit valoir `0.0.0.0` dans `/etc/mysql/mariadb.conf.d/50-server.cnf` (réglage fait au TP 1), puis :

```bash
sudo systemctl restart mariadb
```
