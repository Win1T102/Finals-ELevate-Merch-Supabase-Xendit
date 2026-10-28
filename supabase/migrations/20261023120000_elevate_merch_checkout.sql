-- ============================================================================
-- ELEVATE MERCH — catalogue, checkout, orders, and row-level security
-- ============================================================================
-- Additive migration. No table is dropped and no product record is deleted.
-- Apply with: supabase db push   (or paste into the Supabase SQL editor)
-- ============================================================================

begin;

-- ----------------------------------------------------------------------------
-- 1. Products: catalogue metadata + insertable IDs
-- ----------------------------------------------------------------------------
alter table public.products add column if not exists description text;
alter table public.products add column if not exists stock integer;
alter table public.products add column if not exists is_active boolean not null default true;
alter table public.products add column if not exists updated_at timestamptz not null default now();

do $$
begin
  alter table public.products
    add constraint products_price_nonnegative check (price >= 0);
exception when duplicate_object then null;
end $$;

do $$
begin
  alter table public.products
    add constraint products_stock_nonnegative check (stock is null or stock >= 0);
exception when duplicate_object then null;
end $$;

-- The id column is already an identity column. Realign its sequence with the
-- existing rows so the next insert does not collide with an explicit id.
select setval(
  pg_get_serial_sequence('public.products', 'id'),
  greatest(coalesce((select max(id) from public.products), 0), 1),
  true
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at
  before update on public.products
  for each row execute function public.touch_updated_at();

-- ----------------------------------------------------------------------------
-- 2. Orders: checkout data, payment lifecycle, guest access
-- ----------------------------------------------------------------------------
alter table public.orders add column if not exists user_id uuid references auth.users(id) on delete set null;
alter table public.orders add column if not exists customer_name text;
alter table public.orders add column if not exists customer_email text;
alter table public.orders add column if not exists customer_phone text;
alter table public.orders add column if not exists delivery_address text;
alter table public.orders add column if not exists notes text;
alter table public.orders add column if not exists subtotal numeric(12,2) not null default 0;
alter table public.orders add column if not exists shipping_fee numeric(12,2) not null default 0;
alter table public.orders add column if not exists total_amount numeric(12,2) not null default 0;
alter table public.orders add column if not exists payment_status text not null default 'pending';
alter table public.orders add column if not exists order_status text not null default 'pending_payment';
alter table public.orders add column if not exists payment_provider text default 'xendit';
alter table public.orders add column if not exists payment_session_id text;
alter table public.orders add column if not exists payment_url text;
alter table public.orders add column if not exists payment_expires_at timestamptz;
alter table public.orders add column if not exists guest_token_hash text;
alter table public.orders add column if not exists idempotency_key text;
alter table public.orders add column if not exists paid_at timestamptz;
alter table public.orders add column if not exists updated_at timestamptz not null default now();

do $$
begin
  alter table public.orders
    add constraint orders_payment_status_check
    check (payment_status in ('pending', 'paid', 'failed', 'expired', 'cancelled'));
exception when duplicate_object then null;
end $$;

do $$
begin
  alter table public.orders
    add constraint orders_order_status_check
    check (order_status in ('pending_payment', 'processing', 'completed', 'cancelled'));
exception when duplicate_object then null;
end $$;

do $$
begin
  alter table public.orders
    add constraint orders_total_nonnegative check (total_amount >= 0);
exception when duplicate_object then null;
end $$;

-- Realign the existing identity sequence with current order ids.
select setval(
  pg_get_serial_sequence('public.orders', 'id'),
  greatest(coalesce((select max(id) from public.orders), 0), 1),
  true
);

create unique index if not exists orders_idempotency_key_key
  on public.orders (idempotency_key) where idempotency_key is not null;
create unique index if not exists orders_payment_session_id_key
  on public.orders (payment_session_id) where payment_session_id is not null;
create index if not exists orders_user_id_idx
  on public.orders (user_id, created_at desc);
create index if not exists orders_created_at_idx
  on public.orders (created_at desc);

-- ----------------------------------------------------------------------------
-- 3. Order line items
-- ----------------------------------------------------------------------------
create table if not exists public.order_items (
  id bigint generated by default as identity primary key,
  order_id bigint not null references public.orders(id) on delete cascade,
  product_id bigint references public.products(id) on delete set null,
  product_name text not null,
  product_image_url text,
  unit_price numeric(12,2) not null check (unit_price >= 0),
  quantity integer not null check (quantity > 0),
  subtotal numeric(12,2) not null check (subtotal >= 0),
  created_at timestamptz not null default now()
);

create index if not exists order_items_order_id_idx on public.order_items (order_id);

-- ----------------------------------------------------------------------------
-- 4. Keep the payment lifecycle consistent, and deduct stock exactly once
-- ----------------------------------------------------------------------------
create or replace function public.sync_order_payment_status()
returns trigger
language plpgsql
as $$
begin
  if new.payment_status = 'paid' and old.payment_status is distinct from 'paid' then
    new.status := 'PAID';
    if new.order_status = 'pending_payment' then
      new.order_status := 'processing';
    end if;
    new.paid_at := coalesce(new.paid_at, now());
  elsif new.status = 'PAID' and old.payment_status is distinct from 'paid' then
    new.payment_status := 'paid';
    if new.order_status = 'pending_payment' then
      new.order_status := 'processing';
    end if;
    new.paid_at := coalesce(new.paid_at, now());
  elsif new.status = 'EXPIRED' and old.payment_status is distinct from 'paid' then
    new.payment_status := 'expired';
    new.order_status := 'cancelled';
  elsif new.status = 'FAILED' and old.payment_status is distinct from 'paid' then
    new.payment_status := 'failed';
  end if;

  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists orders_sync_payment_status on public.orders;
create trigger orders_sync_payment_status
  before update on public.orders
  for each row execute function public.sync_order_payment_status();

create or replace function public.deduct_stock_when_paid()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if new.payment_status = 'paid' and old.payment_status is distinct from 'paid' then
    update public.products p
       set stock = greatest(p.stock - oi.quantity, 0),
           updated_at = now()
      from public.order_items oi
     where oi.order_id = new.id
       and p.id = oi.product_id
       and p.stock is not null;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_deduct_stock on public.orders;
create trigger orders_deduct_stock
  after update on public.orders
  for each row execute function public.deduct_stock_when_paid();

-- ----------------------------------------------------------------------------
-- 5. Trusted order creation: prices, stock, and totals come from the database
-- ----------------------------------------------------------------------------
create or replace function public.create_order(
  p_items jsonb,
  p_customer jsonb,
  p_idempotency_key text default null,
  p_guest_token text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_ref text;
  v_order_id bigint;
  v_existing public.orders;
  v_guest_hash text;
  v_name text;
  v_phone text;
  v_email text;
  v_address text;
  v_notes text;
  v_requested_count int;
  v_found_count int;
  v_subtotal numeric(12,2) := 0;
  v_shipping numeric(12,2) := 0;
  v_total numeric(12,2) := 0;
  v_summary text := '';
  v_lines jsonb := '[]'::jsonb;
  v_line record;
  v_qty int;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_CART: Add at least one item.' using errcode = 'P0001';
  end if;

  if jsonb_array_length(p_items) > 50 then
    raise exception 'CART_TOO_LARGE: This cart has too many different items.' using errcode = 'P0001';
  end if;

  if exists (
    select 1
      from jsonb_array_elements(p_items) e
     where e->>'product_id' is null
        or (e->>'product_id') !~ '^[0-9]+$'
        or e->>'quantity' is null
        or (e->>'quantity') !~ '^[0-9]+$'
  ) then
    raise exception 'INVALID_CART: The cart contains an invalid item.' using errcode = 'P0001';
  end if;

  v_name := btrim(coalesce(p_customer->>'name', ''));
  v_phone := btrim(coalesce(p_customer->>'phone', ''));
  v_email := nullif(btrim(coalesce(p_customer->>'email', '')), '');
  v_address := btrim(coalesce(p_customer->>'address', ''));
  v_notes := nullif(btrim(coalesce(p_customer->>'notes', '')), '');

  if char_length(v_name) < 2 or char_length(v_name) > 120 then
    raise exception 'INVALID_NAME: Enter the full name for this order.' using errcode = 'P0001';
  end if;
  if v_phone !~ '^\+?[0-9][0-9 -]{6,19}$' then
    raise exception 'INVALID_PHONE: Enter a valid contact number.' using errcode = 'P0001';
  end if;
  if char_length(v_address) < 10 or char_length(v_address) > 500 then
    raise exception 'INVALID_ADDRESS: Enter a complete delivery address.' using errcode = 'P0001';
  end if;
  if v_email is not null and (char_length(v_email) > 254 or v_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$') then
    raise exception 'INVALID_EMAIL: Enter a valid email address, or leave it blank.' using errcode = 'P0001';
  end if;

  if v_uid is null then
    if p_guest_token is null or char_length(p_guest_token) < 32 then
      raise exception 'INVALID_ACCESS: Missing order access code.' using errcode = 'P0001';
    end if;
    v_guest_hash := encode(extensions.digest(p_guest_token, 'sha256'), 'hex');
  end if;

  -- Idempotent retries: a repeated submit returns the original order instead of
  -- charging or creating a second one.
  if p_idempotency_key is not null and char_length(p_idempotency_key) between 8 and 100 then
    select * into v_existing
      from public.orders
     where idempotency_key = p_idempotency_key
     limit 1;

    if found then
      if (v_uid is not null and v_existing.user_id = v_uid)
         or (v_guest_hash is not null and v_existing.guest_token_hash = v_guest_hash) then
        return jsonb_build_object(
          'reference', v_existing.external_id,
          'total', v_existing.total_amount,
          'subtotal', v_existing.subtotal,
          'shipping_fee', v_existing.shipping_fee,
          'reused', true
        );
      end if;
      raise exception 'DUPLICATE_REQUEST: This checkout request was already used.' using errcode = 'P0001';
    end if;
  end if;

  select count(distinct (e->>'product_id')::bigint)
    into v_requested_count
    from jsonb_array_elements(p_items) e;

  -- Lock the catalogue rows so two simultaneous checkouts cannot oversell stock.
  perform 1
     from public.products p
    where p.id in (select (e->>'product_id')::bigint from jsonb_array_elements(p_items) e)
    order by p.id
    for update;

  for v_line in
    select
      p.id,
      p.name,
      p.price,
      p.stock,
      p.image_url,
      p.is_active,
      sum((e->>'quantity')::int) as requested_quantity
     from jsonb_array_elements(p_items) e
     join public.products p on p.id = (e->>'product_id')::bigint
    group by p.id, p.name, p.price, p.stock, p.image_url, p.is_active
    order by p.id
  loop
    v_qty := v_line.requested_quantity;

    if v_qty < 1 or v_qty > 20 then
      raise exception 'INVALID_QUANTITY: Choose between 1 and 20 of each item.' using errcode = 'P0001';
    end if;
    if not v_line.is_active then
      raise exception 'UNAVAILABLE: % is no longer available.', v_line.name using errcode = 'P0001';
    end if;
    if v_line.stock is not null and v_line.stock < v_qty then
      raise exception 'OUT_OF_STOCK: % only has % left.', v_line.name, v_line.stock using errcode = 'P0001';
    end if;

    v_subtotal := v_subtotal + round(v_line.price * v_qty, 2);
    v_summary := case when v_summary = '' then '' else v_summary || ', ' end
                 || v_line.name || ' x ' || v_qty::text;

    v_lines := v_lines || jsonb_build_object(
      'product_id', v_line.id,
      'product_name', v_line.name,
      'image_url', coalesce(v_line.image_url, ''),
      'unit_price', v_line.price,
      'quantity', v_qty,
      'subtotal', round(v_line.price * v_qty, 2)
    );
  end loop;

  select count(*) into v_found_count from jsonb_array_elements(v_lines);

  if v_found_count = 0 then
    raise exception 'UNAVAILABLE: One or more items are no longer available.' using errcode = 'P0001';
  end if;
  if v_found_count < v_requested_count then
    raise exception 'UNAVAILABLE: One or more items are no longer available.' using errcode = 'P0001';
  end if;

  v_total := v_subtotal + v_shipping;
  if v_total <= 0 then
    raise exception 'INVALID_TOTAL: This order total is not valid.' using errcode = 'P0001';
  end if;

  v_ref := 'ELV-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 10));

  insert into public.orders (
    external_id, product_name, amount, status,
    user_id, customer_name, customer_email, customer_phone,
    delivery_address, notes,
    subtotal, shipping_fee, total_amount,
    payment_status, order_status, payment_provider,
    guest_token_hash, idempotency_key
  ) values (
    v_ref, v_summary, v_total, 'PENDING',
    v_uid, v_name, v_email, v_phone,
    v_address, v_notes,
    v_subtotal, v_shipping, v_total,
    'pending', 'pending_payment', 'xendit',
    v_guest_hash, nullif(btrim(coalesce(p_idempotency_key, '')), '')
  )
  returning id into v_order_id;

  insert into public.order_items (
    order_id, product_id, product_name, product_image_url,
    unit_price, quantity, subtotal
  )
  select
    v_order_id,
    (line->>'product_id')::bigint,
    line->>'product_name',
    nullif(line->>'image_url', ''),
    (line->>'unit_price')::numeric,
    (line->>'quantity')::int,
    (line->>'subtotal')::numeric
  from jsonb_array_elements(v_lines) line;

  return jsonb_build_object(
    'reference', v_ref,
    'total', v_total,
    'subtotal', v_subtotal,
    'shipping_fee', v_shipping,
    'reused', false
  );
end;
$$;

revoke all on function public.create_order(jsonb, jsonb, text, text) from public;
grant execute on function public.create_order(jsonb, jsonb, text, text) to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 6. Guest order access: requires the order access code (stored hashed)
-- ----------------------------------------------------------------------------
create or replace function public.get_guest_order(
  p_reference text,
  p_token text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_uid uuid := auth.uid();
  v_order public.orders;
  v_items jsonb;
begin
  if p_reference is null or btrim(p_reference) = '' then
    raise exception 'NOT_FOUND: Order not found.' using errcode = 'P0001';
  end if;

  select * into v_order
    from public.orders
   where external_id = upper(btrim(p_reference))
   limit 1;

  if not found then
    raise exception 'NOT_FOUND: Order not found.' using errcode = 'P0001';
  end if;

  if not (
    (v_uid is not null and v_order.user_id = v_uid)
    or (
      p_token is not null
      and v_order.guest_token_hash is not null
      and v_order.guest_token_hash = encode(extensions.digest(p_token, 'sha256'), 'hex')
    )
  ) then
    raise exception 'NOT_FOUND: Order not found.' using errcode = 'P0001';
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'product_id', oi.product_id,
        'product_name', oi.product_name,
        'product_image_url', oi.product_image_url,
        'unit_price', oi.unit_price,
        'quantity', oi.quantity,
        'subtotal', oi.subtotal
      ) order by oi.id
    ),
    '[]'::jsonb
  )
  into v_items
  from public.order_items oi
  where oi.order_id = v_order.id;

  return jsonb_build_object(
    'reference', v_order.external_id,
    'created_at', v_order.created_at,
    'customer_name', v_order.customer_name,
    'customer_email', v_order.customer_email,
    'customer_phone', v_order.customer_phone,
    'delivery_address', v_order.delivery_address,
    'notes', v_order.notes,
    'subtotal', v_order.subtotal,
    'shipping_fee', v_order.shipping_fee,
    'total_amount', v_order.total_amount,
    'payment_status', v_order.payment_status,
    'order_status', v_order.order_status,
    'payment_url', v_order.payment_url,
    'payment_expires_at', v_order.payment_expires_at,
    'paid_at', v_order.paid_at,
    'items', v_items
  );
end;
$$;

revoke all on function public.get_guest_order(text, text) from public;
grant execute on function public.get_guest_order(text, text) to anon, authenticated;

-- ----------------------------------------------------------------------------
-- 7. Payment events: service-role only, idempotent, amount-checked
-- ----------------------------------------------------------------------------
create or replace function public.apply_payment_event(
  p_reference text,
  p_event_status text,
  p_amount numeric,
  p_payment_session_id text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_order public.orders;
begin
  select * into v_order
    from public.orders
   where external_id = upper(btrim(p_reference))
   for update;

  if not found then
    raise exception 'ORDER_NOT_FOUND: No order matches this reference.' using errcode = 'P0001';
  end if;

  if p_event_status = 'paid' then
    if p_amount is null or abs(v_order.total_amount - p_amount) > 0.009 then
      raise exception 'AMOUNT_MISMATCH: Payment amount does not match the order total.'
        using errcode = 'P0001';
    end if;

    if v_order.payment_status = 'paid' then
      return jsonb_build_object('updated', false, 'payment_status', 'paid');
    end if;

    update public.orders
       set status = 'PAID',
           payment_status = 'paid',
           order_status = 'processing',
           paid_at = now(),
           payment_session_id = coalesce(p_payment_session_id, payment_session_id)
     where id = v_order.id;

    return jsonb_build_object('updated', true, 'payment_status', 'paid');
  elsif p_event_status = 'expired' then
    if v_order.payment_status = 'paid' then
      return jsonb_build_object('updated', false, 'payment_status', 'paid');
    end if;

    update public.orders
       set status = 'EXPIRED',
           payment_status = 'expired',
           order_status = 'cancelled'
     where id = v_order.id;

    return jsonb_build_object('updated', true, 'payment_status', 'expired');
  elsif p_event_status = 'failed' then
    if v_order.payment_status = 'paid' then
      return jsonb_build_object('updated', false, 'payment_status', 'paid');
    end if;

    update public.orders
       set status = 'FAILED',
           payment_status = 'failed'
     where id = v_order.id;

    return jsonb_build_object('updated', true, 'payment_status', 'failed');
  elsif p_event_status = 'cancelled' then
    if v_order.payment_status = 'paid' then
      return jsonb_build_object('updated', false, 'payment_status', 'paid');
    end if;

    update public.orders
       set status = 'CANCELLED',
           payment_status = 'cancelled',
           order_status = 'cancelled'
     where id = v_order.id;

    return jsonb_build_object('updated', true, 'payment_status', 'cancelled');
  end if;

  raise exception 'INVALID_EVENT: Unsupported payment status.' using errcode = 'P0001';
end;
$$;

revoke all on function public.apply_payment_event(text, text, numeric, text) from public, anon, authenticated;
grant execute on function public.apply_payment_event(text, text, numeric, text) to service_role;

-- ----------------------------------------------------------------------------
-- 8. Row-level security
-- ----------------------------------------------------------------------------
alter table public.products enable row level security;
drop policy if exists "Allow public read access on products" on public.products;
drop policy if exists "Active products are publicly readable" on public.products;
create policy "Active products are publicly readable"
  on public.products for select
  to anon, authenticated
  using (is_active = true);

alter table public.orders enable row level security;
drop policy if exists "Allow public read access on orders" on public.orders;
drop policy if exists "Customers can read their own orders" on public.orders;
create policy "Customers can read their own orders"
  on public.orders for select
  to authenticated
  using (user_id = auth.uid());

alter table public.order_items enable row level security;
drop policy if exists "Customers can read their own order items" on public.order_items;
create policy "Customers can read their own order items"
  on public.order_items for select
  to authenticated
  using (
    exists (
      select 1 from public.orders o
       where o.id = order_items.order_id
         and o.user_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------------------
-- 9. Normalise the catalogue values that already exist
-- ----------------------------------------------------------------------------
update public.products
   set category = 'Pins'
 where lower(btrim(category)) in ('pin', 'pins');

update public.products
   set category = 'T-shirts'
 where lower(btrim(category)) in ('shirt', 'shirts', 't-shirt', 't-shirts', 'tshirt', 'tshirts', 'tee', 'tees');

update public.products
   set category = 'Long sleeves'
 where lower(btrim(category)) in ('long sleeve', 'long sleeves', 'long-sleeve', 'long-sleeves', 'longsleeve', 'longsleeves');

update public.products
   set category = 'Lanyards'
 where lower(btrim(category)) in ('lanyard', 'lanyards');

update public.products
   set category = 'Bookmarks'
 where lower(btrim(category)) in ('bookmark', 'bookmarks', 'bible bookmark', 'bible bookmarks');

-- Hide the three unrelated sample peripherals without deleting the records.
-- Re-enable them from the Supabase Table Editor if they are ever needed.
update public.products
   set is_active = false
 where id in (1, 2, 3)
   and category is null
   and name in (
     'Mechanical Gaming Keyboard',
     'Wireless Ergonomic Mouse',
     'USB-C Hub Multiport Adapter'
   );

commit;
