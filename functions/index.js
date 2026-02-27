const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");

admin.initializeApp();
const db = admin.firestore();
const openAiApiKey = defineSecret("OPENAI_API_KEY");
const geminiApiKey = defineSecret("GEMINI_API_KEY");

function normalizeEmail(email) {
  return String(email || "").trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

function isValidCode(code) {
  return /^\d{6}$/.test(code);
}

function isStrongPassword(password) {
  if (typeof password !== "string") return false;
  if (password.length < 8) return false;
  if (!/[A-Za-z]/.test(password)) return false;
  if (!/\d/.test(password)) return false;
  return true;
}

function extractJsonObject(text) {
  const raw = String(text || "").trim();
  if (!raw) return null;
  const fenced = raw.match(/```(?:json)?\s*([\s\S]*?)```/i);
  const candidate = fenced ? fenced[1].trim() : raw;
  const start = candidate.indexOf("{");
  const end = candidate.lastIndexOf("}");
  if (start === -1 || end === -1 || end < start) return null;
  try {
    return JSON.parse(candidate.slice(start, end + 1));
  } catch (_) {
    return null;
  }
}

async function runOpenAiModeration(text, apiKey) {
  const res = await fetch("https://api.openai.com/v1/moderations", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: "omni-moderation-latest",
      input: text,
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`OpenAI moderation failed (${res.status}): ${body}`);
  }
  const data = await res.json();
  const result = data?.results?.[0] || {};
  const categories = result.categories || {};
  const blocked = Boolean(
      categories.hate ||
      categories["hate/threatening"] ||
      categories.harassment ||
      categories["harassment/threatening"] ||
      categories["self-harm"] ||
      categories["self-harm/intent"] ||
      categories["self-harm/instructions"],
  );
  return {
    safe: !blocked,
    reason: blocked ?
      "Blocked by OpenAI moderation (hate/harassment/self-harm)." :
      "",
  };
}

async function runGeminiSafetyCheck(text, apiKey) {
  const prompt = [
    "You are a safety bot for TeenWorkly.",
    "Flag this post if an adult is asking a teen to meet in private,",
    "asking for photos, or sounds like a scam.",
    'Respond with JSON only: {"safe": boolean, "reason": string}.',
    "",
    "Post:",
    text,
  ].join("\n");

  const res = await fetch(
      "https://generativelanguage.googleapis.com/v1beta/models/" +
      `gemini-2.0-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: {"Content-Type": "application/json"},
        body: JSON.stringify({
          contents: [{parts: [{text: prompt}]}],
          generationConfig: {
            temperature: 0.1,
            maxOutputTokens: 200,
          },
        }),
      },
  );
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Gemini check failed (${res.status}): ${body}`);
  }
  const data = await res.json();
  const textOut =
    data?.candidates?.[0]?.content?.parts?.map((p) => p.text || "").join("") ||
    "";
  const parsed = extractJsonObject(textOut);
  if (!parsed || typeof parsed.safe !== "boolean") {
    throw new Error("Gemini did not return valid safety JSON.");
  }
  return {
    safe: parsed.safe,
    reason: String(parsed.reason || "").trim(),
  };
}

exports.validatePost = onCall(
    {secrets: [openAiApiKey, geminiApiKey]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError(
            "unauthenticated",
            "You must be signed in to validate content.",
        );
      }
      const text = String(request.data?.text || "").trim();
      if (!text) {
        throw new HttpsError("invalid-argument", "Post text is required.");
      }
      if (text.length > 8000) {
        throw new HttpsError("invalid-argument", "Post text is too long.");
      }

      const openAiKey = openAiApiKey.value();
      const geminiKey = geminiApiKey.value();
      if (!openAiKey || !geminiKey) {
        throw new HttpsError(
            "failed-precondition",
            "Safety keys are not configured on backend.",
        );
      }

      try {
        const openAiResult = await runOpenAiModeration(text, openAiKey);
        if (!openAiResult.safe) {
          throw new HttpsError("permission-denied", openAiResult.reason);
        }

        const geminiResult = await runGeminiSafetyCheck(text, geminiKey);
        if (!geminiResult.safe) {
          throw new HttpsError(
              "permission-denied",
              geminiResult.reason || "Blocked by TeenWorkly safety policy.",
          );
        }

        return {safe: true, reason: ""};
      } catch (e) {
        if (e instanceof HttpsError) throw e;
        throw new HttpsError(
            "internal",
            `Safety validation failed: ${e?.message || String(e)}`,
        );
      }
    },
);

exports.issuePasswordResetCode = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = String(request.data?.code || "").trim();

  if (!isValidEmail(email) || !isValidCode(code)) {
    throw new HttpsError("invalid-argument", "Invalid email or code format.");
  }

  const expiresAt = admin.firestore.Timestamp.fromMillis(
      Date.now() + 15 * 60 * 1000,
  );

  const existing = await db
      .collection("password_reset_codes")
      .where("email", "==", email)
      .where("used", "==", false)
      .get();

  const batch = db.batch();
  for (const doc of existing.docs) {
    batch.update(doc.ref, {
      used: true,
      invalidatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  const newRef = db.collection("password_reset_codes").doc();
  batch.set(newRef, {
    email,
    code,
    used: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt,
  });
  await batch.commit();

  return {ok: true, expiresInSeconds: 900};
});

exports.resetPasswordWithCode = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = String(request.data?.code || "").trim();
  const newPassword = String(request.data?.newPassword || "");

  if (!isValidEmail(email) || !isValidCode(code)) {
    throw new HttpsError("invalid-argument", "Invalid email or code.");
  }
  if (!isStrongPassword(newPassword)) {
    throw new HttpsError("invalid-argument", "New password is too weak.");
  }

  const match = await db
      .collection("password_reset_codes")
      .where("email", "==", email)
      .where("code", "==", code)
      .where("used", "==", false)
      .limit(1)
      .get();

  if (match.empty) {
    throw new HttpsError("invalid-argument", "Invalid code.");
  }

  const doc = match.docs[0];
  const data = doc.data();
  const expiresAtMs = data.expiresAt?.toMillis?.() || 0;
  if (Date.now() > expiresAtMs) {
    await doc.ref.update({
      used: true,
      expiredAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw new HttpsError("deadline-exceeded", "Code has expired.");
  }

  let user;
  try {
    user = await admin.auth().getUserByEmail(email);
  } catch (_) {
    throw new HttpsError("not-found", "No account found for this email.");
  }

  await admin.auth().updateUser(user.uid, {password: newPassword});
  await doc.ref.update({
    used: true,
    usedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {ok: true};
});

exports.verifyPasswordResetCodeOnly = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = String(request.data?.code || "").trim();

  if (!isValidEmail(email) || !isValidCode(code)) {
    throw new HttpsError("invalid-argument", "Invalid email or code.");
  }

  const match = await db
      .collection("password_reset_codes")
      .where("email", "==", email)
      .where("code", "==", code)
      .where("used", "==", false)
      .limit(1)
      .get();

  if (match.empty) {
    throw new HttpsError("invalid-argument", "Invalid code.");
  }

  const doc = match.docs[0];
  const data = doc.data();
  const expiresAtMs = data.expiresAt?.toMillis?.() || 0;
  if (Date.now() > expiresAtMs) {
    await doc.ref.update({
      used: true,
      expiredAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw new HttpsError("deadline-exceeded", "Code has expired.");
  }

  return {ok: true};
});

exports.signInWithCode = onCall(async (request) => {
  const email = normalizeEmail(request.data?.email);
  const code = String(request.data?.code || "").trim();

  if (!isValidEmail(email) || !isValidCode(code)) {
    throw new HttpsError("invalid-argument", "Invalid email or code.");
  }

  const match = await db
      .collection("password_reset_codes")
      .where("email", "==", email)
      .where("code", "==", code)
      .where("used", "==", false)
      .limit(1)
      .get();

  if (match.empty) {
    throw new HttpsError("invalid-argument", "Invalid code.");
  }

  const doc = match.docs[0];
  const data = doc.data();
  const expiresAtMs = data.expiresAt?.toMillis?.() || 0;
  if (Date.now() > expiresAtMs) {
    await doc.ref.update({
      used: true,
      expiredAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    throw new HttpsError("deadline-exceeded", "Code has expired.");
  }

  let user;
  try {
    user = await admin.auth().getUserByEmail(email);
  } catch (_) {
    throw new HttpsError("not-found", "No account found for this email.");
  }

  await doc.ref.update({
    used: true,
    usedForSignInAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const customToken = await admin.auth().createCustomToken(user.uid);
  return {ok: true, customToken};
});
