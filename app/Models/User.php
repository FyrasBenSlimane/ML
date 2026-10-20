<?php
/**
 * Modèle « User » : comptes patients et personnel.
 * Table créée automatiquement au premier usage (migration idempotente).
 */
class User extends Model
{
    public function __construct()
    {
        parent::__construct();
        $this->ensureTable();
    }

    private function ensureTable()
    {
        $sql = "CREATE TABLE IF NOT EXISTS users (
                    id            INT AUTO_INCREMENT PRIMARY KEY,
                    first_name    VARCHAR(80)  NOT NULL,
                    last_name     VARCHAR(80)  NOT NULL,
                    email         VARCHAR(190) NOT NULL UNIQUE,
                    phone         VARCHAR(30)  NULL,
                    password_hash VARCHAR(255) NOT NULL,
                    role          ENUM('patient','personnel') NOT NULL DEFAULT 'patient',
                    created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        // Pas de DDL à chaque requête : vérifié une fois via information_schema.
        $this->ensureSchema('users', $sql);
    }

    /** Crée un compte (le mot de passe est haché ici). Renvoie l'id ou false. */
    public function create(array $d)
    {
        $ok = $this->db->query(
            "INSERT INTO users (first_name, last_name, email, phone, password_hash, role)
             VALUES (:fn, :ln, :email, :phone, :hash, :role)"
        )
        ->bind(':fn',    $d['first_name'])
        ->bind(':ln',    $d['last_name'])
        ->bind(':email', $d['email'])
        ->bind(':phone', $d['phone'] ?? null)
        ->bind(':hash',  password_hash($d['password'], PASSWORD_DEFAULT))
        ->bind(':role',  $d['role'])
        ->execute();

        if (!$ok) {
            return false;
        }
        $row = $this->findByEmail($d['email']);
        return $row ? (int) $row->id : false;
    }

    public function findByEmail($email)
    {
        return $this->db->query("SELECT * FROM users WHERE email = :email LIMIT 1")
                        ->bind(':email', $email)->single();
    }

    public function findById($id)
    {
        return $this->db->query("SELECT * FROM users WHERE id = :id LIMIT 1")
                        ->bind(':id', (int) $id)->single();
    }

    public function emailExists($email)
    {
        return (bool) $this->findByEmail($email);
    }
}
