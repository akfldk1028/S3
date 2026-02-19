import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../workspace/theme.dart';

/// SNOW-style 전체화면 카메라 화면
///
/// 촬영한 사진 [XFile] 리스트를 `Navigator.pop(context, photos)`로 반환한다.
/// 갤러리 버튼 탭 시 [ImagePicker.pickMultiImage]로 기존 갤러리 선택도 지원.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
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
    _initCamera();
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
      // 후면 카메라 우선 선택
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

  void _onDone() {
    Navigator.pop(context, _capturedPhotos);
  }

  void _onClose() {
    Navigator.pop(context, <XFile>[]);
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 카메라 프리뷰
            _buildPreview(),

            // 상단 바: 닫기 + 카메라 전환
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

            // 하단 컨트롤: 갤러리 / 셔터 / 완료
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 닫기 버튼
        _CircleButton(
          icon: Icons.close,
          onTap: _onClose,
        ),
        // 카메라 전환
        if (_cameras.length >= 2)
          _CircleButton(
            icon: Icons.cameraswitch_rounded,
            onTap: _onSwitchCamera,
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

          // 완료 버튼 (촬영 수 표시)
          _capturedPhotos.isEmpty
              ? const SizedBox(width: 48)
              : GestureDetector(
                  onTap: _onDone,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: WsColors.accent1,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        '${_capturedPhotos.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

/// 반투명 원형 아이콘 버튼 (상단 컨트롤용)
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
