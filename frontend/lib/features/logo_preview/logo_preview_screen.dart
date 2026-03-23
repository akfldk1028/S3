import 'package:flutter/material.dart';

import '../workspace/theme.dart';
import 'logo_painters.dart';

/// 로고 시안 4종 프리뷰 화면.
///
/// 각 시안을 다양한 사이즈(1024, 180, 60, 29)로 보여줌.
/// 다크 배경 + 라이트 배경 모두에서 확인 가능.
class LogoPreviewScreen extends StatelessWidget {
  const LogoPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WsColors.bg,
      appBar: AppBar(
        title: const Text('Logo 시안 프리뷰',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        backgroundColor: WsColors.surface,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('시안 비교 (큰 사이즈)'),
            const SizedBox(height: 12),
            _largeComparisonRow(),
            const SizedBox(height: 32),
            _sectionTitle('앱스토어 사이즈 시뮬레이션 (180px)'),
            const SizedBox(height: 12),
            _appStoreSizeRow(),
            const SizedBox(height: 32),
            _sectionTitle('홈화면 아이콘 (60px) + 알림 (29px)'),
            const SizedBox(height: 12),
            _smallSizeRow(),
            const SizedBox(height: 32),
            _sectionTitle('라이트 배경 테스트'),
            const SizedBox(height: 12),
            _lightBgTest(),
            const SizedBox(height: 32),
            _sectionTitle('각 시안 상세'),
            const SizedBox(height: 16),
            ..._detailCards(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // 큰 사이즈 4개 나란히
  Widget _largeComparisonRow() {
    return Row(
      children: _allPainters
          .map((e) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      CustomPaint(
                        size: const Size(150, 150),
                        painter: e.painter,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.name,
                        style: TextStyle(
                            color: WsColors.textSecondary, fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  // 앱스토어 사이즈
  Widget _appStoreSizeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _allPainters
          .map((e) => Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: CustomPaint(
                      size: const Size(90, 90),
                      painter: e.painter,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(e.label,
                      style: TextStyle(
                          color: WsColors.textSecondary, fontSize: 10)),
                ],
              ))
          .toList(),
    );
  }

  // 작은 사이즈
  Widget _smallSizeRow() {
    return Row(
      children: _allPainters.map((e) {
        return Expanded(
          child: Column(
            children: [
              Text(e.label,
                  style:
                      TextStyle(color: WsColors.textSecondary, fontSize: 10)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 홈화면 (60px)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: CustomPaint(
                      size: const Size(60, 60),
                      painter: e.painter,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 알림 (29px)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: CustomPaint(
                      size: const Size(29, 29),
                      painter: e.painter,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 라이트 배경 테스트
  Widget _lightBgTest() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _allPainters
            .map((e) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CustomPaint(
                    size: const Size(70, 70),
                    painter: e.painter,
                  ),
                ))
            .toList(),
      ),
    );
  }

  // 상세 카드
  List<Widget> _detailCards() {
    return _allPainters.map((e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: WsColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: WsColors.glassBorder, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CustomPaint(
                size: const Size(100, 100),
                painter: e.painter,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.label,
                    style: TextStyle(
                      color: WsColors.accent1,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.description,
                    style: TextStyle(
                      color: WsColors.textSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<_LogoOption> get _allPainters => [
        _LogoOption(
          name: '시안 1: Segmented S',
          label: '#1 세그먼트',
          description:
              'S자를 세그멘테이션 조각으로 분할.\nSAM3 핵심 기능(이미지 분할)을 직접 암시.\n퍼플→핑크 그라데이션 조각들.',
          painter: SegmentedSPainter(),
        ),
        _LogoOption(
          name: '시안 2: Palette Lens',
          label: '#2 렌즈',
          description:
              '카메라 렌즈 안에 팔레트 색상 조각.\n촬영→변환 파이프라인 암시.\n건축+쇼핑 컬러 모두 포함.',
          painter: PaletteLensPainter(),
        ),
        _LogoOption(
          name: '시안 3: Gradient Gem',
          label: '#3 보석',
          description:
              '다이아몬드 패싯 구조.\n프리미엄/럭셔리 이미지.\n셀러 도메인(골드)과도 어울림.',
          painter: GradientGemPainter(),
        ),
        _LogoOption(
          name: '시안 4: Minimal Glow S',
          label: '#4 글로우',
          description:
              '미니멀 S + 글로우 링.\n가장 깔끔하고 모던.\n작은 사이즈에서도 인식 좋음.',
          painter: MinimalGlowSPainter(),
        ),
      ];
}

class _LogoOption {
  final String name;
  final String label;
  final String description;
  final CustomPainter painter;

  const _LogoOption({
    required this.name,
    required this.label,
    required this.description,
    required this.painter,
  });
}
