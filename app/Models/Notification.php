<?php
/**
 * Modèle « Notification » : alerte envoyée à un patient par un membre du personnel
 * (médecin) à la suite d'une évaluation Doza ou Sora.
 *
 * Un patient ne lit QUE ses propres alertes (patient_id). La table est créée
 * automatiquement au premier usage (migration idempotente, sans information_schema).
 */
class Notification extends Model
{
    public function __construct()
    {
        parent::__construct();
        $this->ensureTable();
    }

    private function ensureTable()
    {
        $sql = "CREATE TABLE IF NOT EXISTS notifications (
                    id         INT AUTO_INCREMENT PRIMARY KEY,
                    patient_id INT NOT NULL,
                    sender_id  INT NULL,
                    source     ENUM('doza','sora') NOT NULL,
                    source_id  INT NULL,
                    niveau     ENUM('info','attention','important') NOT NULL DEFAULT 'info',
                    titre      VARCHAR(120) NOT NULL,
                    message    TEXT NOT NULL,
                    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
                    read_at    DATETIME NULL,
                    INDEX (patient_id),
                    INDEX (patient_id, read_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        $this->ensureSchema('notifications', $sql);
    }

    /** Crée une alerte. Renvoie true/false. */
    public function create(array $d)
    {
        return $this->db->query(
            "INSERT INTO notifications (patient_id, sender_id, source, source_id, niveau, titre, message)
             VALUES (:patient_id, :sender_id, :source, :source_id, :niveau, :titre, :message)"
        )
        ->bind(':patient_id', (int) $d['patient_id'])
        ->bind(':sender_id',  isset($d['sender_id']) ? (int) $d['sender_id'] : null)
        ->bind(':source',     $d['source'])
        ->bind(':source_id',  isset($d['source_id']) ? (int) $d['source_id'] : null)
        ->bind(':niveau',     $d['niveau'])
        ->bind(':titre',      $d['titre'])
        ->bind(':message',    $d['message'])
        ->execute();
    }

    /** Nombre d'alertes non lues d'un patient (badge de la cloche). */
    public function unreadCountByPatient($patientId)
    {
        $row = $this->db->query(
            "SELECT COUNT(*) AS n FROM notifications WHERE patient_id = :p AND read_at IS NULL"
        )->bind(':p', (int) $patientId)->single();
        return $row ? (int) $row->n : 0;
    }

    /** Alertes d'un patient (plus récentes d'abord), avec le nom de l'expéditeur. */
    public function listByPatient($patientId, $limit = 50)
    {
        $limit = (int) $limit;
        return $this->db->query(
            "SELECT n.*, u.first_name AS sender_first, u.last_name AS sender_last
             FROM notifications n
             LEFT JOIN users u ON u.id = n.sender_id
             WHERE n.patient_id = :p
             ORDER BY n.created_at DESC, n.id DESC
             LIMIT $limit"
        )->bind(':p', (int) $patientId)->all();
    }

    /** Alertes d'un patient pour une source donnée (doza|sora), plus récentes d'abord. */
    public function listByPatientAndSource($patientId, $source, $limit = 50)
    {
        $limit = (int) $limit;
        return $this->db->query(
            "SELECT n.*, u.first_name AS sender_first, u.last_name AS sender_last
             FROM notifications n
             LEFT JOIN users u ON u.id = n.sender_id
             WHERE n.patient_id = :p AND n.source = :s
             ORDER BY n.created_at DESC, n.id DESC
             LIMIT $limit"
        )->bind(':p', (int) $patientId)->bind(':s', $source)->all();
    }

    /** Marque une alerte comme lue — uniquement si elle appartient à ce patient. */
    public function markRead($id, $patientId)
    {
        return $this->db->query(
            "UPDATE notifications SET read_at = NOW()
             WHERE id = :id AND patient_id = :p AND read_at IS NULL"
        )->bind(':id', (int) $id)->bind(':p', (int) $patientId)->execute();
    }
}
