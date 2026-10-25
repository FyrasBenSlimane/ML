<?php
/**
 * Modèle « Consultation » : une session Doza terminée.
 *
 * Chaque enregistrement contient à la fois :
 *   - la question du patient (ce qu'il a demandé à Doza)
 *   - la réponse du modèle (prédiction + niveau de confiance)
 *
 * La table est créée automatiquement au premier usage (pratique avec XAMPP) :
 * il suffit d'avoir une base `medcare` (voir database/medcare.sql).
 */
class Consultation extends Model
{
    public function __construct()
    {
        parent::__construct();
        $this->ensureTable();
    }

    /** Crée la table si elle n'existe pas encore, et ajoute user_id s'il manque. */
    private function ensureTable()
    {
        $sql = "CREATE TABLE IF NOT EXISTS consultations (
                    id           INT AUTO_INCREMENT PRIMARY KEY,
                    user_id      INT          NULL,
                    tag          VARCHAR(50)  NOT NULL,
                    question     VARCHAR(255) NOT NULL,
                    answer       TEXT         NOT NULL,
                    result       VARCHAR(50)  NOT NULL,
                    probability  TINYINT UNSIGNED NOT NULL,
                    answers_json TEXT         NULL,
                    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        // Pas de DDL à chaque requête : vérifié une fois via information_schema.
        // Si la table existe déjà mais sans user_id (ancienne version), on l'ajoute (NULL pour l'historique).
        $this->ensureSchema('consultations', $sql, [
            'user_id' => "ALTER TABLE consultations ADD COLUMN user_id INT NULL AFTER id",
        ]);
    }

    /** Enregistre une consultation (user_id optionnel : NULL si non connecté). */
    public function create(array $d)
    {
        $this->db->query(
            "INSERT INTO consultations (user_id, tag, question, answer, result, probability, answers_json)
             VALUES (:user_id, :tag, :question, :answer, :result, :probability, :answers_json)"
        )
        ->bind(':user_id',      isset($d['user_id']) ? (int) $d['user_id'] : null)
        ->bind(':tag',          $d['tag'])
        ->bind(':question',     $d['question'])
        ->bind(':answer',       $d['answer'])
        ->bind(':result',       $d['result'])
        ->bind(':probability',  $d['probability'])
        ->bind(':answers_json', $d['answers_json']);

        return $this->db->execute();
    }

    /** Historique, du plus récent au plus ancien. */
    public function recent($limit = 50)
    {
        $limit = (int) $limit; // sécurisé par cast (LIMIT ne se bind pas en mode non émulé)
        return $this->db->query(
            "SELECT * FROM consultations ORDER BY created_at DESC, id DESC LIMIT $limit"
        )->all();
    }

    /** Historique Doza d'un patient donné. */
    public function recentByUser($userId, $limit = 50)
    {
        $limit = (int) $limit;
        return $this->db->query(
            "SELECT * FROM consultations WHERE user_id = :uid ORDER BY created_at DESC, id DESC LIMIT $limit"
        )->bind(':uid', (int) $userId)->all();
    }

    /** Nombre de sessions Doza d'un patient (compteur du profil). */
    public function countByUser($userId)
    {
        $row = $this->db->query(
            "SELECT COUNT(*) AS n FROM consultations WHERE user_id = :uid"
        )->bind(':uid', (int) $userId)->single();
        return $row ? (int) $row->n : 0;
    }

    /** Nombre total de sessions Doza enregistrées (compteur médecin). */
    public function countAll()
    {
        $row = $this->db->query("SELECT COUNT(*) AS n FROM consultations")->single();
        return $row ? (int) $row->n : 0;
    }

    /** Identifiants des patients ayant au moins une session Doza (compteur médecin). */
    public function distinctUserIds()
    {
        $ids = [];
        foreach ($this->db->query(
            "SELECT DISTINCT user_id FROM consultations WHERE user_id IS NOT NULL"
        )->all() as $row) {
            $ids[] = (int) $row->user_id;
        }
        return $ids;
    }
}
