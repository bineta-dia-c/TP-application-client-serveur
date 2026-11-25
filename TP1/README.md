\# TP1 — Le modèle client-serveur



\*\*Cours :\*\* Applications Client-Serveur et Web (ACSW)



\*\*Établissement :\*\* École Supérieure Polytechnique



\*\*Département :\*\* Génie Informatique



\*\*Année universitaire :\*\* 2026-2027



\*\*Binôme :\*\* Fatoumata Bineta Dia et Serigne Fallou Niane



\---



\## Partie 1 — Préparer le serveur (VM1)



\### Q1. Combien d'étudiants, d'EC et de notes contient la base ? Dessinez le schéma des quatre tables avec leurs clés primaires et étrangères.



La base contient 30 étudiants, 6 EC et 180 notes (voir Fig. 5). Le Schéma 1 ( se trouvant dans rapport\_TP1.pdf), établi à partir de la Fig. 6, résume la structure : la table etudiant a pour clé primaire matricule et une clé étrangère filiere vers filiere.code ; les tables ec et filiere ont pour clé primaire code ; la table note a pour clé primaire id et deux clés étrangères, matricule vers etudiant et ec vers ec.code. 6 Le couple (matricule, ec) est unique dans la table note : un étudiant n'a qu'une note par EC. Les clés étrangères permettent les jointures, comme celle de la Fig. 4. 





\### Q2. Dans cette session, le client mariadb et le serveur mariadbd tournent sur la même machine. Sont-ils pour autant le même programme ?



Non. Le serveur est le démon mariadbd, qui tourne en arrière-plan et détient les données. Le client mariadb est un programme séparé, lancé par l'utilisateur, qui envoie les requêtes. La Fig. 7 montre deux processus avec des PID différents. Ils sont sur la même machine mais restent deux programmes qui communiquent entre eux, ici par un socket local. 



\---



\## Partie 2 — Ouvrir le service au réseau



\### Q3. Que signifie le code d'erreur 10061 ?



Le code 10061 est l'erreur Windows « connexion refusée » : la machine a répondu, mais aucun programme n'accepte de connexion sur cette adresse et ce port. VM1 était donc joignable (voir le ping, Fig. 8). MariaDB fonctionnait aussi, puisqu'il écoutait déjà sur 127.0.0.1 (Fig. 10), mais il n'était pas à l'écoute sur l'adresse réseau 192.168.55.129. 



\### Q4. Quelle différence y a-t-il entre écouter sur 127.0.0.1 et sur 0.0.0.0 ?



L'adresse 127.0.0.1 est la boucle locale : le serveur n'accepte que les connexions venant de la machine elle-même. L'adresse 0.0.0.0 signifie « toutes les interfaces IPv4 » : le serveur accepte aussi les connexions arrivant par le réseau. Ubuntu choisit 127.0.0.1 par défaut pour réduire la surface d'attaque : une base de données ne doit pas être exposée tant que l'administrateur ne l'a pas décidé et sécurisé. 



\### Q5. Résultat de SELECT USER(), CURRENT\_USER()



Résultat relevé (Fig. 16) : USER() = etudiant@192.168.55.1, CURRENT\_USER() = etudiant@192.168.55.%. USER() est le compte que le client a annoncé, avec la machine d'où il vient (ici etudiant@192.168.55.1). CURRENT\_USER() est le compte du serveur qui correspond réellement à cette connexion et dont les droits s'appliquent (ici etudiant@192.168.55.%). Les deux peuvent différer, car un compte peut être défini avec un hôte générique. 



\### Q6. Avec quel compte Windows pourrait-il se connecter en tant que root depuis le réseau ?



La tentative échoue avec un message d'accès refusé (Fig. 18 : ERROR 1045 (28000) : Access denied for user 'root'@'192.168.55.1' (using password: YES)). Sur Ubuntu, root@localhost s'authentifie par le système (socket Unix) et n'est pas utilisable à distance. C'est une bonne chose : root a tous les droits, donc un compte exposé sur le réseau serait la cible première d'une attaque. Les clients distants utilisent des comptes limités. 



\---



\## Partie 3 — Plusieurs clients, un seul serveur



\### Q7. Sortie de PROCESSLIST et de ss



Les sorties sont présentées en Fig. 22 et Fig. 23. Client Windows : 192.168.55.1, port source 50337. Client VM2 : 192.168.55.128, port source 57152. Ces ports sont choisis par le système d'exploitation de chaque client, parmi des ports temporaires, au moment de la connexion. Ils sont différents de 3306 car 3306 est le port fixe du serveur. Le client n'a pas besoin d'un port connu, mais chaque connexion doit avoir un port source distinct pour que le serveur puisse distinguer les deux flux. 



\### Q8. Messages d'erreur et gestion des droits



Messages relevés : pour etudiant, ERROR 1142 (42000) : UPDATE command denied to user 'etudiant'@'192.168.55.1' for table `scolarite`.`note` ; pour secretariat, ERROR 1142 (42000) : DELETE command denied to user 'secretariat'@'192.168.55.128' for table `scolarite`.`note`. Les droits sont enregistrés côté serveur, dans les tables système de la base mysql, et c'est le serveur qui les vérifie à chaque requête. Le client ne peut donc pas les contourner. On en conclut que la sécurité d'un système client-serveur repose sur le serveur, qui ne doit jamais faire confiance au client. 



\### Q9. Cohérence des données



Oui, Windows lit la valeur 12 dès sa requête suivante (Fig. 27). Les données ne sont stockées qu'à un seul endroit, sur le serveur. Les clients n'en gardent aucune copie : chaque lecture interroge la même source. La centralisation garantit donc que tous les clients voient la même information. 



\---



\## Partie 4 — Un deuxième service : le serveur web



\### Q10. Requête du client et réponse du serveur



Dans la Fig. 30, les lignes commençant par > sont la requête du client, celles qui commencent par < sont la réponse du serveur. La première ligne de la requête est GET / HTTP/1.1 : la méthode, la ressource demandée et la version du protocole. Ses en-têtes sont Host (le serveur visé) et User-Agent (le logiciel client, ici curl). La première ligne de la réponse est HTTP/1.1 200 OK : la version et le code de statut. Ses en-têtes, comme Server et Content-Type, décrivent le serveur (Apache) et le type du contenu (html). Le corps de la page suit les entêtes. 



\### Q11. Informations enregistrées dans access.log



Pour chaque requête (Fig. 31), Apache enregistre l'adresse IP du client (192.168.55.1 pour Windows, 192.168.55.128 pour VM2), la date et l'heure, la requête (GET / HTTP/1.1), le code de réponse (200), la taille envoyée et le User-Agent. Ce dernier distingue le navigateur de Windows (Chrome) de curl sur VM2 (curl/8.5.0). La ligne favicon.ico (code 404) est une requête automatique du navigateur. 



\### Q12. Acheminement des segments TCP



Le système d'exploitation de VM1 regarde le port de destination du segment. Chaque serveur s'est déclaré à l'écoute d'un port : 3306 pour mariadbd, 80 pour apache2 (Fig. 28). Le segment est remis au programme qui possède ce port. Le client doit connaître l'adresse pour joindre la bonne machine et le port pour joindre le bon service sur cette machine. C'est lui qui prend l'initiative, et le serveur n'a aucun moyen de le deviner. C'est pourquoi les services courants ont des ports connus (80 pour HTTP, 3306 pour MariaDB). 



\### Q13. Comparaison MariaDB et HTTP



Connexion persistante (MariaDB) : l'avantage est que le contexte reste en mémoire (utilisateur authentifié, transaction en cours), sans se ré-identifier à chaque requête. L'inconvénient est qu'une connexion ouverte occupe des ressources du serveur, même quand le client ne fait rien. Requêtes indépendantes (HTTP) : l'avantage est un serveur plus léger, qui peut servir beaucoup de clients et qui n'est pas affecté par un client qui disparaît. L'inconvénient est que le serveur ne se souvient de rien entre deux requêtes. Un site web « se souvient » grâce à un identifiant de session, transmis dans un cookie à chaque requête : le serveur retrouve ainsi l'utilisateur et son contexte. 



\---



\## Partie 5 — Les limites du modèle



\### Q14. Arrêt du serveur



Windows reçoit ERROR 2002 (HY000) : Can't connect to server on '192.168.55.129' (10061) et VM2 reçoit ERROR 2002 (HY000) : Can't connect to server on '192.168.55.129' (115) : dans les deux cas, la connexion échoue parce que plus aucun programme n'écoute sur le port 3306 (les codes diffèrent seulement parce qu'ils dépendent du système du client). Les deux clients sont touchés, et tous les clients le seraient. Ce défaut d'architecture s'appelle le point unique de défaillance (SPOF, single point of failure) : toute la base dépend d'un seul serveur. 



\### Q15. Analyse de la capture réseau



Dans la capture (Fig. 38 et Fig. 39), on retrouve le nom du compte (etudiant), le texte de la requête SQL et les données de la réponse, tous lisibles en clair. Pour le mot de passe : il n'apparaît pas en clair : on voit seulement le nom du plugin d'authentification mysql\_native\_password, le mot de passe étant remplacé par une valeur calculée avec un défi du serveur. Nous avons utilisé l'option --skip-ssl du client, donc aucune couche TLS ne protège le reste de l'échange. Même ainsi, les données restent visibles pour quiconque écoute le réseau. Pour protéger ces échanges, on active le chiffrement TLS entre le client et MariaDB, ou on passe par un tunnel SSH ou un VPN. 



\---

&#x20;





\### Q16. Définition du modèle client-serveur



Le modèle client-serveur repose sur deux types de programmes. Le serveur est un programme qui attend des demandes sur un port connu d'une machine connue : dans ce TP, mariadbd sur le port 3306 et apache2 sur le port 80 de VM1. Les clients, comme mariadb, le navigateur ou curl, prennent l'initiative de se connecter, envoient une requête et attendent la réponse. Le serveur détient les données et décide des droits : nous l'avons vu avec les comptes etudiant et secretariat, dont les droits sont vérifiés côté serveur. Plusieurs clients peuvent être servis en même temps, comme le montre PROCESSLIST, et ils ne communiquent jamais entre eux : ils passent toujours par le serveur. Deux protocoles ont été comparés : MariaDB garde une connexion ouverte pendant la session, HTTP traite chaque requête de façon indépendante. Avantages : les données sont centralisées, donc cohérentes pour tous les clients (la note modifiée par VM2 est vue tout de suite par Windows) ; les droits et la sécurité sont gérés à un seul endroit, le serveur. Inconvénients : le serveur est un point unique de défaillance, car son arrêt a privé tous les clients de service ; le trafic circule en clair sur le réseau, ce qui exige un chiffrement (TLS, tunnel SSH ou VPN) pour protéger les données. 

