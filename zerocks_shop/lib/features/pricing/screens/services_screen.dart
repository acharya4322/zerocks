import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/pricing_provider.dart';

class ServicesScreen extends ConsumerWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(shopServicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showServiceDialog(context, ref),
          ),
        ],
      ),
      body: servicesAsync.when(
        data: (services) {
          if (services.isEmpty) {
            return const Center(child: Text('No services added yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                child: ListTile(
                  title: Text(service.name),
                  subtitle: Text('₹${service.price.toStringAsFixed(2)} • ${service.description ?? ""}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: service.isAvailable,
                        onChanged: (val) {
                          ref.read(servicesNotifierProvider.notifier).updateService(service.id, {'isAvailable': val});
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showServiceDialog(context, ref, existingService: service),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Service?'),
                              content: Text('Are you sure you want to delete ${service.name}?'),
                              actions: [
                                TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => context.pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(servicesNotifierProvider.notifier).deleteService(service.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showServiceDialog(BuildContext context, WidgetRef ref, {ServiceModel? existingService}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existingService?.name ?? '');
    final priceCtrl = TextEditingController(text: existingService?.price.toString() ?? '');
    final descCtrl = TextEditingController(text: existingService?.description ?? '');
    bool isAvailable = existingService?.isAvailable ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingService == null ? 'Add Service' : 'Edit Service'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name (e.g. Spiral Binding)', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: priceCtrl,
                    decoration: const InputDecoration(labelText: 'Price (₹)', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Available'),
                    value: isAvailable,
                    onChanged: (val) => setState(() => isAvailable = val),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                
                if (existingService == null) {
                  final service = ServiceModel(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    price: double.tryParse(priceCtrl.text) ?? 0,
                    description: descCtrl.text.trim(),
                    isAvailable: isAvailable,
                    createdAt: DateTime.now(),
                  );
                  ref.read(servicesNotifierProvider.notifier).addService(service);
                } else {
                  ref.read(servicesNotifierProvider.notifier).updateService(
                    existingService.id,
                    {
                      'name': nameCtrl.text.trim(),
                      'price': double.tryParse(priceCtrl.text) ?? 0,
                      'description': descCtrl.text.trim(),
                      'isAvailable': isAvailable,
                    },
                  );
                }
                context.pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
