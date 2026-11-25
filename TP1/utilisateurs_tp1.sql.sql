-- =====================================================================
-- utilisateurs_tp1.sql — Comptes d'accès DISTANT à la base scolarite (TP1)
-- À exécuter sur VM1 (serveur de base de données) :  sudo mariadb < utilisateurs_tp1.sql
--
-- '192.168.56.%' = toute machine du réseau privé hôte (Windows, VM2).
-- Un compte MariaDB est le couple (utilisateur, machine d'origine) :
-- 'etudiant'@'localhost' et 'etudiant'@'192.168.56.%' sont DEUX comptes.
-- =====================================================================
DROP USER IF EXISTS 'etudiant'@'192.168.56.%';
DROP USER IF EXISTS 'secretariat'@'192.168.56.%';

-- Consultation seule
CREATE USER 'etudiant'@'192.168.56.%' IDENTIFIED BY 'Etudiant@2026';
GRANT SELECT ON scolarite.* TO 'etudiant'@'192.168.56.%';

-- Saisie des notes (lecture de toute la base, écriture sur la seule table note)
CREATE USER 'secretariat'@'192.168.56.%' IDENTIFIED BY 'Secretariat@2026';
GRANT SELECT ON scolarite.* TO 'secretariat'@'192.168.56.%';
GRANT INSERT, UPDATE ON scolarite.note TO 'secretariat'@'192.168.56.%';

FLUSH PRIVILEGES;
