<?php
/**
 * Modèle « SoraFiche » : une fiche Sora remplie par un patient + ses résultats
 * (modèles M1 Suivi et M2 Contrôle). Liée au patient via user_id.
 * Table créée automatiquement au premier usage (migration idempotente).
 */
class SoraFiche extends Model
{
    public function __construct()
    {
        parent::__construct();
        $this->ensureTable();
    }

    private function ensureTable()
    {
        $sql = "CREATE TABLE IF NOT EXISTS sora_fiches (
                    id                INT AUTO_INCREMENT PRIMARY KEY,
                    user_id           INT NOT NULL,
                    age               VARCHAR(10),
                    hosp_days         INT,
                    medications       INT,
                    diagnostics       INT,
                    diagnosis         VARCHAR(30),
                    glucose           VARCHAR(15),
                    antidiabetic      VARCHAR(10),
                    insulin           VARCHAR(10),
                    metformin         VARCHAR(10),
                    proba_suivi       DECIMAL(5,4),
                    resultat_suivi    VARCHAR(30),
                    proba_controle    DECIMAL(5,4),
                    resultat_controle VARCHAR(30),
                    profil            VARCHAR(120),
                    created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    INDEX (user_id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        // Pas de DDL à chaque requête : vérifié une fois via information_schema.
        $this->ensureSchema('sora_fiches', $sql);
    }

    /** Enregistre une fiche + ses résultats pour un patient. */
    public function create(array $d)
    {
        return $this->db->query(
            "INSERT INTO sora_fiches
                (user_id, age, hosp_days, medications, diagnostics, diagnosis, glucose,
                 antidiabetic, insulin, metformin,
                 proba_suivi, resultat_suivi, proba_controle, resultat_controle, profil)
             VALUES
                (:user_id, :age, :hosp_days, :medications, :diagnostics, :diagnosis, :glucose,
                 :antidiabetic, :insulin, :metformin,
                 :proba_suivi, :resultat_suivi, :proba_controle, :resultat_controle, :profil)"
        )
        ->bind(':user_id',           (int) $d['user_id'])
        ->bind(':age',               $d['age'])
        ->bind(':hosp_days',         (int) $d['hosp_days'])
        ->bind(':medications',       (int) $d['medications'])
        ->bind(':diagnostics',       (int) $d['diagnostics'])
        ->bind(':diagnosis',         $d['diagnosis'])
        ->bind(':glucose',           $d['glucose'])
        ->bind(':antidiabetic',      $d['antidiabetic'])
        ->bind(':insulin',           $d['insulin'])
        ->bind(':metformin',         $d['metformin'])
        ->bind(':proba_suivi',       $d['proba_suivi'])
        ->bind(':resultat_suivi',    $d['resultat_suivi'])
        ->bind(':proba_controle',    $d['proba_controle'])
        ->bind(':resultat_controle', $d['resultat_controle'])
        ->bind(':profil',            $d['profil'])
        ->execute();
    }

    /** Historique Sora d'un patient (plus récent d'abord). */
    public function recentByUser($userId, $limit = 50)
    {
        $limit = (int) $limit;
        return $this->db->query(
            "SELECT * FROM sora_fiches WHERE user_id = :uid ORDER BY created_at DESC, id DESC LIMIT $limit"
        )->bind(':uid', (int) $userId)->all();
    }

    /** Nombre de fiches Sora d'un patient (compteur du profil). */
    public function countByUser($userId)
    {
        $row = $this->db->query(
            "SELECT COUNT(*) AS n FROM sora_fiches WHERE user_id = :uid"
        )->bind(':uid', (int) $userId)->single();
        return $row ? (int) $row->n : 0;
    }

    /** Nombre total de fiches Sora enregistrées (compteur médecin). */
    public function countAll()
    {
        $row = $this->db->query("SELECT COUNT(*) AS n FROM sora_fiches")->single();
        return $row ? (int) $row->n : 0;
    }

    /** Identifiants des patients ayant au moins une fiche Sora (compteur médecin). */
    public function distinctUserIds()
    {
        $ids = [];
        foreach ($this->db->query(
            "SELECT DISTINCT user_id FROM sora_fiches WHERE user_id IS NOT NULL"
        )->all() as $row) {
            $ids[] = (int) $row->user_id;
        }
        return $ids;
    }
}
