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

## 2. ID Generation
Do not use `add()` which returns a long alphanumeric ID.
Instead, manually generate a human-readable ID and use `set()`.

```dart
// Example Repository Method
Future<void> createEntity(MyEntity entity) async {
  // Generate e.g. ENT-042
  final countSnapshot = await _firestore.collection('entities').count().get();
  final newId = 'ENT-${(countSnapshot.count ?? 0 + 1).toString().padLeft(3, '0')}';
  
  final entityWithId = entity.copyWith(id: newId);
  await _firestore.collection('entities').doc(newId).set(entityWithId.toFirestore());
}
```
