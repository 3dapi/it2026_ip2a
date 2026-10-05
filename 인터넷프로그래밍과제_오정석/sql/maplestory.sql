-- 메이플스토리 데이터베이스 구조 (게임 내 기능 관찰 기반 추론 설계)
CREATE SCHEMA IF NOT EXISTS maplestory DEFAULT CHARACTER SET utf8mb4;
USE maplestory;

-- ---------- 계정 / 월드 ----------
CREATE TABLE account (
  account_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '계정 번호',
  nexon_id        VARCHAR(50)  NOT NULL COMMENT '넥슨 로그인 ID',
  email           VARCHAR(100) NOT NULL COMMENT '이메일',
  nexon_cash      INT          NOT NULL DEFAULT 0 COMMENT '넥슨캐시 잔액',
  maple_point     INT          NOT NULL DEFAULT 0 COMMENT '메이플포인트 잔액',
  account_status  VARCHAR(10)  NOT NULL DEFAULT 'NORMAL' COMMENT '정상/정지/휴면',
  created_at      DATETIME     NOT NULL COMMENT '가입일',
  PRIMARY KEY (account_id),
  UNIQUE KEY uq_account_nexon_id (nexon_id)
) ENGINE=InnoDB COMMENT='계정';

CREATE TABLE game_world (
  world_id    TINYINT     NOT NULL COMMENT '월드 번호',
  world_name  VARCHAR(20) NOT NULL COMMENT '스카니아, 루나, 엘리시움, 크로아 등',
  world_type  VARCHAR(10) NOT NULL COMMENT '일반/리부트(에오스, 헬리오스)',
  PRIMARY KEY (world_id),
  UNIQUE KEY uq_world_name (world_name)
) ENGINE=InnoDB COMMENT='월드';

-- ---------- 직업 / 맵 / 길드 / 캐릭터 ----------
CREATE TABLE job (
  job_id      INT         NOT NULL COMMENT '직업 번호',
  job_name    VARCHAR(30) NOT NULL COMMENT '히어로, 아크메이지, 나이트로드 등',
  job_branch  VARCHAR(10) NOT NULL COMMENT '전사/마법사/궁수/도적/해적',
  job_faction VARCHAR(15) NOT NULL COMMENT '모험가/시그너스/영웅/레지스탕스/노바/레프 등',
  main_stat   VARCHAR(5)  NOT NULL COMMENT '주스탯 (STR/DEX/INT/LUK/HP)',
  PRIMARY KEY (job_id)
) ENGINE=InnoDB COMMENT='직업';

CREATE TABLE game_map (
  map_id                INT         NOT NULL COMMENT '맵 번호',
  map_name              VARCHAR(50) NOT NULL COMMENT '맵 이름',
  area_name             VARCHAR(30) NOT NULL COMMENT '지역 (헤네시스, 소멸의 여로 등)',
  recommended_level     INT         NULL COMMENT '권장 레벨',
  required_force_type   VARCHAR(10) NULL COMMENT '아케인포스/어센틱포스',
  required_force        INT         NULL COMMENT '요구 포스 수치',
  is_town               TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '마을 여부',
  PRIMARY KEY (map_id)
) ENGINE=InnoDB COMMENT='맵';

CREATE TABLE guild (
  guild_id     BIGINT      NOT NULL AUTO_INCREMENT COMMENT '길드 번호',
  world_id     TINYINT     NOT NULL COMMENT '월드',
  guild_name   VARCHAR(30) NOT NULL COMMENT '길드 이름',
  guild_level  INT         NOT NULL DEFAULT 1 COMMENT '길드 레벨',
  guild_point  BIGINT      NOT NULL DEFAULT 0 COMMENT '길드 명성치',
  created_at   DATETIME    NOT NULL COMMENT '창설일',
  PRIMARY KEY (guild_id),
  UNIQUE KEY uq_guild_name (world_id, guild_name),
  CONSTRAINT fk_guild_world FOREIGN KEY (world_id) REFERENCES game_world (world_id)
) ENGINE=InnoDB COMMENT='길드';

CREATE TABLE player_character (
  character_id    BIGINT      NOT NULL AUTO_INCREMENT COMMENT '캐릭터 번호',
  account_id      BIGINT      NOT NULL COMMENT '계정',
  world_id        TINYINT     NOT NULL COMMENT '월드',
  job_id          INT         NOT NULL COMMENT '직업',
  current_map_id  INT         NOT NULL COMMENT '현재 위치한 맵',
  character_name  VARCHAR(12) NOT NULL COMMENT '캐릭터 이름',
  char_level      INT         NOT NULL DEFAULT 1 COMMENT '레벨',
  char_exp        BIGINT      NOT NULL DEFAULT 0 COMMENT '경험치',
  meso            BIGINT      NOT NULL DEFAULT 0 COMMENT '보유 메소',
  stat_str        INT         NOT NULL DEFAULT 4 COMMENT 'STR',
  stat_dex        INT         NOT NULL DEFAULT 4 COMMENT 'DEX',
  stat_int        INT         NOT NULL DEFAULT 4 COMMENT 'INT',
  stat_luk        INT         NOT NULL DEFAULT 4 COMMENT 'LUK',
  combat_power    BIGINT      NOT NULL DEFAULT 0 COMMENT '전투력',
  popularity      INT         NOT NULL DEFAULT 0 COMMENT '인기도',
  created_at      DATETIME    NOT NULL COMMENT '생성일',
  PRIMARY KEY (character_id),
  UNIQUE KEY uq_character_name (world_id, character_name),
  CONSTRAINT fk_character_account FOREIGN KEY (account_id)     REFERENCES account (account_id),
  CONSTRAINT fk_character_world   FOREIGN KEY (world_id)       REFERENCES game_world (world_id),
  CONSTRAINT fk_character_job     FOREIGN KEY (job_id)         REFERENCES job (job_id),
  CONSTRAINT fk_character_map     FOREIGN KEY (current_map_id) REFERENCES game_map (map_id)
) ENGINE=InnoDB COMMENT='캐릭터';

CREATE TABLE guild_member (
  character_id  BIGINT      NOT NULL COMMENT '캐릭터 (캐릭터당 길드 1개)',
  guild_id      BIGINT      NOT NULL COMMENT '길드',
  member_role   VARCHAR(10) NOT NULL DEFAULT 'MEMBER' COMMENT '마스터/부마스터/길드원',
  weekly_score  INT         NOT NULL DEFAULT 0 COMMENT '주간 미션 포인트',
  joined_at     DATETIME    NOT NULL COMMENT '가입일',
  PRIMARY KEY (character_id),
  CONSTRAINT fk_guild_member_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_guild_member_guild     FOREIGN KEY (guild_id)     REFERENCES guild (guild_id)
) ENGINE=InnoDB COMMENT='길드 가입 정보';

-- ---------- 유니온 ----------
CREATE TABLE maple_union (
  union_id      BIGINT      NOT NULL AUTO_INCREMENT COMMENT '유니온 번호',
  account_id    BIGINT      NOT NULL COMMENT '계정',
  world_id      TINYINT     NOT NULL COMMENT '월드',
  union_level   INT         NOT NULL DEFAULT 0 COMMENT '유니온 레벨 (캐릭터 레벨 합)',
  union_grade   VARCHAR(20) NOT NULL COMMENT '노비스~그랜드 마스터',
  PRIMARY KEY (union_id),
  UNIQUE KEY uq_union_account_world (account_id, world_id),
  CONSTRAINT fk_union_account FOREIGN KEY (account_id) REFERENCES account (account_id),
  CONSTRAINT fk_union_world   FOREIGN KEY (world_id)   REFERENCES game_world (world_id)
) ENGINE=InnoDB COMMENT='메이플 유니온 (계정-월드 단위 성장)';

CREATE TABLE union_block (
  union_id      BIGINT  NOT NULL COMMENT '유니온',
  character_id  BIGINT  NOT NULL COMMENT '배치한 공격대원',
  board_x       TINYINT NOT NULL COMMENT '전투 지도 X',
  board_y       TINYINT NOT NULL COMMENT '전투 지도 Y',
  rotation      TINYINT NOT NULL DEFAULT 0 COMMENT '블록 회전',
  PRIMARY KEY (union_id, character_id),
  CONSTRAINT fk_union_block_union     FOREIGN KEY (union_id)     REFERENCES maple_union (union_id),
  CONSTRAINT fk_union_block_character FOREIGN KEY (character_id) REFERENCES player_character (character_id)
) ENGINE=InnoDB COMMENT='유니온 공격대원 배치';

-- ---------- 스킬 ----------
CREATE TABLE skill (
  skill_id        INT         NOT NULL COMMENT '스킬 번호',
  job_id          INT         NOT NULL COMMENT '직업',
  skill_name      VARCHAR(50) NOT NULL COMMENT '스킬 이름',
  job_grade       TINYINT     NOT NULL COMMENT '차수 (1~6차, 5차 V, 6차 HEXA)',
  skill_type      VARCHAR(10) NOT NULL COMMENT '액티브/패시브/버프',
  max_level       INT         NOT NULL COMMENT '마스터 레벨',
  cooldown_sec    INT         NULL COMMENT '재사용 대기시간(초)',
  PRIMARY KEY (skill_id),
  CONSTRAINT fk_skill_job FOREIGN KEY (job_id) REFERENCES job (job_id)
) ENGINE=InnoDB COMMENT='스킬';

CREATE TABLE character_skill (
  character_id  BIGINT NOT NULL COMMENT '캐릭터',
  skill_id      INT    NOT NULL COMMENT '스킬',
  skill_level   INT    NOT NULL DEFAULT 1 COMMENT '스킬 레벨',
  PRIMARY KEY (character_id, skill_id),
  CONSTRAINT fk_character_skill_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_character_skill_skill     FOREIGN KEY (skill_id)     REFERENCES skill (skill_id)
) ENGINE=InnoDB COMMENT='캐릭터 스킬 레벨';

-- ---------- 아이템 ----------
CREATE TABLE item_set (
  set_id    INT         NOT NULL COMMENT '세트 번호',
  set_name  VARCHAR(50) NOT NULL COMMENT '앱솔랩스, 아케인셰이드, 에테르넬 등',
  PRIMARY KEY (set_id)
) ENGINE=InnoDB COMMENT='장비 세트';

CREATE TABLE item (
  item_id         INT         NOT NULL COMMENT '아이템 번호',
  item_name       VARCHAR(60) NOT NULL COMMENT '아이템 이름',
  inventory_tab   VARCHAR(6)  NOT NULL COMMENT '장비/소비/설치/기타/캐시',
  required_level  INT         NOT NULL DEFAULT 0 COMMENT '착용 레벨',
  trade_type      VARCHAR(12) NOT NULL COMMENT '교환가능/교환불가/월드 내 이동',
  max_stack       INT         NOT NULL DEFAULT 1 COMMENT '최대 중첩 수',
  npc_price       INT         NOT NULL DEFAULT 0 COMMENT '상점 판매가(메소)',
  is_cash_item    TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '캐시 아이템 여부',
  PRIMARY KEY (item_id)
) ENGINE=InnoDB COMMENT='아이템 기본 정보';

CREATE TABLE equipment (
  item_id        INT         NOT NULL COMMENT '아이템 (장비)',
  set_id         INT         NULL COMMENT '소속 세트',
  equip_slot     VARCHAR(12) NOT NULL COMMENT '무기/모자/상의/하의/장갑/신발/반지/펜던트 등',
  job_branch     VARCHAR(10) NULL COMMENT '착용 가능 직업군',
  base_attack    INT         NOT NULL DEFAULT 0 COMMENT '기본 공격력',
  base_magic     INT         NOT NULL DEFAULT 0 COMMENT '기본 마력',
  base_main_stat INT         NOT NULL DEFAULT 0 COMMENT '기본 주스탯',
  upgrade_slots  TINYINT     NOT NULL DEFAULT 0 COMMENT '업그레이드 가능 횟수',
  max_starforce  TINYINT     NOT NULL DEFAULT 0 COMMENT '최대 스타포스',
  PRIMARY KEY (item_id),
  CONSTRAINT fk_equipment_item FOREIGN KEY (item_id) REFERENCES item (item_id),
  CONSTRAINT fk_equipment_set  FOREIGN KEY (set_id)  REFERENCES item_set (set_id)
) ENGINE=InnoDB COMMENT='장비 기본 능력치 (item의 하위 유형)';

CREATE TABLE inventory_item (
  inventory_item_id  BIGINT     NOT NULL AUTO_INCREMENT COMMENT '보유 아이템 번호',
  character_id       BIGINT     NOT NULL COMMENT '소유 캐릭터',
  item_id            INT        NOT NULL COMMENT '아이템',
  slot_no            INT        NOT NULL COMMENT '인벤토리 칸',
  quantity           INT        NOT NULL DEFAULT 1 COMMENT '수량',
  is_equipped        TINYINT(1) NOT NULL DEFAULT 0 COMMENT '착용 여부',
  expires_at         DATETIME   NULL COMMENT '기간제 만료일',
  PRIMARY KEY (inventory_item_id),
  CONSTRAINT fk_inventory_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_inventory_item      FOREIGN KEY (item_id)      REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='캐릭터 인벤토리';

CREATE TABLE equipment_instance (
  inventory_item_id   BIGINT      NOT NULL COMMENT '보유 장비',
  starforce           TINYINT     NOT NULL DEFAULT 0 COMMENT '스타포스 수치',
  scroll_success      TINYINT     NOT NULL DEFAULT 0 COMMENT '주문서 성공 횟수',
  scroll_remaining    TINYINT     NOT NULL DEFAULT 0 COMMENT '남은 업그레이드 횟수',
  bonus_stat_text     VARCHAR(100) NULL COMMENT '추가 옵션 (환생의 불꽃)',
  potential_grade     VARCHAR(10) NULL COMMENT '잠재능력 등급 (레어~레전드리)',
  additional_grade    VARCHAR(10) NULL COMMENT '에디셔널 잠재능력 등급',
  soul_name           VARCHAR(40) NULL COMMENT '소울 웨폰',
  PRIMARY KEY (inventory_item_id),
  CONSTRAINT fk_instance_inventory FOREIGN KEY (inventory_item_id) REFERENCES inventory_item (inventory_item_id)
) ENGINE=InnoDB COMMENT='장비 강화 상태 (개별 장비마다 다름)';

CREATE TABLE potential_option (
  option_id     INT         NOT NULL COMMENT '옵션 번호',
  option_name   VARCHAR(40) NOT NULL COMMENT '예: 보스 몬스터 공격 시 데미지 +%',
  option_grade  VARCHAR(10) NOT NULL COMMENT '레어/에픽/유니크/레전드리',
  option_value  INT         NOT NULL COMMENT '수치',
  PRIMARY KEY (option_id)
) ENGINE=InnoDB COMMENT='잠재능력 옵션 목록';

CREATE TABLE equipment_potential (
  inventory_item_id  BIGINT     NOT NULL COMMENT '보유 장비',
  potential_type     VARCHAR(10) NOT NULL COMMENT '잠재/에디셔널',
  line_no            TINYINT    NOT NULL COMMENT '옵션 줄 (1~3)',
  option_id          INT        NOT NULL COMMENT '부여된 옵션',
  PRIMARY KEY (inventory_item_id, potential_type, line_no),
  CONSTRAINT fk_potential_instance FOREIGN KEY (inventory_item_id) REFERENCES equipment_instance (inventory_item_id),
  CONSTRAINT fk_potential_option   FOREIGN KEY (option_id)         REFERENCES potential_option (option_id)
) ENGINE=InnoDB COMMENT='장비별 잠재능력 3줄';

-- ---------- 몬스터 / 보스 ----------
CREATE TABLE monster (
  monster_id     INT         NOT NULL COMMENT '몬스터 번호',
  monster_name   VARCHAR(50) NOT NULL COMMENT '몬스터 이름',
  monster_level  INT         NOT NULL COMMENT '레벨',
  max_hp         BIGINT      NOT NULL COMMENT '체력',
  exp_reward     BIGINT      NOT NULL COMMENT '처치 경험치',
  PRIMARY KEY (monster_id)
) ENGINE=InnoDB COMMENT='몬스터';

CREATE TABLE map_monster (
  map_id       INT NOT NULL COMMENT '맵',
  monster_id   INT NOT NULL COMMENT '몬스터',
  spawn_count  INT NOT NULL COMMENT '젠 수',
  PRIMARY KEY (map_id, monster_id),
  CONSTRAINT fk_map_monster_map     FOREIGN KEY (map_id)     REFERENCES game_map (map_id),
  CONSTRAINT fk_map_monster_monster FOREIGN KEY (monster_id) REFERENCES monster (monster_id)
) ENGINE=InnoDB COMMENT='맵별 출현 몬스터';

CREATE TABLE monster_drop (
  monster_id  INT          NOT NULL COMMENT '몬스터',
  item_id     INT          NOT NULL COMMENT '드롭 아이템',
  drop_rate   DECIMAL(8,5) NOT NULL COMMENT '드롭 확률(%)',
  PRIMARY KEY (monster_id, item_id),
  CONSTRAINT fk_monster_drop_monster FOREIGN KEY (monster_id) REFERENCES monster (monster_id),
  CONSTRAINT fk_monster_drop_item    FOREIGN KEY (item_id)    REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='몬스터 드롭 테이블';

CREATE TABLE boss (
  boss_id         INT         NOT NULL COMMENT '보스 번호',
  monster_id      INT         NOT NULL COMMENT '보스 몬스터',
  entry_map_id    INT         NOT NULL COMMENT '입장 맵',
  difficulty      VARCHAR(10) NOT NULL COMMENT '이지/노멀/하드/카오스/익스트림',
  entry_level     INT         NOT NULL COMMENT '입장 레벨',
  reset_period    VARCHAR(10) NOT NULL COMMENT '일간/주간/월간',
  crystal_price   BIGINT      NOT NULL COMMENT '결정석 판매가(메소)',
  max_party_size  TINYINT     NOT NULL DEFAULT 6 COMMENT '최대 파티 인원',
  PRIMARY KEY (boss_id),
  CONSTRAINT fk_boss_monster FOREIGN KEY (monster_id)   REFERENCES monster (monster_id),
  CONSTRAINT fk_boss_map     FOREIGN KEY (entry_map_id) REFERENCES game_map (map_id)
) ENGINE=InnoDB COMMENT='보스 (난이도별)';

CREATE TABLE character_boss_clear (
  clear_id      BIGINT   NOT NULL AUTO_INCREMENT COMMENT '격파 기록 번호',
  character_id  BIGINT   NOT NULL COMMENT '캐릭터',
  boss_id       INT      NOT NULL COMMENT '보스',
  party_size    TINYINT  NOT NULL DEFAULT 1 COMMENT '파티 인원',
  crystal_sold  TINYINT(1) NOT NULL DEFAULT 0 COMMENT '결정석 판매 여부',
  cleared_at    DATETIME NOT NULL COMMENT '격파 시각',
  PRIMARY KEY (clear_id),
  CONSTRAINT fk_boss_clear_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_boss_clear_boss      FOREIGN KEY (boss_id)      REFERENCES boss (boss_id)
) ENGINE=InnoDB COMMENT='보스 격파 기록 (주간 입장 제한 판정)';

-- ---------- 퀘스트 / 심볼 ----------
CREATE TABLE quest (
  quest_id        INT         NOT NULL COMMENT '퀘스트 번호',
  start_map_id    INT         NULL COMMENT '시작 맵',
  quest_name      VARCHAR(60) NOT NULL COMMENT '퀘스트 이름',
  quest_type      VARCHAR(10) NOT NULL COMMENT '메인/일일/주간/이벤트',
  required_level  INT         NOT NULL COMMENT '수락 레벨',
  reward_exp      BIGINT      NOT NULL DEFAULT 0 COMMENT '보상 경험치',
  reward_item_id  INT         NULL COMMENT '보상 아이템',
  PRIMARY KEY (quest_id),
  CONSTRAINT fk_quest_map         FOREIGN KEY (start_map_id)   REFERENCES game_map (map_id),
  CONSTRAINT fk_quest_reward_item FOREIGN KEY (reward_item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='퀘스트';

CREATE TABLE character_quest (
  character_id  BIGINT      NOT NULL COMMENT '캐릭터',
  quest_id      INT         NOT NULL COMMENT '퀘스트',
  quest_status  VARCHAR(10) NOT NULL COMMENT '진행중/완료',
  completed_at  DATETIME    NULL COMMENT '완료일',
  PRIMARY KEY (character_id, quest_id),
  CONSTRAINT fk_character_quest_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_character_quest_quest     FOREIGN KEY (quest_id)     REFERENCES quest (quest_id)
) ENGINE=InnoDB COMMENT='캐릭터 퀘스트 진행';

CREATE TABLE symbol (
  symbol_id    INT         NOT NULL COMMENT '심볼 번호',
  symbol_name  VARCHAR(40) NOT NULL COMMENT '소멸의 여로, 츄츄 아일랜드, 세르니움 등',
  symbol_type  VARCHAR(10) NOT NULL COMMENT '아케인/어센틱',
  max_level    TINYINT     NOT NULL COMMENT '최대 레벨',
  PRIMARY KEY (symbol_id)
) ENGINE=InnoDB COMMENT='심볼';

CREATE TABLE character_symbol (
  character_id  BIGINT  NOT NULL COMMENT '캐릭터',
  symbol_id     INT     NOT NULL COMMENT '심볼',
  symbol_level  TINYINT NOT NULL DEFAULT 1 COMMENT '심볼 레벨',
  growth_count  INT     NOT NULL DEFAULT 0 COMMENT '누적 성장치',
  PRIMARY KEY (character_id, symbol_id),
  CONSTRAINT fk_character_symbol_character FOREIGN KEY (character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_character_symbol_symbol    FOREIGN KEY (symbol_id)    REFERENCES symbol (symbol_id)
) ENGINE=InnoDB COMMENT='캐릭터 심볼 성장';

-- ---------- 경매장 ----------
CREATE TABLE auction_listing (
  listing_id           BIGINT      NOT NULL AUTO_INCREMENT COMMENT '경매 등록 번호',
  seller_character_id  BIGINT      NOT NULL COMMENT '판매 캐릭터',
  buyer_character_id   BIGINT      NULL COMMENT '구매 캐릭터',
  item_id              INT         NOT NULL COMMENT '판매 아이템',
  quantity             INT         NOT NULL DEFAULT 1 COMMENT '수량',
  price_meso           BIGINT      NOT NULL COMMENT '판매가(메소)',
  listing_status       VARCHAR(10) NOT NULL COMMENT '판매중/판매완료/만료',
  registered_at        DATETIME    NOT NULL COMMENT '등록일',
  expires_at           DATETIME    NOT NULL COMMENT '만료일',
  PRIMARY KEY (listing_id),
  CONSTRAINT fk_auction_seller FOREIGN KEY (seller_character_id) REFERENCES player_character (character_id),
  CONSTRAINT fk_auction_buyer  FOREIGN KEY (buyer_character_id)  REFERENCES player_character (character_id),
  CONSTRAINT fk_auction_item   FOREIGN KEY (item_id)             REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='경매장';

-- ---------- 과금 (캐시샵) ----------
CREATE TABLE payment (
  payment_id      BIGINT      NOT NULL AUTO_INCREMENT COMMENT '결제 번호',
  account_id      BIGINT      NOT NULL COMMENT '결제 계정',
  pay_method      VARCHAR(15) NOT NULL COMMENT '신용카드/휴대폰/계좌이체/상품권',
  amount_krw      INT         NOT NULL COMMENT '결제 금액(원)',
  cash_charged    INT         NOT NULL COMMENT '충전된 넥슨캐시',
  payment_status  VARCHAR(10) NOT NULL COMMENT '완료/취소/환불',
  paid_at         DATETIME    NOT NULL COMMENT '결제 시각',
  PRIMARY KEY (payment_id),
  CONSTRAINT fk_payment_account FOREIGN KEY (account_id) REFERENCES account (account_id)
) ENGINE=InnoDB COMMENT='넥슨캐시 충전 결제 내역';

CREATE TABLE cash_product (
  product_id     INT         NOT NULL COMMENT '상품 번호',
  item_id        INT         NOT NULL COMMENT '지급 아이템',
  product_name   VARCHAR(60) NOT NULL COMMENT '상품 이름',
  category       VARCHAR(15) NOT NULL COMMENT '코디/펫/강화(큐브)/편의/패키지',
  price_cash     INT         NOT NULL COMMENT '판매가(캐시)',
  valid_days     INT         NULL COMMENT '사용 기간(일), NULL은 영구',
  is_random_box  TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '확률형 아이템 여부',
  sale_start_at  DATETIME    NOT NULL COMMENT '판매 시작',
  sale_end_at    DATETIME    NULL COMMENT '판매 종료',
  PRIMARY KEY (product_id),
  CONSTRAINT fk_cash_product_item FOREIGN KEY (item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='캐시샵 상품';

CREATE TABLE cash_purchase (
  purchase_id   BIGINT      NOT NULL AUTO_INCREMENT COMMENT '구매 번호',
  account_id    BIGINT      NOT NULL COMMENT '구매 계정',
  product_id    INT         NOT NULL COMMENT '구매 상품',
  quantity      INT         NOT NULL DEFAULT 1 COMMENT '수량',
  currency_type VARCHAR(12) NOT NULL COMMENT '넥슨캐시/메이플포인트',
  amount_spent  INT         NOT NULL COMMENT '사용 금액',
  purchased_at  DATETIME    NOT NULL COMMENT '구매 시각',
  PRIMARY KEY (purchase_id),
  CONSTRAINT fk_cash_purchase_account FOREIGN KEY (account_id) REFERENCES account (account_id),
  CONSTRAINT fk_cash_purchase_product FOREIGN KEY (product_id) REFERENCES cash_product (product_id)
) ENGINE=InnoDB COMMENT='캐시샵 구매 내역';

CREATE TABLE cash_locker (
  locker_item_id  BIGINT   NOT NULL AUTO_INCREMENT COMMENT '보관함 아이템 번호',
  purchase_id     BIGINT   NOT NULL COMMENT '구매 내역',
  item_id         INT      NOT NULL COMMENT '아이템',
  character_id    BIGINT   NULL COMMENT '인벤토리로 옮긴 캐릭터 (NULL은 보관 중)',
  expires_at      DATETIME NULL COMMENT '만료일',
  PRIMARY KEY (locker_item_id),
  CONSTRAINT fk_locker_purchase  FOREIGN KEY (purchase_id)  REFERENCES cash_purchase (purchase_id),
  CONSTRAINT fk_locker_item      FOREIGN KEY (item_id)      REFERENCES item (item_id),
  CONSTRAINT fk_locker_character FOREIGN KEY (character_id) REFERENCES player_character (character_id)
) ENGINE=InnoDB COMMENT='캐시 보관함 (계정 단위, 캐릭터로 수령)';
