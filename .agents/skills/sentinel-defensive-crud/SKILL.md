---
name: sentinel-defensive-crud
description: Use this skill whenever implementing Create, Read, Update, or Delete (CRUD) operations in Sentinel. It guarantees that the UI properly locks and handles errors explicitly.
---

# Sentinel Defensive CRUD Skill

To guarantee absolute data integrity and zero silent failures, every database write operation MUST follow this defensive pattern.

## 1. StatefulBuilder for Dialogs
When creating forms inside `showDialog`, always declare your `isLoading` variable OUTSIDE the `builder` callback of the `StatefulBuilder` to avoid dead code bugs.

```dart
void _showCreateForm(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) {
      // DECLARE HERE
      bool isLoading = false;
      
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            // ...
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setDialogState(() => isLoading = true);
                        try {
                          await _performDbWrite();
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            UIUtils.showToast(context, 'Success!', type: ToastType.success);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            UIUtils.showToast(context, 'Error: $e', type: ToastType.error);
                          }
                        } finally {
                          if (ctx.mounted) {
                            setDialogState(() => isLoading = false);
                          }
                        }
                      },
                child: isLoading 
                    ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
```

## 2. ID Generation (Race-Condition Free)
Do not use `.add()` which returns a long alphanumeric ID.
Instead, use a Firestore Transaction with a dedicated `counters` collection to ensure atomic, human-readable IDs (e.g., `ENT-042`) without race conditions.

> **Note on `counters` Collection:** The `counters` collection must exist at the root of Firestore. Each document inside it should correspond to a module (e.g., `entities`, `projects`) and contain an integer field `count`. The transaction will automatically create the document if it doesn't exist.

```dart
// Example Repository Method using Transactions for safe ID generation
Future<void> createEntity(MyEntity entity) async {
  await _firestore.runTransaction((transaction) async {
    // 1. Reference the counter document
    final counterRef = _firestore.collection('counters').doc('entities');
    final counterSnapshot = await transaction.get(counterRef);
    
    int currentCount = 0;
    if (counterSnapshot.exists) {
      currentCount = counterSnapshot.data()?['count'] ?? 0;
    }
    
    // 2. Increment the counter
    final newCount = currentCount + 1;
    transaction.set(counterRef, {'count': newCount}, SetOptions(merge: true));
    
    // 3. Format the new ID
    final generatedId = 'ENT-${newCount.toString().padLeft(3, '0')}';
    
    // 4. Create the new entity document
    final entityRef = _firestore.collection('entities').doc(generatedId);
    final entityWithId = entity.copyWith(id: generatedId);
    transaction.set(entityRef, entityWithId.toFirestore());
  });
}
```
