// ============================================================================
// ELEVATE MERCH — xendit-webhook
// ============================================================================
// Deploy: npx supabase functions deploy xendit-webhook --no-verify-jwt
//
// Required function secrets:
//   XENDIT_CALLBACK_TOKEN   (Dashboard -> Settings -> Developers -> Webhooks)
//
// Xendit signs every webhook with the x-callback-token header. We compare it in
// constant time, then hand the event to public.apply_payment_event(), which is
// callable only by the service role. That function validates the reference and
// the amount, and is idempotent, so duplicate deliveries are safe.
//
// This endpoint accepts both the current Payment Session webhooks and the
// legacy Invoice webhooks, in case the dashboard still has the old event
// selected while migrating.
// ============================================================================

import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type, x-callback-token',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function constantTimeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i += 1) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}

type NormalizedEvent = {
  reference: string;
  status: string;
  amount: number | null;
  sessionId: string | null;
};

function normalize(body: Record<string, unknown>): NormalizedEvent | null {
  const event = typeof body.event === 'string' ? body.event : '';
  const data = (body.data ?? null) as Record<string, unknown> | null;

  // Current Payment Session webhooks
  if (event.startsWith('payment_session.') && data) {
    const status = String(data.status ?? '');
    return {
      reference: String(data.reference_id ?? '').toUpperCase(),
      status,
      amount: data.amount == null ? null : Number(data.amount),
      sessionId: data.payment_session_id ? String(data.payment_session_id) : null,
    };
  }

  // Legacy Invoice webhooks
  if (body.external_id != null) {
    return {
      reference: String(body.external_id).toUpperCase(),
      status: String(body.status ?? ''),
      amount: body.amount == null ? null : Number(body.amount),
      sessionId: body.id ? String(body.id) : null,
    };
  }

  return null;
}

function mapStatus(raw: string): string | null {
  switch (raw.toUpperCase()) {
    case 'COMPLETED':
    case 'PAID':
    case 'SETTLED':
      return 'paid';
    case 'EXPIRED':
      return 'expired';
    case 'FAILED':
      return 'failed';
    case 'CANCELED':
    case 'CANCELLED':
      return 'cancelled';
    default:
      return null; // ACTIVE / PENDING — nothing to record yet
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'METHOD_NOT_ALLOWED' }, 405);

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const callbackToken =
      Deno.env.get('XENDIT_CALLBACK_TOKEN') ??
      Deno.env.get('XENDIT_WEBHOOK_TOKEN');

    if (!supabaseUrl || !serviceKey || !callbackToken) {
      console.error('xendit-webhook: required function secrets are missing.');
      return json({ error: 'SERVER_NOT_CONFIGURED' }, 500);
    }

    const suppliedToken = req.headers.get('x-callback-token') ?? '';
    if (!constantTimeEqual(suppliedToken, callbackToken)) {
      console.warn('xendit-webhook: rejected a request with an invalid callback token.');
      return json({ error: 'UNAUTHORIZED' }, 401);
    }

    const body = await req.json().catch(() => null);
    if (!body || typeof body !== 'object') return json({ error: 'INVALID_PAYLOAD' }, 400);

    const event = normalize(body as Record<string, unknown>);
    if (!event || !event.reference) return json({ error: 'INVALID_PAYLOAD' }, 400);

    const mapped = mapStatus(event.status);
    if (!mapped) {
      console.log('xendit-webhook: ignored non-terminal event for', event.reference);
      return json({ received: true, ignored: true });
    }

    const service = createClient(supabaseUrl, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const { data, error } = await service.rpc('apply_payment_event', {
      p_reference: event.reference,
      p_event_status: mapped,
      p_amount: event.amount,
      p_payment_session_id: event.sessionId,
    });

    if (error) {
      const message = error.message ?? '';
      if (message.includes('ORDER_NOT_FOUND')) {
        console.warn('xendit-webhook: no local order for', event.reference);
        return json({ error: 'ORDER_NOT_FOUND' }, 404);
      }
      if (message.includes('AMOUNT_MISMATCH')) {
        console.error('xendit-webhook: amount mismatch for', event.reference);
        return json({ error: 'AMOUNT_MISMATCH' }, 400);
      }
      console.error('xendit-webhook: processing failed for', event.reference, error.code);
      return json({ error: 'PROCESSING_FAILED' }, 500);
    }

    console.log('xendit-webhook: processed', event.reference, mapped);
    return json({ received: true, result: data });
  } catch (error) {
    console.error('xendit-webhook: unexpected error', error instanceof Error ? error.name : 'unknown');
    return json({ error: 'SERVER_ERROR' }, 500);
  }
});
