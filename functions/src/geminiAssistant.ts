import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";

function assertAdmin(context: { auth?: { uid: string; token: Record<string, unknown> } }) {
  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const role = context.auth.token.role as string | undefined;
  if (
    role !== "admin_general_owner" &&
    role !== "admin_general" &&
    role !== "admin_simple"
  ) {
    throw new HttpsError("permission-denied", "Accès non autorisé.");
  }
}

/** Assistant IA — clé Gemini côté serveur uniquement. */
export const askGeminiAssistantCallable = onCall(async (request) => {
  assertAdmin(request);
  const { prompt, role } = request.data as { prompt?: string; role?: string };
  if (!prompt?.trim()) {
    throw new HttpsError("invalid-argument", "Question requise.");
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return {
      answer: "Assistant en configuration. Contactez le responsable principal.",
      role: role ?? "admin",
    };
  }

  try {
    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`;
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt.slice(0, 4000) }] }],
      }),
    });
    const json = (await res.json()) as {
      candidates?: Array<{ content?: { parts?: Array<{ text?: string }> } }>;
    };
    const text =
      json.candidates?.[0]?.content?.parts?.[0]?.text ??
      "Réponse indisponible pour le moment.";
    await admin.firestore().collection("aiChatHistory").add({
      prompt: prompt.slice(0, 500),
      role: role ?? "admin",
      createdAt: new Date().toISOString(),
      city: "Lubumbashi",
    });
    return { answer: text };
  } catch {
    return { answer: "Assistant indisponible. Réessayez plus tard." };
  }
});

/** Seed tous les comptes staff — idempotent. */
export const seedAdminAccountsCallable = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const actorRole = request.auth.token.role as string | undefined;
  if (actorRole !== "admin_general_owner") {
    throw new HttpsError("permission-denied", "Réservé au responsable principal.");
  }

  const seeds = [
    { email: "verdicky9@gmail.com", login: "verdick", name: "Verdick Yav", role: "admin_general_owner", pwd: "Verd@2026", isOwner: true },
    { email: "jeno@medialubumbashi.app", login: "jeno", name: "Jeno", role: "admin_general", pwd: "Jeno@2026", isOwner: false },
    { email: "alex@gmail.com", login: "alex", name: "Alex", role: "admin_simple", pwd: "Alex@2026", isOwner: false },
    { email: "mechack@gmail.com", login: "mechack", name: "Mechack", role: "attendance_operator", pwd: "Mechack@2026", isOwner: false },
    { email: "bisibo@gmail.com", login: "bisibo", name: "Bisibo", role: "attendance_operator", pwd: "Bisibo@2026", isOwner: false },
  ];

  let created = 0;
  let updated = 0;

  for (const s of seeds) {
    let uid: string;
    try {
      uid = (await admin.auth().getUserByEmail(s.email)).uid;
      await admin.auth().updateUser(uid, { password: s.pwd, disabled: false });
      updated++;
    } catch {
      const u = await admin.auth().createUser({
        email: s.email,
        password: s.pwd,
        displayName: s.name,
      });
      uid = u.uid;
      created++;
    }
    await admin.firestore().collection("users").doc(uid).set(
      {
        email: s.email,
        loginIdentifier: s.login,
        displayName: s.name,
        fullName: s.name,
        role: s.role,
        roles: [s.role],
        isOwner: s.isOwner,
        isActive: true,
        mustChangePassword: true,
        city: "Lubumbashi",
        updatedAt: new Date().toISOString(),
      },
      { merge: true },
    );
  }

  await admin.firestore().collection("auditLogs").add({
    actorId: request.auth.uid,
    action: "seed_admin_accounts",
    createdAt: new Date().toISOString(),
    metadata: { created, updated },
  });

  return { success: true, message: "Comptes configurés avec succès.", created, updated };
});

export const createAppointmentCallable = onCall(async (request) => {
  assertAdmin(request);
  const { title, scheduledAt, assigneeId, type } = request.data as {
    title?: string;
    scheduledAt?: string;
    assigneeId?: string;
    type?: string;
  };
  if (!title || !scheduledAt) {
    throw new HttpsError("invalid-argument", "title et scheduledAt requis.");
  }
  const ref = admin.firestore().collection("appointments").doc();
  await ref.set({
    id: ref.id,
    title,
    scheduledAt,
    assigneeId: assigneeId ?? null,
    type: type ?? "general",
    status: "planned",
    createdBy: request.auth!.uid,
    createdAt: new Date().toISOString(),
    city: "Lubumbashi",
  });
  return { success: true, id: ref.id };
});

export const sendNotificationCallable = onCall(async (request) => {
  assertAdmin(request);
  const { title, body, memberId } = request.data as {
    title?: string;
    body?: string;
    memberId?: string;
  };
  if (!title || !body) {
    throw new HttpsError("invalid-argument", "title et body requis.");
  }
  await admin.firestore().collection("notifications").add({
    title,
    body,
    memberId: memberId ?? null,
    createdAt: new Date().toISOString(),
    city: "Lubumbashi",
  });
  return { success: true };
});
