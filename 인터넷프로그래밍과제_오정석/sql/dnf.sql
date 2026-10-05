-- 던전앤파이터 데이터베이스 구조 (게임 내 기능 관찰 기반 추론 설계)
CREATE SCHEMA IF NOT EXISTS dnf DEFAULT CHARACTER SET utf8mb4;
USE dnf;

-- ---------- 계정 / 서버 / 모험단 ----------
CREATE TABLE account (
  account_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '계정 번호',
  nexon_id        VARCHAR(50)  NOT NULL COMMENT '넥슨 로그인 ID',
  email           VARCHAR(100) NOT NULL COMMENT '이메일',
  cera_balance    INT          NOT NULL DEFAULT 0 COMMENT '보유 세라(유료 재화)',
  account_status  VARCHAR(10)  NOT NULL DEFAULT 'NORMAL' COMMENT '정상/정지/휴면',
  created_at      DATETIME     NOT NULL COMMENT '가입일',
  last_login_at   DATETIME     NULL COMMENT '최근 접속일',
  PRIMARY KEY (account_id),
  UNIQUE KEY uq_account_nexon_id (nexon_id)
) ENGINE=InnoDB COMMENT='계정';

CREATE TABLE game_server (
  server_id    TINYINT     NOT NULL COMMENT '서버 번호',
  server_name  VARCHAR(20) NOT NULL COMMENT '카인, 디레지에, 시로코 등',
  PRIMARY KEY (server_id),
  UNIQUE KEY uq_server_name (server_name)
) ENGINE=InnoDB COMMENT='서버';

CREATE TABLE adventure_group (
  adventure_id     BIGINT      NOT NULL AUTO_INCREMENT COMMENT '모험단 번호',
  account_id       BIGINT      NOT NULL COMMENT '계정',
  server_id        TINYINT     NOT NULL COMMENT '서버',
  adventure_name   VARCHAR(30) NOT NULL COMMENT '모험단 이름',
  adventure_level  INT         NOT NULL DEFAULT 1 COMMENT '모험단 레벨',
  adventure_exp    BIGINT      NOT NULL DEFAULT 0 COMMENT '모험단 경험치',
  PRIMARY KEY (adventure_id),
  UNIQUE KEY uq_adventure_account_server (account_id, server_id),
  UNIQUE KEY uq_adventure_name (server_id, adventure_name),
  CONSTRAINT fk_adventure_account FOREIGN KEY (account_id) REFERENCES account (account_id),
  CONSTRAINT fk_adventure_server  FOREIGN KEY (server_id)  REFERENCES game_server (server_id)
) ENGINE=InnoDB COMMENT='모험단 (계정-서버 단위 캐릭터 묶음)';

-- ---------- 직업 / 캐릭터 / 길드 ----------
CREATE TABLE job (
  job_id             INT         NOT NULL COMMENT '직업 번호',
  parent_job_id      INT         NULL COMMENT '상위 직업 (전직 전 직업)',
  job_name           VARCHAR(30) NOT NULL COMMENT '귀검사, 버서커, 헬벤터 등',
  advancement_stage  TINYINT     NOT NULL DEFAULT 0 COMMENT '0 기본, 1 전직, 2 각성, 3 2차 각성, 4 진 각성',
  PRIMARY KEY (job_id),
  CONSTRAINT fk_job_parent FOREIGN KEY (parent_job_id) REFERENCES job (job_id)
) ENGINE=InnoDB COMMENT='직업 (전직 계층 구조)';

CREATE TABLE guild (
  guild_id     BIGINT      NOT NULL AUTO_INCREMENT COMMENT '길드 번호',
  server_id    TINYINT     NOT NULL COMMENT '서버',
  guild_name   VARCHAR(30) NOT NULL COMMENT '길드 이름',
  guild_level  INT         NOT NULL DEFAULT 1 COMMENT '길드 레벨',
  notice       VARCHAR(200) NULL COMMENT '길드 공지',
  created_at   DATETIME    NOT NULL COMMENT '창설일',
  PRIMARY KEY (guild_id),
  UNIQUE KEY uq_guild_name (server_id, guild_name),
  CONSTRAINT fk_guild_server FOREIGN KEY (server_id) REFERENCES game_server (server_id)
) ENGINE=InnoDB COMMENT='길드';

CREATE TABLE player_character (
  character_id    BIGINT      NOT NULL AUTO_INCREMENT COMMENT '캐릭터 번호',
  adventure_id    BIGINT      NOT NULL COMMENT '소속 모험단',
  job_id          INT         NOT NULL COMMENT '현재 직업',
  character_name  VARCHAR(30) NOT NULL COMMENT '캐릭터 이름',
  char_level      INT         NOT NULL DEFAULT 1 COMMENT '레벨',
  char_exp        BIGINT      NOT NULL DEFAULT 0 COMMENT '경험치',
  fame            INT         NOT NULL DEFAULT 0 COMMENT '명성',
  gold            BIGINT      NOT NULL DEFAULT 0 COMMENT '보유 골드',
  fatigue         INT         NOT NULL DEFAULT 156 COMMENT '남은 피로도',
  created_at      DATETIME    NOT NULL COMMENT '생성일',
  PRIMARY KEY (character_id),
  KEY ix_character_name (character_name),
  CONSTRAINT fk_character_adventure FOREIGN KEY (adventure_id) REFERENCES adventure_group (adventure_id),
  CONSTRAINT fk_character_job       FOREIGN KEY (job_id)       REFERENCES job (job_id)
) ENGINE=InnoDB COMMENT='캐릭터';

CREATE TABLE guild_member (
  character_id  BIGINT      NOT NULL COMMENT '캐릭터 (캐릭터당 길드 1개)',
  guild_id      BIGINT      NOT NULL COMMENT '길드',
  member_role   VARCHAR(10) NOT NULL DEFAULT 'MEMBER' COMMENT '길드장/부길드장/길드원',
  contribution  INT         NOT NULL DEFAULT 0 COMMENT '기여도',
  joined_at     DATETIME    NOT NULL COMMENT '가입일',
  PRIMARY KEY (character_id),
  CONSTRAINT fk_guild_member_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_guild_member_guild     FOREIGN KEY (guild_id)     REFERENCES guild (guild_id)
) ENGINE=InnoDB COMMENT='길드 가입 정보';

-- ---------- 스킬 ----------
CREATE TABLE skill (
  skill_id        INT         NOT NULL COMMENT '스킬 번호',
  job_id          INT         NOT NULL COMMENT '사용 직업',
  skill_name      VARCHAR(50) NOT NULL COMMENT '스킬 이름',
  skill_type      VARCHAR(10) NOT NULL COMMENT '액티브/패시브/버프/각성기',
  required_level  INT         NOT NULL COMMENT '습득 레벨',
  max_level       INT         NOT NULL COMMENT '마스터 레벨',
  sp_cost         INT         NOT NULL COMMENT '레벨당 소모 SP',
  cooldown_sec    DECIMAL(5,1) NULL COMMENT '쿨타임(초)',
  mp_cost         INT         NULL COMMENT 'MP 소모량',
  PRIMARY KEY (skill_id),
  CONSTRAINT fk_skill_job FOREIGN KEY (job_id) REFERENCES job (job_id)
) ENGINE=InnoDB COMMENT='스킬';

CREATE TABLE character_skill (
  character_id  BIGINT  NOT NULL COMMENT '캐릭터',
  skill_id      INT     NOT NULL COMMENT '스킬',
  skill_level   INT     NOT NULL DEFAULT 1 COMMENT '투자한 스킬 레벨',
  quick_slot    TINYINT NULL COMMENT '단축키 슬롯',
  PRIMARY KEY (character_id, skill_id),
  CONSTRAINT fk_character_skill_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_character_skill_skill     FOREIGN KEY (skill_id)     REFERENCES skill (skill_id)
) ENGINE=InnoDB COMMENT='캐릭터 스킬 트리';

-- ---------- 아이템 ----------
CREATE TABLE item_set (
  set_id    INT         NOT NULL COMMENT '세트 번호',
  set_name  VARCHAR(50) NOT NULL COMMENT '세트 이름',
  PRIMARY KEY (set_id)
) ENGINE=InnoDB COMMENT='장비 세트';

CREATE TABLE item (
  item_id         INT          NOT NULL COMMENT '아이템 번호',
  item_name       VARCHAR(60)  NOT NULL COMMENT '아이템 이름',
  item_type       VARCHAR(10)  NOT NULL COMMENT '장비/소모품/재료/아바타/크리쳐',
  rarity          VARCHAR(10)  NOT NULL COMMENT '커먼~에픽/태초',
  required_level  INT          NOT NULL DEFAULT 1 COMMENT '착용/사용 레벨',
  trade_type      VARCHAR(10)  NOT NULL COMMENT '교환가능/계정귀속/교환불가',
  max_stack       INT          NOT NULL DEFAULT 1 COMMENT '최대 중첩 수',
  sell_price      INT          NOT NULL DEFAULT 0 COMMENT '상점 판매가',
  PRIMARY KEY (item_id)
) ENGINE=InnoDB COMMENT='아이템 기본 정보';

CREATE TABLE equipment (
  item_id        INT         NOT NULL COMMENT '아이템 (장비)',
  set_id         INT         NULL COMMENT '소속 세트',
  equip_slot     VARCHAR(10) NOT NULL COMMENT '무기/상의/하의/어깨/벨트/신발/목걸이/팔찌/반지/보조장비/마법석/귀걸이',
  equip_kind     VARCHAR(10) NULL COMMENT '무기 종류 또는 방어구 재질',
  phys_attack    INT         NOT NULL DEFAULT 0 COMMENT '물리 공격력',
  magic_attack   INT         NOT NULL DEFAULT 0 COMMENT '마법 공격력',
  stat_strength  INT         NOT NULL DEFAULT 0 COMMENT '힘',
  stat_intellect INT         NOT NULL DEFAULT 0 COMMENT '지능',
  base_fame      INT         NOT NULL DEFAULT 0 COMMENT '기본 명성',
  PRIMARY KEY (item_id),
  CONSTRAINT fk_equipment_item FOREIGN KEY (item_id) REFERENCES item (item_id),
  CONSTRAINT fk_equipment_set  FOREIGN KEY (set_id)  REFERENCES item_set (set_id)
) ENGINE=InnoDB COMMENT='장비 상세 (item의 하위 유형)';

CREATE TABLE inventory_item (
  inventory_item_id  BIGINT   NOT NULL AUTO_INCREMENT COMMENT '보유 아이템 번호',
  character_id       BIGINT   NOT NULL COMMENT '소유 캐릭터',
  item_id            INT      NOT NULL COMMENT '아이템',
  quantity           INT      NOT NULL DEFAULT 1 COMMENT '수량',
  slot_no            INT      NOT NULL COMMENT '인벤토리 칸',
  is_equipped        TINYINT(1) NOT NULL DEFAULT 0 COMMENT '착용 여부',
  acquired_at        DATETIME NOT NULL COMMENT '획득일',
  PRIMARY KEY (inventory_item_id),
  CONSTRAINT fk_inventory_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_inventory_item      FOREIGN KEY (item_id)      REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='캐릭터 인벤토리';

CREATE TABLE equipment_enhance (
  inventory_item_id  BIGINT      NOT NULL COMMENT '보유 장비',
  reinforce_level    TINYINT     NOT NULL DEFAULT 0 COMMENT '강화 수치',
  amplify_level      TINYINT     NOT NULL DEFAULT 0 COMMENT '증폭 수치',
  amplify_stat       VARCHAR(10) NULL COMMENT '증폭 스탯 (힘/지능/체력/정신력)',
  refine_level       TINYINT     NOT NULL DEFAULT 0 COMMENT '제련 수치 (무기)',
  enchant_name       VARCHAR(60) NULL COMMENT '마법부여 카드',
  PRIMARY KEY (inventory_item_id),
  CONSTRAINT fk_enhance_inventory FOREIGN KEY (inventory_item_id) REFERENCES inventory_item (inventory_item_id)
) ENGINE=InnoDB COMMENT='장비 강화/증폭/마법부여 상태';

CREATE TABLE adventure_storage (
  storage_id    BIGINT NOT NULL AUTO_INCREMENT COMMENT '금고 칸 번호',
  adventure_id  BIGINT NOT NULL COMMENT '모험단',
  item_id       INT    NOT NULL COMMENT '아이템',
  quantity      INT    NOT NULL DEFAULT 1 COMMENT '수량',
  PRIMARY KEY (storage_id),
  CONSTRAINT fk_storage_adventure FOREIGN KEY (adventure_id) REFERENCES adventure_group (adventure_id),
  CONSTRAINT fk_storage_item      FOREIGN KEY (item_id)      REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='모험단 금고 (캐릭터 간 공유 창고)';

-- ---------- 던전 / 몬스터 ----------
CREATE TABLE dungeon (
  dungeon_id     INT         NOT NULL COMMENT '던전 번호',
  dungeon_name   VARCHAR(50) NOT NULL COMMENT '던전 이름',
  dungeon_type   VARCHAR(10) NOT NULL COMMENT '일반/상급/레기온/레이드',
  region_name    VARCHAR(30) NOT NULL COMMENT '지역',
  min_level      INT         NOT NULL COMMENT '입장 레벨',
  required_fame  INT         NOT NULL DEFAULT 0 COMMENT '입장 명성',
  fatigue_cost   INT         NOT NULL DEFAULT 0 COMMENT '소모 피로도',
  max_party_size TINYINT     NOT NULL DEFAULT 4 COMMENT '최대 파티 인원',
  weekly_limit   TINYINT     NULL COMMENT '주간 입장 제한 횟수',
  PRIMARY KEY (dungeon_id)
) ENGINE=InnoDB COMMENT='던전';

CREATE TABLE monster (
  monster_id    INT         NOT NULL COMMENT '몬스터 번호',
  monster_name  VARCHAR(50) NOT NULL COMMENT '몬스터 이름',
  monster_grade VARCHAR(10) NOT NULL COMMENT '일반/네임드/보스',
  monster_level INT         NOT NULL COMMENT '레벨',
  max_hp        BIGINT      NOT NULL COMMENT '체력',
  PRIMARY KEY (monster_id)
) ENGINE=InnoDB COMMENT='몬스터';

CREATE TABLE dungeon_monster (
  dungeon_id  INT     NOT NULL COMMENT '던전',
  monster_id  INT     NOT NULL COMMENT '몬스터',
  room_no     TINYINT NOT NULL COMMENT '등장 방 번호',
  spawn_count TINYINT NOT NULL DEFAULT 1 COMMENT '등장 수',
  PRIMARY KEY (dungeon_id, monster_id, room_no),
  CONSTRAINT fk_dungeon_monster_dungeon FOREIGN KEY (dungeon_id) REFERENCES dungeon (dungeon_id),
  CONSTRAINT fk_dungeon_monster_monster FOREIGN KEY (monster_id) REFERENCES monster (monster_id)
) ENGINE=InnoDB COMMENT='던전별 등장 몬스터';

CREATE TABLE dungeon_drop (
  dungeon_id  INT          NOT NULL COMMENT '던전',
  item_id     INT          NOT NULL COMMENT '드롭 아이템',
  drop_rate   DECIMAL(7,4) NOT NULL COMMENT '드롭 확률(%)',
  PRIMARY KEY (dungeon_id, item_id),
  CONSTRAINT fk_dungeon_drop_dungeon FOREIGN KEY (dungeon_id) REFERENCES dungeon (dungeon_id),
  CONSTRAINT fk_dungeon_drop_item    FOREIGN KEY (item_id)    REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='던전 드롭 테이블';

CREATE TABLE dungeon_run (
  run_id          BIGINT   NOT NULL AUTO_INCREMENT COMMENT '플레이 기록 번호',
  dungeon_id      INT      NOT NULL COMMENT '던전',
  started_at      DATETIME NOT NULL COMMENT '입장 시각',
  clear_time_sec  INT      NULL COMMENT '클리어 시간(초)',
  is_cleared      TINYINT(1) NOT NULL DEFAULT 0 COMMENT '클리어 여부',
  PRIMARY KEY (run_id),
  CONSTRAINT fk_run_dungeon FOREIGN KEY (dungeon_id) REFERENCES dungeon (dungeon_id)
) ENGINE=InnoDB COMMENT='던전 플레이 기록 (파티 단위)';

CREATE TABLE dungeon_run_member (
  run_id        BIGINT       NOT NULL COMMENT '플레이 기록',
  character_id  BIGINT       NOT NULL COMMENT '참여 캐릭터',
  is_leader     TINYINT(1)   NOT NULL DEFAULT 0 COMMENT '파티장 여부',
  damage_share  DECIMAL(5,2) NULL COMMENT '피해량 비중(%)',
  clear_grade   VARCHAR(3)   NULL COMMENT '결과 등급 (SSS~F)',
  PRIMARY KEY (run_id, character_id),
  CONSTRAINT fk_run_member_run       FOREIGN KEY (run_id)       REFERENCES dungeon_run (run_id),
  CONSTRAINT fk_run_member_character FOREIGN KEY (character_id) REFERENCES player_character (character_id)
) ENGINE=InnoDB COMMENT='던전 참여 파티원';

-- ---------- 퀘스트 ----------
CREATE TABLE quest (
  quest_id        INT         NOT NULL COMMENT '퀘스트 번호',
  quest_name      VARCHAR(60) NOT NULL COMMENT '퀘스트 이름',
  quest_type      VARCHAR(10) NOT NULL COMMENT '에픽/일반/일일/업적',
  required_level  INT         NOT NULL COMMENT '수락 레벨',
  target_dungeon_id INT       NULL COMMENT '목표 던전',
  reward_exp      BIGINT      NOT NULL DEFAULT 0 COMMENT '보상 경험치',
  reward_gold     INT         NOT NULL DEFAULT 0 COMMENT '보상 골드',
  reward_item_id  INT         NULL COMMENT '보상 아이템',
  PRIMARY KEY (quest_id),
  CONSTRAINT fk_quest_dungeon     FOREIGN KEY (target_dungeon_id) REFERENCES dungeon (dungeon_id),
  CONSTRAINT fk_quest_reward_item FOREIGN KEY (reward_item_id)    REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='퀘스트';

CREATE TABLE character_quest (
  character_id   BIGINT      NOT NULL COMMENT '캐릭터',
  quest_id       INT         NOT NULL COMMENT '퀘스트',
  quest_status   VARCHAR(10) NOT NULL COMMENT '진행중/완료',
  progress_count INT         NOT NULL DEFAULT 0 COMMENT '진행 수치',
  accepted_at    DATETIME    NOT NULL COMMENT '수락일',
  completed_at   DATETIME    NULL COMMENT '완료일',
  PRIMARY KEY (character_id, quest_id),
  CONSTRAINT fk_character_quest_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_character_quest_quest     FOREIGN KEY (quest_id)     REFERENCES quest (quest_id)
) ENGINE=InnoDB COMMENT='캐릭터 퀘스트 진행';

-- ---------- 경매장 ----------
CREATE TABLE auction_listing (
  listing_id           BIGINT      NOT NULL AUTO_INCREMENT COMMENT '경매 등록 번호',
  seller_character_id  BIGINT      NOT NULL COMMENT '판매 캐릭터',
  buyer_character_id   BIGINT      NULL COMMENT '구매 캐릭터',
  item_id              INT         NOT NULL COMMENT '판매 아이템',
  quantity             INT         NOT NULL DEFAULT 1 COMMENT '수량',
  unit_price           BIGINT      NOT NULL COMMENT '개당 가격(골드)',
  listing_status       VARCHAR(10) NOT NULL COMMENT '판매중/판매완료/유찰',
  registered_at        DATETIME    NOT NULL COMMENT '등록일',
  expires_at           DATETIME    NOT NULL COMMENT '만료일',
  PRIMARY KEY (listing_id),
  CONSTRAINT fk_auction_seller FOREIGN KEY (seller_character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_auction_buyer  FOREIGN KEY (buyer_character_id)  REFERENCES player_character (character_id),
  CONSTRAINT fk_auction_item   FOREIGN KEY (item_id)             REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='경매장';

-- ---------- 과금 (세라샵) ----------
CREATE TABLE payment (
  payment_id      BIGINT      NOT NULL AUTO_INCREMENT COMMENT '결제 번호',
  account_id      BIGINT      NOT NULL COMMENT '결제 계정',
  pay_method      VARCHAR(15) NOT NULL COMMENT '신용카드/휴대폰/넥슨캐시/문화상품권',
  amount_krw      INT         NOT NULL COMMENT '결제 금액(원)',
  cera_charged    INT         NOT NULL COMMENT '충전된 세라',
  payment_status  VARCHAR(10) NOT NULL COMMENT '완료/취소/환불',
  paid_at         DATETIME    NOT NULL COMMENT '결제 시각',
  PRIMARY KEY (payment_id),
  CONSTRAINT fk_payment_account FOREIGN KEY (account_id) REFERENCES account (account_id)
) ENGINE=InnoDB COMMENT='세라 충전 결제 내역';

CREATE TABLE cash_product (
  product_id      INT         NOT NULL COMMENT '상품 번호',
  item_id         INT         NOT NULL COMMENT '지급 아이템',
  product_name    VARCHAR(60) NOT NULL COMMENT '상품 이름',
  category        VARCHAR(15) NOT NULL COMMENT '아바타/패키지/크리쳐/편의',
  price_cera      INT         NOT NULL COMMENT '판매가(세라)',
  purchase_limit  INT         NULL COMMENT '계정당 구매 제한',
  sale_start_at   DATETIME    NOT NULL COMMENT '판매 시작',
  sale_end_at     DATETIME    NULL COMMENT '판매 종료 (기간 한정)',
  PRIMARY KEY (product_id),
  CONSTRAINT fk_cash_product_item FOREIGN KEY (item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='세라샵 상품';

CREATE TABLE cash_purchase (
  purchase_id    BIGINT   NOT NULL AUTO_INCREMENT COMMENT '구매 번호',
  account_id     BIGINT   NOT NULL COMMENT '구매 계정',
  product_id     INT      NOT NULL COMMENT '구매 상품',
  character_id   BIGINT   NOT NULL COMMENT '수령 캐릭터',
  quantity       INT      NOT NULL DEFAULT 1 COMMENT '수량',
  cera_spent     INT      NOT NULL COMMENT '사용 세라',
  is_gift        TINYINT(1) NOT NULL DEFAULT 0 COMMENT '선물 여부',
  purchased_at   DATETIME NOT NULL COMMENT '구매 시각',
  PRIMARY KEY (purchase_id),
  CONSTRAINT fk_cash_purchase_account   FOREIGN KEY (account_id)   REFERENCES account (account_id),
  CONSTRAINT fk_cash_purchase_product   FOREIGN KEY (product_id)   REFERENCES cash_product (product_id),
  CONSTRAINT fk_cash_purchase_character FOREIGN KEY (character_id) REFERENCES player_character (character_id)
) ENGINE=InnoDB COMMENT='세라샵 구매 내역';
