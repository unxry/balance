CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$ BEGIN
  CREATE TYPE source_type AS ENUM (
    'manufacturer', 'official_retailer', 'open_food_facts',
    'manual', 'import', 'restaurant_menu', 'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE product_quality AS ENUM (
    'verified', 'good', 'partial', 'unverified', 'needs_review'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE nutrition_basis AS ENUM (
    'per100g', 'per100ml', 'per_serving', 'per_item'
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE product_kind AS ENUM ('packaged', 'restaurant');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE product_status AS ENUM ('active', 'archived', 'merged');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS sources (
  id bigserial PRIMARY KEY,
  slug text NOT NULL UNIQUE,
  type source_type NOT NULL,
  name text NOT NULL,
  url text,
  license_name text,
  license_url text,
  attribution text,
  priority smallint NOT NULL CHECK (priority BETWEEN 0 AND 1000),
  enabled boolean NOT NULL DEFAULT true,
  last_sync_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS brands (
  id bigserial PRIMARY KEY,
  name text NOT NULL,
  normalized_name text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS categories (
  id bigserial PRIMARY KEY,
  external_key text UNIQUE,
  name text NOT NULL,
  normalized_name text NOT NULL,
  parent_id bigint REFERENCES categories(id)
);

CREATE TABLE IF NOT EXISTS retailers (
  id bigserial PRIMARY KEY,
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  kind text NOT NULL DEFAULT 'retailer' CHECK (kind IN ('retailer', 'restaurant')),
  official_url text
);

CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  barcode text,
  external_key text,
  kind product_kind NOT NULL DEFAULT 'packaged',
  name text NOT NULL CHECK (length(trim(name)) > 0),
  normalized_name text NOT NULL,
  search_text text NOT NULL,
  brand_id bigint REFERENCES brands(id),
  category_id bigint REFERENCES categories(id),
  net_weight numeric(12,3),
  net_weight_unit text,
  serving_size numeric(12,3),
  serving_unit text,
  ingredients text,
  status product_status NOT NULL DEFAULT 'active',
  data_quality product_quality NOT NULL DEFAULT 'unverified',
  needs_review boolean NOT NULL DEFAULT false,
  source_priority smallint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  last_verified_at timestamptz,
  CHECK (barcode IS NULL OR barcode ~ '^[0-9]{8,14}$'),
  CHECK (net_weight IS NULL OR net_weight > 0),
  CHECK (serving_size IS NULL OR serving_size > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS products_barcode_uq
  ON products(barcode) WHERE barcode IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS products_external_key_uq
  ON products(external_key) WHERE external_key IS NOT NULL;
CREATE INDEX IF NOT EXISTS products_search_fts_idx
  ON products USING gin(to_tsvector('simple', search_text));
CREATE INDEX IF NOT EXISTS products_search_trgm_idx
  ON products USING gin(search_text gin_trgm_ops);
CREATE INDEX IF NOT EXISTS products_updated_idx ON products(updated_at, id);
CREATE INDEX IF NOT EXISTS products_quality_idx ON products(data_quality);

CREATE TABLE IF NOT EXISTS product_nutrition (
  product_id uuid PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE,
  basis nutrition_basis NOT NULL,
  basis_amount numeric(12,3) NOT NULL DEFAULT 100 CHECK (basis_amount > 0),
  energy_kcal numeric(10,3),
  protein numeric(10,3),
  fat numeric(10,3),
  carbohydrates numeric(10,3),
  fiber numeric(10,3),
  sugar numeric(10,3),
  salt numeric(10,3),
  source_id bigint NOT NULL REFERENCES sources(id),
  verified boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (energy_kcal IS NULL OR energy_kcal BETWEEN 0 AND 2000),
  CHECK (protein IS NULL OR protein BETWEEN 0 AND 200),
  CHECK (fat IS NULL OR fat BETWEEN 0 AND 200),
  CHECK (carbohydrates IS NULL OR carbohydrates BETWEEN 0 AND 200)
);

CREATE TABLE IF NOT EXISTS product_images (
  id bigserial PRIMARY KEY,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  url text NOT NULL,
  type text NOT NULL CHECK (type IN ('front', 'nutrition', 'ingredients', 'other')),
  source_id bigint NOT NULL REFERENCES sources(id),
  license_name text,
  license_url text,
  attribution text,
  width integer,
  height integer,
  is_primary boolean NOT NULL DEFAULT false,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(product_id, url)
);
CREATE UNIQUE INDEX IF NOT EXISTS product_images_primary_uq
  ON product_images(product_id) WHERE is_primary;

CREATE TABLE IF NOT EXISTS product_sources (
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  source_id bigint NOT NULL REFERENCES sources(id),
  source_product_id text NOT NULL,
  source_url text,
  source_revision text,
  payload jsonb,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  source_modified_at timestamptz,
  is_primary boolean NOT NULL DEFAULT false,
  PRIMARY KEY(source_id, source_product_id)
);
CREATE INDEX IF NOT EXISTS product_sources_product_idx ON product_sources(product_id);

CREATE TABLE IF NOT EXISTS product_retailers (
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  retailer_id bigint NOT NULL REFERENCES retailers(id),
  source_id bigint NOT NULL REFERENCES sources(id),
  confidence numeric(4,3) NOT NULL DEFAULT 0.5 CHECK (confidence BETWEEN 0 AND 1),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(product_id, retailer_id, source_id)
);

CREATE TABLE IF NOT EXISTS product_versions (
  id bigserial PRIMARY KEY,
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  source_id bigint REFERENCES sources(id),
  source_revision text,
  changed_at timestamptz NOT NULL DEFAULT now(),
  changed_by text NOT NULL DEFAULT 'sync',
  snapshot jsonb NOT NULL
);
CREATE INDEX IF NOT EXISTS product_versions_product_idx
  ON product_versions(product_id, changed_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS product_versions_source_revision_uq
  ON product_versions(product_id, source_id, source_revision)
  WHERE source_id IS NOT NULL AND source_revision IS NOT NULL;

CREATE TABLE IF NOT EXISTS sync_runs (
  id bigserial PRIMARY KEY,
  source_id bigint NOT NULL REFERENCES sources(id),
  mode text NOT NULL,
  status text NOT NULL CHECK (status IN ('running', 'succeeded', 'failed')),
  source_etag text,
  source_last_modified text,
  scanned_count bigint NOT NULL DEFAULT 0,
  accepted_count bigint NOT NULL DEFAULT 0,
  rejected_count bigint NOT NULL DEFAULT 0,
  started_at timestamptz NOT NULL DEFAULT now(),
  finished_at timestamptz,
  error text
);

CREATE TABLE IF NOT EXISTS sync_state (
  source_id bigint PRIMARY KEY REFERENCES sources(id),
  cursor text,
  etag text,
  last_modified text,
  last_success_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO sources(slug, type, name, url, license_name, license_url, attribution, priority)
VALUES (
  'open-food-facts', 'open_food_facts', 'Open Food Facts',
  'https://world.openfoodfacts.org', 'ODbL 1.0',
  'https://opendatacommons.org/licenses/odbl/1-0/',
  'Open Food Facts contributors', 400
)
ON CONFLICT (slug) DO UPDATE SET
  url = EXCLUDED.url, license_name = EXCLUDED.license_name,
  license_url = EXCLUDED.license_url, attribution = EXCLUDED.attribution;

INSERT INTO retailers(slug, name, kind, official_url) VALUES
  ('magnit', 'Магнит', 'retailer', 'https://magnit.ru'),
  ('pyaterochka', 'Пятёрочка', 'retailer', 'https://5ka.ru'),
  ('perekrestok', 'Перекрёсток', 'retailer', 'https://perekrestok.ru'),
  ('vkusvill', 'ВкусВилл', 'retailer', 'https://vkusvill.ru'),
  ('fix-price', 'Fix Price', 'retailer', 'https://fix-price.com'),
  ('pobeda', 'ПОБЕДА', 'retailer', 'https://магазинпобеда.рф'),
  ('vkusno-i-tochka', 'Вкусно — и точка', 'restaurant', 'https://vkusnoitochka.ru'),
  ('rostics', 'ROSTIC''S', 'restaurant', 'https://rostics.ru')
ON CONFLICT (slug) DO UPDATE SET name = EXCLUDED.name, official_url = EXCLUDED.official_url;

CREATE OR REPLACE VIEW catalog_quality_stats AS
SELECT
  count(*) AS total_products,
  count(*) FILTER (WHERE barcode IS NOT NULL) AS products_with_barcode,
  count(*) FILTER (WHERE EXISTS (
    SELECT 1 FROM product_images i WHERE i.product_id = p.id
  )) AS products_with_image,
  count(*) FILTER (WHERE EXISTS (
    SELECT 1 FROM product_nutrition n WHERE n.product_id = p.id
      AND n.energy_kcal IS NOT NULL AND n.protein IS NOT NULL
      AND n.fat IS NOT NULL AND n.carbohydrates IS NOT NULL
  )) AS products_with_complete_kbju,
  count(*) FILTER (WHERE data_quality = 'verified') AS verified_products,
  count(*) FILTER (WHERE data_quality = 'partial') AS partial_products,
  count(*) FILTER (WHERE needs_review OR data_quality = 'needs_review') AS needs_review
FROM products p WHERE status = 'active';

CREATE OR REPLACE VIEW retailer_coverage AS
SELECT r.slug, r.name,
  count(DISTINCT pr.product_id) AS total_products,
  count(DISTINCT pr.product_id) FILTER (WHERE p.barcode IS NOT NULL) AS with_barcode,
  count(DISTINCT pr.product_id) FILTER (WHERE i.product_id IS NOT NULL) AS with_image,
  count(DISTINCT pr.product_id) FILTER (
    WHERE n.energy_kcal IS NOT NULL AND n.protein IS NOT NULL
      AND n.fat IS NOT NULL AND n.carbohydrates IS NOT NULL
  ) AS with_complete_kbju,
  count(DISTINCT pr.product_id) FILTER (WHERE p.data_quality = 'verified') AS verified,
  count(DISTINCT pr.product_id) FILTER (WHERE p.data_quality = 'partial') AS partial,
  count(DISTINCT pr.product_id) FILTER (WHERE p.needs_review) AS needs_review
FROM retailers r
LEFT JOIN product_retailers pr ON pr.retailer_id = r.id
LEFT JOIN products p ON p.id = pr.product_id
LEFT JOIN product_images i ON i.product_id = p.id AND i.is_primary
LEFT JOIN product_nutrition n ON n.product_id = p.id
GROUP BY r.id, r.slug, r.name;
