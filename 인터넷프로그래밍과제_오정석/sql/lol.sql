-- 리그 오브 레전드 데이터베이스 구조 (게임 내 기능 관찰 기반 추론 설계)
CREATE SCHEMA IF NOT EXISTS lol DEFAULT CHARACTER SET utf8mb4;
USE lol;

-- ---------- 계정 / 소환사 ----------
CREATE TABLE game_region (
  region_id    TINYINT     NOT NULL COMMENT '지역 번호',
  region_code  VARCHAR(5)  NOT NULL COMMENT 'KR, NA, EUW 등',
  region_name  VARCHAR(30) NOT NULL COMMENT '지역 이름',
  PRIMARY KEY (region_id),
  UNIQUE KEY uq_region_code (region_code)
) ENGINE=InnoDB COMMENT='서버 지역';

CREATE TABLE account (
  account_id      BIGINT       NOT NULL AUTO_INCREMENT COMMENT '계정 번호',
  region_id       TINYINT      NOT NULL COMMENT '지역',
  login_name      VARCHAR(50)  NOT NULL COMMENT '로그인 ID',
  riot_id_name    VARCHAR(16)  NOT NULL COMMENT 'Riot ID 이름',
  riot_id_tag     VARCHAR(5)   NOT NULL COMMENT 'Riot ID 태그 (#KR1 등)',
  email           VARCHAR(100) NOT NULL COMMENT '이메일',
  rp_balance      INT          NOT NULL DEFAULT 0 COMMENT '보유 RP (유료 재화)',
  blue_essence    INT          NOT NULL DEFAULT 0 COMMENT '보유 파랑 정수 (무료 재화)',
  orange_essence  INT          NOT NULL DEFAULT 0 COMMENT '보유 주황 정수',
  created_at      DATETIME     NOT NULL COMMENT '가입일',
  PRIMARY KEY (account_id),
  UNIQUE KEY uq_account_login (login_name),
  UNIQUE KEY uq_account_riot_id (riot_id_name, riot_id_tag),
  CONSTRAINT fk_account_region FOREIGN KEY (region_id) REFERENCES game_region (region_id)
) ENGINE=InnoDB COMMENT='라이엇 계정';

CREATE TABLE summoner (
  summoner_id      BIGINT   NOT NULL AUTO_INCREMENT COMMENT '소환사 번호',
  account_id       BIGINT   NOT NULL COMMENT '계정',
  summoner_level   INT      NOT NULL DEFAULT 1 COMMENT '소환사 레벨',
  level_exp        INT      NOT NULL DEFAULT 0 COMMENT '레벨 경험치',
  profile_icon_no  INT      NOT NULL DEFAULT 0 COMMENT '프로필 아이콘',
  honor_level      TINYINT  NOT NULL DEFAULT 2 COMMENT '명예 레벨',
  last_played_at   DATETIME NULL COMMENT '최근 게임 시각',
  PRIMARY KEY (summoner_id),
  UNIQUE KEY uq_summoner_account (account_id),
  CONSTRAINT fk_summoner_account FOREIGN KEY (account_id) REFERENCES account (account_id)
) ENGINE=InnoDB COMMENT='소환사 (게임 안 프로필, 계정과 1:1)';

CREATE TABLE friendship (
  summoner_id         BIGINT      NOT NULL COMMENT '소환사',
  friend_summoner_id  BIGINT      NOT NULL COMMENT '친구 소환사',
  friend_note         VARCHAR(50) NULL COMMENT '친구 메모',
  since_at            DATETIME    NOT NULL COMMENT '친구가 된 날',
  PRIMARY KEY (summoner_id, friend_summoner_id),
  CONSTRAINT fk_friendship_summoner FOREIGN KEY (summoner_id)        REFERENCES summoner (summoner_id),
  CONSTRAINT fk_friendship_friend   FOREIGN KEY (friend_summoner_id) REFERENCES summoner (summoner_id)
) ENGINE=InnoDB COMMENT='친구 목록';

-- ---------- 챔피언 / 스킨 ----------
CREATE TABLE champion (
  champion_id    INT         NOT NULL COMMENT '챔피언 번호',
  champion_name  VARCHAR(30) NOT NULL COMMENT '챔피언 이름',
  champion_title VARCHAR(50) NOT NULL COMMENT '칭호',
  main_role      VARCHAR(10) NOT NULL COMMENT '전사/마법사/암살자/원거리/탱커/서포터',
  resource_type  VARCHAR(10) NOT NULL COMMENT '마나/기력/없음',
  price_be       INT         NOT NULL COMMENT '파랑 정수 가격',
  price_rp       INT         NOT NULL COMMENT 'RP 가격',
  released_at    DATE        NOT NULL COMMENT '출시일',
  PRIMARY KEY (champion_id)
) ENGINE=InnoDB COMMENT='챔피언';

CREATE TABLE champion_ability (
  ability_id    INT         NOT NULL COMMENT '스킬 번호',
  champion_id   INT         NOT NULL COMMENT '챔피언',
  slot_key      CHAR(1)     NOT NULL COMMENT 'P/Q/W/E/R',
  ability_name  VARCHAR(50) NOT NULL COMMENT '스킬 이름',
  max_rank      TINYINT     NOT NULL COMMENT '최대 레벨',
  cooldown_sec  DECIMAL(5,1) NULL COMMENT '재사용 대기시간(1레벨)',
  PRIMARY KEY (ability_id),
  UNIQUE KEY uq_ability_slot (champion_id, slot_key),
  CONSTRAINT fk_ability_champion FOREIGN KEY (champion_id) REFERENCES champion (champion_id)
) ENGINE=InnoDB COMMENT='챔피언 스킬';

CREATE TABLE skin (
  skin_id      INT         NOT NULL COMMENT '스킨 번호',
  champion_id  INT         NOT NULL COMMENT '챔피언',
  skin_name    VARCHAR(60) NOT NULL COMMENT '스킨 이름',
  skin_tier    VARCHAR(10) NOT NULL COMMENT '일반/서사/전설/초월',
  price_rp     INT         NULL COMMENT 'RP 가격 (NULL은 상점 미판매)',
  is_limited   TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '한정 스킨 여부',
  PRIMARY KEY (skin_id),
  CONSTRAINT fk_skin_champion FOREIGN KEY (champion_id) REFERENCES champion (champion_id)
) ENGINE=InnoDB COMMENT='스킨';

CREATE TABLE summoner_champion (
  summoner_id     BIGINT   NOT NULL COMMENT '소환사',
  champion_id     INT      NOT NULL COMMENT '보유 챔피언',
  mastery_level   INT      NOT NULL DEFAULT 0 COMMENT '숙련도 레벨',
  mastery_points  INT      NOT NULL DEFAULT 0 COMMENT '숙련도 점수',
  acquired_at     DATETIME NOT NULL COMMENT '획득일',
  PRIMARY KEY (summoner_id, champion_id),
  CONSTRAINT fk_summoner_champion_summoner FOREIGN KEY (summoner_id) REFERENCES summoner (summoner_id),
  CONSTRAINT fk_summoner_champion_champion FOREIGN KEY (champion_id) REFERENCES champion (champion_id)
) ENGINE=InnoDB COMMENT='보유 챔피언과 숙련도';

CREATE TABLE summoner_skin (
  summoner_id   BIGINT      NOT NULL COMMENT '소환사',
  skin_id       INT         NOT NULL COMMENT '보유 스킨',
  acquire_type  VARCHAR(10) NOT NULL COMMENT '구매/전리품/선물/이벤트',
  acquired_at   DATETIME    NOT NULL COMMENT '획득일',
  PRIMARY KEY (summoner_id, skin_id),
  CONSTRAINT fk_summoner_skin_summoner FOREIGN KEY (summoner_id) REFERENCES summoner (summoner_id),
  CONSTRAINT fk_summoner_skin_skin     FOREIGN KEY (skin_id)     REFERENCES skin (skin_id)
) ENGINE=InnoDB COMMENT='보유 스킨';

-- ---------- 아이템 / 룬 / 소환사 주문 ----------
CREATE TABLE item (
  item_id      INT          NOT NULL COMMENT '아이템 번호',
  item_name    VARCHAR(50)  NOT NULL COMMENT '아이템 이름',
  item_grade   VARCHAR(10)  NOT NULL COMMENT '시작/기본/서사/전설/장화',
  gold_cost    INT          NOT NULL COMMENT '총 가격(골드)',
  stat_text    VARCHAR(200) NULL COMMENT '능력치',
  PRIMARY KEY (item_id)
) ENGINE=InnoDB COMMENT='게임 안 상점 아이템';

CREATE TABLE item_recipe (
  item_id            INT     NOT NULL COMMENT '완성 아이템',
  component_item_id  INT     NOT NULL COMMENT '재료 아이템',
  quantity           TINYINT NOT NULL DEFAULT 1 COMMENT '필요 수량',
  PRIMARY KEY (item_id, component_item_id),
  CONSTRAINT fk_recipe_item      FOREIGN KEY (item_id)           REFERENCES item (item_id),
  CONSTRAINT fk_recipe_component FOREIGN KEY (component_item_id) REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='아이템 조합식';

CREATE TABLE rune_path (
  path_id    INT         NOT NULL COMMENT '룬 빌드 번호',
  path_name  VARCHAR(10) NOT NULL COMMENT '정밀/지배/마법/결의/영감',
  PRIMARY KEY (path_id)
) ENGINE=InnoDB COMMENT='룬 빌드';

CREATE TABLE rune (
  rune_id      INT         NOT NULL COMMENT '룬 번호',
  path_id      INT         NOT NULL COMMENT '룬 빌드',
  rune_name    VARCHAR(30) NOT NULL COMMENT '룬 이름',
  row_no       TINYINT     NOT NULL COMMENT '줄 번호 (0은 핵심 룬)',
  is_keystone  TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '핵심 룬 여부',
  PRIMARY KEY (rune_id),
  CONSTRAINT fk_rune_path FOREIGN KEY (path_id) REFERENCES rune_path (path_id)
) ENGINE=InnoDB COMMENT='룬';

CREATE TABLE rune_page (
  page_id            BIGINT      NOT NULL AUTO_INCREMENT COMMENT '룬 페이지 번호',
  summoner_id        BIGINT      NOT NULL COMMENT '소환사',
  primary_path_id    INT         NOT NULL COMMENT '주 룬 빌드',
  secondary_path_id  INT         NOT NULL COMMENT '보조 룬 빌드',
  page_name          VARCHAR(30) NOT NULL COMMENT '페이지 이름',
  PRIMARY KEY (page_id),
  CONSTRAINT fk_rune_page_summoner  FOREIGN KEY (summoner_id)       REFERENCES summoner (summoner_id),
  CONSTRAINT fk_rune_page_primary   FOREIGN KEY (primary_path_id)   REFERENCES rune_path (path_id),
  CONSTRAINT fk_rune_page_secondary FOREIGN KEY (secondary_path_id) REFERENCES rune_path (path_id)
) ENGINE=InnoDB COMMENT='소환사가 저장한 룬 페이지';

CREATE TABLE rune_page_rune (
  page_id  BIGINT NOT NULL COMMENT '룬 페이지',
  rune_id  INT    NOT NULL COMMENT '선택한 룬',
  PRIMARY KEY (page_id, rune_id),
  CONSTRAINT fk_page_rune_page FOREIGN KEY (page_id) REFERENCES rune_page (page_id),
  CONSTRAINT fk_page_rune_rune FOREIGN KEY (rune_id) REFERENCES rune (rune_id)
) ENGINE=InnoDB COMMENT='룬 페이지에 넣은 룬';

CREATE TABLE summoner_spell (
  spell_id        INT         NOT NULL COMMENT '소환사 주문 번호',
  spell_name      VARCHAR(20) NOT NULL COMMENT '점멸, 점화, 강타 등',
  cooldown_sec    INT         NOT NULL COMMENT '재사용 대기시간(초)',
  required_level  INT         NOT NULL DEFAULT 1 COMMENT '사용 가능 소환사 레벨',
  PRIMARY KEY (spell_id)
) ENGINE=InnoDB COMMENT='소환사 주문';

-- ---------- 게임(매치) 기록 ----------
CREATE TABLE game_queue (
  queue_id    INT         NOT NULL COMMENT '큐 번호',
  queue_name  VARCHAR(30) NOT NULL COMMENT '솔로랭크/자유랭크/일반/칼바람 나락',
  map_name    VARCHAR(30) NOT NULL COMMENT '소환사의 협곡/칼바람 나락',
  is_ranked   TINYINT(1)  NOT NULL DEFAULT 0 COMMENT '랭크 게임 여부',
  PRIMARY KEY (queue_id)
) ENGINE=InnoDB COMMENT='게임 모드';

CREATE TABLE season (
  season_id    INT         NOT NULL COMMENT '시즌 번호',
  season_name  VARCHAR(30) NOT NULL COMMENT '시즌 이름',
  start_date   DATE        NOT NULL COMMENT '시작일',
  end_date     DATE        NULL COMMENT '종료일',
  PRIMARY KEY (season_id)
) ENGINE=InnoDB COMMENT='시즌';

CREATE TABLE game_match (
  match_id      BIGINT      NOT NULL AUTO_INCREMENT COMMENT '게임 번호',
  queue_id      INT         NOT NULL COMMENT '게임 모드',
  season_id     INT         NOT NULL COMMENT '시즌',
  game_version  VARCHAR(10) NOT NULL COMMENT '패치 버전',
  started_at    DATETIME    NOT NULL COMMENT '시작 시각',
  duration_sec  INT         NOT NULL COMMENT '게임 시간(초)',
  PRIMARY KEY (match_id),
  CONSTRAINT fk_match_queue  FOREIGN KEY (queue_id)  REFERENCES game_queue (queue_id),
  CONSTRAINT fk_match_season FOREIGN KEY (season_id) REFERENCES season (season_id)
) ENGINE=InnoDB COMMENT='게임 한 판';

CREATE TABLE match_team (
  match_id       BIGINT     NOT NULL COMMENT '게임',
  team_side      VARCHAR(4) NOT NULL COMMENT 'BLUE/RED',
  is_win         TINYINT(1) NOT NULL COMMENT '승리 여부',
  tower_kills    TINYINT    NOT NULL DEFAULT 0 COMMENT '포탑 파괴 수',
  dragon_kills   TINYINT    NOT NULL DEFAULT 0 COMMENT '드래곤 처치 수',
  baron_kills    TINYINT    NOT NULL DEFAULT 0 COMMENT '바론 처치 수',
  PRIMARY KEY (match_id, team_side),
  CONSTRAINT fk_team_match FOREIGN KEY (match_id) REFERENCES game_match (match_id)
) ENGINE=InnoDB COMMENT='게임의 팀 결과';

CREATE TABLE match_ban (
  match_id     BIGINT     NOT NULL COMMENT '게임',
  team_side    VARCHAR(4) NOT NULL COMMENT '금지한 팀',
  ban_turn     TINYINT    NOT NULL COMMENT '금지 순서 (1~5)',
  champion_id  INT        NOT NULL COMMENT '금지한 챔피언',
  PRIMARY KEY (match_id, team_side, ban_turn),
  CONSTRAINT fk_ban_team     FOREIGN KEY (match_id, team_side) REFERENCES match_team (match_id, team_side),
  CONSTRAINT fk_ban_champion FOREIGN KEY (champion_id)         REFERENCES champion (champion_id)
) ENGINE=InnoDB COMMENT='챔피언 금지(밴)';

CREATE TABLE match_participant (
  participant_id    BIGINT      NOT NULL AUTO_INCREMENT COMMENT '참가 기록 번호',
  match_id          BIGINT      NOT NULL COMMENT '게임',
  team_side         VARCHAR(4)  NOT NULL COMMENT '소속 팀',
  summoner_id       BIGINT      NOT NULL COMMENT '소환사',
  champion_id       INT         NOT NULL COMMENT '고른 챔피언',
  skin_id           INT         NULL COMMENT '사용한 스킨',
  spell1_id         INT         NOT NULL COMMENT '소환사 주문 D',
  spell2_id         INT         NOT NULL COMMENT '소환사 주문 F',
  keystone_rune_id  INT         NOT NULL COMMENT '핵심 룬',
  lane_position     VARCHAR(8)  NOT NULL COMMENT '탑/정글/미드/원딜/서폿',
  champion_level    TINYINT     NOT NULL COMMENT '종료 시 챔피언 레벨',
  kills             SMALLINT    NOT NULL DEFAULT 0 COMMENT '킬',
  deaths            SMALLINT    NOT NULL DEFAULT 0 COMMENT '데스',
  assists           SMALLINT    NOT NULL DEFAULT 0 COMMENT '어시스트',
  minion_kills      SMALLINT    NOT NULL DEFAULT 0 COMMENT 'CS',
  gold_earned       INT         NOT NULL DEFAULT 0 COMMENT '획득 골드',
  damage_dealt      INT         NOT NULL DEFAULT 0 COMMENT '챔피언에게 가한 피해량',
  vision_score      SMALLINT    NOT NULL DEFAULT 0 COMMENT '시야 점수',
  PRIMARY KEY (participant_id),
  UNIQUE KEY uq_participant (match_id, summoner_id),
  CONSTRAINT fk_participant_team     FOREIGN KEY (match_id, team_side) REFERENCES match_team (match_id, team_side),
  CONSTRAINT fk_participant_summoner FOREIGN KEY (summoner_id)         REFERENCES summoner (summoner_id),
  CONSTRAINT fk_participant_champion FOREIGN KEY (champion_id)         REFERENCES champion (champion_id),
  CONSTRAINT fk_participant_skin     FOREIGN KEY (skin_id)             REFERENCES skin (skin_id),
  CONSTRAINT fk_participant_spell1   FOREIGN KEY (spell1_id)           REFERENCES summoner_spell (spell_id),
  CONSTRAINT fk_participant_spell2   FOREIGN KEY (spell2_id)           REFERENCES summoner_spell (spell_id),
  CONSTRAINT fk_participant_rune     FOREIGN KEY (keystone_rune_id)    REFERENCES rune (rune_id)
) ENGINE=InnoDB COMMENT='게임 참가자 10명의 기록 (전적)';

CREATE TABLE participant_item (
  participant_id  BIGINT  NOT NULL COMMENT '참가 기록',
  slot_no         TINYINT NOT NULL COMMENT '아이템 칸 (0~6)',
  item_id         INT     NOT NULL COMMENT '종료 시 가진 아이템',
  PRIMARY KEY (participant_id, slot_no),
  CONSTRAINT fk_participant_item_participant FOREIGN KEY (participant_id) REFERENCES match_participant (participant_id),
  CONSTRAINT fk_participant_item_item        FOREIGN KEY (item_id)        REFERENCES item (item_id)
) ENGINE=InnoDB COMMENT='참가자의 최종 아이템';

-- ---------- 랭크 ----------
CREATE TABLE ranked_tier (
  tier_id     TINYINT     NOT NULL COMMENT '티어 번호',
  tier_name   VARCHAR(15) NOT NULL COMMENT '아이언~챌린저',
  tier_order  TINYINT     NOT NULL COMMENT '순서',
  PRIMARY KEY (tier_id)
) ENGINE=InnoDB COMMENT='랭크 티어';

CREATE TABLE ranked_entry (
  summoner_id    BIGINT  NOT NULL COMMENT '소환사',
  queue_id       INT     NOT NULL COMMENT '랭크 종류 (솔로/자유)',
  season_id      INT     NOT NULL COMMENT '시즌',
  tier_id        TINYINT NOT NULL COMMENT '티어',
  division       TINYINT NOT NULL COMMENT '단계 (4~1)',
  league_points  INT     NOT NULL DEFAULT 0 COMMENT 'LP',
  wins           INT     NOT NULL DEFAULT 0 COMMENT '승',
  losses         INT     NOT NULL DEFAULT 0 COMMENT '패',
  PRIMARY KEY (summoner_id, queue_id, season_id),
  CONSTRAINT fk_ranked_summoner FOREIGN KEY (summoner_id) REFERENCES summoner (summoner_id),
  CONSTRAINT fk_ranked_queue    FOREIGN KEY (queue_id)    REFERENCES game_queue (queue_id),
  CONSTRAINT fk_ranked_season   FOREIGN KEY (season_id)   REFERENCES season (season_id),
  CONSTRAINT fk_ranked_tier     FOREIGN KEY (tier_id)     REFERENCES ranked_tier (tier_id)
) ENGINE=InnoDB COMMENT='시즌별 랭크 정보';

-- ---------- 과금 (상점) ----------
CREATE TABLE payment (
  payment_id      BIGINT      NOT NULL AUTO_INCREMENT COMMENT '결제 번호',
  account_id      BIGINT      NOT NULL COMMENT '결제 계정',
  pay_method      VARCHAR(15) NOT NULL COMMENT '신용카드/휴대폰/선불카드',
  amount_krw      INT         NOT NULL COMMENT '결제 금액(원)',
  rp_charged      INT         NOT NULL COMMENT '충전된 RP',
  payment_status  VARCHAR(10) NOT NULL COMMENT '완료/취소/환불',
  paid_at         DATETIME    NOT NULL COMMENT '결제 시각',
  PRIMARY KEY (payment_id),
  CONSTRAINT fk_payment_account FOREIGN KEY (account_id) REFERENCES account (account_id)
) ENGINE=InnoDB COMMENT='RP 충전 결제 내역';

CREATE TABLE store_product (
  product_id    INT         NOT NULL COMMENT '상품 번호',
  champion_id   INT         NULL COMMENT '챔피언 상품일 때',
  skin_id       INT         NULL COMMENT '스킨 상품일 때',
  product_type  VARCHAR(10) NOT NULL COMMENT '챔피언/스킨/패스/상자/묶음',
  product_name  VARCHAR(60) NOT NULL COMMENT '상품 이름',
  price_rp      INT         NULL COMMENT 'RP 가격',
  price_be      INT         NULL COMMENT '파랑 정수 가격',
  sale_end_at   DATETIME    NULL COMMENT '판매 종료 (기간 한정)',
  PRIMARY KEY (product_id),
  CONSTRAINT fk_product_champion FOREIGN KEY (champion_id) REFERENCES champion (champion_id),
  CONSTRAINT fk_product_skin     FOREIGN KEY (skin_id)     REFERENCES skin (skin_id)
) ENGINE=InnoDB COMMENT='상점 상품';

CREATE TABLE store_purchase (
  purchase_id          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '구매 번호',
  account_id           BIGINT      NOT NULL COMMENT '구매 계정',
  product_id           INT         NOT NULL COMMENT '구매 상품',
  gift_to_summoner_id  BIGINT      NULL COMMENT '선물 받은 소환사',
  currency_type        VARCHAR(5)  NOT NULL COMMENT 'RP/BE',
  amount_spent         INT         NOT NULL COMMENT '사용 금액',
  purchased_at         DATETIME    NOT NULL COMMENT '구매 시각',
  PRIMARY KEY (purchase_id),
  CONSTRAINT fk_purchase_account FOREIGN KEY (account_id)          REFERENCES account (account_id),
  CONSTRAINT fk_purchase_product FOREIGN KEY (product_id)          REFERENCES store_product (product_id),
  CONSTRAINT fk_purchase_gift    FOREIGN KEY (gift_to_summoner_id) REFERENCES summoner (summoner_id)
) ENGINE=InnoDB COMMENT='상점 구매 내역';

CREATE TABLE loot_item (
  loot_id      BIGINT      NOT NULL AUTO_INCREMENT COMMENT '전리품 번호',
  summoner_id  BIGINT      NOT NULL COMMENT '소환사',
  skin_id      INT         NULL COMMENT '스킨 파편일 때',
  champion_id  INT         NULL COMMENT '챔피언 파편일 때',
  loot_type    VARCHAR(10) NOT NULL COMMENT '상자/열쇠/스킨 파편/챔피언 파편',
  quantity     INT         NOT NULL DEFAULT 1 COMMENT '수량',
  PRIMARY KEY (loot_id),
  CONSTRAINT fk_loot_summoner FOREIGN KEY (summoner_id) REFERENCES summoner (summoner_id),
  CONSTRAINT fk_loot_skin     FOREIGN KEY (skin_id)     REFERENCES skin (skin_id),
  CONSTRAINT fk_loot_champion FOREIGN KEY (champion_id) REFERENCES champion (champion_id)
) ENGINE=InnoDB COMMENT='마법공학 전리품 (상자, 파편)';
