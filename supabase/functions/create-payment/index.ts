// ============================================================================
// ELEVATE MERCH — create-payment
// ============================================================================
// Deploy: npx supabase functions deploy create-payment --no-verify-jwt
//
// Required function secrets:
//   XENDIT_SECRET_KEY       (test key while in sandbox: xnd_development_...)
//   XENDIT_CALLBACK_TOKEN   (Dashboard -> Settings -> Developers -> Webhooks)
// Optional:
//   STOREFRONT_URL          (must be https to be used as a return URL)
//
// The amount is never accepted from the client. It is read from the order row,
// which was itself written by public.create_order() from catalogue prices.
// ============================================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function safeName(value: string | null | undefined): { given: string; surname: string } {
  const cleaned = (value ?? '')
    .replace(/[^A-Za-z0-9\s.-]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  const parts = cleaned.split(' ').filter(Boolean);
  return {
    given: (parts[0] ?? 'Customer').slice(0, 60),
    surname: parts.slice(1).join(' ').slice(0, 60),
  };
}

function hex(buffer: ArrayBuffer): string {
  return Array.from(new Uint8Array(buffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(value));
  return hex(digest);
}

function xenditAuthorization(secret: string): string {
  // Basic auth: secret key as username, empty password.
  return 'Basic ' + btoa(`${secret}:`);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'METHOD_NOT_ALLOWED' }, 405);

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY');
    const xenditKey =
      Deno.env.get('XENDIT_SECRET_KEY') ??
      Deno.env.get('elevate_merch') ??
      Deno.env.get('ELEVATE_MERCH');
    const storefrontUrl = Deno.env.get('STOREFRONT_URL');

    if (!supabaseUrl || !serviceKey) {
      console.error('create-payment: Supabase function secrets are missing.');
      return json({ error: 'SERVER_NOT_CONFIGURED' }, 500);
    }
    if (!xenditKey) {
      console.error('create-payment: XENDIT_SECRET_KEY is not set.');
      return json({ error: 'PAYMENT_NOT_CONFIGURED' }, 503);
    }

    const body = await req.json().catch(() => null);
    const reference = typeof body?.reference === 'string' ? body.reference.trim().toUpperCase() : '';
    const token = typeof body?.token === 'string' ? body.token.trim() : '';
    if (!/^ELV-[A-Z0-9]{6,20}$/.test(reference)) {
      return json({ error: 'INVALID_REFERENCE' }, 400);
    }

    const service = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    // Identify the caller, if they are signed in.
    let userId: string | null = null;
    const authHeader = req.headers.get('Authorization');
    if (authHeader?.startsWith('Bearer ') && anonKey) {
      const caller = createClient(supabaseUrl, anonKey, {
        global: { headers: { Authorization: authHeader } },
        auth: { persistSession: false, autoRefreshToken: false },
      });
      const { data } = await caller.auth.getUser();
      userId = data.user?.id ?? null;
    }

    const { data: order, error: orderError } = await service
      .from('orders')
      .select('*')
      .eq('external_id', reference)
      .maybeSingle();

    if (orderError) {
      console.error('create-payment: order lookup failed', orderError.code);
      return json({ error: 'ORDER_LOOKUP_FAILED' }, 500);
    }
    if (!order) return json({ error: 'ORDER_NOT_FOUND' }, 404);

    // Authorisation: account owner, or the holder of the guest access code.
    let allowed = false;
    if (order.user_id) {
      allowed = userId !== null && userId === order.user_id;
    } else if (order.guest_token_hash && token) {
      allowed = (await sha256Hex(token)) === order.guest_token_hash;
    }
    if (!allowed) return json({ error: 'ORDER_NOT_FOUND' }, 404);

    if (order.payment_status === 'paid') {
      return json({ reference, status: 'paid', checkout_url: null });
    }
    if (order.payment_status === 'cancelled' || order.payment_status === 'expired') {
      return json({ error: 'ORDER_CLOSED', status: order.payment_status }, 409);
    }
    if (order.payment_status === 'failed') {
      return json({ error: 'PAYMENT_FAILED', status: 'failed' }, 409);
    }

    const total = Number(order.total_amount);
    if (!Number.isFinite(total) || total <= 0) {
      console.error('create-payment: invalid stored total for', reference);
      return json({ error: 'INVALID_ORDER_TOTAL' }, 500);
    }

    // Reuse a still-valid hosted checkout page instead of creating duplicates.
    if (order.payment_url) {
      const expiresAt = order.payment_expires_at ? new Date(order.payment_expires_at).getTime() : 0;
      if (expiresAt > Date.now() + 60_000) {
        return json({
          reference,
          status: 'pending',
          checkout_url: order.payment_url,
          expires_at: order.payment_expires_at,
        });
      }
    }

    const { data: items, error: itemsError } = await service
      .from('order_items')
      .select('product_name, unit_price, quantity, product_image_url')
      .eq('order_id', order.id)
      .order('id');

    if (itemsError || !items?.length) {
      console.error('create-payment: order items lookup failed for', reference);
      return json({ error: 'ORDER_LOOKUP_FAILED' }, 500);
    }

    const expiresAt = new Date(Date.now() + 30 * 60 * 1000).toISOString();
    const name = safeName(order.customer_name);

    const lineItems = items.map((item, index) => ({
      reference_id: `item-${index + 1}`,
      type: 'PHYSICAL_PRODUCT',
      name: String(item.product_name).slice(0, 255),
      category: 'Merch',
      net_unit_amount: Number(item.unit_price),
      quantity: Number(item.quantity),
      currency: 'PHP',
      ...(item.product_image_url ? { image_url: item.product_image_url } : {}),
    }));

    if (Number(order.shipping_fee) > 0) {
      lineItems.push({
        reference_id: 'shipping',
        type: 'FEE',
        name: 'Shipping',
        category: 'Fee',
        net_unit_amount: Number(order.shipping_fee),
        quantity: 1,
        currency: 'PHP',
      });
    }

    const validEmail =
      typeof order.customer_email === 'string' &&
      order.customer_email.length <= 50 &&
      /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(order.customer_email);

    const mobile =
      typeof order.customer_phone === 'string' && /^\+[1-9][0-9]{7,14}$/.test(order.customer_phone)
        ? order.customer_phone
        : undefined;

    const isHttps = typeof storefrontUrl === 'string' && /^https:\/\/[^\s]+$/i.test(storefrontUrl);
    const returnUrl = isHttps
      ? `${storefrontUrl!.replace(/\/+$/, '')}/?order=${encodeURIComponent(reference)}`
      : undefined;

    const sessionPayload = {
      reference_id: reference,
      session_type: 'PAY',
      mode: 'PAYMENT_LINK',
      amount: total,
      currency: 'PHP',
      country: 'PH',
      locale: 'en',
      description: `ELEVATE MERCH order ${reference}`,
      expires_at: expiresAt,
      customer: {
        reference_id: `cust${order.id}`,
        type: 'INDIVIDUAL',
        ...(validEmail ? { email: order.customer_email } : {}),
        ...(mobile ? { mobile_number: mobile } : {}),
        individual_detail: {
          given_names: name.given,
          ...(name.surname ? { surname: name.surname } : {}),
        },
      },
      items: lineItems,
      metadata: { order_reference: reference },
      ...(returnUrl ? { success_return_url: returnUrl, cancel_return_url: returnUrl } : {}),
    };

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 20_000);

    let xenditResponse: Response;
    try {
      xenditResponse = await fetch('https://api.xendit.co/sessions', {
        method: 'POST',
        headers: {
          Authorization: xenditAuthorization(xenditKey),
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(sessionPayload),
        signal: controller.signal,
      });
    } finally {
      clearTimeout(timeout);
    }

    const xenditBody = await xenditResponse.json().catch(() => null);

    if (!xenditResponse.ok) {
      console.error(
        'create-payment: Xendit rejected the session',
        xenditResponse.status,
        xenditBody?.error_code ?? 'unknown',
      );
      return json({ error: 'PAYMENT_PROVIDER_ERROR' }, 502);
    }

    const checkoutUrl = xenditBody?.payment_link_url;
    const sessionId = xenditBody?.payment_session_id;

    if (typeof checkoutUrl !== 'string' || typeof sessionId !== 'string') {
      console.error('create-payment: Xendit response did not include a checkout URL.');
      return json({ error: 'PAYMENT_PROVIDER_ERROR' }, 502);
    }

    const { error: updateError } = await service
      .from('orders')
      .update({
        payment_provider: 'xendit',
        payment_session_id: sessionId,
        payment_url: checkoutUrl,
        payment_expires_at: expiresAt,
      })
      .eq('id', order.id)
      .eq('payment_status', 'pending');

    if (updateError) {
      console.error('create-payment: could not save checkout URL for', reference, updateError.code);
      // The webhook can still reconcile by reference, so the customer can pay.
    }

    console.log('create-payment: session created for', reference);
    return json({
      reference,
      status: 'pending',
      checkout_url: checkoutUrl,
      expires_at: expiresAt,
    });
  } catch (error) {
    console.error('create-payment: unexpected error', error instanceof Error ? error.name : 'unknown');
    return json({ error: 'SERVER_ERROR' }, 500);
  }
});
