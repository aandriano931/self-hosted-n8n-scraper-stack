-- Création de la base de données dédiée au scraping
CREATE DATABASE scraping_db;

-- Connexion à la nouvelle base de données (commande spécifique à psql)
\c scraping_db

-- Création de la table avec IF NOT EXISTS pour garantir l'idempotence
CREATE TABLE IF NOT EXISTS vehicle_listings (
    id SERIAL PRIMARY KEY,
    source_id VARCHAR(255) NOT NULL,
    source_site VARCHAR(50) NOT NULL,
    url TEXT,
    title VARCHAR(255),
    price NUMERIC,
    mileage INTEGER,
    dealer VARCHAR(255),
    registration_year INTEGER,
    registration_month INTEGER,
    energy VARCHAR(100),
    gearbox VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(source_id, source_site)
);

-- Création d'un index pour optimiser l'UPSERT et les requêtes futures
CREATE INDEX IF NOT EXISTS idx_vehicle_listings_source ON vehicle_listings(source_id, source_site);