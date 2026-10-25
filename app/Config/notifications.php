<?php
/**
 * Modèles de messages d'alerte envoyés AU PATIENT par le médecin après une
 * évaluation Doza ou Sora.
 *
 * Règles de rédaction (protection du patient) :
 *   - aucun chiffre, pourcentage ou score ;
 *   - aucun mot anxiogène (« risque », « élevé », « grave »…) ;
 *   - ton rassurant, orienté « prochain échange avec votre médecin ».
 *
 * Structure : [source][clé de sortie] => ['niveau', 'titre', 'message'].
 * La clé de sortie est la ZONE Doza ou le résultat de SUIVI Sora.
 * Le médecin peut toujours modifier le message avant l'envoi.
 */
return [
    'doza' => [
        'Risque plus faible' => [
            'niveau'  => 'info',
            'titre'   => 'Suivi de votre traitement',
            'message' => "Bonjour, votre médecin a examiné votre situation. Tout se poursuit normalement : "
                       . "continuez votre suivi habituel. N'hésitez pas à le contacter si vous avez des questions.",
        ],
        'Risque intermédiaire' => [
            'niveau'  => 'attention',
            'titre'   => 'Un point avec votre médecin',
            'message' => "Bonjour, votre médecin a examiné votre situation et souhaite faire un point avec vous "
                       . "sur votre traitement lors d'un prochain échange. Prenez rendez-vous quand cela vous convient.",
        ],
        'Risque élevé' => [
            'niveau'  => 'important',
            'titre'   => 'Votre médecin souhaite vous voir',
            'message' => "Bonjour, votre médecin a examiné votre situation et préfère adapter votre suivi avec vous "
                       . "prochainement. Merci de prendre rendez-vous dès que possible ; il reste disponible pour vous accompagner.",
        ],
    ],
    'sora' => [
        'Suivi léger' => [
            'niveau'  => 'info',
            'titre'   => 'Préparation de votre sortie',
            'message' => "Bonjour, votre médecin a préparé la suite de votre sortie. Un suivi simple est prévu : "
                       . "poursuivez vos habitudes et contactez-le en cas de besoin.",
        ],
        'Suivi renforcé' => [
            'niveau'  => 'attention',
            'titre'   => 'Un accompagnement rapproché',
            'message' => "Bonjour, votre médecin a préparé votre sortie et souhaite vous accompagner d'un peu plus près "
                       . "les prochaines semaines. Il vous proposera un suivi adapté ; prenez rendez-vous quand cela vous convient.",
        ],
    ],
    // Repli si la sortie du modèle ne correspond à aucune clé ci-dessus.
    'default' => [
        'niveau'  => 'info',
        'titre'   => 'Message de votre médecin',
        'message' => "Bonjour, votre médecin a examiné votre situation et vous accompagne dans votre suivi. "
                   . "N'hésitez pas à le contacter pour toute question.",
    ],
];
