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

    /** Crée la table si elle n'existe pas encore. */
    private function ensureTable()
    {
        $sql = "CREATE TABLE IF NOT EXISTS consultations (
                    id           INT AUTO_INCREMENT PRIMARY KEY,
                    tag          VARCHAR(50)  NOT NULL,
                    question     VARCHAR(255) NOT NULL,
                    answer       TEXT         NOT NULL,
                    result       VARCHAR(50)  NOT NULL,
                    probability  TINYINT UNSIGNED NOT NULL,
                    answers_json TEXT         NULL,
                    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        $this->db->query($sql)->execute();
    }

    /** Enregistre une consultation. */
    public function create(array $d)
    {
        $this->db->query(
            "INSERT INTO consultations (tag, question, answer, result, probability, answers_json)
             VALUES (:tag, :question, :answer, :result, :probability, :answers_json)"
        )
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
}
