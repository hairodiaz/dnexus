-- Migration: Add sistema column to negocios table
-- Date: 2026-02-23

-- Add sistema column to negocios
ALTER TABLE negocios ADD COLUMN sistema VARCHAR(50) NOT NULL DEFAULT 'Repuesto';

-- Create index on sistema for faster queries
CREATE INDEX IF NOT EXISTS idx_negocios_sistema ON negocios(sistema);
