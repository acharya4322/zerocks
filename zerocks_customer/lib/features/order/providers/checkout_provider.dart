import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:zerocks_common/zerocks_common.dart';
import '../../upload/providers/upload_provider.dart';
import 'cart_provider.dart';
import '../../../providers/app_providers.dart';

enum CheckoutStatus { idle, initializing, processing, success, error }

class CheckoutState {
  final CheckoutStatus status;
  final String? errorMessage;
  final String? createdOrderId;
  final String? razorpayOrderId;

  const CheckoutState({
    this.status = CheckoutStatus.idle,
    this.errorMessage,
    this.createdOrderId,
    this.razorpayOrderId,
  });

  CheckoutState copyWith({
    CheckoutStatus? status,
    String? errorMessage,
    String? createdOrderId,
    String? razorpayOrderId,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      createdOrderId: createdOrderId ?? this.createdOrderId,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
    );
  }
}

class CheckoutNotifier extends Notifier<CheckoutState> {
  late Razorpay _razorpay;

  @override
  CheckoutState build() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    ref.onDispose(() {
      _razorpay.clear();
    });

    return const CheckoutState();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = state.copyWith(status: CheckoutStatus.processing, errorMessage: null);

    try {
      // 1. Verify Payment via Cloud Function
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('verifyPayment');
      
      await callable.call({
        'razorpayOrderId': response.orderId ?? state.razorpayOrderId,
        'razorpayPaymentId': response.paymentId,
        'razorpaySignature': response.signature,
        'customOrderId': state.createdOrderId,
      });

      // 2. Clear cart and upload state on success
      ref.read(cartNotifierProvider.notifier).clearCart();
      ref.read(uploadNotifierProvider.notifier).reset();

      state = state.copyWith(status: CheckoutStatus.success);
    } catch (e) {
      state = state.copyWith(status: CheckoutStatus.error, errorMessage: 'Payment verification failed: $e');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    state = state.copyWith(
      status: CheckoutStatus.error,
      errorMessage: response.message ?? 'Payment failed',
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    state = state.copyWith(
      status: CheckoutStatus.error,
      errorMessage: 'External wallets not supported yet',
    );
  }

  Future<void> startCheckout() async {
    final billing = ref.read(liveBillingProvider);
    final user = ref.read(authStateProvider).value;
    final cartState = ref.read(cartNotifierProvider);
    final uploadState = ref.read(uploadNotifierProvider);
    final storageService = ref.read(storageServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    if (user == null) {
      state = state.copyWith(status: CheckoutStatus.error, errorMessage: 'User not authenticated');
      return;
    }

    if (billing.totalAmount <= 0) {
      state = state.copyWith(status: CheckoutStatus.error, errorMessage: 'Total amount must be greater than 0');
      return;
    }

    state = state.copyWith(status: CheckoutStatus.initializing, errorMessage: null);

    try {
      final orderId = const Uuid().v4();
      final amountInPaise = (billing.totalAmount * 100).toInt();

      // 1. Upload file if there is a print job
      String? jobId;
      String? fileUrl;
      if (uploadState.filePath != null && uploadState.fileName != null) {
        jobId = const Uuid().v4();
        fileUrl = await storageService.uploadFile(
          jobId: jobId,
          filePath: uploadState.filePath!,
          fileName: uploadState.fileName!,
        );

        final job = PrintJobModel(
          id: jobId,
          userId: user.uid,
          shopId: cartState.shopId,
          orderId: orderId, // Link print job to order
          fileUrl: fileUrl,
          fileName: uploadState.fileName!,
          fileType: uploadState.fileType ?? 'pdf',
          fileSizeBytes: uploadState.fileSizeBytes,
          pageCount: uploadState.analysis?.totalPages,
          status: PrintJobStatus.uploaded,
          copies: uploadState.copies,
          isColor: uploadState.isColor,
          isDuplex: uploadState.isDuplex,
          pageSize: uploadState.pageSize,
          createdAt: DateTime.now(),
        );
        await firestoreService.createPrintJob(job);
      }

      // 2. Build Unified Order Items
      final List<OrderItemModel> items = [];

      if (jobId != null && fileUrl != null) {
        items.add(OrderItemModel(
          id: jobId, // Link directly to PrintJobModel ID
          type: OrderItemType.print,
          name: uploadState.fileName!,
          price: billing.printCost,
          quantity: uploadState.copies,
          fileUrl: fileUrl,
          fileType: uploadState.fileType ?? 'pdf',
          pageCount: uploadState.analysis?.totalPages,
          printOptions: {
            'isColor': uploadState.isColor,
            'isDuplex': uploadState.isDuplex,
            'pageSize': uploadState.pageSize,
          },
        ));
      }

      for (final service in cartState.services) {
        items.add(OrderItemModel(
          id: const Uuid().v4(),
          type: OrderItemType.service,
          name: service.name,
          price: service.total,
          quantity: 1,
        ));
      }

      for (final item in cartState.stationeryItems) {
        items.add(OrderItemModel(
          id: const Uuid().v4(),
          type: OrderItemType.product,
          name: item.name,
          price: item.unitPrice,
          quantity: item.quantity,
          productId: item.id, // Original product ID
        ));
      }

      // 3. Create order in Firestore first with 'pending' status
      final order = OrderModel(
        id: orderId,
        userId: user.uid,
        shopId: cartState.shopId,
        status: OrderStatus.pending,
        totalAmount: billing.totalAmount,
        items: items,
        createdAt: DateTime.now(),
      );
      await firestoreService.createOrder(order);

      state = state.copyWith(createdOrderId: orderId);

      // 2. Call Cloud Function to create Razorpay Order
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createRazorpayOrder');
      
      final result = await callable.call({
        'amountInPaise': amountInPaise,
        'orderId': orderId,
      });

      final razorpayOrderId = result.data['id'];
      
      state = state.copyWith(razorpayOrderId: razorpayOrderId, status: CheckoutStatus.processing);

      // 3. Open Razorpay Checkout
      var options = {
        'key': PaymentConfig.razorpayKeyId,
        'amount': amountInPaise,
        'name': 'Zerocks',
        'description': 'Print Order',
        'order_id': razorpayOrderId,
        'prefill': {
          'contact': user.phoneNumber ?? '',
          'email': user.email ?? '',
        },
        'external': {
          'wallets': ['paytm']
        },
        'theme': {
          'color': '#6200EE' // Elegant Brand color
        }
      };

      _razorpay.open(options);
      
    } catch (e) {
      state = state.copyWith(status: CheckoutStatus.error, errorMessage: 'Checkout initialization failed: $e');
    }
  }

  void reset() {
    state = const CheckoutState();
  }
}

final checkoutNotifierProvider = NotifierProvider<CheckoutNotifier, CheckoutState>(CheckoutNotifier.new);
