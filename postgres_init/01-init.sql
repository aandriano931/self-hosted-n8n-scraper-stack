-- Création de la base de données
-- CREATE DATABASE scraping_db;
-- \c scraping_db

-- Extension nécessaire pour la performance des recherches textuelles (optionnel mais recommandé)
-- CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE TABLE IF NOT EXISTS vehicle_listings (
    id SERIAL PRIMARY KEY,
    
    -- Identifiants uniques et sources
    source_id VARCHAR(255) NOT NULL,
    source_site VARCHAR(50) NOT NULL,
    url TEXT NOT NULL,
    
    -- Données techniques du véhicule
    title TEXT,
    price NUMERIC(12, 2),
    previous_price NUMERIC(12, 2), -- Suivi de l'évolution du prix
    mileage INTEGER,
    dealer TEXT,
    registration_year INTEGER,
    registration_month INTEGER,
    energy VARCHAR(100),
    gearbox VARCHAR(100),
    
    -- Métadonnées de workflow et de scoring
    analysis_status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, PROCESSED, ERROR
    event_type VARCHAR(50) DEFAULT 'NEW',        -- NEW, PRICE_DROP, PRICE_UPDATE
    deal_score INTEGER,                          -- Score qualitatif LLM (1-5)
    
    -- Horodatage
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    -- Contrainte d'unicité pour l'UPSERT (ON CONFLICT)
    CONSTRAINT unique_source_vehicle UNIQUE(source_id, source_site)
);

-- --- INDEXATION STRATÉGIQUE ---

-- 1. Index pour les agrégations de marché (Performance de la CTE market_stats)
-- Indispensable pour éviter les sélections lentes (Sequential Scan) lors des calculs de moyenne
CREATE INDEX IF NOT EXISTS idx_listings_market_agg 
ON vehicle_listings(registration_year, energy);

-- 2. Index pour le workflow n8n (Consumer)
-- Permet de récupérer instantanément les offres à analyser
CREATE INDEX IF NOT EXISTS idx_listings_pending_analysis 
ON vehicle_listings(analysis_status) 
WHERE analysis_status = 'PENDING';

-- 3. Index partiel pour les alertes "Hot Deals"
-- Optimise les requêtes de reporting/affichage sur les scores élevés
CREATE INDEX IF NOT EXISTS idx_listings_hot_deals 
ON vehicle_listings(deal_score) 
WHERE deal_score >= 4;

-- 4. Index de recherche pour le dealer (optionnel)
CREATE INDEX IF NOT EXISTS idx_listings_dealer ON vehicle_listings(dealer);