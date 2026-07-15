import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const escapeHtml = (value: unknown): string =>
  String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");

async function sendResendEmail(
  apiKey: string,
  payload: Record<string, unknown>,
  idempotencyKey: string,
) {
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "Idempotency-Key": idempotencyKey,
    },
    body: JSON.stringify(payload),
  });

  const result = await response.json();
  if (!response.ok) {
    throw new Error(result?.message || "Resend rejected the email.");
  }
  return result;
}

Deno.serve(async (request: Request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authorization = request.headers.get("Authorization");
    if (!authorization) throw new Error("Missing authorization header.");

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    const fromEmail =
      Deno.env.get("JP_FIT_FROM_EMAIL") ||
      "JP Fit <onboarding@trainwithjpfit.com>";
    const coachEmail =
      Deno.env.get("JP_FIT_COACH_EMAIL") ||
      "jeremyparr18@gmail.com";

    if (!supabaseUrl || !anonKey || !serviceRoleKey) {
      throw new Error("Required Supabase environment values are unavailable.");
    }
    if (!resendApiKey) {
      throw new Error("RESEND_API_KEY is not configured.");
    }

    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authorization } },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const { data: userData, error: userError } =
      await userClient.auth.getUser();
    if (userError || !userData.user) {
      throw new Error("Unable to verify the signed-in user.");
    }

    const body = await request.json().catch(() => ({}));
    const agreementId = body?.agreementId;
    if (!agreementId) throw new Error("agreementId is required.");

    const { data: agreement, error: agreementError } = await adminClient
      .from("agreements")
      .select("*")
      .eq("id", agreementId)
      .eq("user_id", userData.user.id)
      .single();

    if (agreementError || !agreement) {
      throw new Error("The signed agreement could not be found.");
    }

    const snapshot = agreement.agreement_snapshot || {};
    const client = snapshot.client || {};
    const clientEmail = client.email || userData.user.email;
    if (!clientEmail) throw new Error("The client email address is missing.");

    const { data: existingEvent } = await adminClient
      .from("email_events")
      .select("id,status")
      .eq("agreement_id", agreement.id)
      .eq("event_type", "welcome_agreement")
      .maybeSingle();

    if (existingEvent?.status === "sent") {
      return new Response(JSON.stringify({ ok: true, skipped: true }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const service = snapshot.service || "JP Fit Coaching";
    const frequency = snapshot.frequency || "Selected frequency";
    const term = snapshot.term || "Selected agreement";
    const price =
      snapshot.price != null
        ? `$${snapshot.price} every 14 days`
        : "See Stripe checkout";
    const startDate = client.startDate || "To be confirmed";
    const signedDate = new Date(agreement.signed_at).toLocaleString(
      "en-US",
      { dateStyle: "long", timeStyle: "short" },
    );

    const clientName = escapeHtml(client.name || agreement.signed_name);
    const agreementCode = escapeHtml(agreement.agreement_code);

    const agreementTerms = `
      <div style="margin-top:28px;padding-top:24px;border-top:1px solid #333">
        <div style="color:#caff38;font-size:12px;font-weight:800;letter-spacing:2px">
          COMPLETE AGREEMENT TERMS
        </div>

        <h3>1. Coaching Services</h3>
        <p>Depending on the selected program, services may include personal training sessions, individualized workout programming, general nutrition guidance, accountability check-ins, progress tracking, exercise instruction, and reasonable coaching support. Specific schedules and deliverables may be adjusted by mutual written agreement.</p>

        <h3>2. Payments and Automatic Billing</h3>
        <p>The client authorizes recurring billing according to the selected membership. Payments are generally charged every fourteen days through Stripe. The client is responsible for maintaining a valid payment method and for any outstanding balance.</p>

        <h3>3. Session Scheduling and 24-Hour Policy</h3>
        <p>Sessions must be scheduled with the coach. A session cancelled or rescheduled with less than twenty-four hours’ notice may be charged or counted as used, except when the coach approves an exception.</p>

        <h3>4. Month-to-Month Cancellation</h3>
        <p>A month-to-month client must provide thirty days’ written notice to cancel. Charges scheduled during the notice period remain due. Cancellation requests must be submitted in writing to jeremyparr18@gmail.com.</p>

        <h3>5. Fixed-Term Agreements</h3>
        <p>Six-month and twelve-month agreements remain active for the selected minimum term. Fixed-term agreements do not automatically renew into another fixed term. Continued service afterward requires the client’s affirmative agreement or a separate month-to-month arrangement.</p>

        <h3>6. Downgrade Policy</h3>
        <p>For a six-month agreement, the client may request one reduction in training frequency after the first sixty days. For a twelve-month agreement, the client may request up to two reductions after the first ninety days. A downgrade requires written approval, applies to a future billing cycle, does not shorten the agreement term, and changes future charges to the then-current rate for the lower frequency.</p>

        <h3>7. Early Termination</h3>
        <p>A client ending a six-month or twelve-month agreement before its scheduled end must provide written notice and pay an early termination fee equal to one final biweekly payment at the client’s then-current rate. JP Fit may waive or modify the fee in writing for documented medical inability, permanent relocation, death, or another exceptional circumstance.</p>

        <h3>8. Health, Risk, and Medical Clearance</h3>
        <p>The client confirms that relevant health conditions have been disclosed and understands that exercise involves inherent risks. The client should obtain medical clearance when appropriate and must stop exercising and seek appropriate help if unusual pain, dizziness, shortness of breath, or other concerning symptoms occur.</p>

        <h3>9. Assumption of Risk and Release</h3>
        <p>To the extent permitted by law, the client voluntarily assumes the ordinary risks of exercise and releases JP Fit from claims arising from those inherent risks, except where a release is prohibited by law or where harm results from conduct that cannot legally be waived.</p>

        <h3>10. Nutrition Guidance</h3>
        <p>Nutrition information is educational and is not medical care, diagnosis, or treatment. JP Fit does not replace a physician or registered dietitian.</p>

        <h3>11. Progress Photos and Testimonials</h3>
        <p>Marketing use of progress photos or testimonials is optional and depends on the separate consent selection made by the client. Consent may be declined without affecting coaching services.</p>

        <h3>12. Electronic Records and Signature</h3>
        <p>The client consents to electronic records and intended the typed name submitted during checkout to serve as an electronic signature. The agreement snapshot and signature record are stored electronically by JP Fit.</p>

        <h3>13. Entire Agreement and Governing Law</h3>
        <p>The selected membership summary, these terms, and incorporated written policies form the agreement between the parties. Changes must be in writing. If one provision is unenforceable, the remaining provisions continue to the extent permitted by law. Florida law governs, subject to mandatory consumer rights.</p>
      </div>`;

    const clientHtml = `
<!doctype html>
<html>
<body style="margin:0;background:#0b0b0b;font-family:Arial,sans-serif;color:#fff">
  <div style="max-width:720px;margin:auto;padding:30px 18px">
    <div style="background:#171717;border:1px solid #303030;border-radius:22px;overflow:hidden">
      <div style="padding:30px;background:linear-gradient(135deg,#1d1d1d,#101010)">
        <div style="color:#caff38;font-size:12px;font-weight:800;letter-spacing:2px">WELCOME TO JP FIT</div>
        <h1 style="font-size:38px;margin:10px 0 8px">Your coaching journey starts now.</h1>
        <p style="color:#aaa;line-height:1.7">Hi ${clientName}, your JP Fit enrollment and signed coaching agreement have been received successfully.</p>
      </div>

      <div style="padding:25px 30px">
        <h2>Getting Started</h2>
        <p style="color:#bbb;line-height:1.7">Log in to complete your intake, view assigned workouts, monitor nutrition targets, submit check-ins, upload progress updates, and message Coach Jeremy.</p>
        <p>
          <a href="https://trainwithjpfit.com/auth.html" style="display:inline-block;background:#caff38;color:#111;text-decoration:none;font-weight:800;border-radius:999px;padding:13px 20px">
            OPEN MY JP FIT
          </a>
        </p>

        <div style="margin-top:28px;padding:20px;background:#101010;border:1px solid #303030;border-radius:16px">
          <h2 style="margin-top:0">Enrollment Summary</h2>
          <p><strong>Service:</strong> ${escapeHtml(service)}</p>
          <p><strong>Frequency:</strong> ${escapeHtml(frequency)}</p>
          <p><strong>Agreement:</strong> ${escapeHtml(term)}</p>
          <p><strong>Payment:</strong> ${escapeHtml(price)}</p>
          <p><strong>Start date:</strong> ${escapeHtml(startDate)}</p>
        </div>

        <div style="margin-top:28px;padding-top:24px;border-top:1px solid #333">
          <div style="color:#caff38;font-size:12px;font-weight:800;letter-spacing:2px">SIGNED AGREEMENT RECEIPT</div>
          <h2>Electronic Signature Record</h2>
          <p><strong>Agreement ID:</strong> ${agreementCode}</p>
          <p><strong>Signed by:</strong> ${escapeHtml(agreement.signed_name)}</p>
          <p><strong>Signed:</strong> ${escapeHtml(signedDate)}</p>
          <p><strong>Agreement version:</strong> ${escapeHtml(agreement.agreement_version || "JP Fit v1")}</p>
          <p><strong>Photo/testimonial consent:</strong> ${agreement.photo_consent ? "Granted" : "Not granted"}</p>
        </div>

        ${agreementTerms}

        <p style="margin-top:28px;font-size:12px;color:#888;line-height:1.6">
          This email is an electronic receipt of the agreement stored by JP Fit. Keep it for your records. Contact ${escapeHtml(coachEmail)} with questions or to request an additional copy.
        </p>
      </div>
    </div>
    <p style="text-align:center;color:#777;font-size:12px;margin-top:18px">JP Fit · Fitness Anytime. Anywhere.</p>
  </div>
</body>
</html>`;

    const coachHtml = `
<!doctype html>
<html>
<body style="margin:0;background:#0b0b0b;font-family:Arial,sans-serif;color:#fff">
  <div style="max-width:640px;margin:auto;padding:30px 18px">
    <div style="background:#171717;border:1px solid #303030;border-radius:20px;padding:26px">
      <div style="color:#caff38;font-size:12px;font-weight:800;letter-spacing:2px">NEW JP FIT ENROLLMENT</div>
      <h1>${clientName} signed an agreement.</h1>
      <p><strong>Email:</strong> ${escapeHtml(clientEmail)}</p>
      <p><strong>Phone:</strong> ${escapeHtml(client.phone || "Not provided")}</p>
      <p><strong>Service:</strong> ${escapeHtml(service)}</p>
      <p><strong>Frequency:</strong> ${escapeHtml(frequency)}</p>
      <p><strong>Term:</strong> ${escapeHtml(term)}</p>
      <p><strong>Payment:</strong> ${escapeHtml(price)}</p>
      <p><strong>Start date:</strong> ${escapeHtml(startDate)}</p>
      <p><strong>Agreement ID:</strong> ${agreementCode}</p>
      <p><a href="https://trainwithjpfit.com/coach-dashboard.html" style="display:inline-block;background:#caff38;color:#111;text-decoration:none;font-weight:800;border-radius:999px;padding:12px 18px">OPEN COACH STUDIO</a></p>
    </div>
  </div>
</body>
</html>`;

    const { data: emailEvent, error: eventError } = await adminClient
      .from("email_events")
      .upsert(
        {
          user_id: userData.user.id,
          agreement_id: agreement.id,
          event_type: "welcome_agreement",
          recipient_email: clientEmail,
          status: "pending",
          error_message: null,
        },
        { onConflict: "agreement_id,event_type" },
      )
      .select("id")
      .single();

    if (eventError) throw eventError;

    try {
      const clientResult = await sendResendEmail(
        resendApiKey,
        {
          from: fromEmail,
          to: [clientEmail],
          reply_to: coachEmail,
          subject: "Welcome to JP Fit — Your Signed Agreement",
          html: clientHtml,
        },
        `jpfit-client-${agreement.id}`,
      );

      await sendResendEmail(
        resendApiKey,
        {
          from: fromEmail,
          to: [coachEmail],
          reply_to: clientEmail,
          subject: `New JP Fit Client — ${client.name || agreement.signed_name}`,
          html: coachHtml,
        },
        `jpfit-coach-${agreement.id}`,
      );

      await adminClient
        .from("email_events")
        .update({
          status: "sent",
          provider_message_id: clientResult.id,
          sent_at: new Date().toISOString(),
          error_message: null,
        })
        .eq("id", emailEvent.id);

      return new Response(
        JSON.stringify({ ok: true, clientMessageId: clientResult.id }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    } catch (sendError) {
      await adminClient
        .from("email_events")
        .update({
          status: "failed",
          error_message:
            sendError instanceof Error ? sendError.message : String(sendError),
        })
        .eq("id", emailEvent.id);
      throw sendError;
    }
  } catch (error) {
    return new Response(
      JSON.stringify({
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      }),
      {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
