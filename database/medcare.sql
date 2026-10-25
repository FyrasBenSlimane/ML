-- ============================================================
--  MedCare / Doza / Sora — base de données
--  À importer dans phpMyAdmin (XAMPP) ou via la ligne de commande.
--  Les tables sont AUSSI créées automatiquement au premier usage
--  par les modèles PHP (migrations idempotentes) ; ce fichier sert
--  de référence et permet de tout créer d'un coup.
-- ============================================================

CREATE DATABASE IF NOT EXISTS `medcare`
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `medcare`;

-- Comptes : patients et personnel soignant
CREATE TABLE IF NOT EXISTS `users` (
    `id`            INT AUTO_INCREMENT PRIMARY KEY,
    `first_name`    VARCHAR(80)  NOT NULL,
    `last_name`     VARCHAR(80)  NOT NULL,
    `email`         VARCHAR(190) NOT NULL UNIQUE,
    `phone`         VARCHAR(30)  NULL,
    `password_hash` VARCHAR(255) NOT NULL,                 -- password_hash() (bcrypt)
    `role`          ENUM('patient','personnel') NOT NULL DEFAULT 'patient',
    `created_at`    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Historique des sessions Doza (une ligne = une consultation terminée)
CREATE TABLE IF NOT EXISTS `consultations` (
    `id`           INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`      INT          NULL,                      -- patient connecté (NULL pour l'ancien historique)
    `tag`          VARCHAR(50)  NOT NULL,                  -- domaine (Diabète, Cœur, …)
    `question`     VARCHAR(255) NOT NULL,
    `answer`       TEXT         NOT NULL,
    `result`       VARCHAR(50)  NOT NULL,                  -- zone de l'API : Risque plus faible / intermédiaire / élevé
    `probability`  TINYINT UNSIGNED NOT NULL,              -- confiance en % (0–100)
    `answers_json` TEXT         NULL,
    `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Migration idempotente (si la table consultations existait déjà sans user_id).
-- MariaDB (XAMPP) supporte IF NOT EXISTS :
ALTER TABLE `consultations` ADD COLUMN IF NOT EXISTS `user_id` INT NULL AFTER `id`;

-- Fiches Sora (compagnon de sortie) + résultats, liées au patient
CREATE TABLE IF NOT EXISTS `sora_fiches` (
    `id`                INT AUTO_INCREMENT PRIMARY KEY,
    `user_id`           INT NOT NULL,
    `age`               VARCHAR(10),                       -- ex. "[70-80]"
    `hosp_days`         INT,
    `medications`       INT,
    `diagnostics`       INT,
    `diagnosis`         VARCHAR(30),                       -- diag_1_group
    `glucose`           VARCHAR(15),                       -- max_glu_serum
    `antidiabetic`      VARCHAR(10),
    `insulin`           VARCHAR(10),
    `metformin`         VARCHAR(10),
    `proba_suivi`       DECIMAL(5,4),
    `resultat_suivi`    VARCHAR(30),                       -- Suivi renforcé / Suivi léger
    `proba_controle`    DECIMAL(5,4),
    `resultat_controle` VARCHAR(30),                       -- Mal contrôlé / Bien contrôlé
    `profil`            VARCHAR(120),                      -- profil combiné (recommandation)
    `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX (`user_id`),
    CONSTRAINT `fk_sora_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------
--  Protection du patient : les évaluations Doza/Sora sont réalisées PAR un
--  membre du personnel (médecin) POUR un patient. On trace les deux.
--  Migrations idempotentes (MariaDB / XAMPP supporte IF NOT EXISTS).
-- ------------------------------------------------------------
ALTER TABLE `consultations` ADD COLUMN IF NOT EXISTS `personnel_id` INT NULL AFTER `user_id`;
ALTER TABLE `sora_fiches`   ADD COLUMN IF NOT EXISTS `personnel_id` INT NULL AFTER `user_id`;

-- Alertes envoyées au patient par le médecin après une évaluation.
-- Le patient ne lit QUE ses propres alertes ; il ne voit jamais la sortie du modèle.
CREATE TABLE IF NOT EXISTS `notifications` (
    `id`         INT AUTO_INCREMENT PRIMARY KEY,
    `patient_id` INT NOT NULL,                              -- destinataire (rôle patient)
    `sender_id`  INT NULL,                                  -- médecin émetteur (rôle personnel)
    `source`     ENUM('doza','sora') NOT NULL,              -- modèle à l'origine de l'alerte
    `source_id`  INT NULL,                                  -- id de la consultation / fiche liée
    `niveau`     ENUM('info','attention','important') NOT NULL DEFAULT 'info',
    `titre`      VARCHAR(120) NOT NULL,
    `message`    TEXT NOT NULL,                             -- message rassurant, sans chiffres
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `read_at`    DATETIME NULL,
    INDEX (`patient_id`),
    INDEX (`patient_id`, `read_at`),
    CONSTRAINT `fk_notif_patient` FOREIGN KEY (`patient_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_notif_sender`  FOREIGN KEY (`sender_id`)  REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
