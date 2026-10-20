<?php
/**
 * Modèle de base dont héritent les autres modèles.
 */
class Model
{
    protected $db;

    public function __construct()
    {
        $this->db = new Database();
    }

    /**
     * Garantit la présence d'une table SANS lancer de DDL à chaque requête.
     *
     * La source de vérité reste database/medcare.sql. Ici on se contente de :
     *   1. sauter entièrement si déjà vérifié dans cette session (aucune requête) ;
     *   2. sinon sonder une seule fois table et colonnes par un SELECT léger ;
     *   3. ne lancer CREATE/ALTER (DDL) que si la table/colonne manque vraiment.
     *
     * Le but : ne plus envoyer de CREATE/ALTER à chaque requête — ce sont eux qui
     * faisaient planter mysqld de XAMPP (crash Windows 0xc0000005 / segfault) sur ce poste.
     *
     * NB : on sonde via « SELECT ... LIMIT 1 » et non via information_schema.
     * Sur ce poste, information_schema fait lui-même crasher mysqld
     * (segfault dans fill_schema_schemata) : un SELECT sur la vraie table emprunte
     * un chemin stable. Le coût est une exception interceptée au tout premier appel.
     *
     * @param string $table    nom de la table
     * @param string $createSql CREATE TABLE ... (exécuté seulement si absente)
     * @param array  $alters    [ 'colonne' => 'ALTER TABLE ...' ] (si la colonne manque)
     */
    protected function ensureSchema($table, $createSql, array $alters = [])
    {
        $key = 'schema_ok_' . $table;
        if (session_status() === PHP_SESSION_ACTIVE && !empty($_SESSION[$key])) {
            return; // déjà vérifié cette session : zéro requête
        }

        if (!$this->tableExists($table)) {
            $this->db->query($createSql)->execute();
        } else {
            foreach ($alters as $column => $alterSql) {
                if (!$this->columnExists($table, $column)) {
                    $this->db->query($alterSql)->execute();
                }
            }
        }

        if (session_status() === PHP_SESSION_ACTIVE) {
            $_SESSION[$key] = true;
        }
    }

    /** La table existe-t-elle ? (SELECT léger ; false si « table inconnue »). */
    private function tableExists($table)
    {
        try {
            $this->db->query("SELECT 1 FROM `$table` LIMIT 1")->single();
            return true;
        } catch (\PDOException $e) {
            // 42S02 / 1146 = table inconnue → à créer. Toute autre erreur : on relance.
            if ($e->getCode() === '42S02' || strpos($e->getMessage(), '1146') !== false) {
                return false;
            }
            throw $e;
        }
    }

    /** La colonne existe-t-elle ? (SELECT léger ; false si « colonne inconnue »). */
    private function columnExists($table, $column)
    {
        try {
            $this->db->query("SELECT `$column` FROM `$table` LIMIT 1")->single();
            return true;
        } catch (\PDOException $e) {
            // 42S22 / 1054 = colonne inconnue → à ajouter. Toute autre erreur : on relance.
            if ($e->getCode() === '42S22' || strpos($e->getMessage(), '1054') !== false) {
                return false;
            }
            throw $e;
        }
    }
}
