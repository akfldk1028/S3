/**
 * Supabase Edge Function — Process Webhook
 *
 * Backend(Vast.ai)에서 추론 완료 시 호출.
 * segmentation_results 업데이트 + 크레딧 차감.
 *
 * TODO: 실제 webhook 처리 로직 구현.
 */

import { createSupabaseAdmin } from '../_shared/supabase-client.ts';
import { corsHeaders } from '../_shared/cors.ts';

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    // TODO: API Key 검증
    // const apiKey = req.headers.get('X-API-Key');

    const body = await req.json();
    const { task_id, status, mask_url, labels, metadata } = body;

    // TODO: Supabase admin 클라이언트
    // const supabase = createSupabaseAdmin();

    // TODO: segmentation_results 업데이트
    // await supabase.from('segmentation_results').update({
    //   status,
    //   mask_image_url: mask_url,
    //   labels,
    //   metadata,
    //   updated_at: new Date().toISOString(),
    // }).eq('id', task_id);

    // TODO: 크레딧 차감 (usage_logs INSERT + users_profile UPDATE)

    return new Response(JSON.stringify({ success: true }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ success: false, error: String(error) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
