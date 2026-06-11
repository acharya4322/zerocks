import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _initFields(ShopModel shop) {
    if (!_initialized) {
      _nameController.text = shop.name;
      _addressController.text = shop.address;
      _priceController.text = shop.pricePerPage.toStringAsFixed(2);
      _initialized = true;
    }
  }

  Future<void> _saveSettings(ShopModel shop) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = FirebaseFirestore.instance;
      await db.collection('shops').doc(shop.id).update({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'pricePerPage': double.parse(_priceController.text.trim()),
      });

      ref.invalidate(shopProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Settings saved successfully'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopAsync = ref.watch(shopProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppConstants.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: textTheme.headlineLarge),
          const SizedBox(height: 28),
          Expanded(
            child: shopAsync.when(
              data: (shop) {
                if (shop == null) {
                  return Center(
                    child: Text(
                      'No shop found',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }

                _initFields(shop);

                return SingleChildScrollView(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Shop details section
                          Text(
                            'Shop Details',
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Update your shop information visible to customers',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 24),

                          // Shop name
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Shop Name',
                              prefixIcon: Icon(Icons.store_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Shop name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Address
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Address is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Price per page
                          TextFormField(
                            controller: _priceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Price per Page (₹)',
                              prefixIcon:
                                  Icon(Icons.currency_rupee_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Price is required';
                              }
                              final parsed = double.tryParse(value.trim());
                              if (parsed == null || parsed < 0) {
                                return 'Enter a valid price';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Save button
                          SizedBox(
                            width: 200,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isSaving ? null : () => _saveSettings(shop),
                              icon: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(
                                  _isSaving ? 'Saving...' : 'Save Changes'),
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Divider
                          Divider(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 32),

                          // Advanced Config Section
                          Text(
                            'Configuration',
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage pricing, products, and inventory',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 24),
                          
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildConfigCard(
                                context,
                                icon: Icons.attach_money,
                                title: 'Print Pricing',
                                subtitle: 'Rates, duplex discount, tax',
                                onTap: () => context.push('/pricing'),
                              ),
                              _buildConfigCard(
                                context,
                                icon: Icons.inventory_2_outlined,
                                title: 'Products & Stationery',
                                subtitle: 'Manage shop items for sale',
                                onTap: () => context.push('/products'),
                              ),
                              _buildConfigCard(
                                context,
                                icon: Icons.warehouse_outlined,
                                title: 'Inventory Tracker',
                                subtitle: 'Track paper stock and thresholds',
                                onTap: () => context.push('/inventory'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 48),

                          // Divider
                          Divider(
                            color: colorScheme.outline.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 32),

                          // Account section
                          Text(
                            'Account',
                            style: textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage your shop account',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 24),

                          // Sign out button
                          SizedBox(
                            width: 200,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signOut,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.logout_outlined,
                                      color: colorScheme.error,
                                    ),
                              label: Text(
                                _isLoading ? 'Signing out...' : 'Sign Out',
                                style: TextStyle(color: colorScheme.error),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: colorScheme.error.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
