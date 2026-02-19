import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../domain_select/selected_preset_provider.dart';
import '../workspace/theme.dart';
import '../workspace/workspace_provider.dart';
import 'widgets/concept_chips_bar.dart';
import 'widgets/domain_drawer.dart';

/// SNOW-style 카메라 홈 화면 — 앱의 메인 진입점
///
/// 스플래시 → 인증 후 이 화면이 표시된다.
/// 사진 촬영/갤러리 선택 후 "다음" 버튼으로 도메인 선택으로 진행.
/// 웹에서는 카메라 대신 갤러리 전용 UI를 표시한다.
class CameraHomeScreen extends ConsumerStatefulWidget {
  const CameraHomeScreen({super.key});

  @override
  ConsumerState<CameraHomeScreen> createState() => _CameraHomeScreenState();
}

class _CameraHomeScreenState extends ConsumerState<CameraHomeScreen>
    with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isInitialized = false;
  FlashMode _flashMode = FlashMode.off;
  final List<XFile> _capturedPhotos = [];
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (!kIsWeb) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_cameras[_cameraIndex]);
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;
      _cameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_cameraIndex < 0) _cameraIndex = 0;
      await _initCameraController(_cameras[_cameraIndex]);
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _initCameraController(CameraDescription camera) async {
    final prev = _controller;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await prev?.dispose();
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setFlashMode(_flashMode);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera controller error: $e');
    }
  }

  // ── Actions ──

  Future<void> _onCapture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      setState(() => _capturedPhotos.add(file));
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _onSwitchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _isInitialized = false);
    await _initCameraController(_cameras[_cameraIndex]);
  }

  void _onFlashToggle() {
    final modes = [FlashMode.off, FlashMode.auto, FlashMode.always];
    final next = modes[(modes.indexOf(_flashMode) + 1) % modes.length];
    _flashMode = next;
    _controller?.setFlashMode(next);
    setState(() {});
  }

  Future<void> _onGallery() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _capturedPhotos.addAll(images));
    }
  }

  /// 촬영/선택한 사진을 workspace에 추가하고 다음 화면으로 이동.
  ///
  /// 도메인 선택됨 → /upload?presetId=... (domain-select 스킵)
  /// 도메인 미선택 → /domain-select (기존 flow)
  Future<void> _onProceed() async {
    if (_capturedPhotos.isEmpty) return;

    await ref
        .read(workspaceProvider.notifier)
        .addPhotosFromFiles(_capturedPhotos);

    if (mounted) {
      final presetId = ref.read(selectedPresetProvider);
      if (presetId != null) {
        context.push('/upload?presetId=$presetId');
      } else {
        context.push('/domain-select');
      }
    }
  }

  void _onSettings() {
    context.push('/settings');
  }

  // ── UI Helpers ──

  IconData get _flashIcon {
    switch (_flashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flash_on;
    }
  }

  String get _flashLabel {
    switch (_flashMode) {
      case FlashMode.off:
        return 'OFF';
      case FlashMode.auto:
        return 'AUTO';
      case FlashMode.always:
        return 'ON';
      case FlashMode.torch:
        return 'ON';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 웹에서는 카메라 없이 갤러리 전용 UI
    if (kIsWeb) return _buildWebFallback();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: const DomainDrawer(),
      drawerEdgeDragWidth: 40,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 카메라 프리뷰
            _buildPreview(),

            // 상단 바: 햄버거 + S3 + 카메라전환 + 설정
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: _buildTopBar(),
            ),

            // 좌측 플래시 토글
            Positioned(
              left: 16,
              bottom: MediaQuery.of(context).size.height * 0.25,
              child: _buildFlashButton(),
            ),

            // 컨셉 칩 바 (카메라 컨트롤 위)
            const Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              child: ConceptChipsBar(),
            ),

            // 하단 컨트롤: 갤러리 / 셔터 / 다음
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: _buildBottomBar(),
            ),
          ],
        ),
      ),
    );
  }

  /// 웹 플랫폼 — 카메라 대신 갤러리 선택 UI
  Widget _buildWebFallback() {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: WsColors.bg,
      drawer: const DomainDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 바 (햄버거 + S3 + 설정)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    onPressed: () =>
                        _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'S3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined,
                        color: WsColors.textMuted),
                    onPressed: _onSettings,
                  ),
                ],
              ),
            ),

            // 컨셉 칩 바
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ConceptChipsBar(),
            ),

            // 메인 콘텐츠
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 로고
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: WsColors.glassWhite,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: WsColors.glassBorder, width: 1.5),
                      ),
                      child: const Center(
                        child: Text(
                          'S3',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 2.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Add Photos to Get Started',
                      style: TextStyle(
                        color: WsColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Select images from your gallery',
                      style: TextStyle(
                        color: WsColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // 갤러리 선택 버튼
                    FilledButton.icon(
                      onPressed: () async {
                        await _onGallery();
                        if (_capturedPhotos.isNotEmpty) {
                          await _onProceed();
                        }
                      },
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('Choose from Gallery'),
                      style: FilledButton.styleFrom(
                        backgroundColor: WsColors.accent1,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (!_isInitialized || _controller == null) {
      return const Center(
        child: CircularProgressIndicator(color: WsColors.accent1),
      );
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize?.height ?? 1,
          height: _controller!.value.previewSize?.width ?? 1,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        // 햄버거 메뉴 → 도메인 사이드바
        _CircleButton(
          icon: Icons.menu_rounded,
          onTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        const SizedBox(width: 8),
        // S3 타이틀
        const Text(
          'S3',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        // 카메라 전환
        if (_cameras.length >= 2) ...[
          _CircleButton(
            icon: Icons.cameraswitch_rounded,
            onTap: _onSwitchCamera,
          ),
          const SizedBox(width: 8),
        ],
        // 설정
        _CircleButton(
          icon: Icons.settings_outlined,
          onTap: _onSettings,
        ),
      ],
    );
  }

  Widget _buildFlashButton() {
    return GestureDetector(
      onTap: _onFlashToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_flashIcon, color: Colors.white, size: 20),
            const SizedBox(width: 4),
            Text(
              _flashLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 갤러리 버튼
          _CircleButton(
            icon: Icons.photo_library_outlined,
            size: 48,
            onTap: _onGallery,
          ),

          // 셔터 버튼 (SNOW-style ring)
          _ShutterButton(
            onTap: _onCapture,
            isCapturing: _isCapturing,
          ),

          // 다음 버튼 (촬영 수 표시) — 사진 없으면 빈 공간
          _capturedPhotos.isEmpty
              ? const SizedBox(width: 48)
              : GestureDetector(
                  onTap: _onProceed,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: WsColors.accent1,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_capturedPhotos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

/// 반투명 원형 아이콘 버튼
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.55),
      ),
    );
  }
}

/// SNOW-style 셔터 버튼: 바깥 accent 링 + 안쪽 흰 원
class _ShutterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isCapturing;

  const _ShutterButton({
    required this.onTap,
    required this.isCapturing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCapturing ? null : onTap,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: WsColors.accent1, width: 4),
        ),
        padding: const EdgeInsets.all(4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: isCapturing ? Colors.grey : Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
