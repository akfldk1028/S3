// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;

/// 로고 시안 10종 SVG 생성 스크립트.
///
/// 리서치 기반:
/// - 3개 이하 시각 요소 → 전환율 180%↑
/// - 색상 심리 원칙 → 전환율 340%↑
/// - iOS 26 Liquid Glass 트렌드
/// - 연령대별 선호: 10대(비비드), 20-30대(미니멀), 40-50대(클린)
///
/// 실행: cd frontend && dart run tool/generate_logo_svgs.dart
void main() {
  final outputDir = Directory('assets/icon/candidates');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final generators = <String, String Function()>{
    // ── 기존 시안 (재현 님 선호) ──
    '00_segmented_s_original': _build00SegmentedSOriginal,

    // ── 카테고리 A: 미니멀/모던 (20-30대 타겟, 전환율 최고) ──
    '01_minimal_s_gradient': _build01MinimalSGradient,
    '02_circle_s_clean': _build02CircleSClean,
    '03_liquid_glass_s': _build03LiquidGlassS,

    // ── 카테고리 B: 기능 암시 (앱 정체성 전달) ──
    '04_lens_segments': _build04LensSegments,
    '05_palette_drop': _build05PaletteDrop,

    // ── 카테고리 C: 프리미엄/럭셔리 (셀러 도메인 궁합) ──
    '06_gem_facet': _build06GemFacet,
    '07_gold_emboss_s': _build07GoldEmbossS,

    // ── 카테고리 D: 트렌디/비비드 (10대, Gen Z) ──
    '08_neon_glow_s': _build08NeonGlowS,
    '09_dopamine_burst': _build09DopamineBurst,

    // ── 카테고리 E: 클린/클래식 (40-50대, 범용) ──
    '10_classic_monogram': _build10ClassicMonogram,
  };

  for (final entry in generators.entries) {
    final path = '${outputDir.path}/${entry.key}.svg';
    File(path).writeAsStringSync(entry.value());
    print('  [OK] $path');
  }

  print('\n10 SVGs exported to assets/icon/candidates/');
  print('VS Code or browser에서 열어서 확인하세요.');
}

// ============================================================
// 공통 상수
// ============================================================
const _bg = '#0F0F17';
const _accent1 = '#6C63FF'; // 퍼플
const _accent2 = '#FF6B9D'; // 핑크
const _gold = '#D4AF37';
const _roseGold = '#E8B4B8';
const _white = '#FFFFFF';

String _svgWrap(String id, String body, {String? extraDefs}) {
  return '''<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024" width="1024" height="1024">
  <defs>
    ${ extraDefs ?? ''}
  </defs>
  $body
</svg>''';
}

String _roundedBg(String color, {double rx = 225}) {
  return '<rect width="1024" height="1024" rx="$rx" fill="$color"/>';
}

// ============================================================
// 01: Minimal S Gradient
// 타겟: 20-30대 | 미니멀 그라데이션 S, 요소 2개(배경+S)
// 근거: 3개 이하 요소 → 180% 전환율
// ============================================================
String _build01MinimalSGradient() {
  return _svgWrap('01', '''
  ${_roundedBg(_bg)}

  <!-- S curve — thick gradient stroke, no extra decoration -->
  <path d="M 620 300
           C 650 210, 340 200, 375 330
           C 410 460, 615 490, 645 630
           C 675 770, 370 780, 400 690"
        fill="none" stroke="url(#g01)" stroke-width="64"
        stroke-linecap="round"/>
''', extraDefs: '''
    <linearGradient id="g01" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0%" stop-color="$_accent1"/>
      <stop offset="100%" stop-color="$_accent2"/>
    </linearGradient>
''');
}

// ============================================================
// 02: Circle S Clean
// 타겟: 전연령 | 원 안에 S, 심플 투톤
// 근거: 원형 = 신뢰감, 커뮤니티 (Instagram/Spotify 패턴)
// ============================================================
String _build02CircleSClean() {
  return _svgWrap('02', '''
  ${_roundedBg(_bg)}

  <!-- Gradient circle background -->
  <circle cx="512" cy="512" r="310" fill="url(#g02bg)"/>

  <!-- White S on gradient circle -->
  <path d="M 600 380
           C 620 310, 400 295, 420 375
           C 440 455, 590 475, 610 560
           C 630 650, 410 665, 430 590"
        fill="none" stroke="$_white" stroke-width="52"
        stroke-linecap="round"/>
''', extraDefs: '''
    <linearGradient id="g02bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="$_accent1"/>
      <stop offset="100%" stop-color="$_accent2"/>
    </linearGradient>
''');
}

// ============================================================
// 03: Liquid Glass S (iOS 26 트렌드)
// 타겟: 20-30대 | Liquid Glass 효과 + S
// 근거: iOS 26 최대 트렌드, Apple 생태계 유저 어필
// ============================================================
String _build03LiquidGlassS() {
  return _svgWrap('03', '''
  ${_roundedBg(_bg)}

  <!-- Ambient gradient glow behind glass -->
  <ellipse cx="512" cy="512" rx="350" ry="350" fill="url(#g03ambient)" opacity="0.4"/>

  <!-- Glass panel (frosted effect) -->
  <rect x="220" y="220" width="584" height="584" rx="120"
        fill="url(#g03glass)" stroke="$_white" stroke-opacity="0.15" stroke-width="1.5"/>

  <!-- Inner highlight (top-left reflection) -->
  <ellipse cx="400" cy="380" rx="180" ry="120"
           fill="$_white" opacity="0.06"/>

  <!-- S on glass -->
  <path d="M 610 370
           C 635 290, 385 270, 410 365
           C 435 460, 600 480, 625 590
           C 650 700, 395 720, 415 640"
        fill="none" stroke="url(#g03s)" stroke-width="50"
        stroke-linecap="round" opacity="0.95"/>
''', extraDefs: '''
    <linearGradient id="g03ambient" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="$_accent1"/>
      <stop offset="100%" stop-color="$_accent2"/>
    </linearGradient>
    <linearGradient id="g03glass" x1="0.3" y1="0" x2="0.7" y2="1">
      <stop offset="0%" stop-color="$_white" stop-opacity="0.12"/>
      <stop offset="100%" stop-color="$_white" stop-opacity="0.04"/>
    </linearGradient>
    <linearGradient id="g03s" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0%" stop-color="$_white"/>
      <stop offset="100%" stop-color="$_white" stop-opacity="0.7"/>
    </linearGradient>
''');
}

// ============================================================
// 04: Lens + Segments
// 타겟: 전연령 | 카메라 렌즈 + 세그먼트 조각 4개
// 근거: 기능 암시 (촬영→AI분할→변환), 요소 3개
// ============================================================
String _build04LensSegments() {
  final cx = 512.0, cy = 512.0;
  final r = 280.0;
  final colors = [_accent1, _accent2, _gold, _roseGold];
  final gap = 0.08;
  final sweep = (2 * math.pi - gap * 4) / 4;

  final sectors = StringBuffer();
  for (int i = 0; i < 4; i++) {
    final sa = -math.pi / 2 + i * (sweep + gap);
    final ea = sa + sweep;
    final x1 = cx + r * math.cos(sa);
    final y1 = cy + r * math.sin(sa);
    final x2 = cx + r * math.cos(ea);
    final y2 = cy + r * math.sin(ea);
    sectors.writeln('''
    <path d="M $cx $cy L ${x1.toStringAsFixed(1)} ${y1.toStringAsFixed(1)}
             A $r $r 0 0 1 ${x2.toStringAsFixed(1)} ${y2.toStringAsFixed(1)} Z"
          fill="${colors[i]}" opacity="0.9"/>''');
  }

  return _svgWrap('04', '''
  ${_roundedBg(_bg)}

  <!-- Outer ring glow -->
  <circle cx="$cx" cy="$cy" r="310" fill="none"
          stroke="$_accent1" stroke-width="15" opacity="0.1"
          filter="url(#f04glow)"/>

  <!-- Outer ring -->
  <circle cx="$cx" cy="$cy" r="300" fill="none"
          stroke="url(#g04ring)" stroke-width="10"/>

  <!-- 4 color sectors -->
  <g>$sectors</g>

  <!-- Center lens core -->
  <circle cx="$cx" cy="$cy" r="80" fill="$_bg"/>
  <circle cx="$cx" cy="$cy" r="60" fill="none"
          stroke="$_white" stroke-opacity="0.2" stroke-width="1.5"/>

  <!-- Lens reflection dot -->
  <circle cx="480" cy="480" r="15" fill="$_white" opacity="0.25"/>
''', extraDefs: '''
    <filter id="f04glow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="15"/>
    </filter>
    <linearGradient id="g04ring" gradientTransform="rotate(90)">
      <stop offset="0%" stop-color="$_accent1"/>
      <stop offset="50%" stop-color="$_accent2"/>
      <stop offset="100%" stop-color="$_accent1"/>
    </linearGradient>
''');
}

// ============================================================
// 05: Palette Drop
// 타겟: 20-40대 | 물방울/팔레트 형태 + 그라데이션
// 근거: 유기적 형태 = 친근함+창의성, 에디팅 앱 연상
// ============================================================
String _build05PaletteDrop() {
  return _svgWrap('05', '''
  ${_roundedBg(_bg)}

  <!-- Main drop shape with gradient -->
  <path d="M 512 220
           C 512 220, 720 420, 720 570
           A 208 208 0 1 1 304 570
           C 304 420, 512 220, 512 220 Z"
        fill="url(#g05drop)"/>

  <!-- Inner cut-out circle (palette hole) -->
  <circle cx="430" cy="600" r="55" fill="$_bg"/>

  <!-- Highlight streak -->
  <ellipse cx="480" cy="420" rx="40" ry="90"
           fill="$_white" opacity="0.1"
           transform="rotate(-15, 480, 420)"/>

  <!-- Glow -->
  <path d="M 512 220
           C 512 220, 720 420, 720 570
           A 208 208 0 1 1 304 570
           C 304 420, 512 220, 512 220 Z"
        fill="none" stroke="$_accent2" stroke-width="3" opacity="0.2"
        filter="url(#f05glow)"/>
''', extraDefs: '''
    <linearGradient id="g05drop" x1="0.3" y1="0" x2="0.7" y2="1">
      <stop offset="0%" stop-color="$_accent1"/>
      <stop offset="60%" stop-color="$_accent2"/>
      <stop offset="100%" stop-color="$_gold"/>
    </linearGradient>
    <filter id="f05glow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="12"/>
    </filter>
''');
}

// ============================================================
// 06: Gem Facet (리파인된 보석)
// 타겟: 30-50대 | 세련된 다이아몬드, 절제된 패싯
// 근거: 프리미엄 느낌, 럭셔리 카테고리 앱 패턴
// ============================================================
String _build06GemFacet() {
  return _svgWrap('06', '''
  ${_roundedBg(_bg)}

  <g filter="url(#f06glow)">
    <!-- Top facet (큰 삼각형) -->
    <polygon points="512,210 280,500 744,500"
             fill="url(#g06top)" stroke="$_white" stroke-opacity="0.1" stroke-width="1"/>

    <!-- Bottom left -->
    <polygon points="280,500 420,540 512,810"
             fill="url(#g06bl)" stroke="$_white" stroke-opacity="0.08" stroke-width="1"/>

    <!-- Bottom center -->
    <polygon points="420,540 604,540 512,810"
             fill="url(#g06bc)" stroke="$_white" stroke-opacity="0.08" stroke-width="1"/>

    <!-- Bottom right -->
    <polygon points="604,540 744,500 512,810"
             fill="url(#g06br)" stroke="$_white" stroke-opacity="0.08" stroke-width="1"/>

    <!-- Center highlight band -->
    <polygon points="280,500 420,540 604,540 744,500"
             fill="$_white" opacity="0.06"/>
  </g>
''', extraDefs: '''
    <filter id="f06glow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="8" result="blur"/>
      <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
    </filter>
    <linearGradient id="g06top" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0%" stop-color="$_accent1"/>
      <stop offset="100%" stop-color="${_lerpColor(_accent1, _accent2, 0.5)}"/>
    </linearGradient>
    <linearGradient id="g06bl" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="${_lerpColor(_accent1, _accent2, 0.4)}"/>
      <stop offset="100%" stop-color="$_accent2"/>
    </linearGradient>
    <linearGradient id="g06bc" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0%" stop-color="${_lerpColor(_accent1, _accent2, 0.5)}" stop-opacity="0.7"/>
      <stop offset="100%" stop-color="$_accent2"/>
    </linearGradient>
    <linearGradient id="g06br" x1="1" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="${_lerpColor(_accent1, _accent2, 0.6)}"/>
      <stop offset="100%" stop-color="$_accent2" stop-opacity="0.85"/>
    </linearGradient>
''');
}

// ============================================================
// 07: Gold Emboss S
// 타겟: 30-50대 | 골드 엠보싱 S, 블랙 배경
// 근거: 셀러 도메인 골드 팔레트와 일치, 프리미엄 브랜딩
// ============================================================
String _build07GoldEmbossS() {
  return _svgWrap('07', '''
  ${_roundedBg('#0A0A12')}

  <!-- Subtle radial ambient -->
  <circle cx="512" cy="512" r="400" fill="url(#g07ambient)" opacity="0.3"/>

  <!-- Gold S with emboss effect -->
  <!-- Shadow layer -->
  <path d="M 615 320
           C 640 240, 385 225, 408 340
           C 431 455, 600 475, 620 600
           C 640 725, 390 740, 410 660"
        fill="none" stroke="#1a1a00" stroke-width="58"
        stroke-linecap="round" opacity="0.5"
        transform="translate(3,4)"/>

  <!-- Main gold S -->
  <path d="M 615 320
           C 640 240, 385 225, 408 340
           C 431 455, 600 475, 620 600
           C 640 725, 390 740, 410 660"
        fill="none" stroke="url(#g07gold)" stroke-width="56"
        stroke-linecap="round"/>

  <!-- Highlight S (top reflection) -->
  <path d="M 615 320
           C 640 240, 385 225, 408 340
           C 431 455, 600 475, 620 600
           C 640 725, 390 740, 410 660"
        fill="none" stroke="$_white" stroke-width="56"
        stroke-linecap="round" opacity="0.08"
        transform="translate(-1,-2)"/>
''', extraDefs: '''
    <radialGradient id="g07ambient" cx="50%" cy="50%">
      <stop offset="0%" stop-color="$_gold" stop-opacity="0.15"/>
      <stop offset="100%" stop-color="$_gold" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="g07gold" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0%" stop-color="#F5D060"/>
      <stop offset="40%" stop-color="$_gold"/>
      <stop offset="70%" stop-color="#B8960C"/>
      <stop offset="100%" stop-color="$_roseGold"/>
    </linearGradient>
''');
}

// ============================================================
// 08: Neon Glow S
// 타겟: 10-20대 | 네온 사인 느낌, 레트로퓨처리즘
// 근거: Gen Z = 펀+리얼, 도파민 컬러, 레트로퓨처리즘 트렌드
// ============================================================
String _build08NeonGlowS() {
  return _svgWrap('08', '''
  ${_roundedBg('#08081A')}

  <!-- Multi-layer neon glow -->
  <!-- Outer glow (wide, faint) -->
  <path d="M 620 310
           C 648 225, 370 210, 395 335
           C 420 460, 600 485, 625 620
           C 650 755, 370 770, 400 685"
        fill="none" stroke="$_accent2" stroke-width="80"
        stroke-linecap="round" opacity="0.08"
        filter="url(#f08blur2)"/>

  <!-- Mid glow -->
  <path d="M 620 310
           C 648 225, 370 210, 395 335
           C 420 460, 600 485, 625 620
           C 650 755, 370 770, 400 685"
        fill="none" stroke="url(#g08neon)" stroke-width="56"
        stroke-linecap="round" opacity="0.35"
        filter="url(#f08blur1)"/>

  <!-- Core neon line -->
  <path d="M 620 310
           C 648 225, 370 210, 395 335
           C 420 460, 600 485, 625 620
           C 650 755, 370 770, 400 685"
        fill="none" stroke="url(#g08neon)" stroke-width="38"
        stroke-linecap="round"/>

  <!-- Bright center core -->
  <path d="M 620 310
           C 648 225, 370 210, 395 335
           C 420 460, 600 485, 625 620
           C 650 755, 370 770, 400 685"
        fill="none" stroke="$_white" stroke-width="10"
        stroke-linecap="round" opacity="0.5"/>
''', extraDefs: '''
    <filter id="f08blur1" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="18"/>
    </filter>
    <filter id="f08blur2" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="35"/>
    </filter>
    <linearGradient id="g08neon" x1="0.5" y1="0" x2="0.5" y2="1">
      <stop offset="0%" stop-color="#7B68EE"/>
      <stop offset="50%" stop-color="$_accent2"/>
      <stop offset="100%" stop-color="#FF3CAC"/>
    </linearGradient>
''');
}

// ============================================================
// 09: Dopamine Burst
// 타겟: 10-20대 | 비비드 멀티컬러 버스트, 에너지
// 근거: 도파민 컬러 = 다운로드 욕구 ↑, Z세대 선호
// ============================================================
String _build09DopamineBurst() {
  return _svgWrap('09', '''
  ${_roundedBg('#0C0C1A')}

  <!-- Background radial burst -->
  <circle cx="512" cy="512" r="380" fill="url(#g09burst)" opacity="0.15"/>

  <!-- Burst rays -->
  <g opacity="0.12">
    <line x1="512" y1="512" x2="512" y2="150" stroke="$_accent1" stroke-width="40"/>
    <line x1="512" y1="512" x2="825" y2="330" stroke="$_accent2" stroke-width="40"/>
    <line x1="512" y1="512" x2="874" y2="512" stroke="#FF3CAC" stroke-width="40"/>
    <line x1="512" y1="512" x2="825" y2="694" stroke="$_gold" stroke-width="40"/>
    <line x1="512" y1="512" x2="512" y2="874" stroke="#4ADE80" stroke-width="40"/>
    <line x1="512" y1="512" x2="199" y2="694" stroke="#00D4FF" stroke-width="40"/>
    <line x1="512" y1="512" x2="150" y2="512" stroke="$_accent1" stroke-width="40"/>
    <line x1="512" y1="512" x2="199" y2="330" stroke="$_accent2" stroke-width="40"/>
  </g>

  <!-- Gradient S centered -->
  <path d="M 610 350
           C 635 270, 390 255, 412 355
           C 434 455, 595 478, 615 580
           C 635 685, 395 698, 415 610"
        fill="none" stroke="url(#g09s)" stroke-width="58"
        stroke-linecap="round"/>

  <!-- White core highlight -->
  <path d="M 610 350
           C 635 270, 390 255, 412 355
           C 434 455, 595 478, 615 580
           C 635 685, 395 698, 415 610"
        fill="none" stroke="$_white" stroke-width="14"
        stroke-linecap="round" opacity="0.35"/>
''', extraDefs: '''
    <radialGradient id="g09burst" cx="50%" cy="50%">
      <stop offset="0%" stop-color="$_accent2"/>
      <stop offset="100%" stop-color="$_accent1"/>
    </radialGradient>
    <linearGradient id="g09s" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="$_accent1"/>
      <stop offset="35%" stop-color="$_accent2"/>
      <stop offset="65%" stop-color="#FF3CAC"/>
      <stop offset="100%" stop-color="$_gold"/>
    </linearGradient>
''');
}

// ============================================================
// 10: Classic Monogram
// 타겟: 40-50대 | 클래식 모노그램, 세리프 느낌
// 근거: Gen X = 심플+직관, 신뢰감, 요소 2개
// ============================================================
String _build10ClassicMonogram() {
  return _svgWrap('10', '''
  <!-- Solid gradient background -->
  <rect width="1024" height="1024" rx="225" fill="url(#g10bg)"/>

  <!-- Thin border inset -->
  <rect x="80" y="80" width="864" height="864" rx="180"
        fill="none" stroke="$_white" stroke-opacity="0.15" stroke-width="1.5"/>

  <!-- S monogram — elegant weight -->
  <path d="M 605 340
           C 628 260, 395 245, 415 345
           C 435 445, 590 465, 610 575
           C 630 685, 400 700, 420 620"
        fill="none" stroke="$_white" stroke-width="48"
        stroke-linecap="round"/>

  <!-- Subtle "3" subscript -->
  <text x="620" y="720" font-family="Georgia, serif" font-size="100"
        fill="$_white" opacity="0.5" font-weight="300">3</text>
''', extraDefs: '''
    <linearGradient id="g10bg" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="$_accent1"/>
      <stop offset="100%" stop-color="${_lerpColor(_accent1, _accent2, 0.6)}"/>
    </linearGradient>
''');
}

// ============================================================
// 00: Segmented S Original (기존 시안 — 재현 님 선호)
// S자를 세그멘테이션 조각으로 분할 — SAM3 핵심 기능 암시
// ============================================================
String _build00SegmentedSOriginal() {
  final mid33 = _lerpColor(_accent1, _accent2, 0.33);
  final mid50 = _lerpColor(_accent1, _accent2, 0.50);
  final mid66 = _lerpColor(_accent1, _accent2, 0.66);

  return _svgWrap('00', '''
  ${_roundedBg(_bg)}

  <g filter="url(#f00glow)">
    <!-- Top arc segment -->
    <path d="M 620 280
             A 140 140 0 0 0 380 260
             A 140 140 0 0 0 420 380
             L 480 350
             A 80 80 0 0 1 400 310
             A 80 80 0 0 1 580 300 Z"
          fill="$_accent1" opacity="0.95"/>

    <!-- Upper-mid segment -->
    <path d="M 420 380
             A 120 120 0 0 0 460 420
             L 530 380
             A 60 60 0 0 1 480 350 Z"
          fill="$mid33" opacity="0.9"/>

    <!-- Middle diagonal segment -->
    <path d="M 460 420
             C 500 480, 530 520, 560 580
             L 620 550
             C 590 490, 560 450, 530 380 Z"
          fill="$mid50" opacity="0.9"/>

    <!-- Lower-mid segment -->
    <path d="M 560 580
             A 120 120 0 0 0 540 640
             L 600 670
             A 60 60 0 0 1 620 550 Z"
          fill="$mid66" opacity="0.9"/>

    <!-- Bottom arc segment -->
    <path d="M 540 640
             A 140 140 0 0 0 640 740
             A 140 140 0 0 0 400 760
             L 420 690
             A 80 80 0 0 1 610 700
             A 80 80 0 0 1 600 670 Z"
          fill="$_accent2" opacity="0.95"/>
  </g>
''', extraDefs: '''
    <filter id="f00glow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="12" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
''');
}

// ============================================================
// Helper
// ============================================================
String _lerpColor(String hex1, String hex2, double t) {
  final r1 = int.parse(hex1.substring(1, 3), radix: 16);
  final g1 = int.parse(hex1.substring(3, 5), radix: 16);
  final b1 = int.parse(hex1.substring(5, 7), radix: 16);
  final r2 = int.parse(hex2.substring(1, 3), radix: 16);
  final g2 = int.parse(hex2.substring(3, 5), radix: 16);
  final b2 = int.parse(hex2.substring(5, 7), radix: 16);
  final r = (r1 + (r2 - r1) * t).round().clamp(0, 255);
  final g = (g1 + (g2 - g1) * t).round().clamp(0, 255);
  final b = (b1 + (b2 - b1) * t).round().clamp(0, 255);
  return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
}
