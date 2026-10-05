-- 엘든 링 데이터베이스 구조 (게임 내 기능 관찰 기반 추론 설계)
CREATE SCHEMA IF NOT EXISTS eldenring DEFAULT CHARACTER SET utf8mb4;
USE eldenring;

-- ---------- 플랫폼 계정 / DLC ----------
CREATE TABLE player_profile (
  profile_id        BIGINT      NOT NULL AUTO_INCREMENT COMMENT '프로필 번호',
  platform          VARCHAR(10) NOT NULL COMMENT 'Steam/PlayStation/Xbox',
  platform_user_id  VARCHAR(40) NOT NULL COMMENT '플랫폼 사용자 ID',
  display_name      VARCHAR(40) NOT NULL COMMENT '표시 이름',
  first_played_at   DATETIME    NOT NULL COMMENT '최초 실행일',
  PRIMARY KEY (profile_id),
  UNIQUE KEY uq_profile_platform_user (platform, platform_user_id)
) ENGINE=InnoDB COMMENT='플랫폼 계정 (게임 자체 계정 없음)';

CREATE TABLE dlc (
  dlc_id       INT         NOT NULL COMMENT 'DLC 번호',
  dlc_name     VARCHAR(60) NOT NULL COMMENT 'Shadow of the Erdtree 등',
  released_at  DATE        NOT NULL COMMENT '출시일',
  PRIMARY KEY (dlc_id)
) ENGINE=InnoDB COMMENT='확장팩';

CREATE TABLE profile_dlc (
  profile_id   BIGINT   NOT NULL COMMENT '프로필',
  dlc_id       INT      NOT NULL COMMENT 'DLC',
  unlocked_at  DATETIME NOT NULL COMMENT '보유 확인 시각',
  PRIMARY KEY (profile_id, dlc_id),
  CONSTRAINT fk_profile_dlc_profile FOREIGN KEY (profile_id) REFERENCES player_profile (profile_id),
  CONSTRAINT fk_profile_dlc_dlc     FOREIGN KEY (dlc_id)     REFERENCES dlc (dlc_id)
) ENGINE=InnoDB COMMENT='DLC 보유 정보 (구매는 플랫폼 스토어에서 처리)';

-- ---------- 지역 / 축복 ----------
CREATE TABLE region (
  region_id    INT         NOT NULL COMMENT '지역 번호',
  dlc_id       INT         NULL COMMENT 'DLC 지역일 때',
  region_name  VARCHAR(40) NOT NULL COMMENT '림그레이브, 리에니에, 케일리드 등',
  PRIMARY KEY (region_id),
  CONSTRAINT fk_region_dlc FOREIGN KEY (dlc_id) REFERENCES dlc (dlc_id)
) ENGINE=InnoDB COMMENT='지역';

CREATE TABLE site_of_grace (
  grace_id    INT         NOT NULL COMMENT '축복 번호',
  region_id   INT         NOT NULL COMMENT '지역',
  grace_name  VARCHAR(60) NOT NULL COMMENT '축복 이름',
  PRIMARY KEY (grace_id),
  CONSTRAINT fk_grace_region FOREIGN KEY (region_id) REFERENCES region (region_id)
) ENGINE=InnoDB COMMENT='축복 (저장/빠른 이동 지점)';

-- ---------- 아이템 계열 ----------
CREATE TABLE weapon_skill (
  skill_id    INT         NOT NULL COMMENT '전투 기술 번호',
  skill_name  VARCHAR(50) NOT NULL COMMENT '전투 기술 이름',
  fp_cost     INT         NOT NULL DEFAULT 0 COMMENT 'FP 소모량',
  PRIMARY KEY (skill_id)
) ENGINE=InnoDB COMMENT='전투 기술';

CREATE TABLE item (
  item_id        INT          NOT NULL COMMENT '아이템 번호',
  dlc_id         INT          NULL COMMENT 'DLC 아이템일 때',
  item_name      VARCHAR(60)  NOT NULL COMMENT '아이템 이름',
  item_category  VARCHAR(12)  NOT NULL COMMENT '무기/방어구/탈리스만/마법/전회/영체/소모품/재료/귀중품',
  weight         DECIMAL(4,1) NOT NULL DEFAULT 0 COMMENT '무게',
  max_hold       INT          NOT NULL DEFAULT 1 COMMENT '최대 소지 수',
  max_storage    INT          NOT NULL DEFAULT 0 COMMENT '최대 보관 수',
  sell_price     INT          NOT NULL DEFAULT 0 COMMENT '판매가(룬)',
  description    VARCHAR(500) NULL COMMENT '아이템 설명문',
  PRIMARY KEY (item_id),
  CONSTRAINT fk_item_dlc FOREIGN KEY (dlc_id) REFERENCES dlc (dlc_id)
) ENGINE=InnoDB COMMENT='아이템 기본 정보';

CREATE TABLE weapon (
  item_id           INT         NOT NULL COMMENT '아이템 (무기)',
  default_skill_id  INT         NULL COMMENT '기본 전투 기술',
  weapon_type       VARCHAR(20) NOT NULL COMMENT '직검/대검/도/지팡이/성인 등',
  upgrade_type      VARCHAR(10) NOT NULL COMMENT '일반 단석(+25)/색 잃은 단석(+10)',
  attack_physical   INT         NOT NULL DEFAULT 0 COMMENT '물리 공격력',
  attack_magic      INT         NOT NULL DEFAULT 0 COMMENT '마력 공격력',
  attack_fire       INT         NOT NULL DEFAULT 0 COMMENT '화염 공격력',
  attack_lightning  INT         NOT NULL DEFAULT 0 COMMENT '벼락 공격력',
  attack_holy       INT         NOT NULL DEFAULT 0 COMMENT '성 공격력',
  req_strength      TINYINT     NOT NULL DEFAULT 0 COMMENT '요구 근력',
  req_dexterity     TINYINT     NOT NULL DEFAULT 0 COMMENT '요구 기량',
  req_intelligence  TINYINT     NOT NULL DEFAULT 0 COMMENT '요구 지력',
  req_faith         TINYINT     NOT NULL DEFAULT 0 COMMENT '요구 신앙',
  req_arcane        TINYINT     NOT NULL DEFAULT 0 COMMENT '요구 신비',
  scaling_grade     VARCHAR(20) NULL COMMENT '능력 보정 (예: 근D/기C)',
  PRIMARY KEY (item_id),
  CONSTRAINT fk_weapon_item  FOREIGN KEY (item_id)          REFERENCES item (item_id),
  CONSTRAINT fk_weapon_skill FOREIGN KEY (default_skill_id) REFERENCES weapon_skill (skill_id)
) ENGINE=InnoDB COMMENT='무기 (item의 하위 유형)';

CREATE TABLE armor (
  item_id         INT          NOT NULL COMMENT '아이템 (방어구)',
  armor_slot      VARCHAR(6)   NOT NULL COMMENT '머리/몸통/팔/다리',
  def_physical    DECIMAL(4,1) NOT NULL DEFAULT 0 COMMENT '물리 컷율',
  def_magic       DECIMAL(4,1) NOT NULL DEFAULT 0 COMMENT '마력 컷율',
  def_fire        DECIMAL(4,1) NOT NULL DEFAULT 0 COMMENT '화염 컷율',
  def_lightning   DECIMAL(4,1) NOT NULL DEFAULT 0 COMMENT '벼락 컷율',
  def_holy        DECIMAL(4,1) NOT NULL DEFAULT 0 COMMENT '성 컷율',
  poise           INT          NOT NULL DEFAULT 0 COMMENT '강인도',
  PRIMARY KEY (item_id),
  CONSTRAINT fk_armor_item FOREIGN KEY (item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='방어구 (item의 하위 유형)';

CREATE TABLE talisman (
  item_id      INT          NOT NULL COMMENT '아이템 (탈리스만)',
  effect_text  VARCHAR(200) NOT NULL COMMENT '효과',
  PRIMARY KEY (item_id),
  CONSTRAINT fk_talisman_item FOREIGN KEY (item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='탈리스만 (item의 하위 유형)';

CREATE TABLE spell (
  item_id           INT         NOT NULL COMMENT '아이템 (마법)',
  spell_type        VARCHAR(10) NOT NULL COMMENT '마술/기도',
  fp_cost           INT         NOT NULL COMMENT 'FP 소모량',
  slots_used        TINYINT     NOT NULL DEFAULT 1 COMMENT '기억 슬롯 사용 수',
  req_intelligence  TINYINT     NOT NULL DEFAULT 0 COMMENT '요구 지력',
  req_faith         TINYINT     NOT NULL DEFAULT 0 COMMENT '요구 신앙',
  req_arcane        TINYINT     NOT NULL DEFAULT 0 COMMENT '요구 신비',
  PRIMARY KEY (item_id),
  CONSTRAINT fk_spell_item FOREIGN KEY (item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='마술/기도 (item의 하위 유형)';

CREATE TABLE ash_of_war (
  item_id           INT         NOT NULL COMMENT '아이템 (전회)',
  skill_id          INT         NOT NULL COMMENT '부여되는 전투 기술',
  default_affinity  VARCHAR(10) NOT NULL COMMENT '기본 속성 (중후/예리/상질/마력 등)',
  PRIMARY KEY (item_id),
  CONSTRAINT fk_ash_item  FOREIGN KEY (item_id)  REFERENCES item (item_id),
  CONSTRAINT fk_ash_skill FOREIGN KEY (skill_id) REFERENCES weapon_skill (skill_id)
) ENGINE=InnoDB COMMENT='전회 (item의 하위 유형)';

-- ---------- 캐릭터 ----------
CREATE TABLE origin_class (
  class_id      INT         NOT NULL COMMENT '소체 번호',
  class_name    VARCHAR(20) NOT NULL COMMENT '방랑 기사, 사무라이, 점성술사 등',
  base_level    TINYINT     NOT NULL COMMENT '시작 레벨',
  vigor         TINYINT     NOT NULL COMMENT '생명력',
  mind          TINYINT     NOT NULL COMMENT '정신력',
  endurance     TINYINT     NOT NULL COMMENT '지구력',
  strength      TINYINT     NOT NULL COMMENT '근력',
  dexterity     TINYINT     NOT NULL COMMENT '기량',
  intelligence  TINYINT     NOT NULL COMMENT '지력',
  faith         TINYINT     NOT NULL COMMENT '신앙',
  arcane        TINYINT     NOT NULL COMMENT '신비',
  PRIMARY KEY (class_id)
) ENGINE=InnoDB COMMENT='소체 (시작 직업)';

CREATE TABLE player_character (
  character_id         BIGINT      NOT NULL AUTO_INCREMENT COMMENT '캐릭터 번호',
  profile_id           BIGINT      NOT NULL COMMENT '프로필',
  class_id             INT         NOT NULL COMMENT '선택한 소체',
  last_grace_id        INT         NULL COMMENT '마지막으로 쉰 축복',
  great_rune_item_id   INT         NULL COMMENT '장착한 큰 룬',
  save_slot_no         TINYINT     NOT NULL COMMENT '세이브 슬롯 (1~10)',
  character_name       VARCHAR(16) NOT NULL COMMENT '캐릭터 이름',
  char_level           SMALLINT    NOT NULL COMMENT '레벨 (최대 713)',
  runes_held           BIGINT      NOT NULL DEFAULT 0 COMMENT '보유 룬',
  vigor                TINYINT UNSIGNED NOT NULL COMMENT '생명력',
  mind                 TINYINT UNSIGNED NOT NULL COMMENT '정신력',
  endurance            TINYINT UNSIGNED NOT NULL COMMENT '지구력',
  strength             TINYINT UNSIGNED NOT NULL COMMENT '근력',
  dexterity            TINYINT UNSIGNED NOT NULL COMMENT '기량',
  intelligence         TINYINT UNSIGNED NOT NULL COMMENT '지력',
  faith                TINYINT UNSIGNED NOT NULL COMMENT '신앙',
  arcane               TINYINT UNSIGNED NOT NULL COMMENT '신비',
  flask_crimson_count  TINYINT     NOT NULL DEFAULT 3 COMMENT '붉은 성배병 수',
  flask_cerulean_count TINYINT     NOT NULL DEFAULT 1 COMMENT '푸른 성배병 수',
  ng_plus_cycle        TINYINT     NOT NULL DEFAULT 0 COMMENT '회차',
  play_time_sec        INT         NOT NULL DEFAULT 0 COMMENT '플레이 시간(초)',
  PRIMARY KEY (character_id),
  UNIQUE KEY uq_character_slot (profile_id, save_slot_no),
  CONSTRAINT fk_character_profile    FOREIGN KEY (profile_id)         REFERENCES player_profile (profile_id),
  CONSTRAINT fk_character_class      FOREIGN KEY (class_id)           REFERENCES origin_class (class_id),
  CONSTRAINT fk_character_grace      FOREIGN KEY (last_grace_id)      REFERENCES site_of_grace (grace_id),
  CONSTRAINT fk_character_great_rune FOREIGN KEY (great_rune_item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='캐릭터 (세이브 슬롯)';

CREATE TABLE character_inventory (
  inventory_id      BIGINT      NOT NULL AUTO_INCREMENT COMMENT '보유 아이템 번호',
  character_id      BIGINT      NOT NULL COMMENT '캐릭터',
  item_id           INT         NOT NULL COMMENT '아이템',
  ash_item_id       INT         NULL COMMENT '무기에 부여한 전회',
  quantity          INT         NOT NULL DEFAULT 1 COMMENT '수량',
  upgrade_level     TINYINT     NOT NULL DEFAULT 0 COMMENT '강화 수치',
  affinity          VARCHAR(10) NULL COMMENT '무기 속성',
  storage_location  VARCHAR(10) NOT NULL DEFAULT 'INVENTORY' COMMENT '소지품/보관함',
  PRIMARY KEY (inventory_id),
  CONSTRAINT fk_inventory_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_inventory_item      FOREIGN KEY (item_id)      REFERENCES item (item_id),
  CONSTRAINT fk_inventory_ash       FOREIGN KEY (ash_item_id)  REFERENCES ash_of_war (item_id)
) ENGINE=InnoDB COMMENT='캐릭터 소지품/보관함';

CREATE TABLE character_equipment (
  character_id  BIGINT      NOT NULL COMMENT '캐릭터',
  slot_code     VARCHAR(12) NOT NULL COMMENT '오른손1~3/왼손1~3/머리/몸통/팔/다리/탈리스만1~4/퀵슬롯',
  inventory_id  BIGINT      NOT NULL COMMENT '장착한 보유 아이템',
  PRIMARY KEY (character_id, slot_code),
  CONSTRAINT fk_equipment_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_equipment_inventory FOREIGN KEY (inventory_id) REFERENCES character_inventory (inventory_id)
) ENGINE=InnoDB COMMENT='장비 슬롯';

CREATE TABLE character_spell_slot (
  character_id   BIGINT  NOT NULL COMMENT '캐릭터',
  slot_no        TINYINT NOT NULL COMMENT '기억 슬롯 번호',
  spell_item_id  INT     NOT NULL COMMENT '기억한 마법',
  PRIMARY KEY (character_id, slot_no),
  CONSTRAINT fk_spell_slot_character FOREIGN KEY (character_id)  REFERENCES player_character (character_id),
  CONSTRAINT fk_spell_slot_spell     FOREIGN KEY (spell_item_id) REFERENCES spell (item_id)
) ENGINE=InnoDB COMMENT='마법 기억 슬롯';

CREATE TABLE character_grace (
  character_id   BIGINT   NOT NULL COMMENT '캐릭터',
  grace_id       INT      NOT NULL COMMENT '발견한 축복',
  discovered_at  DATETIME NOT NULL COMMENT '발견 시각',
  PRIMARY KEY (character_id, grace_id),
  CONSTRAINT fk_character_grace_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_character_grace_grace     FOREIGN KEY (grace_id)     REFERENCES site_of_grace (grace_id)
) ENGINE=InnoDB COMMENT='축복 발견 기록 (빠른 이동 해금)';

-- ---------- 보스 ----------
CREATE TABLE boss (
  boss_id         INT         NOT NULL COMMENT '보스 번호',
  region_id       INT         NOT NULL COMMENT '등장 지역',
  boss_name       VARCHAR(60) NOT NULL COMMENT '보스 이름',
  boss_type       VARCHAR(12) NOT NULL COMMENT '필드/던전/데미갓/최종',
  max_hp          INT         NOT NULL COMMENT '체력',
  rune_reward     INT         NOT NULL COMMENT '처치 보상 룬',
  is_required     TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '엔딩 필수 여부',
  PRIMARY KEY (boss_id),
  CONSTRAINT fk_boss_region FOREIGN KEY (region_id) REFERENCES region (region_id)
) ENGINE=InnoDB COMMENT='보스';

CREATE TABLE boss_drop (
  boss_id   INT NOT NULL COMMENT '보스',
  item_id   INT NOT NULL COMMENT '드롭 아이템 (추억, 큰 룬 등)',
  quantity  INT NOT NULL DEFAULT 1 COMMENT '수량',
  PRIMARY KEY (boss_id, item_id),
  CONSTRAINT fk_boss_drop_boss FOREIGN KEY (boss_id) REFERENCES boss (boss_id),
  CONSTRAINT fk_boss_drop_item FOREIGN KEY (item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='보스 확정 드롭';

CREATE TABLE character_boss_defeat (
  character_id  BIGINT   NOT NULL COMMENT '캐릭터',
  boss_id       INT      NOT NULL COMMENT '보스',
  ng_plus_cycle TINYINT  NOT NULL DEFAULT 0 COMMENT '처치한 회차',
  death_count   INT      NOT NULL DEFAULT 0 COMMENT '처치 전 사망 횟수',
  defeated_at   DATETIME NOT NULL COMMENT '처치 시각',
  PRIMARY KEY (character_id, boss_id, ng_plus_cycle),
  CONSTRAINT fk_boss_defeat_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_boss_defeat_boss      FOREIGN KEY (boss_id)      REFERENCES boss (boss_id)
) ENGINE=InnoDB COMMENT='보스 처치 기록';

-- ---------- NPC / 상점 / 이벤트 ----------
CREATE TABLE npc (
  npc_id       INT         NOT NULL COMMENT 'NPC 번호',
  region_id    INT         NOT NULL COMMENT '최초 등장 지역',
  npc_name     VARCHAR(40) NOT NULL COMMENT 'NPC 이름',
  is_merchant  TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '상인 여부',
  PRIMARY KEY (npc_id),
  CONSTRAINT fk_npc_region FOREIGN KEY (region_id) REFERENCES region (region_id)
) ENGINE=InnoDB COMMENT='NPC';

CREATE TABLE merchant_stock (
  npc_id       INT NOT NULL COMMENT '상인',
  item_id      INT NOT NULL COMMENT '판매 아이템',
  price_runes  INT NOT NULL COMMENT '가격(룬)',
  stock_limit  INT NULL COMMENT '재고 (NULL은 무제한)',
  PRIMARY KEY (npc_id, item_id),
  CONSTRAINT fk_stock_npc  FOREIGN KEY (npc_id)  REFERENCES npc (npc_id),
  CONSTRAINT fk_stock_item FOREIGN KEY (item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='상인 판매 목록';

CREATE TABLE npc_quest_step (
  npc_id          INT          NOT NULL COMMENT 'NPC',
  step_no         TINYINT      NOT NULL COMMENT '단계',
  grace_id        INT          NULL COMMENT '진행 장소 근처 축복',
  step_condition  VARCHAR(200) NOT NULL COMMENT '진행 조건',
  reward_item_id  INT          NULL COMMENT '보상 아이템',
  PRIMARY KEY (npc_id, step_no),
  CONSTRAINT fk_quest_step_npc    FOREIGN KEY (npc_id)         REFERENCES npc (npc_id),
  CONSTRAINT fk_quest_step_grace  FOREIGN KEY (grace_id)       REFERENCES site_of_grace (grace_id),
  CONSTRAINT fk_quest_step_reward FOREIGN KEY (reward_item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='NPC 이벤트 단계 (퀘스트 목록 UI 없음)';

CREATE TABLE character_npc_progress (
  character_id  BIGINT      NOT NULL COMMENT '캐릭터',
  npc_id        INT         NOT NULL COMMENT 'NPC',
  current_step  TINYINT     NOT NULL DEFAULT 0 COMMENT '현재 단계',
  npc_state     VARCHAR(10) NOT NULL DEFAULT 'ALIVE' COMMENT '생존/사망/적대/완료',
  PRIMARY KEY (character_id, npc_id),
  CONSTRAINT fk_npc_progress_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_npc_progress_npc       FOREIGN KEY (npc_id)       REFERENCES npc (npc_id)
) ENGINE=InnoDB COMMENT='캐릭터별 NPC 이벤트 진행 (이벤트 플래그)';

-- ---------- 온라인 ----------
CREATE TABLE multiplayer_session (
  session_id         BIGINT      NOT NULL AUTO_INCREMENT COMMENT '세션 번호',
  host_character_id  BIGINT      NOT NULL COMMENT '호스트 캐릭터',
  region_id          INT         NOT NULL COMMENT '진행 지역',
  session_type       VARCHAR(10) NOT NULL COMMENT '협력/침입/투기장',
  started_at         DATETIME    NOT NULL COMMENT '시작 시각',
  ended_at           DATETIME    NULL COMMENT '종료 시각',
  PRIMARY KEY (session_id),
  CONSTRAINT fk_session_host   FOREIGN KEY (host_character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_session_region FOREIGN KEY (region_id)         REFERENCES region (region_id)
) ENGINE=InnoDB COMMENT='멀티플레이 세션';

CREATE TABLE session_participant (
  session_id    BIGINT      NOT NULL COMMENT '세션',
  character_id  BIGINT      NOT NULL COMMENT '참가 캐릭터',
  join_role     VARCHAR(10) NOT NULL COMMENT '협력 영체/침입자/사냥꾼',
  join_result   VARCHAR(10) NULL COMMENT '임무 달성/사망/귀환',
  rune_reward   INT         NOT NULL DEFAULT 0 COMMENT '획득 룬',
  PRIMARY KEY (session_id, character_id),
  CONSTRAINT fk_participant_session   FOREIGN KEY (session_id)   REFERENCES multiplayer_session (session_id),
  CONSTRAINT fk_participant_character FOREIGN KEY (character_id) REFERENCES player_character (character_id)
) ENGINE=InnoDB COMMENT='세션 참가자';

CREATE TABLE player_message (
  message_id           BIGINT       NOT NULL AUTO_INCREMENT COMMENT '메시지 번호',
  author_character_id  BIGINT       NOT NULL COMMENT '작성 캐릭터',
  region_id            INT          NOT NULL COMMENT '작성 지역',
  message_text         VARCHAR(100) NOT NULL COMMENT '정형문 조합 문장',
  pos_x                FLOAT        NOT NULL COMMENT '좌표 X',
  pos_y                FLOAT        NOT NULL COMMENT '좌표 Y',
  pos_z                FLOAT        NOT NULL COMMENT '좌표 Z',
  good_count           INT          NOT NULL DEFAULT 0 COMMENT '좋음 평가 수',
  bad_count            INT          NOT NULL DEFAULT 0 COMMENT '나쁨 평가 수',
  written_at           DATETIME     NOT NULL COMMENT '작성 시각',
  PRIMARY KEY (message_id),
  CONSTRAINT fk_message_author FOREIGN KEY (author_character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_message_region FOREIGN KEY (region_id)           REFERENCES region (region_id)
) ENGINE=InnoDB COMMENT='바닥 메시지 (비동기 온라인)';

-- ---------- 도전 과제 ----------
CREATE TABLE achievement (
  achievement_id    INT          NOT NULL COMMENT '도전 과제 번호',
  boss_id           INT          NULL COMMENT '보스 처치형 과제의 대상 보스',
  achievement_name  VARCHAR(60)  NOT NULL COMMENT '도전 과제 이름',
  unlock_condition  VARCHAR(200) NOT NULL COMMENT '달성 조건',
  PRIMARY KEY (achievement_id),
  CONSTRAINT fk_achievement_boss FOREIGN KEY (boss_id) REFERENCES boss (boss_id)
) ENGINE=InnoDB COMMENT='도전 과제';

CREATE TABLE profile_achievement (
  profile_id      BIGINT   NOT NULL COMMENT '프로필',
  achievement_id  INT      NOT NULL COMMENT '도전 과제',
  unlocked_at     DATETIME NOT NULL COMMENT '달성 시각',
  PRIMARY KEY (profile_id, achievement_id),
  CONSTRAINT fk_profile_achievement_profile     FOREIGN KEY (profile_id)     REFERENCES player_profile (profile_id),
  CONSTRAINT fk_profile_achievement_achievement FOREIGN KEY (achievement_id) REFERENCES achievement (achievement_id)
) ENGINE=InnoDB COMMENT='도전 과제 달성 (프로필 단위)';
