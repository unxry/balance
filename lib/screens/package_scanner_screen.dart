import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/food_product.dart';
import '../services/app_settings_service.dart';
import '../services/food_catalog_repository.dart';
import '../services/package_recognition_service.dart';
import '../services/package_scanner_coordinator.dart';
import '../theme/app_text_styles.dart';
import '../theme/i18n.dart';
import '../widgets/common.dart';
import '../widgets/food_thumb.dart';

enum PackageScanAction { product, manual }

class PackageScanResult {
  final PackageScanAction action;
  final FoodProduct? product;

  const PackageScanResult.product(this.product)
    : action = PackageScanAction.product;
  const PackageScanResult.manual()
    : action = PackageScanAction.manual,
      product = null;
}

class PackageScannerScreen extends StatefulWidget {
  final FoodCatalogRepository repository;
  final S strings;
  final String? retailerSlug;

  const PackageScannerScreen({
    super.key,
    required this.repository,
    required this.strings,
    this.retailerSlug,
  });

  @override
  State<PackageScannerScreen> createState() => _PackageScannerScreenState();
}

class _PackageScannerScreenState extends State<PackageScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _camera;
  late final PackageScannerCoordinator _coordinator;
  final PackageRecognitionService _recognition = PackageRecognitionService();
  final ImagePicker _picker = ImagePicker();
  List<OcrProductCandidate> _candidates = const [];
  FoodProduct? _selectedProduct;
  bool _ocrBusy = false;
  String? _ocrError;
  Timer? _scanHelpTimer;
  bool _showScanHelp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _coordinator = PackageScannerCoordinator(
      widget.repository,
      retailerSlug: widget.retailerSlug,
    )..addListener(_refresh);
    _camera = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.itf14,
        BarcodeFormat.code128,
      ],
    );
    _scheduleScanHelp();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_camera.stop());
    } else if (state == AppLifecycleState.resumed) {
      if (_coordinator.phase == PackageScannerPhase.permissionDenied) {
        _coordinator.resume();
      }
      if (_coordinator.phase == PackageScannerPhase.scanning) {
        unawaited(_camera.start());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _coordinator
      ..removeListener(_refresh)
      ..dispose();
    _camera.dispose();
    _scanHelpTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = AppText(c);
    final s = widget.strings;
    final preview = _selectedProduct ?? _coordinator.product;
    return Scaffold(
      backgroundColor: c.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  GhostBackButton(onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 14),
                  Text(
                    s.isRu ? 'Сканировать продукт' : 'Scan product',
                    style: t.fraunces(size: 22, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  _cameraCard(c, t, s),
                  if (_showScanHelp &&
                      _coordinator.phase == PackageScannerPhase.scanning) ...[
                    const SizedBox(height: 10),
                    _scanHelp(c, t, s),
                  ],
                  const SizedBox(height: 14),
                  if (preview != null) _productPreview(c, t, s, preview),
                  if (preview == null &&
                      _coordinator.phase == PackageScannerPhase.searching)
                    _statusCard(
                      c,
                      t,
                      s.isRu ? 'Ищем товар…' : 'Looking up product…',
                      loading: true,
                    ),
                  if (preview == null &&
                      (_coordinator.phase == PackageScannerPhase.notFound ||
                          _coordinator.phase ==
                              PackageScannerPhase.invalidCode ||
                          _coordinator.phase ==
                              PackageScannerPhase.offlineNotFound))
                    _notFound(c, t, s),
                  if (_candidates.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      s.isRu ? 'Возможно, это' : 'Possible matches',
                      style: t.fraunces(size: 20, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    for (final candidate in _candidates)
                      _candidateRow(c, t, s, candidate),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cameraCard(dynamic c, AppText t, S s) {
    if (_coordinator.phase == PackageScannerPhase.error) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: c.muted, size: 42),
            const SizedBox(height: 12),
            Text(
              s.isRu
                  ? 'Не удалось запустить камеру'
                  : 'Could not start the camera',
              style: t.inter(size: 14, weight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _scanAgain,
              child: Text(s.isRu ? 'Повторить' : 'Try again'),
            ),
          ],
        ),
      );
    }
    if (_coordinator.phase == PackageScannerPhase.permissionDenied ||
        _coordinator.phase == PackageScannerPhase.restricted) {
      return Container(
        height: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_photography_outlined, color: c.muted, size: 42),
            const SizedBox(height: 12),
            Text(
              _coordinator.phase == PackageScannerPhase.restricted
                  ? (s.isRu
                        ? 'Камера ограничена на этом устройстве'
                        : 'Camera access is restricted')
                  : (s.isRu
                        ? 'Разрешите камеру для сканирования упаковки'
                        : 'Allow camera access to scan packaging'),
              textAlign: TextAlign.center,
              style: t.inter(size: 14, weight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_coordinator.phase == PackageScannerPhase.permissionDenied)
              PrimaryButton(
                label: s.isRu ? 'Открыть настройки' : 'Open Settings',
                icon: Icons.settings_outlined,
                onTap: const AppSettingsService().open,
              ),
          ],
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 310,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scanWindow = Rect.fromCenter(
              center: Offset(constraints.maxWidth / 2, 155),
              width: constraints.maxWidth * 0.76,
              height: 120,
            );
            return Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _camera,
                  scanWindow: scanWindow,
                  onDetect: _onDetect,
                  errorBuilder: (_, error) {
                    if (error.errorCode ==
                        MobileScannerErrorCode.permissionDenied) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _coordinator.permissionDenied(),
                      );
                    } else if (error.errorCode ==
                        MobileScannerErrorCode.unsupported) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _coordinator.permissionDenied(restricted: true),
                      );
                    } else {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _coordinator.cameraError(),
                      );
                    }
                    return ColoredBox(color: c.card2);
                  },
                ),
                ColoredBox(color: Colors.black.withValues(alpha: 0.10)),
                Center(
                  child: Container(
                    width: scanWindow.width,
                    height: scanWindow.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton.filledTonal(
                    tooltip: s.isRu ? 'Фонарик' : 'Torch',
                    onPressed: _camera.toggleTorch,
                    icon: const Icon(Icons.flashlight_on_rounded, size: 20),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 18,
                  child: Text(
                    s.isRu
                        ? 'Наведите камеру на штрихкод'
                        : 'Point the camera at the barcode',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      unawaited(
        _coordinator.handleBarcode(
          barcode.rawValue,
          onAccepted: () {
            _scanHelpTimer?.cancel();
            unawaited(_camera.stop());
            HapticFeedback.selectionClick();
          },
          onRejected: () {
            _scanHelpTimer?.cancel();
            unawaited(_camera.stop());
          },
        ),
      );
      if (_coordinator.scanLocked) break;
    }
  }

  Widget _productPreview(dynamic c, AppText t, S s, FoodProduct product) {
    final amount = product.netWeightGrams ?? product.netVolumeMl;
    final amountUnit = product.netWeightGrams != null ? 'г' : 'мл';
    final basis = switch (product.nutritionBasis) {
      FoodNutritionBasis.per100g => '/ 100 г',
      FoodNutritionBasis.per100ml => '/ 100 мл',
      FoodNutritionBasis.perServing => s.isRu ? '/ порцию' : '/ serving',
      FoodNutritionBasis.perItem => s.isRu ? '/ позицию' : '/ item',
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FoodThumb(
                seed: product.colorSeed,
                imageUrl: product.imageUrl,
                size: 72,
                radius: 18,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: t.fraunces(size: 20, weight: FontWeight.w700),
                    ),
                    if (product.brand != null || amount != null)
                      Text(
                        [
                          if (product.brand != null) product.brand!,
                          if (amount != null)
                            '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)} $amountUnit',
                        ].join(' · '),
                        style: t.inter(size: 12, color: c.muted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            product.nutrition.calories == null
                ? (s.isRu ? 'Нет полных данных' : 'Incomplete data')
                : '${product.nutrition.calories!.round()} ккал $basis',
            style: t.inter(size: 15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Б ${_value(product.nutrition.protein)}  ·  '
            'Ж ${_value(product.nutrition.fat)}  ·  '
            'У ${_value(product.nutrition.carbs)}',
            style: t.mono(size: 10),
          ),
          const SizedBox(height: 8),
          Text(
            '${s.isRu ? 'Источник' : 'Source'}: ${_source(product.source)}',
            style: t.inter(size: 10, color: c.muted),
          ),
          Text(
            '${s.isRu ? 'Качество' : 'Quality'}: ${_quality(product.dataQuality, s)}',
            style: t.inter(size: 10, color: c.muted),
          ),
          if (product.imageAttribution != null)
            Text(
              '${product.imageAttribution} · ${product.imageLicense ?? ''}',
              style: t.mono(size: 8, color: c.muted),
            ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: s.isRu ? 'Добавить' : 'Add',
            icon: Icons.add_rounded,
            onTap: product.nutrition.calories == null
                ? null
                : () => Navigator.pop(
                    context,
                    PackageScanResult.product(product),
                  ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _scanAgain,
              child: Text(s.isRu ? 'Сканировать ещё' : 'Scan another'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notFound(dynamic c, AppText t, S s) {
    final invalid = _coordinator.phase == PackageScannerPhase.invalidCode;
    final offline = _coordinator.phase == PackageScannerPhase.offlineNotFound;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          Text(
            invalid
                ? (s.isRu
                      ? 'Не удалось считать штрихкод'
                      : 'Could not read the barcode')
                : offline
                ? (s.isRu
                      ? 'Не удалось проверить товар'
                      : 'Could not check the product')
                : (s.isRu ? 'Товар пока не найден' : 'Product not found yet'),
            style: t.fraunces(size: 20, weight: FontWeight.w700),
          ),
          if (_ocrError != null) ...[
            const SizedBox(height: 6),
            Text(
              _ocrError!,
              textAlign: TextAlign.center,
              style: t.inter(size: 11, color: c.muted),
            ),
          ],
          const SizedBox(height: 14),
          if (offline) ...[
            PrimaryButton(
              label: s.isRu ? 'Повторить поиск' : 'Retry lookup',
              icon: Icons.refresh_rounded,
              onTap: _coordinator.retryLookup,
            ),
            const SizedBox(height: 8),
          ] else if (!invalid) ...[
            PrimaryButton(
              label: _ocrBusy
                  ? (s.isRu ? 'Распознаём…' : 'Recognizing…')
                  : (s.isRu ? 'Найти по упаковке' : 'Find by packaging'),
              icon: Icons.document_scanner_outlined,
              onTap: _ocrBusy ? null : _findByPackaging,
            ),
            const SizedBox(height: 8),
          ],
          TextButton.icon(
            onPressed: _scanAgain,
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
            label: Text(s.isRu ? 'Сканировать снова' : 'Scan again'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const PackageScanResult.manual()),
            child: Text(s.isRu ? 'Ввести вручную' : 'Enter manually'),
          ),
        ],
      ),
    );
  }

  Widget _candidateRow(
    dynamic c,
    AppText t,
    S s,
    OcrProductCandidate candidate,
  ) {
    final confidence = switch (candidate.confidence) {
      CandidateConfidence.high =>
        s.isRu ? 'Высокая уверенность' : 'High confidence',
      CandidateConfidence.medium =>
        s.isRu ? 'Средняя уверенность' : 'Medium confidence',
      CandidateConfidence.low =>
        s.isRu ? 'Низкая уверенность' : 'Low confidence',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() {
          _selectedProduct = candidate.product;
          _candidates = const [];
        }),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              FoodThumb(
                seed: candidate.product.colorSeed,
                imageUrl: candidate.product.imageUrl,
                size: 46,
                radius: 12,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.inter(size: 12, weight: FontWeight.w600),
                    ),
                    Text(confidence, style: t.mono(size: 8, color: c.muted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusCard(
    dynamic c,
    AppText t,
    String text, {
    bool loading = false,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: c.card,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.accent),
          ),
          const SizedBox(width: 10),
        ],
        Text(text, style: t.inter(size: 13)),
      ],
    ),
  );

  Future<void> _findByPackaging() async {
    setState(() {
      _ocrBusy = true;
      _ocrError = null;
      _candidates = const [];
    });
    await _camera.stop();
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        maxWidth: 2200,
      );
      if (image == null) {
        _scanAgain();
        return;
      }
      final features = await _recognition.recognize(image.path);
      final candidates = await _recognition.findCandidates(
        features,
        widget.repository,
      );
      if (!mounted) return;
      setState(() {
        _candidates = candidates;
        if (candidates.isEmpty) {
          _ocrError = widget.strings.isRu
              ? 'По тексту упаковки совпадений нет. Создайте продукт вручную.'
              : 'No catalog match from packaging text. Enter it manually.';
        }
      });
    } on PlatformException {
      if (mounted) {
        setState(() {
          _ocrError = widget.strings.isRu
              ? 'Не удалось распознать текст. Попробуйте снять упаковку ровнее.'
              : 'Could not recognize text. Try a clearer packaging photo.';
        });
      }
    } on FormatException {
      if (mounted) {
        setState(() {
          _ocrError = widget.strings.isRu
              ? 'Текст не распознан. Можно ввести продукт вручную.'
              : 'No text recognized. You can enter the product manually.';
        });
      }
    } finally {
      if (mounted) setState(() => _ocrBusy = false);
    }
  }

  void _scanAgain() {
    setState(() {
      _selectedProduct = null;
      _candidates = const [];
      _ocrError = null;
    });
    _coordinator.resume();
    _scheduleScanHelp();
    unawaited(_camera.start());
  }

  void _scheduleScanHelp() {
    _scanHelpTimer?.cancel();
    _showScanHelp = false;
    _scanHelpTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _coordinator.phase == PackageScannerPhase.scanning) {
        setState(() => _showScanHelp = true);
      }
    });
  }

  Widget _scanHelp(dynamic c, AppText t, S s) => Container(
    key: const ValueKey('scannerTimeoutHelp'),
    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
    decoration: BoxDecoration(
      color: c.card2,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            s.isRu
                ? 'Не получается считать штрихкод?'
                : 'Having trouble reading the barcode?',
            style: t.inter(size: 11, color: c.fg2),
          ),
        ),
        TextButton(
          onPressed: _scanAgain,
          child: Text(s.isRu ? 'Повторить' : 'Retry'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, const PackageScanResult.manual()),
          child: Text(s.isRu ? 'Вручную' : 'Manual'),
        ),
      ],
    ),
  );

  static String _value(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(1)} г';

  static String _source(FoodProductSource source) => switch (source) {
    FoodProductSource.openFoodFacts => 'Open Food Facts',
    FoodProductSource.officialManufacturer => 'производитель',
    FoodProductSource.officialRetailer => 'официальный ритейлер',
    FoodProductSource.restaurantMenu => 'ресторанное меню',
    FoodProductSource.verifiedCatalog => 'Balance Catalog',
    FoodProductSource.manual => 'пользователь',
  };

  static String _quality(FoodDataQuality quality, S s) => switch (quality) {
    FoodDataQuality.verified => s.isRu ? 'проверено' : 'verified',
    FoodDataQuality.good => s.isRu ? 'хорошее' : 'good',
    FoodDataQuality.partial => s.isRu ? 'неполное' : 'partial',
    FoodDataQuality.unverified => s.isRu ? 'не проверено' : 'unverified',
  };
}
