-- ============================================================
--  MedCare / Doza — base de données
--  À importer dans phpMyAdmin (XAMPP) ou via la ligne de commande.
--  La table `consultations` est aussi créée automatiquement au
--  premier usage par le modèle PHP ; ce fichier sert de référence
--  et permet de créer la base d'un coup.
-- ============================================================

CREATE DATABASE IF NOT EXISTS `medcare`
    DEFAULT CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `medcare`;

-- Historique des sessions Doza (une ligne = une consultation terminée)
CREATE TABLE IF NOT EXISTS `consultations` (
    `id`           INT AUTO_INCREMENT PRIMARY KEY,
    `tag`          VARCHAR(50)  NOT NULL,                 -- domaine (Diabète, Cœur, …)
    `question`     VARCHAR(255) NOT NULL,                 -- question posée par le patient
    `answer`       TEXT         NOT NULL,                 -- réponse du modèle Doza
    `result`       VARCHAR(50)  NOT NULL,                 -- Réajustement probable / À surveiller / Dose stable
    `probability`  TINYINT UNSIGNED NOT NULL,             -- confiance en % (0–100)
    `answers_json` TEXT         NULL,                     -- réponses brutes collectées (JSON)
    `created_at`   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
