/**
 * 하드코딩 프리셋 데이터 — workflow.md 섹션 5.4
 * MVP: interior, seller (v2: profile, ootd 추가)
 */

import type { Preset } from '../_shared/types';

export const PRESETS: Record<string, Preset> = {
  interior: {
    id: 'interior',
    name: '건축/인테리어',
    concepts: [
      'Wall', 'Floor', 'Ceiling', 'Window', 'Door', 'Frame_Molding',
      'Tile', 'Grout', 'Cabinet', 'Countertop', 'Light', 'Handle',
    ],
    protect_defaults: ['Grout', 'Frame_Molding', 'Glass_highlight'],
    output_templates: [
      { id: '시안3안팩', name: '시안 3안 패키지', description: '모던/내추럴/호텔 각 공간별 6~10장' },
      { id: '전후비교', name: '전/후 비교 세트', description: 'Before+After 나란히 10장' },
      { id: '고객공유카드', name: '고객 공유 카드', description: 'Before+After+팔레트 요약' },
    ],
  },
  seller: {
    id: 'seller',
    name: '쇼핑/셀러',
    concepts: [
      'Body', 'Label_Text', 'Logo', 'Gloss', 'Parts', 'Accessories',
    ],
    protect_defaults: ['Label_Text', 'Logo', 'Gloss'],
    output_templates: [
      { id: '상품팩', name: '상품 패키지', description: '메인1+디테일4+착용1+패키지1' },
      { id: '옵션보드', name: '옵션 보드', description: '옵션 색상별 동기화 보드' },
      { id: '썸네일8종', name: '썸네일 8종', description: '플랫폼별 최적 사이즈 썸네일' },
    ],
  },
};
