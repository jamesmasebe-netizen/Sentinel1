import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/invite_service.dart';

class InviteUsersScreen extends ConsumerWidget {
  const InviteUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingInvitesAsync = ref.watch(pendingInvitesStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pending Invites'), centerTitle: true),
      body: pendingInvitesAsync.when(
        data: (invites) {
          if (invites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.mail_outline,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending invites',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the button below to invite new users.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invites.length,
            itemBuilder: (context, index) {
              final invite = invites[index];
              final dateStr =
                  invite.createdAt != null
                      ? DateFormat.yMMMd().add_jm().format(invite.createdAt!)
                      : 'Unknown date';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_add,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    invite.email,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Role: ${invite.role.toUpperCase()}'),
                      const SizedBox(height: 2),
                      Text(
                        'Invited: $dateStr',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      invite.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Colors.orange.shade100,
                    labelStyle: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading invites: $err',
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Invite User'),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const InviteUserDialog(),
    );
  }
}

class InviteUserDialog extends ConsumerStatefulWidget {
  const InviteUserDialog({super.key});

  @override
  ConsumerState<InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends ConsumerState<InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'user';
  bool _isLoading = false;

  final List<String> _roles = ['admin', 'manager', 'user'];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(inviteServiceProvider)
          .createInvite(
            email: _emailController.text.trim(),
            role: _selectedRole,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite sent successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Invite New User'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'user@example.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Role',
                prefixIcon: Icon(Icons.security),
                border: OutlineInputBorder(),
              ),
              items:
                  _roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase()),
                    );
                  }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedRole = val);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _submitInvite,
          child:
              _isLoading
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Send Invite'),
        ),
      ],
    );
  }
}
