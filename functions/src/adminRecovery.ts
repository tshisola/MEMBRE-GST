import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as crypto from "crypto";

const OWNER_EMAIL = "verdicky9@gmail.com";
const JENO_LOGIN = "jeno";
/** Mot de passe provisoire owner — côté serveur uniquement, jamais loggé. */
const OWNER_PROVISIONAL_PASSWORD = "Verd@2026";

const OWNER_PERMISSIONS = [
  "can_manage_everything",
  "can_assign_roles",
  "can_remove_roles",
  "can_reset_passwords",
  "can_create_accounts",
  "can_activate_accounts",
  "can_disable_accounts",
  "can_delete_member",
  "can_restore_member",
  "can_view_audit_logs",
  "can_view_diagnostics",
  "can_force_sync",
  "can_manage_firebase_from_app",
];

const JENO_PERMISSIONS = [
  "can_create_accounts",
  "can_create_member",
  "can_manage_members",
  "can_manage_lists",
  "can_take_attendance",
  "can_view_sync",
  "can_reset_member_passwords",
  "can_activate_accounts",
  "can_manage_department_lists",
  "can_manage_media_roles",
  "can_manage_media_lists",
];

function assertOwner(context: { auth?: { uid: string; token: Record<string, unknown> } }) {
  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const role = context.auth.token.role as string | undefined;
  if (role !== "admin_general_owner") {
    throw new HttpsError("permission-denied", "Réservé au responsable principal.");
  }
}

async function roleFromUid(uid: string): Promise<string | undefined> {
  const snap = await admin.firestore().collection("users").doc(uid).get();
  return snap.data()?.role as string | undefined;
}

async function writeAuditLog(data: Record<string, unknown>) {
  await admin.firestore().collection("auditLogs").add({
    ...data,
    createdAt: new Date().toISOString(),
    city: "Lubumbashi",
  });
}

async function writeRecoveryLog(data: Record<string, unknown>) {
  await admin.firestore().collection("adminRecoveryLogs").add({
    ...data,
    createdAt: new Date().toISOString(),
  });
}

function generateTempPassword(): string {
  const raw = crypto.randomBytes(12).toString("base64url");
  return `Ml${raw.slice(0, 10)}!9`;
}

async function upsertAuthUser(email: string, password?: string) {
  try {
    const existing = await admin.auth().getUserByEmail(email);
    if (password) {
      await admin.auth().updateUser(existing.uid, {
        password,
        disabled: false,
        emailVerified: existing.emailVerified,
      });
    } else {
      await admin.auth().updateUser(existing.uid, { disabled: false });
    }
    return existing.uid;
  } catch (e: unknown) {
    const err = e as { code?: string };
    if (err.code !== "auth/user-not-found") throw e;
    const created = await admin.auth().createUser({
      email,
      password: password ?? generateTempPassword(),
      disabled: false,
    });
    return created.uid;
  }
}

async function upsertUserDoc(
  uid: string,
  data: Record<string, unknown>,
) {
  const ref = admin.firestore().collection("users").doc(uid);
  const existing = await ref.get();
  const payload: Record<string, unknown> = {
    ...data,
    updatedAt: new Date().toISOString(),
    city: "Lubumbashi",
  };
  if (!existing.exists && !payload.createdAt) {
    payload.createdAt = new Date().toISOString();
  }
  await ref.set(payload, { merge: true });
}

/** Seed ou reset du compte owner Verdick — idempotent, sans doublon. */
export const seedOrResetVerdickOwnerAccountCallable = onCall(async (request) => {
  const { email, resetPassword } = request.data as {
    email?: string;
    resetPassword?: boolean;
  };
  const normalized = (email ?? OWNER_EMAIL).trim().toLowerCase();
  if (normalized !== OWNER_EMAIL) {
    throw new HttpsError("permission-denied", "Opération non autorisée.");
  }

  const shouldReset = resetPassword !== false;
  let created = false;
  let uid: string;

  try {
    const existing = await admin.auth().getUserByEmail(normalized);
    uid = existing.uid;
    if (shouldReset) {
      await admin.auth().updateUser(uid, {
        password: OWNER_PROVISIONAL_PASSWORD,
        disabled: false,
      });
    } else {
      await admin.auth().updateUser(uid, { disabled: false });
    }
  } catch (e: unknown) {
    const err = e as { code?: string };
    if (err.code !== "auth/user-not-found") throw e;
    const newUser = await admin.auth().createUser({
      email: normalized,
      password: OWNER_PROVISIONAL_PASSWORD,
      disabled: false,
    });
    uid = newUser.uid;
    created = true;
  }

  await upsertUserDoc(uid, {
    uid,
    email: normalized,
    fullName: "Verdick Yav",
    displayName: "Verdick Yav",
    loginIdentifier: "verdick",
    role: "admin_general_owner",
    roles: ["admin_general_owner"],
    permissions: OWNER_PERMISSIONS,
    canManageEverything: true,
    isOwner: true,
    isActive: true,
    mustChangePassword: true,
  });

  await writeRecoveryLog({
    action: "seed_or_reset_verdick_owner",
    email: normalized,
    status: "success",
    metadata: { created, passwordReset: shouldReset },
  });
  await writeAuditLog({
    actorId: uid,
    action: "seed_or_reset_verdick_owner",
    targetType: "admin_staff",
    targetId: uid,
    metadata: { email: normalized, created, passwordReset: shouldReset },
  });

  return {
    success: true,
    uid,
    created,
    mustChangePassword: true,
    message: created
      ? "Compte Admin Général configuré avec succès."
      : "Compte restauré avec succès.",
  };
});

/** Bootstrap public — email Verdick uniquement, idempotent. */
export const bootstrapOwnerRecoveryCallable = onCall(async (request) => {
  const { email } = request.data as { email?: string };
  const normalized = (email ?? "").trim().toLowerCase();
  if (normalized !== OWNER_EMAIL) {
    throw new HttpsError("permission-denied", "Opération non autorisée.");
  }

  const uid = await upsertAuthUser(normalized, OWNER_PROVISIONAL_PASSWORD);
  await upsertUserDoc(uid, {
    uid,
    email: normalized,
    fullName: "Verdick Yav",
    displayName: "Verdick Yav",
    loginIdentifier: "verdick",
    role: "admin_general_owner",
    roles: ["admin_general_owner"],
    permissions: OWNER_PERMISSIONS,
    canManageEverything: true,
    isOwner: true,
    isActive: true,
    mustChangePassword: true,
  });

  await writeRecoveryLog({
    action: "bootstrap_owner",
    email: normalized,
    status: "success",
  });
  await writeAuditLog({
    actorId: uid,
    action: "bootstrap_owner_recovery",
    targetType: "admin_staff",
    targetId: uid,
    metadata: { email: normalized },
  });

  return {
    success: true,
    uid,
    mustChangePassword: true,
    message: "Compte Admin Général configuré avec succès.",
  };
});

export const seedVerdickOwnerAccountCallable = onCall(async (request) => {
  assertOwner(request);
  const { loginIdentifier, email, displayName, permissions } = request.data as {
    loginIdentifier?: string;
    email?: string;
    displayName?: string;
    permissions?: string[];
  };
  const resolvedEmail = (email ?? OWNER_EMAIL).trim().toLowerCase();
  const uid = await upsertAuthUser(resolvedEmail);
  await upsertUserDoc(uid, {
    uid,
    email: resolvedEmail,
    fullName: displayName ?? "Verdick Yav",
    displayName: displayName ?? "Verdick Yav",
    loginIdentifier: loginIdentifier ?? "verdick",
    role: "admin_general_owner",
    roles: ["admin_general_owner"],
    permissions: permissions ?? OWNER_PERMISSIONS,
    canManageEverything: true,
    isOwner: true,
    isActive: true,
    mustChangePassword: true,
  });

  await writeAuditLog({
    actorId: request.auth?.uid,
    action: "seed_verdick_owner",
    targetType: "admin_staff",
    targetId: uid,
  });

  return { success: true, uid, alreadyExists: false };
});

export const resetVerdickPasswordCallable = onCall(async (request) => {
  const { email, sendEmail } = request.data as {
    email?: string;
    sendEmail?: boolean;
  };
  const resolvedEmail = (email ?? OWNER_EMAIL).trim().toLowerCase();
  if (resolvedEmail !== OWNER_EMAIL && request.auth) {
    assertOwner(request);
  } else if (resolvedEmail !== OWNER_EMAIL) {
    throw new HttpsError("permission-denied", "Opération non autorisée.");
  }

  let tempPassword: string | undefined;
  const uid = await upsertAuthUser(resolvedEmail);

  if (sendEmail) {
    const link = await admin.auth().generatePasswordResetLink(resolvedEmail);
    await writeRecoveryLog({
      action: "password_reset_link",
      email: resolvedEmail,
      status: "sent",
      metadata: { linkGenerated: !!link },
    });
  } else {
    tempPassword = generateTempPassword();
    await admin.auth().updateUser(uid, { password: tempPassword });
  }

  await upsertUserDoc(uid, {
    mustChangePassword: true,
    isActive: true,
  });

  await writeAuditLog({
    actorId: request.auth?.uid ?? uid,
    action: "reset_verdick_password",
    targetType: "admin_staff",
    targetId: uid,
    metadata: { sendEmail: !!sendEmail },
  });

  return {
    success: true,
    mustChangePassword: true,
    temporaryPassword: tempPassword,
    emailSent: !!sendEmail,
  };
});

export const createJenoAdminGeneralCallable = onCall(async (request) => {
  assertOwner(request);
  const { loginIdentifier, email, displayName } = request.data as {
    loginIdentifier?: string;
    email?: string;
    displayName?: string;
  };
  const resolvedEmail = (email ?? "jeno@medialubumbashi.app").trim().toLowerCase();
  const uid = await upsertAuthUser(resolvedEmail);
  await upsertUserDoc(uid, {
    uid,
    email: resolvedEmail,
    fullName: displayName ?? "Jeno",
    displayName: displayName ?? "Jeno",
    loginIdentifier: loginIdentifier ?? JENO_LOGIN,
    role: "admin_general",
    roles: ["admin_general"],
    permissions: JENO_PERMISSIONS,
    isOwner: false,
    isActive: true,
    mustChangePassword: true,
  });

  await writeAuditLog({
    actorId: request.auth?.uid,
    action: "create_jeno_admin_general",
    targetType: "admin_staff",
    targetId: uid,
  });

  return { success: true, uid };
});

export const resetUserPasswordCallable = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const actorRole = (request.auth.token.role as string | undefined) ??
    (await roleFromUid(request.auth.uid));
  const actorPerms = request.auth.token.permissions as string[] | undefined;
  const { uid, newPassword, targetRole } = request.data as {
    uid?: string;
    newPassword?: string;
    targetRole?: string;
  };
  if (!uid || !newPassword) {
    throw new HttpsError("invalid-argument", "uid et newPassword requis.");
  }

  if (targetRole === "admin_general_owner" && actorRole !== "admin_general_owner") {
    throw new HttpsError("permission-denied", "Droits insuffisants.");
  }

  if (actorRole === "admin_general_owner") {
    // owner can reset anyone
  } else if (
    actorRole === "admin_general" &&
    (actorPerms?.includes("can_reset_passwords") ||
      actorPerms?.includes("can_reset_member_passwords"))
  ) {
    if (targetRole === "admin_general_owner") {
      throw new HttpsError("permission-denied", "Droits insuffisants.");
    }
  } else {
    throw new HttpsError("permission-denied", "Droits insuffisants.");
  }

  await admin.auth().updateUser(uid, { password: newPassword });
  await admin.firestore().collection("users").doc(uid).set(
    { mustChangePassword: true, updatedAt: new Date().toISOString() },
    { merge: true },
  );

  await writeAuditLog({
    actorId: request.auth.uid,
    action: "reset_user_password",
    targetType: "user",
    targetId: uid,
  });

  return { success: true, mustChangePassword: true };
});

export const assignRoleCallableSecure = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const actorRole = (request.auth.token.role as string | undefined) ??
    (await roleFromUid(request.auth.uid));
  const actorPerms = request.auth.token.permissions as string[] | undefined;
  const { uid, role, permissions } = request.data as {
    uid?: string;
    role?: string;
    permissions?: string[];
  };
  if (!uid || !role) {
    throw new HttpsError("invalid-argument", "uid et role requis.");
  }

  if (role === "admin_general_owner" && actorRole !== "admin_general_owner") {
    throw new HttpsError("permission-denied", "Droits insuffisants.");
  }

  const targetSnap = await admin.firestore().collection("users").doc(uid).get();
  const targetRole = targetSnap.data()?.role as string | undefined;
  if (targetRole === "admin_general_owner" && role !== "admin_general_owner") {
    if (actorRole !== "admin_general_owner") {
      throw new HttpsError("permission-denied", "Impossible de retirer le rôle principal.");
    }
  }

  if (actorRole === "admin_general_owner") {
    // allowed
  } else if (
    actorRole === "admin_general" &&
    actorPerms?.includes("can_assign_roles")
  ) {
    if (role === "admin_general_owner") {
      throw new HttpsError("permission-denied", "Droits insuffisants.");
    }
  } else {
    throw new HttpsError("permission-denied", "Droits insuffisants.");
  }

  await admin.firestore().collection("users").doc(uid).set(
    {
      role,
      roles: [role],
      permissions: permissions ?? [],
      updatedAt: new Date().toISOString(),
    },
    { merge: true },
  );

  await writeAuditLog({
    actorId: request.auth.uid,
    action: "assign_role",
    targetType: "user",
    targetId: uid,
    metadata: { role },
  });

  return { success: true };
});

export const removeRoleCallable = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const actorRole = (request.auth.token.role as string | undefined) ??
    (await roleFromUid(request.auth.uid));
  const actorPerms = request.auth.token.permissions as string[] | undefined;
  const { uid, role } = request.data as { uid?: string; role?: string };
  if (!uid || !role) {
    throw new HttpsError("invalid-argument", "uid et role requis.");
  }

  const targetSnap = await admin.firestore().collection("users").doc(uid).get();
  const targetRole = targetSnap.data()?.role as string | undefined;
  if (targetRole === "admin_general_owner" || role === "admin_general_owner") {
    if (actorRole !== "admin_general_owner") {
      throw new HttpsError("permission-denied", "Impossible de retirer le rôle principal.");
    }
  }

  if (actorRole === "admin_general_owner") {
    // allowed
  } else if (
    actorRole === "admin_general" &&
    actorPerms?.includes("can_remove_roles")
  ) {
    if (role === "admin_general_owner" || role === "admin_general") {
      throw new HttpsError("permission-denied", "Droits insuffisants.");
    }
  } else {
    throw new HttpsError("permission-denied", "Droits insuffisants.");
  }

  const fallbackRole = "member";
  await admin.firestore().collection("users").doc(uid).set(
    {
      role: fallbackRole,
      roles: [fallbackRole],
      permissions: [],
      updatedAt: new Date().toISOString(),
    },
    { merge: true },
  );

  await writeAuditLog({
    actorId: request.auth.uid,
    action: "remove_role",
    targetType: "user",
    targetId: uid,
    metadata: { removedRole: role },
  });

  return { success: true, role: fallbackRole };
});
