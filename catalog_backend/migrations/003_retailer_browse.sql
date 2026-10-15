CREATE OR REPLACE FUNCTION catalog_taxonomy(product_name text, category_name text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
AS $$
  SELECT CASE
    WHEN replace(lower(coalesce(product_name, '') || ' ' || coalesce(category_name, '')), 'ё', 'е')
      SIMILAR TO '%(горячая выпечка|свежая выпечка|выпечка|пекарня|bakery|fresh bakery|hot bakery|pastry|croissant|buns|pies|слойка|булочка|пирожок|круассан|пицца[- ]слайс)%'
      THEN 'hotBakery'
    WHEN replace(lower(coalesce(product_name, '') || ' ' || coalesce(category_name, '')), 'ё', 'е')
      SIMILAR TO '%(готовая еда|готовые блюда|кулинария|салат|суп|вторые блюда|ready meal|prepared meal|prepared food|prepared dish|cooked food|culinary|sandwich|prepared salad)%'
      THEN 'preparedFood'
    ELSE 'other'
  END
$$;

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
  count(*) FILTER (WHERE needs_review OR data_quality = 'needs_review') AS needs_review,
  count(*) FILTER (WHERE data_quality = 'good') AS good_products,
  count(*) FILTER (WHERE EXISTS (
    SELECT 1 FROM product_nutrition n WHERE n.product_id = p.id
      AND n.basis_amount > 0 AND n.energy_kcal IS NOT NULL
  )) AS usable_products
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
  count(DISTINCT pr.product_id) FILTER (WHERE p.needs_review) AS needs_review,
  count(DISTINCT pr.product_id) FILTER (WHERE p.data_quality = 'good') AS good,
  count(DISTINCT pr.product_id) FILTER (
    WHERE n.basis_amount > 0 AND n.energy_kcal IS NOT NULL
  ) AS usable,
  count(DISTINCT pr.product_id) FILTER (
    WHERE catalog_taxonomy(p.name, c.name) = 'preparedFood'
  ) AS prepared_food,
  count(DISTINCT pr.product_id) FILTER (
    WHERE catalog_taxonomy(p.name, c.name) = 'hotBakery'
  ) AS hot_bakery
FROM retailers r
LEFT JOIN product_retailers pr ON pr.retailer_id = r.id
LEFT JOIN products p ON p.id = pr.product_id AND p.status = 'active'
LEFT JOIN product_images i ON i.product_id = p.id AND i.is_primary
LEFT JOIN product_nutrition n ON n.product_id = p.id
LEFT JOIN categories c ON c.id = p.category_id
GROUP BY r.id, r.slug, r.name;
