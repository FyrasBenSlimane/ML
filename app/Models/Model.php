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
}
