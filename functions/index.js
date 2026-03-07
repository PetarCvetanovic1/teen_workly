const admin = require("firebase-admin");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onObjectFinalized} = require("firebase-functions/v2/storage");
const {defineSecret} = require("firebase-functions/params");
const crypto = require("crypto");
const os = require("os");
const path = require("path");
const fs = require("fs/promises");
const sharp = require("sharp");

admin.initializeApp();
const db = admin.firestore();
const openAiApiKey = defineSecret("OPENAI_API_KEY");
const geminiApiKey = defineSecret("GEMINI_API_KEY");
const CONTACT_INFO_RE = /(?:\+?\d[\d\s().-]{7,}\d)|(?:[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,})|(?:^|\s)(@[\w._]{2,}|snap(?:chat)?|instagram|insta|ig|tiktok|discord|telegram|whatsapp)\b/i;

function containsContactInfo(text) {
  return CONTACT_INFO_RE.test(String(text || ""));
}

function approximateLabelFromLocation(location) {
  const parts = String(location || "")
      .split(",")
      .map((p) => p.trim())
      .filter(Boolean);
  const adminOrCountry = /\b(region|county|district|state|province|canada|usa|united states|ontario|quebec|alberta|manitoba|saskatchewan|british columbia|nova scotia|new brunswick|newfoundland|prince edward island|pei)\b/i;
  const streetWords = /\b(st|street|ave|avenue|rd|road|cres|crescent|blvd|boulevard|dr|drive|lane|ln|way|court|ct)\b/i;
  const postalLike = /(^\d{5}(-\d{4})?$)|(^[A-Z]\d[A-Z][ -]?\d[A-Z]\d$)/i;
  let city = "";
  for (const p of parts) {
    if (/\d/.test(p)) continue;
    if (streetWords.test(p)) continue;
    if (postalLike.test(p)) continue;
    if (adminOrCountry.test(p)) continue;
    city = p;
    break;
  }
  if (!city) {
    city = parts.find((p) => !postalLike.test(p) && !adminOrCountry.test(p)) ||
      parts[0] ||
      "local area";
  }
  return `Near ${city} (~500m)`;
}

function fuzzCoordinates(lat, lng, seed) {
  const radiusM = 500;
  const hash = crypto.createHash("sha256").update(String(seed)).digest();
  const theta = (hash.readUInt32BE(0) / 0xffffffff) * 2 * Math.PI;
  const distanceM = (hash.readUInt32BE(4) / 0xffffffff) * radiusM;
  const dLat = (distanceM * Math.cos(theta)) / 111320;
  const lonMeters = Math.max(1, Math.abs(111320 * Math.cos((lat * Math.PI) / 180)));
  const dLng = (distanceM * Math.sin(theta)) / lonMeters;
  return {
    lat: lat + dLat,
    lng: lng + dLng,
    radiusMeters: radiusM,
  };
}

async function geocodeLocation(query) {
  const uri = new URL("https://nominatim.openstreetmap.org/search");
  uri.searchParams.set("q", String(query || "").trim());
  uri.searchParams.set("format", "jsonv2");
  uri.searchParams.set("limit", "1");
  const res = await fetch(uri.toString(), {
    headers: {"User-Agent": "TeenWorkly/1.0 (contact: support@teenworkly.app)"},
  });
  if (!res.ok) return null;
  const data = await res.json();
  if (!Array.isArray(data) || !data.length) return null;
  const lat = Number(data[0]?.lat);
  const lng = Number(data[0]?.lon);
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  return {lat, lng};
}

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

async function validateSafetyOrThrow(text) {
  const normalized = String(text || "").trim();
  if (!normalized) {
    throw new HttpsError("invalid-argument", "Text is required.");
  }
  if (normalized.length > 8000) {
    throw new HttpsError("invalid-argument", "Text is too long.");
  }

  const openAiKey = openAiApiKey.value();
  const geminiKey = geminiApiKey.value();
  if (!openAiKey || !geminiKey) {
    throw new HttpsError(
        "failed-precondition",
        "Safety keys are not configured on backend.",
    );
  }

  const openAiResult = await runOpenAiModeration(normalized, openAiKey);
  if (!openAiResult.safe) {
    throw new HttpsError("permission-denied", openAiResult.reason);
  }

  const geminiResult = await runGeminiSafetyCheck(normalized, geminiKey);
  if (!geminiResult.safe) {
    throw new HttpsError(
        "permission-denied",
        geminiResult.reason || "Blocked by TeenWorkly safety policy.",
    );
  }
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

exports.createJob = onCall(
    {secrets: [openAiApiKey, geminiApiKey]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }
      const uid = request.auth.uid;
      const job = request.data?.job || {};
      const id = String(job.id || "").trim();
      const title = String(job.title || "").trim();
      const type = String(job.type || "").trim();
      const location = String(job.location || "").trim();
      const description = String(job.description || "").trim();
      const posterId = String(job.posterId || "").trim();
      const posterName = String(job.posterName || "").trim();
      const services = Array.isArray(job.services) ? job.services : [];
      const otherService = job.otherService == null ? null :
        String(job.otherService).trim();
      const payment = Number(job.payment || 0);
      const createdAtMs = Number(job.createdAtMs || Date.now());
      const profileSnap = await db.collection("users").doc(uid).get();
      const profile = profileSnap.exists ? profileSnap.data() : {};
      const age = Number(profile?.age ?? 18);
      const isMinorPoster = age < 18;
      const publicLocation = isMinorPoster ?
        approximateLabelFromLocation(location) : location;
      let fuzzy = null;
      try {
        const coords = await geocodeLocation(location);
        if (coords) {
          fuzzy = fuzzCoordinates(coords.lat, coords.lng, `${uid}|${id}|job`);
        }
      } catch (_) {}

      if (!id || !title || !type || !location || !description || !posterName) {
        throw new HttpsError("invalid-argument", "Missing required job fields.");
      }
      if (posterId !== uid) {
        throw new HttpsError("permission-denied", "Poster mismatch.");
      }
      if (description.length < 8) {
        throw new HttpsError("invalid-argument", "Description is too short.");
      }
      if (!Number.isFinite(payment) || payment < 5 || payment > 5000) {
        throw new HttpsError("invalid-argument", "Invalid payment amount.");
      }

      const moderationText = [
        `Title: ${title}`,
        `Type: ${type}`,
        `Location: ${location}`,
        `Description: ${description}`,
        `Services: ${services.join(", ")}`,
        otherService ? `Other Service: ${otherService}` : "",
      ].filter(Boolean).join("\n");
      await validateSafetyOrThrow(moderationText);

      await db.collection("jobs").doc(id).set({
        title,
        type,
        location: publicLocation,
        publicLocation,
        isMinorPoster,
        publicLat: fuzzy?.lat ?? null,
        publicLng: fuzzy?.lng ?? null,
        publicRadiusMeters: fuzzy?.radiusMeters ?? 500,
        description,
        services: services.map((s) => String(s)),
        otherService,
        posterId: uid,
        posterName,
        createdAt: admin.firestore.Timestamp.fromMillis(createdAtMs),
        applicantIds: [],
        applicantNames: [],
        hiredId: null,
        hiredName: null,
        status: "open",
        payment,
      }, {merge: false});

      return {ok: true};
    },
);

exports.createService = onCall(
    {secrets: [openAiApiKey, geminiApiKey]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }
      const uid = request.auth.uid;
      const service = request.data?.service || {};
      const id = String(service.id || "").trim();
      const providerName = String(service.providerName || "").trim();
      const location = String(service.location || "").trim();
      const skills = Array.isArray(service.skills) ? service.skills : [];
      const otherSkill = service.otherSkill == null ? null :
        String(service.otherSkill).trim();
      const availableDays = Array.isArray(service.availableDays) ?
        service.availableDays : [];
      const startHour = Number(service.startHour ?? 9);
      const startMinute = Number(service.startMinute ?? 0);
      const endHour = Number(service.endHour ?? 17);
      const endMinute = Number(service.endMinute ?? 0);
      const bio = String(service.bio || "").trim();
      const providerId = String(service.providerId || "").trim();
      const createdAtMs = Number(service.createdAtMs || Date.now());
      const minPrice = Number(service.minPrice || 0);
      const maxPrice = Number(service.maxPrice || 0);
      const workRadiusKm = Number(service.workRadiusKm || 5);
      const profileSnap = await db.collection("users").doc(uid).get();
      const profile = profileSnap.exists ? profileSnap.data() : {};
      const age = Number(profile?.age ?? 18);
      const isMinorProvider = age < 18;
      const publicLocation = isMinorProvider ?
        approximateLabelFromLocation(location) : location;
      let fuzzy = null;
      try {
        const coords = await geocodeLocation(location);
        if (coords) {
          fuzzy = fuzzCoordinates(coords.lat, coords.lng, `${uid}|${id}|service`);
        }
      } catch (_) {}

      if (!id || !providerName || !location || !bio) {
        throw new HttpsError("invalid-argument", "Missing required service fields.");
      }
      if (providerId !== uid) {
        throw new HttpsError("permission-denied", "Provider mismatch.");
      }
      if (bio.length < 8) {
        throw new HttpsError("invalid-argument", "Bio is too short.");
      }
      if (!Number.isFinite(minPrice) || !Number.isFinite(maxPrice) ||
          minPrice < 0 || maxPrice < minPrice) {
        throw new HttpsError("invalid-argument", "Invalid price range.");
      }
      if (!Number.isFinite(workRadiusKm) || workRadiusKm < 1 || workRadiusKm > 10) {
        throw new HttpsError("invalid-argument", "Invalid work radius.");
      }

      const moderationText = [
        `Name: ${providerName}`,
        `Location: ${location}`,
        `Skills: ${skills.join(", ")}`,
        otherSkill ? `Other skill: ${otherSkill}` : "",
        `Bio: ${bio}`,
      ].filter(Boolean).join("\n");
      await validateSafetyOrThrow(moderationText);

      await db.collection("services").doc(id).set({
        providerName,
        location: publicLocation,
        publicLocation,
        isMinorProvider,
        publicLat: fuzzy?.lat ?? null,
        publicLng: fuzzy?.lng ?? null,
        publicRadiusMeters: fuzzy?.radiusMeters ?? 500,
        skills: skills.map((s) => String(s)),
        otherSkill,
        availableDays: availableDays.map((d) => String(d)),
        startHour,
        startMinute,
        endHour,
        endMinute,
        bio,
        providerId: uid,
        createdAt: admin.firestore.Timestamp.fromMillis(createdAtMs),
        workRadiusKm,
        minPrice,
        maxPrice,
      }, {merge: false});

      return {ok: true};
    },
);

exports.updateServiceSecure = onCall(
    {secrets: [openAiApiKey, geminiApiKey]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }
      const uid = request.auth.uid;
      const service = request.data?.service || {};
      const id = String(service.id || "").trim();
      const providerName = String(service.providerName || "").trim();
      const location = String(service.location || "").trim();
      const skills = Array.isArray(service.skills) ? service.skills : [];
      const otherSkill = service.otherSkill == null ? null :
        String(service.otherSkill).trim();
      const availableDays = Array.isArray(service.availableDays) ?
        service.availableDays : [];
      const startHour = Number(service.startHour ?? 9);
      const startMinute = Number(service.startMinute ?? 0);
      const endHour = Number(service.endHour ?? 17);
      const endMinute = Number(service.endMinute ?? 0);
      const bio = String(service.bio || "").trim();
      const providerId = String(service.providerId || "").trim();
      const createdAtMs = Number(service.createdAtMs || Date.now());
      const minPrice = Number(service.minPrice || 0);
      const maxPrice = Number(service.maxPrice || 0);
      const workRadiusKm = Number(service.workRadiusKm || 5);

      if (!id || !providerName || !location || !bio) {
        throw new HttpsError("invalid-argument", "Missing required service fields.");
      }
      if (providerId !== uid) {
        throw new HttpsError("permission-denied", "Provider mismatch.");
      }
      if (!Number.isFinite(workRadiusKm) || workRadiusKm < 1 || workRadiusKm > 10) {
        throw new HttpsError("invalid-argument", "Invalid work radius.");
      }
      if (!Number.isFinite(minPrice) || !Number.isFinite(maxPrice) ||
          minPrice < 0 || maxPrice < minPrice) {
        throw new HttpsError("invalid-argument", "Invalid price range.");
      }

      const moderationText = [
        `Name: ${providerName}`,
        `Location: ${location}`,
        `Skills: ${skills.join(", ")}`,
        otherSkill ? `Other skill: ${otherSkill}` : "",
        `Bio: ${bio}`,
      ].filter(Boolean).join("\n");
      await validateSafetyOrThrow(moderationText);

      const profileSnap = await db.collection("users").doc(uid).get();
      const profile = profileSnap.exists ? profileSnap.data() : {};
      const age = Number(profile?.age ?? 18);
      const isMinorProvider = age < 18;
      const publicLocation = isMinorProvider ?
        approximateLabelFromLocation(location) : location;

      let fuzzy = null;
      try {
        const coords = await geocodeLocation(location);
        if (coords) {
          fuzzy = fuzzCoordinates(coords.lat, coords.lng, `${uid}|${id}|service`);
        }
      } catch (_) {}

      await db.collection("services").doc(id).set({
        providerName,
        location: publicLocation,
        publicLocation,
        isMinorProvider,
        publicLat: fuzzy?.lat ?? null,
        publicLng: fuzzy?.lng ?? null,
        publicRadiusMeters: fuzzy?.radiusMeters ?? 500,
        skills: skills.map((s) => String(s)),
        otherSkill,
        availableDays: availableDays.map((d) => String(d)),
        startHour,
        startMinute,
        endHour,
        endMinute,
        bio,
        providerId: uid,
        createdAt: admin.firestore.Timestamp.fromMillis(createdAtMs),
        workRadiusKm,
        minPrice,
        maxPrice,
      }, {merge: true});

      return {ok: true};
    },
);

exports.sendConversationMessage = onCall(
    {secrets: [openAiApiKey, geminiApiKey]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }
      const uid = request.auth.uid;
      const conversationId = String(request.data?.conversationId || "").trim();
      const message = request.data?.message || {};
      const id = String(message.id || "").trim();
      const senderId = String(message.senderId || "").trim();
      const senderName = String(message.senderName || "").trim();
      const text = String(message.text || "").trim();
      const timestampMs = Number(message.timestampMs || Date.now());

      if (!conversationId || !id || !senderName || !text) {
        throw new HttpsError("invalid-argument", "Missing required message fields.");
      }
      if (senderId !== uid) {
        throw new HttpsError("permission-denied", "Sender mismatch.");
      }
      if (containsContactInfo(text)) {
        throw new HttpsError(
            "permission-denied",
            "Keep it in the app! For your safety, sharing personal contact info is disabled. Use the in-app call or chat instead.",
        );
      }
      await validateSafetyOrThrow(text);

      const convRef = db.collection("conversations").doc(conversationId);
      const convSnap = await convRef.get();
      if (!convSnap.exists) {
        throw new HttpsError("not-found", "Conversation not found.");
      }
      const conv = convSnap.data() || {};
      const participants = Array.isArray(conv.participants) ?
        conv.participants.map((p) => String(p)) : [];
      if (!participants.includes(uid)) {
        throw new HttpsError("permission-denied", "Not a participant.");
      }

      const ts = admin.firestore.Timestamp.fromMillis(timestampMs);
      const batch = db.batch();
      const msgRef = convRef.collection("messages").doc(id);
      batch.set(msgRef, {
        senderId: uid,
        senderName,
        text,
        timestamp: ts,
      });
      batch.update(convRef, {
        lastMessageAt: ts,
        lastMessageText: text,
        [`typingBy.${uid}`]: false,
        [`lastSeenBy.${uid}`]: ts,
      });
      await batch.commit();
      return {ok: true};
    },
);

exports.createHuddlePost = onCall(
    {secrets: [openAiApiKey, geminiApiKey]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }
      const uid = request.auth.uid;
      const post = request.data?.post || {};
      const id = String(post.id || "").trim();
      const authorId = String(post.authorId || "").trim();
      const authorName = String(post.authorName || "").trim();
      const text = String(post.text || "").trim();
      const tag = String(post.tag || "justChatting").trim();
      const ageGroup = String(post.ageGroup || "").trim();
      const createdAtMs = Number(post.createdAtMs || Date.now());

      if (!id || !authorName || !text || !ageGroup) {
        throw new HttpsError("invalid-argument", "Missing required post fields.");
      }
      if (authorId !== uid) {
        throw new HttpsError("permission-denied", "Author mismatch.");
      }
      await validateSafetyOrThrow(`${tag}\n${text}`);

      await db.collection("huddle_posts").doc(id).set({
        authorId: uid,
        authorName,
        text,
        tag,
        ageGroup,
        createdAt: admin.firestore.Timestamp.fromMillis(createdAtMs),
        lastReplyAt: null,
        lastReplyAuthorId: null,
        replyCount: 0,
      }, {merge: false});
      return {ok: true};
    },
);

exports.createHuddleReply = onCall(
    {secrets: [openAiApiKey, geminiApiKey]},
    async (request) => {
      if (!request.auth) {
        throw new HttpsError("unauthenticated", "Sign in required.");
      }
      const uid = request.auth.uid;
      const postId = String(request.data?.postId || "").trim();
      const reply = request.data?.reply || {};
      const id = String(reply.id || "").trim();
      const authorId = String(reply.authorId || "").trim();
      const authorName = String(reply.authorName || "").trim();
      const text = String(reply.text || "").trim();
      const createdAtMs = Number(reply.createdAtMs || Date.now());

      if (!postId || !id || !authorName || !text) {
        throw new HttpsError("invalid-argument", "Missing required reply fields.");
      }
      if (authorId !== uid) {
        throw new HttpsError("permission-denied", "Author mismatch.");
      }
      await validateSafetyOrThrow(text);

      await db.collection("huddle_posts")
          .doc(postId)
          .collection("replies")
          .doc(id)
          .set({
            authorId: uid,
            authorName,
            text,
            createdAt: admin.firestore.Timestamp.fromMillis(createdAtMs),
          }, {merge: false});
      await db.collection("huddle_posts").doc(postId).set({
        lastReplyAt: admin.firestore.Timestamp.fromMillis(createdAtMs),
        lastReplyAuthorId: uid,
        replyCount: admin.firestore.FieldValue.increment(1),
      }, {merge: true});
      return {ok: true};
    },
);

exports.reportSafetyIncident = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;
  const report = request.data?.report || {};
  const id = String(report.id || Date.now()).trim();
  const targetType = String(report.targetType || "").trim();
  const targetId = String(report.targetId || "").trim();
  const reportedUserId = report.reportedUserId ?
    String(report.reportedUserId).trim() : null;
  const reason = String(report.reason || "").trim();
  const blocked = report.blocked === true;
  const createdAtMs = Number(report.createdAtMs || Date.now());

  if (!targetType || !targetId || !reason) {
    throw new HttpsError("invalid-argument", "Missing required report fields.");
  }

  await db.collection("reports").doc(id).set({
    reporterId: uid,
    targetType,
    targetId,
    reportedUserId,
    reason,
    blocked,
    createdAt: admin.firestore.Timestamp.fromMillis(createdAtMs),
  }, {merge: false});

  const reasonLower = reason.toLowerCase();
  const creepyLike = reasonLower.includes("creepy behavior") ||
    reasonLower.includes("harassment");
  if (creepyLike && reportedUserId && reportedUserId !== uid) {
    await db.collection("users").doc(reportedUserId).set({
      shadowBanned: true,
      shadowBannedAt: admin.firestore.FieldValue.serverTimestamp(),
      shadowBanReason: "creepy_behavior_flag",
    }, {merge: true});
    await db.collection("admin_flags").add({
      type: "creepy_behavior_shadowban",
      reportId: id,
      targetUserId: reportedUserId,
      reporterId: uid,
      reason,
      targetType,
      targetId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return {ok: true};
});

exports.deleteMyAccountData = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const uid = request.auth.uid;

  const deletions = [];

  const jobsPosted = await db.collection("jobs").where("posterId", "==", uid).get();
  for (const doc of jobsPosted.docs) {
    deletions.push(db.recursiveDelete(doc.ref));
  }

  const services = await db.collection("services").where("providerId", "==", uid).get();
  for (const doc of services.docs) {
    deletions.push(db.recursiveDelete(doc.ref));
  }

  const huddlePosts = await db.collection("huddle_posts").where("authorId", "==", uid).get();
  for (const doc of huddlePosts.docs) {
    deletions.push(db.recursiveDelete(doc.ref));
  }

  const replies = await db.collectionGroup("replies").where("authorId", "==", uid).get();
  for (const doc of replies.docs) {
    deletions.push(doc.ref.delete());
  }

  const convs = await db.collection("conversations").where("participants", "array-contains", uid).get();
  for (const doc of convs.docs) {
    deletions.push(db.recursiveDelete(doc.ref));
  }

  const reportsByMe = await db.collection("reports").where("reporterId", "==", uid).get();
  for (const doc of reportsByMe.docs) {
    deletions.push(doc.ref.delete());
  }

  const reportsAboutMe = await db.collection("reports").where("reportedUserId", "==", uid).get();
  for (const doc of reportsAboutMe.docs) {
    deletions.push(doc.ref.delete());
  }

  const reviewsByMe = await db.collection("reviews").where("reviewerId", "==", uid).get();
  for (const doc of reviewsByMe.docs) {
    deletions.push(doc.ref.delete());
  }

  const reviewsForMe = await db.collection("reviews").where("workerId", "==", uid).get();
  for (const doc of reviewsForMe.docs) {
    deletions.push(doc.ref.delete());
  }

  deletions.push(db.collection("users").doc(uid).delete());
  await Promise.allSettled(deletions);

  try {
    const bucket = admin.storage().bucket();
    await Promise.allSettled([
      bucket.deleteFiles({prefix: `users/${uid}/`}),
      bucket.deleteFiles({prefix: `jobs/${uid}/`}),
      bucket.deleteFiles({prefix: `services/${uid}/`}),
    ]);
  } catch (_) {}

  return {ok: true};
});

exports.stripTeenImageMetadata = onObjectFinalized(async (event) => {
  const object = event.data || {};
  const name = object.name || "";
  const contentType = object.contentType || "";
  if (!name || !contentType.startsWith("image/")) return;
  if (!name.startsWith("users/") &&
      !name.startsWith("jobs/") &&
      !name.startsWith("services/")) {
    return;
  }
  const customMetadata = object.metadata || {};
  if (customMetadata.exifStripped === "true") return;

  const bucket = admin.storage().bucket(object.bucket);
  const file = bucket.file(name);
  const tmpIn = path.join(os.tmpdir(), `in-${Date.now()}-${path.basename(name)}`);
  const tmpOut = path.join(os.tmpdir(), `out-${Date.now()}-${path.basename(name)}`);

  await file.download({destination: tmpIn});
  await sharp(tmpIn).rotate().toFile(tmpOut);
  await bucket.upload(tmpOut, {
    destination: name,
    metadata: {
      contentType,
      metadata: {
        ...customMetadata,
        exifStripped: "true",
      },
    },
  });
  await Promise.allSettled([fs.unlink(tmpIn), fs.unlink(tmpOut)]);
});

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
