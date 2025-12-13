-- =======================================================
--  BASE DE DONNÉES DU PROJET PAPERS PLEASE
--  Auteur : Toi + binôme
--  Base : MySQL
-- =======================================================

CREATE DATABASE IF NOT EXISTS grestin_db;
USE grestin_db;

-- =======================================================
-- TABLE IMMIGRANTS
-- =======================================================

CREATE TABLE immigrants (
    immigrant_id VARCHAR(50) PRIMARY KEY,
    nom VARCHAR(100),
    prenom VARCHAR(100),
    pays_origine VARCHAR(100),
    raison_visite VARCHAR(200),
    duree_sejour VARCHAR(50),
    taille_cm INT,
    poids_kg INT,
    fichier_txt VARCHAR(255),
    fichier_pdf VARCHAR(255),
    statut VARCHAR(20) DEFAULT 'en_attente',
    date_depot TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =======================================================
-- TABLE DES INSPECTEURS (optionnel mais utile)
-- =======================================================

CREATE TABLE inspecteurs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100),
    prenom VARCHAR(100),
    grade VARCHAR(50)
);

-- =======================================================
-- TABLE LOGS (pour traçabilité décision)
-- =======================================================

CREATE TABLE decisions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    immigrant_id VARCHAR(50),
    inspecteur_id INT,
    decision VARCHAR(20),
    date_decision TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    commentaire TEXT,
    FOREIGN KEY (immigrant_id) REFERENCES immigrants(immigrant_id),
    FOREIGN KEY (inspecteur_id) REFERENCES inspecteurs(id)
);

-- =======================================================
-- EXEMPLES D'INSERTIONS
-- =======================================================

INSERT INTO immigrants 
(immigrant_id, nom, prenom, pays_origine, raison_visite, duree_sejour, taille_cm, poids_kg, fichier_txt, fichier_pdf, statut)
VALUES
('ARST-0001', 'Ivanov', 'Piotr', 'Kolechia', 'Travail', '30 jours', 180, 75, '/docs/ARST-0001/info.txt', '/docs/ARST-0001/passport.pdf', 'en_attente'),
('ARST-0002', 'Garcia', 'Luis', 'Republia', 'Tourisme', '14 jours', 172, 68, '/docs/ARST-0002/info.txt', '/docs/ARST-0002/passport.pdf', 'en_attente'),
('ARST-0003', 'Petrova', 'Anna', 'Impor', 'Visite familiale', '2 semaines', 165, 55, '/docs/ARST-0003/info.txt', '/docs/ARST-0003/passport.pdf', 'en_attente'),
('ARST-0004', 'Kovacs', 'Milan', 'United Federation', 'Études', '90 jours', 178, 82, '/docs/ARST-0004/info.txt', '/docs/ARST-0004/passport.pdf', 'en_attente'),
('ARST-0005', 'Santos', 'Maria', 'Republia', 'Tourisme', '7 jours', 160, 60, '/docs/ARST-0005/info.txt', '/docs/ARST-0005/passport.pdf', 'en_attente'),
('ARST-0006', 'Markov', 'Ivan', 'Kolechia', '', '15 jours', 185, 40, '/docs/ARST-0006/info.txt', '/docs/ARST-0006/passport.pdf', 'en_attente');

INSERT INTO inspecteurs (nom, prenom, grade)
VALUES
('Stefanov', 'Gregor', 'Inspecteur Senior'),
('Meyer', 'Elisa', 'Inspectrice Adjointe'),
('Orlov', 'Sergueï', 'Inspecteur Stagiaire');

INSERT INTO decisions (immigrant_id, inspecteur_id, decision, commentaire)
VALUES
('ARST-0001', 1, 'accepte', 'Documents conformes.'),
('ARST-0002', 2, 'refuse', 'Durée de séjour incohérente.'),
('ARST-0003', 1, 'accepte', 'Raison de visite valide.'),
('ARST-0004', 2, 'refuse', 'Taille déclarée incorrecte.'),
('ARST-0005', 1, 'accepte', 'Documents en règle, visite touristique confirmée.'),
('ARST-0006', 3, 'refuse', 'Anomalie détectée : raison de visite manquante et incohérence taille/poids.');

