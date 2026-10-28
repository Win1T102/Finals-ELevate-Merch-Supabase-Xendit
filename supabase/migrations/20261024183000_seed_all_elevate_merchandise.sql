-- ============================================================================
-- ELEVATE MERCH — Seed all 16 official merchandise items
-- ============================================================================
-- Safe additive insert: only inserts items if they don't already exist by name.
-- Apply in the Supabase SQL Editor:
-- ============================================================================

begin;

insert into public.products (name, category, price, description, stock, image_url, is_active)
select v.name, v.category, v.price, v.description, v.stock, v.image_url, true
from (values
  ('Elevate Pin', 'Pins', 25.00, 'The signature ELEVATE metallic badge pin for everyday wear on caps, bags, and jackets.', 100, 'https://yqevxsnqvdtdgodbhrkv.supabase.co/storage/v1/object/public/elevate-products/elevate%20pin.jfif'),
  ('Set an Example Pin', 'Pins', 35.00, '1 Timothy 4:12 commemorative pin: "Set an example in speech, in conduct, in love, in faith, and in purity."', 80, 'elevatepin2.jfif'),
  ('Light & Salt Pin', 'Pins', 35.00, 'Matthew 5:13-14 enamel pin reminding you to be the light of the world and the salt of the earth.', 75, 'elevatepin3.jfif'),
  ('Overcomer Pin', 'Pins', 35.00, 'John 16:33 pin: "In this world you will have trouble. But take heart! I have overcome the world."', 60, 'elevatepin4.jfif'),
  ('Called & Chosen Pin', 'Pins', 35.00, '1 Peter 2:9 badge pin celebrating royal priesthood and true identity in Christ.', 90, 'elevatepin5.jfif'),
  ('Unashamed Pin', 'Pins', 35.00, 'Romans 1:16 bold enamel pin for the ELEVATE community: unashamed of the Gospel.', 70, 'elevatepin6.jfif'),
  ('ELEVATE Shirt', 'T-shirts', 350.00, 'Heavyweight breathable cotton crewneck shirt with the iconic ELEVATE wordmark across the chest.', 50, 'elevate shirt.jfif'),
  ('ELEVATE Long Sleeve', 'Long sleeves', 450.00, 'Premium ribbed cuffed long-sleeve tee tailored for comfort, movement, and cool days.', 40, 'longsleeve.jfif'),
  ('ELEVATE Lanyard', 'Lanyards', 95.00, 'High-density satin woven lanyard with heavy-duty metal clasp and safety breakaway buckle.', 120, 'lanyard.jfif'),
  ('ELEVATE Strap Lanyard', 'Lanyards', 95.00, 'Minimalist dual-tone lanyard strap featuring repeated ELEVATE typography in red and black.', 110, 'lanyard2.jfif'),
  ('Ruth Bible Bookmark', 'Bookmarks', 45.00, 'Durable matte laminated Bible bookmark featuring Ruth 1:16 loyalty and devotion scripture.', 150, 'elevatebm.jfif'),
  ('Jesus Bible Bookmark', 'Bookmarks', 45.00, 'The Way, the Truth, and the Life Bible bookmark with gold cord accent and clear protective coat.', 150, 'elevatebm2.jfif'),
  ('Faith Bible Bookmark', 'Bookmarks', 45.00, 'Hebrews 11:1 scripture bookmark printed on heavy-weight textured cardstock with velvet ribbon.', 130, 'elevatebm3.jfif'),
  ('Grace Bible Bookmark', 'Bookmarks', 45.00, 'Ephesians 2:8 inspirational bookmark for daily scripture reading and devotional reflection.', 140, 'elevatebm4.jfif'),
  ('Hope Bible Bookmark', 'Bookmarks', 45.00, 'Romans 15:13 May the God of Hope fill you with all joy and peace devotional bookmark.', 140, 'elevatebm5.jfif'),
  ('Love Bible Bookmark', 'Bookmarks', 45.00, '1 Corinthians 13:13 Faith, Hope, and Love bookmark with elegant typography and tassel.', 140, 'elevatebm6.jfif')
) as v(name, category, price, description, stock, image_url)
where not exists (
  select 1 from public.products p where lower(btrim(p.name)) = lower(btrim(v.name))
);

commit;

