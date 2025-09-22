-- MySQL 8.x
-- 세션 기본 설정(선택)
SET NAMES utf8mb4;
SET time_zone = '+09:00';

-- =========================================================
-- Users & Auth
-- =========================================================
CREATE TABLE Users (
                     user_id           INT AUTO_INCREMENT PRIMARY KEY,
                     email             VARCHAR(100) NOT NULL UNIQUE,
                     password          VARCHAR(255) NULL COMMENT '소셜 로그인 시 NULL 가능',
                     name              VARCHAR(50)  NOT NULL,
                     phone             VARCHAR(20)  NULL,
                     job               VARCHAR(30)  NULL,
                     introduce         VARCHAR(300) NULL, -- Introduce -> introduce (소문자 시작)
                     profile_image     VARCHAR(255) NULL,
                     login_type        ENUM('email','google') NOT NULL DEFAULT 'email',
                     is_email_verified BOOLEAN NOT NULL DEFAULT FALSE,
                     is_phone_verified BOOLEAN NOT NULL DEFAULT FALSE,
                     terms_agreed      BOOLEAN NOT NULL,
                     status            ENUM('active','suspended','deleted') NOT NULL DEFAULT 'active',
                     created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                     updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                     role              ENUM('user','admin') NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Email_Verifications (
                                   verification_id INT AUTO_INCREMENT PRIMARY KEY,
                                   user_id         INT NOT NULL,
                                   email           VARCHAR(100) NOT NULL,
                                   token           VARCHAR(255) NOT NULL UNIQUE,
                                   expires_at      TIMESTAMP NOT NULL,
                                   is_used         BOOLEAN NOT NULL DEFAULT FALSE,
                                   created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   used_at         TIMESTAMP NULL,
                                   CONSTRAINT fk_email_verifications_user
                                     FOREIGN KEY (user_id) REFERENCES Users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Password_Resets (
                               reset_id    INT AUTO_INCREMENT PRIMARY KEY,
                               user_id     INT NOT NULL,
                               reset_token VARCHAR(255) NOT NULL,
                               expires_at  TIMESTAMP NOT NULL,
                               is_used     BOOLEAN NOT NULL DEFAULT FALSE,
                               created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               CONSTRAINT fk_password_resets_user
                                 FOREIGN KEY (user_id) REFERENCES Users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- Taxonomy
-- =========================================================
CREATE TABLE Categories (
                          category_id INT AUTO_INCREMENT PRIMARY KEY,
                          name        VARCHAR(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- Spaces
-- =========================================================
CREATE TABLE Spaces (
                      space_id       INT AUTO_INCREMENT PRIMARY KEY,
                      host_id        INT NOT NULL,
                      category_id    INT NOT NULL,
                      space_name     VARCHAR(100) NOT NULL,
                      description    TEXT NOT NULL,
                      notice         VARCHAR(500) NULL,
                      address        VARCHAR(200) NOT NULL,
                      max_capacity   INT NOT NULL,
                      min_capacity   INT NOT NULL DEFAULT 1,
                      price_per_hour INT NOT NULL,
                      main_image     VARCHAR(255) NOT NULL,
                      status         ENUM('active','inactive','suspended','deleted') NOT NULL DEFAULT 'active',
                      created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                      updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                      CONSTRAINT fk_spaces_host
                        FOREIGN KEY (host_id) REFERENCES Users(user_id),
                      CONSTRAINT fk_spaces_category
                        FOREIGN KEY (category_id) REFERENCES Categories(category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Space_Images (
                            image_id    INT AUTO_INCREMENT PRIMARY KEY,
                            space_id    INT NOT NULL,
                            image_url   VARCHAR(255) NOT NULL,
                            description VARCHAR(500) NULL,
                            sort_order  INT NOT NULL DEFAULT 0,
                            created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            CONSTRAINT fk_space_images_space
                              FOREIGN KEY (space_id) REFERENCES Spaces(space_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Tags (
                    tag_id       INT AUTO_INCREMENT PRIMARY KEY,
                    tag_name     VARCHAR(50) NOT NULL,
                    tag_category ENUM('수용인원','넓이') NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 소문자 시작 테이블명 → 대문자로 시작 (space_tags → Space_Tags)
CREATE TABLE Space_Tags (
                          space_id INT NOT NULL,
                          tag_id   INT NOT NULL,
                          PRIMARY KEY (space_id, tag_id),
                          CONSTRAINT fk_space_tags_space
                            FOREIGN KEY (space_id) REFERENCES Spaces(space_id),
                          CONSTRAINT fk_space_tags_tag
                            FOREIGN KEY (tag_id) REFERENCES Tags(tag_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Space_Operating_Hours (
                                     hours_id    INT AUTO_INCREMENT PRIMARY KEY,
                                     space_id    INT NOT NULL,
                                     day_of_week ENUM('monday','tuesday','wednesday','thursday','friday','saturday','sunday') NOT NULL,
                                     start_time  TIME NOT NULL,
                                     end_time    TIME NOT NULL,
                                     created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     CONSTRAINT fk_space_hours_space
                                       FOREIGN KEY (space_id) REFERENCES Spaces(space_id),
                                     UNIQUE KEY unique_space_day_time (space_id, day_of_week, start_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- Reservations & Payments
-- =========================================================
CREATE TABLE Reservations (
                            reservation_id   INT AUTO_INCREMENT PRIMARY KEY,
                            space_id         INT NOT NULL,
                            guest_id         INT NOT NULL,
                            host_id          INT NOT NULL,
                            reservation_date DATE NOT NULL,
                            start_time       TIME NOT NULL,
                            end_time         TIME NOT NULL,
                            guest_count      INT NOT NULL,
                            total_price      INT NOT NULL,
                            platform_fee     INT NOT NULL COMMENT '플랫폼 수수료 8%',
                            host_amount      INT NOT NULL COMMENT '호스트 수령액',
                            status           ENUM('pending','approved','rejected','confirmed','completed','cancelled') NOT NULL DEFAULT 'pending',
                            guest_message    VARCHAR(500) NULL,
                            responded_at     TIMESTAMP NULL,
                            created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            updated_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                            CONSTRAINT fk_reservations_space
                              FOREIGN KEY (space_id) REFERENCES Spaces(space_id),
                            CONSTRAINT fk_reservations_guest
                              FOREIGN KEY (guest_id) REFERENCES Users(user_id),
                            CONSTRAINT fk_reservations_host
                              FOREIGN KEY (host_id)  REFERENCES Users(user_id),
                            UNIQUE KEY unique_space_datetime (space_id, reservation_date, start_time, end_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Payments (
                        payment_id        INT AUTO_INCREMENT PRIMARY KEY,
                        reservation_id    INT NOT NULL,
                        amount            INT NOT NULL,
                        payment_method    ENUM('card','bank_transfer') NOT NULL,
                        payment_status    ENUM('pending','completed','failed','cancelled','refunded') NOT NULL DEFAULT 'pending',
                        pg_transaction_id VARCHAR(100) NULL COMMENT 'PG사 거래번호',
                        paid_at           TIMESTAMP NULL,
                        refunded_at       TIMESTAMP NULL,
                        refund_amount     INT NOT NULL DEFAULT 0,
                        refund_reason     TEXT NULL,
                        created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                        CONSTRAINT fk_payments_reservation
                          FOREIGN KEY (reservation_id) REFERENCES Reservations(reservation_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Payment_Cards (
                             card_id     INT AUTO_INCREMENT PRIMARY KEY,
                             user_id     INT NOT NULL,
                             card_token  VARCHAR(255) NOT NULL UNIQUE,
                             brand       VARCHAR(50) NULL,
                             last4       VARCHAR(4)  NOT NULL,
                             exp_month   INT NOT NULL,
                             exp_year    INT NOT NULL,
                             is_default  BOOLEAN NOT NULL DEFAULT FALSE,
                             created_at  TIMESTAMP NOT NULL,
                             updated_at  TIMESTAMP NOT NULL,
                             CONSTRAINT fk_payment_cards_user
                               FOREIGN KEY (user_id) REFERENCES Users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- Settlements
-- =========================================================
CREATE TABLE Host_Settlements (
                                settlement_id      INT AUTO_INCREMENT PRIMARY KEY,
                                host_id            INT NOT NULL,
                                settlement_month   DATE NOT NULL COMMENT 'YYYY-MM-01 형식',
                                total_reservations INT NOT NULL DEFAULT 0,
                                total_amount       INT NOT NULL DEFAULT 0 COMMENT '정산 대상 금액',
                                platform_fee       INT NOT NULL DEFAULT 0 COMMENT '플랫폼 수수료',
                                settlement_amount  INT NOT NULL DEFAULT 0 COMMENT '실제 정산 금액',
                                status             ENUM('pending','processing','completed') NOT NULL DEFAULT 'pending',
                                bank_name          VARCHAR(50) NULL,
                                account_number     VARCHAR(50) NULL,
                                account_holder     VARCHAR(50) NULL,
                                processed_at       TIMESTAMP NULL,
                                created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                CONSTRAINT fk_settlements_host
                                  FOREIGN KEY (host_id) REFERENCES Users(user_id),
                                UNIQUE KEY unique_host_month (host_id, settlement_month)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- Reviews
-- =========================================================
CREATE TABLE Reviews (
                       review_id      INT AUTO_INCREMENT PRIMARY KEY,
                       reservation_id INT NOT NULL,
                       reviewer_id    INT NOT NULL,
                       space_id       INT NOT NULL,
                       rating         INT NOT NULL,
                       comment        VARCHAR(500) NULL,
                       status         ENUM('active','deleted') NOT NULL DEFAULT 'active',
                       created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                       CONSTRAINT fk_reviews_reservation
                         FOREIGN KEY (reservation_id) REFERENCES Reservations(reservation_id),
                       CONSTRAINT fk_reviews_reviewer
                         FOREIGN KEY (reviewer_id) REFERENCES Users(user_id),
                       CONSTRAINT fk_reviews_space
                         FOREIGN KEY (space_id) REFERENCES Spaces(space_id),
                       UNIQUE KEY unique_reservation_review (reservation_id),
                       CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Review_Images (
                             image_id   INT AUTO_INCREMENT PRIMARY KEY,
                             review_id  INT NOT NULL,
                             image_url  VARCHAR(255) NOT NULL COMMENT '이미지 경로(URL)',
                             sort_order INT NOT NULL COMMENT '1이면 대표 이미지, 이후는 순서대로',
                             created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                             CONSTRAINT fk_review_images_review
                               FOREIGN KEY (review_id) REFERENCES Reviews(review_id),
                             UNIQUE KEY uq_review_sort (review_id, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- Q&A (Host ↔ Guest)
-- =========================================================
CREATE TABLE Questions (
                         question_id    INT AUTO_INCREMENT PRIMARY KEY,
                         space_id       INT NOT NULL,
                         questioner_id  INT NOT NULL,
                         title          VARCHAR(200) NOT NULL,
                         content        VARCHAR(500) NOT NULL, -- DBML의 text(500)를 VARCHAR(500)으로 매핑
                         content_secret ENUM('active','deleted') NOT NULL DEFAULT 'active',
                         created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                         updated_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                         CONSTRAINT fk_questions_space
                           FOREIGN KEY (space_id) REFERENCES Spaces(space_id),
                         CONSTRAINT fk_questions_user
                           FOREIGN KEY (questioner_id) REFERENCES Users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Answers (
                       answer_id     INT AUTO_INCREMENT PRIMARY KEY,
                       question_id   INT NOT NULL,
                       answerer_id   INT NOT NULL,
                       content       TEXT NOT NULL,
                       content_secret ENUM('active','deleted') NOT NULL DEFAULT 'active',
                       created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                       updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                       CONSTRAINT fk_answers_question
                         FOREIGN KEY (question_id) REFERENCES Questions(question_id),
                       CONSTRAINT fk_answers_user
                         FOREIGN KEY (answerer_id) REFERENCES Users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- Helpdesk Q&A (Admin ↔ Any User)
-- =========================================================
CREATE TABLE Helpdesk_Questions (
                                  helpdesk_question_id INT AUTO_INCREMENT PRIMARY KEY,
                                  asker_id             INT NOT NULL,
                                  title                VARCHAR(200) NOT NULL,
                                  content              VARCHAR(500) NOT NULL, -- DBML의 text(500) → VARCHAR(500)
                                  content_secret       ENUM('active','deleted') NOT NULL DEFAULT 'active',
                                  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                  CONSTRAINT fk_helpdesk_questions_user
                                    FOREIGN KEY (asker_id) REFERENCES Users(user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Helpdesk_Answers (
                                helpdesk_answer_id   INT AUTO_INCREMENT PRIMARY KEY,
                                helpdesk_question_id INT NOT NULL,
                                responder_id         INT NOT NULL,
                                content              TEXT NOT NULL,
                                content_secret       ENUM('active','deleted') NOT NULL DEFAULT 'active',
                                created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                                CONSTRAINT fk_helpdesk_answers_question
                                  FOREIGN KEY (helpdesk_question_id) REFERENCES Helpdesk_Questions(helpdesk_question_id),
                                CONSTRAINT fk_helpdesk_answers_user
                                  FOREIGN KEY (responder_id) REFERENCES Users(user_id)
  -- 질문당 공식 답변 1개 강제 필요 시:
  -- , UNIQUE KEY uq_helpdesk_official_answer (helpdesk_question_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- Bookmarks
-- =========================================================
CREATE TABLE Bookmarks (
                         bookmark_id INT AUTO_INCREMENT PRIMARY KEY,
                         user_id     INT NOT NULL,
                         space_id    INT NOT NULL,
                         created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                         CONSTRAINT fk_bookmarks_user
                           FOREIGN KEY (user_id) REFERENCES Users(user_id),
                         CONSTRAINT fk_bookmarks_space
                           FOREIGN KEY (space_id) REFERENCES Spaces(space_id),
                         UNIQUE KEY unique_user_space (user_id, space_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- Notifications
-- =========================================================
CREATE TABLE Notifications (
                             notification_id INT AUTO_INCREMENT PRIMARY KEY,
                             user_id         INT NOT NULL COMMENT '알림 수신자',
                             type            ENUM(
                      'reservation_created',
                      'reservation_approved',
                      'reservation_rejected',
                      'qna_question_created',
                      'qna_answer_created',
                      'qna_answer_admin'
                    ) NOT NULL,
                             reservation_id  INT NULL,
                             question_id     INT NULL,
                             answer_id       INT NULL,
                             admin_answer_id INT NULL COMMENT '헬프데스크 관리자 답변 전용 참조',
                             is_read         BOOLEAN NOT NULL DEFAULT FALSE,
                             status          ENUM('active','deleted') NOT NULL DEFAULT 'active',
                             created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             expires_at      TIMESTAMP NULL COMMENT '만료일 (예: 30일 후)',
                             CONSTRAINT fk_notifications_user
                               FOREIGN KEY (user_id) REFERENCES Users(user_id),
                             CONSTRAINT fk_notifications_reservation
                               FOREIGN KEY (reservation_id) REFERENCES Reservations(reservation_id),
                             CONSTRAINT fk_notifications_question
                               FOREIGN KEY (question_id) REFERENCES Questions(question_id),
                             CONSTRAINT fk_notifications_answer
                               FOREIGN KEY (answer_id) REFERENCES Answers(answer_id),
                             CONSTRAINT fk_notifications_admin_answer
                               FOREIGN KEY (admin_answer_id) REFERENCES Helpdesk_Answers(helpdesk_answer_id),
                             KEY idx_notifications_user_inbox (user_id, status, is_read, created_at),
                             KEY idx_notifications_admin_answer (admin_answer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
