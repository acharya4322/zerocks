import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../providers/pricing_provider.dart';

class PricingScreen extends ConsumerStatefulWidget {
  const PricingScreen({super.key});

  @override
  ConsumerState<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends ConsumerState<PricingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bwCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _duplexDiscountCtrl;
  late TextEditingController _taxPercentCtrl;

  @override
  void initState() {
    super.initState();
    _bwCtrl = TextEditingController();
    _colorCtrl = TextEditingController();
    _duplexDiscountCtrl = TextEditingController();
    _taxPercentCtrl = TextEditingController();

    // Populate data once fetched
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pricingConfigProvider.future).then((pricing) {
        if (pricing != null) {
          _bwCtrl.text = pricing.bwPerPage.toString();
          _colorCtrl.text = pricing.colorPerPage.toString();
          _duplexDiscountCtrl.text = pricing.duplexDiscount.toString();
          _taxPercentCtrl.text = pricing.taxPercent.toString();
        } else {
          _bwCtrl.text = '2.0';
          _colorCtrl.text = '10.0';
          _duplexDiscountCtrl.text = '0';
          _taxPercentCtrl.text = '0';
        }
      });
    });
  }

  @override
  void dispose() {
    _bwCtrl.dispose();
    _colorCtrl.dispose();
    _duplexDiscountCtrl.dispose();
    _taxPercentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final pricing = PricingModel(
      bwPerPage: double.tryParse(_bwCtrl.text) ?? 2.0,
      colorPerPage: double.tryParse(_colorCtrl.text) ?? 10.0,
      duplexDiscount: double.tryParse(_duplexDiscountCtrl.text) ?? 0.0,
      taxPercent: double.tryParse(_taxPercentCtrl.text) ?? 0.0,
      // Leaving bulk discounts as default empty for now
    );

    await ref.read(pricingNotifierProvider.notifier).updatePricing(pricing);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pricing updated')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(pricingNotifierProvider).isLoading;
    final configAsync = ref.watch(pricingConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print Pricing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.miscellaneous_services_outlined),
            tooltip: 'Manage Services',
            onPressed: () => context.push('/services'),
          ),
        ],
      ),
      body: configAsync.when(
        data: (_) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Base Print Rates', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bwCtrl,
                          decoration: const InputDecoration(labelText: 'B&W per page (₹)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _colorCtrl,
                          decoration: const InputDecoration(labelText: 'Color per page (₹)', border: OutlineInputBorder()),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Discounts & Taxes', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _duplexDiscountCtrl,
                    decoration: const InputDecoration(labelText: 'Duplex Discount (%)', border: OutlineInputBorder(), helperText: 'Discount applied if printed on both sides'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _taxPercentCtrl,
                    decoration: const InputDecoration(labelText: 'Tax / GST (%)', border: OutlineInputBorder(), helperText: 'Optional tax applied to the final bill'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: isLoading ? null : _save,
                    style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
                    child: isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Pricing Config'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
