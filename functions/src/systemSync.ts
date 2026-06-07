import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";

const CITY = "Lubumbashi";

const EXPORT_PERMISSIONS = [
  "can_export_pdf",
  "can_export_csv",
  "can_export_member_list",
  "can_export_attendance_list",
  "can_export_media_list",
  "can_export_department_list",
  "can_export_media_pdf",
  "can_export_media_csv",
  "can_export_media_reports",
];

const MEMBER_VISIBILITY = [
  "can_read_all_members",
  "can_read_members_for_attendance",
  "can_view_member_list",
  "can_search_members",
  "can_view_member_detail",
  "can_view_attendance_dashboard",
  "can_create_attendance_record",
];

const WEB_PERMISSIONS = ["can_access_web", "can_access_web_admin"];

function permissionsForRole(role: string): string[] {
  switch (role) {
    case "admin_general_owner":
      return [
        "can_manage_everything",
        "can_create_admin",
        "can_assign_roles",
        "can_remove_roles",
        "can_reset_passwords",
        "can_create_accounts",
        "can_create_member",
        "can_create_member_account",
        "can_activate_accounts",
        "can_suspend_accounts",
        "can_take_attendance",
        "can_scan_qr",
        "can_manage_departments",
        "can_manage_department_lists",
        "can_manage_lists",
        "can_view_audit_logs",
        "can_view_diagnostics",
        "can_force_sync",
        "can_manage_firebase_from_app",
        "can_delete_member",
        "can_restore_member",
        "can_manage_ai_assistant",
        "can_manage_messaging",
        "can_manage_appointments",
        ...WEB_PERMISSIONS,
        ...MEMBER_VISIBILITY,
        "can_manage_media_roles",
        "can_manage_media_lists",
        ...EXPORT_PERMISSIONS,
      ];
    case "admin_general":
      return [
        "can_assign_roles",
        "can_reset_passwords",
        "can_reset_member_passwords",
        "can_create_accounts",
        "can_create_member",
        "can_create_member_account",
        "can_manage_members",
        "can_manage_lists",
        "can_activate_accounts",
        "can_suspend_accounts",
        "can_take_attendance",
        "can_scan_qr",
        "can_manage_departments",
        "can_manage_department_lists",
        "can_view_audit_logs",
        "can_view_sync",
        "can_force_sync",
        "can_manage_firebase_from_app",
        "can_restore_member",
        "can_manage_messaging",
        "can_manage_appointments",
        ...WEB_PERMISSIONS,
        ...MEMBER_VISIBILITY,
        "can_manage_media_roles",
        "can_manage_media_lists",
        "can_export_pdf",
        "can_export_csv",
        "can_export_member_list",
        "can_export_media_list",
        "can_export_department_list",
        "can_export_media_pdf",
        "can_export_media_csv",
      ];
    case "admin_simple":
      return [
        "can_create_member",
        "can_create_member_account",
        "can_manage_members",
        "can_manage_lists",
        "can_take_attendance",
        "can_scan_qr",
        "can_manage_messaging",
        ...WEB_PERMISSIONS,
        "can_read_all_members",
        "can_view_member_list",
        "can_search_members",
        "can_view_member_detail",
        "can_view_media_lists",
        "can_export_pdf",
        "can_export_csv",
        "can_export_member_list",
      ];
    case "attendance_operator":
      return [
        "can_take_attendance",
        "can_scan_qr",
        "can_access_web",
        "can_read_members_for_attendance",
        "can_search_members",
        "can_view_member_detail",
        "can_view_attendance_dashboard",
        "can_create_attendance_record",
        "can_view_media_lists",
        "can_take_media_attendance",
      ];
    case "member":
    case "media_member":
      return ["can_access_web"];
    default:
      return [];
  }
}

function mergePermissions(existing: string[], template: string[]): string[] {
  return [...new Set([...existing, ...template])];
}

async function roleFromUid(uid: string): Promise<string | undefined> {
  const snap = await admin.firestore().collection("users").doc(uid).get();
  return snap.data()?.role as string | undefined;
}

async function assertOwnerAsync(context: {
  auth?: { uid: string; token: Record<string, unknown> };
}) {
  if (!context.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }
  const tokenRole = context.auth.token.role as string | undefined;
  const role = tokenRole ?? (await roleFromUid(context.auth.uid));
  if (role !== "admin_general_owner") {
    throw new HttpsError("permission-denied", "Réservé au responsable principal.");
  }
}

async function writeAuditLog(data: Record<string, unknown>) {
  await admin.firestore().collection("auditLogs").add({
    ...data,
    createdAt: new Date().toISOString(),
    city: CITY,
  });
}

function validateNewPassword(password: string) {
  if (!password || password.length < 8) {
    throw new HttpsError("invalid-argument", "Mot de passe trop court.");
  }
  if (!/[A-Z]/.test(password)) {
    throw new HttpsError("invalid-argument", "Mot de passe invalide.");
  }
  if (!/[a-z]/.test(password)) {
    throw new HttpsError("invalid-argument", "Mot de passe invalide.");
  }
  if (!/[0-9]/.test(password)) {
    throw new HttpsError("invalid-argument", "Mot de passe invalide.");
  }
}

/** Changement mot de passe — Firebase Auth source officielle, jamais stocké en clair. */
export const changeUserPasswordCallable = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Authentification requise.");
  }

  const { newPassword } = request.data as { newPassword?: string };
  if (!newPassword) {
    throw new HttpsError("invalid-argument", "Nouveau mot de passe requis.");
  }
  validateNewPassword(newPassword);

  const uid = request.auth.uid;
  const now = new Date().toISOString();

  await admin.auth().updateUser(uid, { password: newPassword });

  await admin.firestore().collection("users").doc(uid).set(
    {
      mustChangePassword: false,
      updatedAt: now,
    },
    { merge: true }
  );

  const memberAccRef = admin.firestore().collection("memberAccounts").doc(uid);
  const memberAcc = await memberAccRef.get();
  if (memberAcc.exists) {
    await memberAccRef.set(
      { mustChangePassword: false, updatedAt: now },
      { merge: true }
    );
  }

  await writeAuditLog({
    action: "password_changed",
    actorId: uid,
    targetId: uid,
    targetType: "user",
  });

  return {
    success: true,
    message: "Mot de passe changé avec succès.",
    reconnectHint: "Veuillez vous reconnecter avec votre nouveau mot de passe.",
  };
});

/** Migration accès Web pour comptes existants — sans recréer les comptes. */
export const enableWebAccessForExistingAccountsCallable = onCall(async (request) => {
  await assertOwnerAsync(request);

  let updated = 0;
  let skipped = 0;
  const snap = await admin.firestore().collection("users").get();

  for (const doc of snap.docs) {
    const data = doc.data();
    const role = (data.role as string) ?? "";
    if (!role) {
      skipped++;
      continue;
    }

    const existing: string[] = Array.isArray(data.permissions)
      ? (data.permissions as string[])
      : [];
    const template = permissionsForRole(role);
    const merged = mergePermissions(existing, template);

    const hadWeb = existing.includes("can_access_web");
    const needsUpdate =
      merged.length !== existing.length ||
      !merged.includes("can_access_web");

    if (!needsUpdate && hadWeb) {
      skipped++;
      continue;
    }

    await doc.ref.set(
      {
        permissions: merged,
        updatedAt: new Date().toISOString(),
      },
      { merge: true }
    );

    await admin.auth().setCustomUserClaims(doc.id, {
      role,
      permissions: merged,
    });

    updated++;
  }

  await writeAuditLog({
    action: "enable_web_access_migration",
    actorId: request.auth!.uid,
    metadata: { updated, skipped },
  });

  return {
    success: true,
    updated,
    skipped,
    message: `Accès Web activé pour ${updated} compte(s).`,
  };
});

/** Synchronisation complète — Admin Général Owner uniquement. */
export const syncAllSystemDataCallable = onCall(async (request) => {
  await assertOwnerAsync(request);

  const now = new Date().toISOString();
  let usersUpdated = 0;
  let permissionsFixed = 0;
  let webAccessGranted = 0;
  let claimsUpdated = 0;

  const usersSnap = await admin.firestore().collection("users").get();

  for (const doc of usersSnap.docs) {
    const data = doc.data();
    const role = (data.role as string) ?? "";
    if (!role) continue;

    const existing: string[] = Array.isArray(data.permissions)
      ? (data.permissions as string[])
      : [];
    const template = permissionsForRole(role);
    const merged = mergePermissions(existing, template);

    const permsChanged = merged.length !== existing.length ||
      template.some((p) => !existing.includes(p));

    if (permsChanged) {
      permissionsFixed++;
      if (!existing.includes("can_access_web") && merged.includes("can_access_web")) {
        webAccessGranted++;
      }
    }

    await doc.ref.set(
      {
        permissions: merged,
        roles: data.roles ?? [role],
        updatedAt: now,
        lastSystemSyncAt: now,
      },
      { merge: true }
    );

    await admin.auth().setCustomUserClaims(doc.id, {
      role,
      permissions: merged,
    });
    claimsUpdated++;
    usersUpdated++;
  }

  let pendingRetried = 0;
  const pendingSnap = await admin.firestore()
    .collection("sync_queue")
    .where("status", "==", "failed")
    .limit(50)
    .get();

  for (const doc of pendingSnap.docs) {
    await doc.ref.set(
      { status: "pending", retryAt: now, updatedAt: now },
      { merge: true }
    );
    pendingRetried++;
  }

  await admin.firestore().collection("systemSyncState").doc("latest").set(
    {
      lastSyncAt: now,
      lastSyncBy: request.auth!.uid,
      usersUpdated,
      permissionsFixed,
      webAccessGranted,
      claimsUpdated,
      pendingRetried,
      city: CITY,
    },
    { merge: true }
  );

  await writeAuditLog({
    action: "sync_all_system_data",
    actorId: request.auth!.uid,
    metadata: {
      usersUpdated,
      permissionsFixed,
      webAccessGranted,
      claimsUpdated,
      pendingRetried,
    },
  });

  return {
    success: true,
    usersUpdated,
    permissionsFixed,
    webAccessGranted,
    claimsUpdated,
    pendingRetried,
    message: "Synchronisation terminée avec succès.",
  };
});
