import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";

admin.initializeApp();

function assertAdmin(context: { auth?: { uid: string; token: Record<string, unknown> } }) {
  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const role = context.auth.token.role as string | undefined;
  if (
    role !== "admin_general" &&
    role !== "admin_general_owner" &&
    role !== "admin"
  ) {
    throw new HttpsError("permission-denied", "Droits insuffisants.");
  }
}

async function roleFromAuthContext(context: {
  auth?: { uid: string; token: Record<string, unknown> };
}): Promise<string | undefined> {
  const tokenRole = context.auth?.token.role as string | undefined;
  if (tokenRole) return tokenRole;
  if (!context.auth) return undefined;
  const snap = await admin.firestore().collection("users").doc(context.auth.uid).get();
  return snap.data()?.role as string | undefined;
}

function assertOwner(context: { auth?: { uid: string; token: Record<string, unknown> } }) {
  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const role = context.auth.token.role as string | undefined;
  if (role !== "admin_general_owner") {
    throw new HttpsError("permission-denied", "Réservé au responsable principal.");
  }
}

async function assertOwnerAsync(context: {
  auth?: { uid: string; token: Record<string, unknown> };
}) {
  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const role = await roleFromAuthContext(context);
  if (role !== "admin_general_owner") {
    throw new HttpsError("permission-denied", "Réservé au responsable principal.");
  }
}

export const createMemberAccountCallable = onCall(async (request) => {
  assertAdmin(request);
  const { email, password, memberId } = request.data as {
    email?: string;
    password?: string;
    memberId?: string;
  };
  if (!email || !password) {
    throw new HttpsError("invalid-argument", "email et password requis.");
  }
  const user = await admin.auth().createUser({ email, password });
  await admin.firestore().collection("memberAccounts").doc(user.uid).set({
    memberId: memberId ?? null,
    email,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    city: "Lubumbashi",
  });
  return { uid: user.uid };
});

export const resetMemberPasswordCallable = onCall(async (request) => {
  assertAdmin(request);
  const { uid, newPassword } = request.data as { uid?: string; newPassword?: string };
  if (!uid || !newPassword) {
    throw new HttpsError("invalid-argument", "uid et newPassword requis.");
  }
  await admin.auth().updateUser(uid, { password: newPassword });
  return { success: true };
});

export const deleteAccountCallable = onCall(async (request) => {
  assertAdmin(request);
  const { uid } = request.data as { uid?: string };
  if (!uid) throw new HttpsError("invalid-argument", "uid requis.");
  await admin.auth().updateUser(uid, { disabled: true });
  await admin.firestore().collection("deletedAccounts").add({
    uid,
    deletedAt: admin.firestore.FieldValue.serverTimestamp(),
    city: "Lubumbashi",
  });
  return { success: true };
});

export const restoreAccountCallable = onCall(async (request) => {
  assertAdmin(request);
  const { uid } = request.data as { uid?: string };
  if (!uid) throw new HttpsError("invalid-argument", "uid requis.");
  await admin.auth().updateUser(uid, { disabled: false });
  return { success: true };
});

export const assignRoleCallable = onCall(async (request) => {
  assertAdmin(request);
  const { uid, role } = request.data as { uid?: string; role?: string };
  if (!uid || !role) throw new HttpsError("invalid-argument", "uid et role requis.");
  await admin.firestore().collection("users").doc(uid).set({ role }, { merge: true });
  return { success: true };
});

export const publishWeeklyResultsCallable = onCall(async (request) => {
  assertAdmin(request);
  const { results } = request.data as { results?: unknown[] };
  if (!results?.length) throw new HttpsError("invalid-argument", "results requis.");
  const batch = admin.firestore().batch();
  for (const r of results) {
    const ref = admin.firestore().collection("weeklyResults").doc();
    batch.set(ref, { ...(r as object), publishedAt: admin.firestore.FieldValue.serverTimestamp() });
  }
  await batch.commit();
  return { count: results.length };
});

export const recalculatePercentagesCallable = onCall(async (request) => {
  assertAdmin(request);
  // Placeholder — recalc côté serveur selon attendanceRecords
  return { success: true, message: "Recalcul planifié" };
});

const ACTIVATION_COLLECTION = "media_member_activation_requests";

async function getActivationRequest(requestId: string) {
  const ref = admin.firestore().collection(ACTIVATION_COLLECTION).doc(requestId);
  const snap = await ref.get();
  if (!snap.exists) return null;
  return { ref, data: snap.data()! };
}

export const activateMediaGoogleMemberCallable = onCall(async (request) => {
  assertAdmin(request);
  const { requestId, adminId } = request.data as {
    requestId?: string;
    adminId?: string;
  };
  if (!requestId) {
    throw new HttpsError("invalid-argument", "requestId requis.");
  }

  const existing = await getActivationRequest(requestId);
  if (!existing) {
    throw new HttpsError("not-found", "Demande introuvable.");
  }

  const data = existing.data;
  if (
    data.status === "active" &&
    data.activationCompleted === true
  ) {
    return {
      success: true,
      alreadyActive: true,
      memberId: data.memberId ?? null,
      message: "Compte déjà activé.",
    };
  }

  const memberId = data.memberId ?? admin.firestore().collection("members").doc().id;
  const now = new Date().toISOString();
  const displayName = (data.displayName as string) ?? "Membre Média";
  const parts = displayName.split(" ");
  const firstName = parts[0] ?? "Membre";
  const lastName = parts.slice(1).join(" ") || "Média";
  const year = new Date().getFullYear();
  const memberCode = `IFCM-LUB-${year}-${String(Date.now()).slice(-6)}`;

  const batch = admin.firestore().batch();

  batch.set(
    admin.firestore().collection("members").doc(memberId),
    {
      id: memberId,
      firstName,
      lastName,
      email: data.email,
      departmentId: "media",
      role: "media_member",
      memberCode,
      city: "Lubumbashi",
      isActive: true,
      createdAt: now,
      updatedAt: now,
      firebaseUid: requestId,
    },
    { merge: true }
  );

  batch.set(
    admin.firestore().collection("mediaMembers").doc(memberId),
    {
      id: memberId,
      firebaseUid: requestId,
      memberId,
      email: data.email,
      displayName: data.displayName ?? null,
      photoUrl: data.photoUrl ?? null,
      role: "media_member",
      departmentId: "media",
      memberCode,
      status: "active",
      activationCompleted: true,
      city: "Lubumbashi",
      updatedAt: now,
    },
    { merge: true }
  );

  batch.set(
    admin.firestore().collection("users").doc(requestId),
    {
      role: "media_member",
      memberId,
      departmentId: "media",
      email: data.email,
      displayName: data.displayName ?? null,
      updatedAt: now,
    },
    { merge: true }
  );

  batch.set(
    existing.ref,
    {
      status: "active",
      activationCompleted: true,
      memberId,
      reviewedBy: adminId ?? request.auth?.uid,
      reviewedAt: now,
      updatedAt: now,
    },
    { merge: true }
  );

  batch.set(admin.firestore().collection("audit_logs").doc(), {
    action: "media_google_activation",
    actorId: adminId ?? request.auth?.uid,
    targetId: memberId,
    createdAt: now,
    city: "Lubumbashi",
  });

  await batch.commit();

  return {
    success: true,
    memberId,
    message: "Compte activé.",
  };
});

export const rejectMediaGoogleMemberCallable = onCall(async (request) => {
  assertAdmin(request);
  const { requestId, adminId, reason } = request.data as {
    requestId?: string;
    adminId?: string;
    reason?: string;
  };
  if (!requestId) throw new HttpsError("invalid-argument", "requestId requis.");
  const existing = await getActivationRequest(requestId);
  if (!existing) throw new HttpsError("not-found", "Demande introuvable.");
  await existing.ref.set(
    {
      status: "rejected",
      rejectionReason: reason ?? null,
      reviewedBy: adminId ?? request.auth?.uid,
      reviewedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    },
    { merge: true }
  );
  return { success: true };
});

export const suspendMediaGoogleMemberCallable = onCall(async (request) => {
  assertAdmin(request);
  const { requestId } = request.data as { requestId?: string };
  if (!requestId) throw new HttpsError("invalid-argument", "requestId requis.");
  const existing = await getActivationRequest(requestId);
  if (!existing) throw new HttpsError("not-found", "Demande introuvable.");
  await existing.ref.set(
    { status: "suspended", updatedAt: new Date().toISOString() },
    { merge: true }
  );
  return { success: true };
});

export const restoreMediaGoogleMemberCallable = onCall(async (request) => {
  assertAdmin(request);
  const { requestId } = request.data as { requestId?: string };
  if (!requestId) throw new HttpsError("invalid-argument", "requestId requis.");
  const existing = await getActivationRequest(requestId);
  if (!existing) throw new HttpsError("not-found", "Demande introuvable.");
  await existing.ref.set(
    {
      status: "active",
      activationCompleted: true,
      updatedAt: new Date().toISOString(),
    },
    { merge: true }
  );
  return { success: true };
});

export {
  bootstrapOwnerRecoveryCallable,
  seedOrResetVerdickOwnerAccountCallable,
  seedVerdickOwnerAccountCallable,
  resetVerdickPasswordCallable,
  createJenoAdminGeneralCallable,
  resetUserPasswordCallable,
  assignRoleCallableSecure,
  removeRoleCallable,
} from "./adminRecovery";

export {
  askGeminiAssistantCallable,
  seedAdminAccountsCallable,
  createAppointmentCallable,
  sendNotificationCallable,
} from "./geminiAssistant";

export {
  changeUserPasswordCallable,
  syncAllSystemDataCallable,
  enableWebAccessForExistingAccountsCallable,
} from "./systemSync";

export const createUserAccountCallable = createMemberAccountCallable;

export const resetPasswordCallable = resetMemberPasswordCallable;

function assertCanDeleteMember(context: { auth?: { uid: string; token: Record<string, unknown> } }) {
  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const role = context.auth.token.role as string | undefined;
  const permissions = context.auth.token.permissions as string[] | undefined;
  if (role === "admin_general_owner") return;
  if (role === "attendance_operator" || role === "member" || role === "media_member") {
    throw new HttpsError("permission-denied", "Droits insuffisants.");
  }
  if (role === "admin_general" && permissions?.includes("can_delete_member")) return;
  throw new HttpsError("permission-denied", "Droits insuffisants.");
}

export const deleteMemberCallable = onCall(async (request) => {
  assertCanDeleteMember(request);
  const { memberId, reason, deletedByRole } = request.data as {
    memberId?: string;
    reason?: string;
    deletedByRole?: string;
  };
  if (!memberId) {
    throw new HttpsError("invalid-argument", "memberId requis.");
  }
  const now = new Date().toISOString();
  const batch = admin.firestore().batch();
  batch.set(
    admin.firestore().collection("deletedMembers").doc(memberId),
    {
      memberId,
      deletedAt: now,
      deletedBy: request.auth?.uid,
      deletedByRole: deletedByRole ?? null,
      deletedReason: reason ?? null,
      restoreAvailable: true,
      city: "Lubumbashi",
    },
    { merge: true }
  );
  batch.set(
    admin.firestore().collection("members").doc(memberId),
    {
      isActive: false,
      isDeleted: true,
      deletedAt: now,
      deletedBy: request.auth?.uid,
      deletedReason: reason ?? null,
      updatedAt: now,
    },
    { merge: true }
  );
  batch.set(admin.firestore().collection("audit_logs").doc(), {
    action: "member_soft_delete",
    actorId: request.auth?.uid,
    targetType: "member",
    targetId: memberId,
    metadata: { reason: reason ?? null },
    createdAt: now,
    city: "Lubumbashi",
  });
  await batch.commit();
  return { success: true };
});

export const restoreMemberCallable = onCall(async (request) => {
  assertCanDeleteMember(request);
  const { memberId, reason } = request.data as { memberId?: string; reason?: string };
  if (!memberId) throw new HttpsError("invalid-argument", "memberId requis.");
  const now = new Date().toISOString();
  await admin.firestore().collection("members").doc(memberId).set(
    {
      isActive: true,
      isDeleted: false,
      deletedAt: admin.firestore.FieldValue.delete(),
      deletedBy: admin.firestore.FieldValue.delete(),
      deletedReason: admin.firestore.FieldValue.delete(),
      restoredAt: now,
      updatedAt: now,
    },
    { merge: true }
  );
  await admin.firestore().collection("deletedMembers").doc(memberId).delete();
  await admin.firestore().collection("audit_logs").add({
    action: "member_restore",
    actorId: request.auth?.uid,
    targetType: "member",
    targetId: memberId,
    metadata: { reason: reason ?? null },
    createdAt: now,
    city: "Lubumbashi",
  });
  return { success: true };
});

export const permanentDeleteMemberCallable = onCall(async (request) => {
  assertOwner(request);
  const { memberId, reason, confirmPermanent } = request.data as {
    memberId?: string;
    reason?: string;
    confirmPermanent?: boolean;
  };
  if (!memberId) throw new HttpsError("invalid-argument", "memberId requis.");
  if (!confirmPermanent) {
    throw new HttpsError("failed-precondition", "Confirmation requise.");
  }
  const now = new Date().toISOString();
  const memberRef = admin.firestore().collection("members").doc(memberId);
  const snap = await memberRef.get();
  if (snap.exists) {
    await admin.firestore().collection("deletedMembers").doc(memberId).set(
      {
        backupJson: JSON.stringify(snap.data()),
        permanentDeleteAt: now,
        city: "Lubumbashi",
      },
      { merge: true }
    );
  }
  await memberRef.set(
    {
      isActive: false,
      isDeleted: true,
      deletedAt: now,
      deletedBy: request.auth?.uid,
      deletedReason: reason ?? "permanent_delete",
      updatedAt: now,
    },
    { merge: true }
  );
  await admin.firestore().collection("audit_logs").add({
    action: "member_permanent_delete",
    actorId: request.auth?.uid,
    targetType: "member",
    targetId: memberId,
    metadata: { reason: reason ?? null },
    createdAt: now,
    city: "Lubumbashi",
  });
  return { success: true };
});

const STAFF_FIREBASE_SEEDS = [
  {
    loginIdentifier: "verdick",
    email: "verdicky9@gmail.com",
    password: "Verd@2026",
    displayName: "Verdick Yav",
    role: "admin_general_owner",
    isOwner: true,
    departmentId: "media",
    permissions: ["can_manage_everything", "can_delete_member"],
  },
  {
    loginIdentifier: "jeno",
    email: "jeno@medialubumbashi.app",
    password: "Jeno@2026",
    displayName: "Jeno",
    role: "admin_general",
    isOwner: false,
    departmentId: "media",
    permissions: ["can_assign_roles", "can_reset_passwords"],
  },
  {
    loginIdentifier: "alex",
    email: "alex@gmail.com",
    password: "Alex@2026",
    displayName: "Alex",
    role: "admin_simple",
    isOwner: false,
    departmentId: "media",
    permissions: ["can_create_member", "can_manage_lists"],
  },
  {
    loginIdentifier: "mechack",
    email: "mechack@gmail.com",
    password: "Mechack@2026",
    displayName: "Mechack",
    role: "attendance_operator",
    isOwner: false,
    departmentId: "media",
    permissions: ["can_take_attendance", "can_scan_qr"],
  },
  {
    loginIdentifier: "bisibo",
    email: "bisibo@gmail.com",
    password: "Bisibo@2026",
    displayName: "Bisibo",
    role: "attendance_operator",
    isOwner: false,
    departmentId: "media",
    permissions: ["can_take_attendance", "can_scan_qr"],
  },
];

export const provisionStaffAccountsCallable = onCall(async (request) => {
  await assertOwnerAsync(request);
  let created = 0;
  let linked = 0;
  let skipped = 0;
  const accounts: Array<{
    loginIdentifier: string;
    uid: string;
    email: string;
  }> = [];

  for (const seed of STAFF_FIREBASE_SEEDS) {
    let uid: string;
    try {
      const existing = await admin.auth().getUserByEmail(seed.email);
      uid = existing.uid;
      linked++;
    } catch {
      const user = await admin.auth().createUser({
        email: seed.email,
        password: seed.password,
        displayName: seed.displayName,
      });
      uid = user.uid;
      created++;
    }

    await admin.firestore().collection("users").doc(uid).set(
      {
        loginIdentifier: seed.loginIdentifier,
        email: seed.email,
        displayName: seed.displayName,
        role: seed.role,
        roles: [seed.role],
        permissions: seed.permissions,
        isOwner: seed.isOwner,
        departmentId: seed.departmentId,
        city: "Lubumbashi",
        isActive: true,
        updatedAt: new Date().toISOString(),
      },
      { merge: true }
    );

    await admin.auth().setCustomUserClaims(uid, {
      role: seed.role,
      permissions: seed.permissions,
    });

    accounts.push({
      loginIdentifier: seed.loginIdentifier,
      uid,
      email: seed.email,
    });
  }

  await admin.firestore().collection("audit_logs").add({
    action: "provision_staff_firebase_accounts",
    actorId: request.auth?.uid,
    createdAt: new Date().toISOString(),
    city: "Lubumbashi",
    metadata: { created, linked, skipped },
  });

  return { success: true, created, linked, skipped, accounts };
});

export const createAdminAccountCallable = onCall(async (request) => {
  assertAdmin(request);
  const { email, password, role, displayName } = request.data as {
    email?: string;
    password?: string;
    role?: string;
    displayName?: string;
  };
  if (!email || !password || !role) {
    throw new HttpsError("invalid-argument", "email, password et role requis.");
  }
  const user = await admin.auth().createUser({ email, password, displayName });
  await admin.firestore().collection("users").doc(user.uid).set({
    email,
    displayName: displayName ?? email,
    role,
    roles: [role],
    city: "Lubumbashi",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { uid: user.uid };
});
