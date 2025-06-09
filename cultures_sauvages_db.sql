-- ============================================
-- SCHÉMA DE BASE DE DONNÉES - CULTURES SAUVAGES
-- Application de gestion pour éco-tiers-lieu
-- ============================================

-- Table centrale des utilisateurs - Le cœur de notre système
-- Cette table unifie tous les types d'utilisateurs sous une même structure
CREATE TABLE utilisateurs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL, -- Unique pour éviter les doublons
    telephone VARCHAR(20),
    date_naissance DATE,
    ville VARCHAR(100),
    
    -- Système de permissions graduées
    statut ENUM('admin', 'membre_actif', 'benevole', 'adherent') NOT NULL DEFAULT 'adherent',
    
    -- Informations spécifiques à l'engagement associatif
    disponibilites TEXT, -- Format JSON pour flexibilité : {"lundi": ["matin", "soir"], "weekend": true}
    competences_partagees TEXT, -- Compétences que la personne peut apporter
    interets TEXT, -- Pourquoi souhaite rejoindre l'association
    contrepartie_souhaitee TEXT, -- Ce que la personne attend en retour
    
    -- Métadonnées de gestion
    date_inscription DATETIME DEFAULT CURRENT_TIMESTAMP,
    derniere_connexion DATETIME,
    actif BOOLEAN DEFAULT true, -- Permet de désactiver sans supprimer
    
    -- Champs pour la gestion des adhésions
    date_derniere_cotisation DATE,
    montant_derniere_cotisation DECIMAL(10,2),
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Table des thématiques - Organise les différents domaines d'activité
-- Correspond à vos besoins : Travaux, Administration, Événements, Entretien, Divers
CREATE TABLE thematiques (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    couleur VARCHAR(7), -- Code couleur hexadécimal pour l'interface (#FF5733)
    icone VARCHAR(50), -- Nom de l'icône pour l'affichage
    actif BOOLEAN DEFAULT true,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insertion des thématiques de base
INSERT INTO thematiques (nom, description, couleur, icone) VALUES
('Travaux', 'Travaux de construction, rénovation et aménagement', '#2E8B57', 'hammer'),
('Administration', 'Gestion administrative, comptabilité, communication', '#4682B4', 'briefcase'),
('Événements', 'Organisation et animation d\'événements', '#FF6B35', 'calendar'),
('Entretien', 'Maintenance et entretien des espaces', '#8FBC8F', 'settings'),
('Divers', 'Autres activités et besoins ponctuels', '#DDA0DD', 'help-circle');

-- Table des événements - Cœur de la planification associative
CREATE TABLE evenements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    titre VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Informations temporelles
    date_debut DATETIME NOT NULL,
    date_fin DATETIME,
    duree_estimee INTEGER, -- En minutes, pour les tâches sans heure de fin fixe
    
    -- Localisation et logistique
    lieu VARCHAR(200),
    adresse TEXT,
    
    -- Classification et organisation
    thematique_id INTEGER,
    type_evenement ENUM('atelier', 'chantier', 'reunion', 'formation', 'festivite', 'autre') NOT NULL,
    
    -- Gestion des participants
    nombre_places_max INTEGER,
    nombre_inscrits INTEGER DEFAULT 0,
    inscription_obligatoire BOOLEAN DEFAULT false,
    
    -- Informations financières
    tarif DECIMAL(10,2) DEFAULT 0.00,
    frais_participation TEXT, -- Description des frais éventuels
    
    -- Besoins en ressources humaines
    besoins_competences TEXT, -- JSON des compétences recherchées
    materiels_necessaires TEXT,
    materiels_fournis TEXT,
    
    -- Métadonnées de gestion
    organisateur_id INTEGER NOT NULL, -- Référence vers utilisateurs
    statut ENUM('planifie', 'confirme', 'en_cours', 'termine', 'annule') DEFAULT 'planifie',
    publique BOOLEAN DEFAULT true, -- Visible par tous ou membres seulement
    
    -- Informations complémentaires
    notes_organisation TEXT, -- Notes internes pour l'organisation
    retour_experience TEXT, -- Bilan post-événement
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes de cohérence
    FOREIGN KEY (thematique_id) REFERENCES thematiques(id),
    FOREIGN KEY (organisateur_id) REFERENCES utilisateurs(id),
    CHECK (date_fin IS NULL OR date_fin >= date_debut),
    CHECK (nombre_places_max IS NULL OR nombre_places_max > 0)
);

-- Table de liaison pour les inscriptions aux événements
-- Cette table capture la relation many-to-many entre utilisateurs et événements
CREATE TABLE inscriptions_evenements (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    utilisateur_id INTEGER NOT NULL,
    evenement_id INTEGER NOT NULL,
    
    -- Détails de l'inscription
    date_inscription DATETIME DEFAULT CURRENT_TIMESTAMP,
    statut ENUM('inscrit', 'confirme', 'present', 'absent', 'annule') DEFAULT 'inscrit',
    
    -- Informations spécifiques du participant
    commentaire TEXT, -- Message du participant lors de l'inscription
    besoins_speciaux TEXT, -- Régime alimentaire, accessibilité, etc.
    transport_propose BOOLEAN DEFAULT false, -- Peut proposer du covoiturage
    transport_recherche BOOLEAN DEFAULT false, -- Cherche du covoiturage
    
    -- Gestion financière
    paiement_effectue BOOLEAN DEFAULT false,
    montant_paye DECIMAL(10,2) DEFAULT 0.00,
    mode_paiement VARCHAR(50), -- 'especes', 'virement', 'cheque', etc.
    
    -- Évaluation post-participation
    note_satisfaction INTEGER CHECK (note_satisfaction BETWEEN 1 AND 5),
    commentaire_retour TEXT,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    -- Contraintes d'intégrité
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (evenement_id) REFERENCES evenements(id) ON DELETE CASCADE,
    UNIQUE (utilisateur_id, evenement_id) -- Un utilisateur ne peut s'inscrire qu'une fois par événement
);

-- Table des projets et besoins - Pour la gestion long terme
CREATE TABLE projets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom VARCHAR(200) NOT NULL,
    description TEXT,
    
    -- Classification
    thematique_id INTEGER,
    priorite ENUM('basse', 'normale', 'haute', 'urgente') DEFAULT 'normale',
    
    -- Planification temporelle
    date_debut_prevue DATE,
    date_fin_prevue DATE,
    duree_estimee_jours INTEGER,
    
    -- Ressources nécessaires
    budget_estime DECIMAL(10,2),
    nombre_benevoles_requis INTEGER,
    competences_requises TEXT, -- JSON des compétences nécessaires
    materiels_requis TEXT,
    
    -- Suivi d'avancement
    statut ENUM('idee', 'planifie', 'en_cours', 'en_pause', 'termine', 'abandonne') DEFAULT 'idee',
    pourcentage_completion INTEGER DEFAULT 0 CHECK (pourcentage_completion BETWEEN 0 AND 100),
    
    -- Responsabilité
    responsable_id INTEGER,
    
    -- Informations complémentaires
    objectifs TEXT,
    resultats_attendus TEXT,
    notes TEXT,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (thematique_id) REFERENCES thematiques(id),
    FOREIGN KEY (responsable_id) REFERENCES utilisateurs(id),
    CHECK (date_fin_prevue IS NULL OR date_fin_prevue >= date_debut_prevue)
);

-- Table de liaison entre projets et événements
-- Un projet peut donner lieu à plusieurs événements (chantiers, réunions, etc.)
CREATE TABLE projets_evenements (
    projet_id INTEGER,
    evenement_id INTEGER,
    relation_type ENUM('reunion_planning', 'chantier', 'formation', 'bilan') NOT NULL,
    
    PRIMARY KEY (projet_id, evenement_id),
    FOREIGN KEY (projet_id) REFERENCES projets(id) ON DELETE CASCADE,
    FOREIGN KEY (evenement_id) REFERENCES evenements(id) ON DELETE CASCADE
);

-- Table des compétences - Référentiel des savoir-faire
CREATE TABLE competences (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nom VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    categorie VARCHAR(50), -- 'technique', 'artistique', 'administrative', etc.
    niveau_requis ENUM('debutant', 'intermediaire', 'avance', 'expert') DEFAULT 'debutant',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Table de liaison utilisateurs-compétences
-- Permet de tracker qui maîtrise quoi et à quel niveau
CREATE TABLE utilisateurs_competences (
    utilisateur_id INTEGER,
    competence_id INTEGER,
    niveau ENUM('debutant', 'intermediaire', 'avance', 'expert') NOT NULL,
    certifie BOOLEAN DEFAULT false, -- Si la compétence est certifiée/validée
    date_acquisition DATE,
    notes TEXT,
    
    PRIMARY KEY (utilisateur_id, competence_id),
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE,
    FOREIGN KEY (competence_id) REFERENCES competences(id) ON DELETE CASCADE
);

-- Table de gestion des sessions utilisateur et sécurité
CREATE TABLE sessions_utilisateur (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    utilisateur_id INTEGER NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    user_agent TEXT,
    date_creation DATETIME DEFAULT CURRENT_TIMESTAMP,
    date_expiration DATETIME NOT NULL,
    actif BOOLEAN DEFAULT true,
    
    FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
);

-- ============================================
-- INDEX POUR OPTIMISER LES PERFORMANCES
-- ============================================

-- Index sur les colonnes fréquemment utilisées pour les recherches
CREATE INDEX idx_utilisateurs_email ON utilisateurs(email);
CREATE INDEX idx_utilisateurs_statut ON utilisateurs(statut);
CREATE INDEX idx_utilisateurs_actif ON utilisateurs(actif);

CREATE INDEX idx_evenements_date ON evenements(date_debut);
CREATE INDEX idx_evenements_statut ON evenements(statut);
CREATE INDEX idx_evenements_thematique ON evenements(thematique_id);
CREATE INDEX idx_evenements_organisateur ON evenements(organisateur_id);

CREATE INDEX idx_inscriptions_utilisateur ON inscriptions_evenements(utilisateur_id);
CREATE INDEX idx_inscriptions_evenement ON inscriptions_evenements(evenement_id);
CREATE INDEX idx_inscriptions_statut ON inscriptions_evenements(statut);

CREATE INDEX idx_projets_statut ON projets(statut);
CREATE INDEX idx_projets_responsable ON projets(responsable_id);
CREATE INDEX idx_projets_priorite ON projets(priorite);

-- ============================================
-- TRIGGERS POUR MAINTENIR LA COHÉRENCE
-- ============================================

-- Trigger pour mettre à jour automatiquement le nombre d'inscrits
CREATE TRIGGER update_nombre_inscrits_after_insert
    AFTER INSERT ON inscriptions_evenements
    WHEN NEW.statut IN ('inscrit', 'confirme')
BEGIN
    UPDATE evenements 
    SET nombre_inscrits = (
        SELECT COUNT(*) 
        FROM inscriptions_evenements 
        WHERE evenement_id = NEW.evenement_id 
        AND statut IN ('inscrit', 'confirme')
    )
    WHERE id = NEW.evenement_id;
END;

CREATE TRIGGER update_nombre_inscrits_after_update
    AFTER UPDATE ON inscriptions_evenements
    WHEN OLD.statut != NEW.statut
BEGIN
    UPDATE evenements 
    SET nombre_inscrits = (
        SELECT COUNT(*) 
        FROM inscriptions_evenements 
        WHERE evenement_id = NEW.evenement_id 
        AND statut IN ('inscrit', 'confirme')
    )
    WHERE id = NEW.evenement_id;
END;

-- Trigger pour mettre à jour updated_at automatiquement
CREATE TRIGGER update_utilisateurs_timestamp
    AFTER UPDATE ON utilisateurs
BEGIN
    UPDATE utilisateurs SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;

CREATE TRIGGER update_evenements_timestamp
    AFTER UPDATE ON evenements
BEGIN
    UPDATE evenements SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;