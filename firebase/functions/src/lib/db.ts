import { getFirestore } from "firebase-admin/firestore";

/**
 * This project's Firestore uses a named, non-default database — see
 * firebase.json's `firestore[0].database` and the Flutter app's
 * `FirebaseFirestore.instanceFor(databaseId: ...)` call in lib/main.dart.
 * `admin.firestore()` always targets "(default)", which nothing else in this
 * app reads from or writes to, so every Cloud Function must go through
 * `getDb()` instead — never call `admin.firestore()` directly.
 */
export const FIRESTORE_DATABASE_ID =
  "ai-studio-4bb0fb1c-c6d6-4397-a015-156f3ff9dfb5";

export function getDb() {
  return getFirestore(FIRESTORE_DATABASE_ID);
}
