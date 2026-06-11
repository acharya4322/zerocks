import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/inventory_provider.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(shopInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showInventoryDialog(context, ref),
          ),
        ],
      ),
      body: inventoryAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No inventory items found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isLowStock = item.currentStock <= item.lowStockThreshold;

              return Card(
                child: ListTile(
                  title: Text(item.name, style: TextStyle(
                    color: isLowStock ? Colors.red.shade700 : null,
                    fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                  )),
                  subtitle: Text('Stock: ${item.currentStock} ${item.unit} (Low threshold: ${item.lowStockThreshold})'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showInventoryDialog(context, ref, existingItem: item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Item?'),
                              content: Text('Are you sure you want to delete ${item.name}?'),
                              actions: [
                                TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
                                TextButton(onPressed: () => context.pop(true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(inventoryNotifierProvider.notifier).deleteInventory(item.id);
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
        onPressed: () => _showInventoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showInventoryDialog(BuildContext context, WidgetRef ref, {InventoryModel? existingItem}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existingItem?.name ?? '');
    final stockCtrl = TextEditingController(text: existingItem?.currentStock.toString() ?? '');
    final thresholdCtrl = TextEditingController(text: existingItem?.lowStockThreshold.toString() ?? '');
    String unit = existingItem?.unit ?? 'sheets';
    String category = existingItem?.category ?? 'paper';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existingItem == null ? 'Add Inventory Item' : 'Edit Inventory Item'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: stockCtrl,
                          decoration: const InputDecoration(labelText: 'Current Stock', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: thresholdCtrl,
                          decoration: const InputDecoration(labelText: 'Alert Threshold', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: unit,
                    decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'sheets', child: Text('Sheets')),
                      DropdownMenuItem(value: 'items', child: Text('Items')),
                      DropdownMenuItem(value: 'bottles', child: Text('Bottles')),
                      DropdownMenuItem(value: 'kg', child: Text('Kg')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => unit = v);
                    },
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
                
                final stock = int.tryParse(stockCtrl.text) ?? 0;
                final threshold = int.tryParse(thresholdCtrl.text) ?? 0;

                if (existingItem == null) {
                  final item = InventoryModel(
                    id: const Uuid().v4(),
                    name: nameCtrl.text.trim(),
                    category: category,
                    currentStock: stock,
                    lowStockThreshold: threshold,
                    unit: unit,
                    lastRestockedAt: DateTime.now(),
                  );
                  ref.read(inventoryNotifierProvider.notifier).addInventory(item);
                } else {
                  ref.read(inventoryNotifierProvider.notifier).updateInventory(
                    existingItem.id,
                    {
                      'name': nameCtrl.text.trim(),
                      'currentStock': stock,
                      'lowStockThreshold': threshold,
                      'unit': unit,
                      'lastRestockedAt': DateTime.now(), // update restock date on edit
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
