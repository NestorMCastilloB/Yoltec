<?php

return [
    'special_days' => [
        // Días festivos oficiales México 2026
        ['date' => '2026-01-01', 'type' => 'holiday', 'label' => 'Año Nuevo'],
        ['date' => '2026-02-02', 'type' => 'holiday', 'label' => 'Día de la Constitución'],  // Primer lunes de febrero
        ['date' => '2026-03-16', 'type' => 'holiday', 'label' => 'Natalicio de Benito Juárez'], // Tercer lunes de marzo
        ['date' => '2026-04-02', 'type' => 'holiday', 'label' => 'Jueves Santo'],
        ['date' => '2026-04-03', 'type' => 'holiday', 'label' => 'Viernes Santo'],
        ['date' => '2026-05-01', 'type' => 'holiday', 'label' => 'Día del Trabajo'],
        ['date' => '2026-09-16', 'type' => 'holiday', 'label' => 'Independencia de México'],
        ['date' => '2026-11-02', 'type' => 'holiday', 'label' => 'Día de Muertos'],
        ['date' => '2026-11-16', 'type' => 'holiday', 'label' => 'Revolución Mexicana'], // Tercer lunes de noviembre
        ['date' => '2026-12-12', 'type' => 'holiday', 'label' => 'Día de la Virgen de Guadalupe'],
        ['date' => '2026-12-25', 'type' => 'holiday', 'label' => 'Navidad'],
    ],
    'types' => [
        'holiday' => [
            'status' => 'full',
            'color' => '#ef5350',
        ],
        'vacation' => [
            'status' => 'full',
            'color' => '#ef5350',
        ],
        'reduced' => [
            'status' => 'partial',
            'color' => '#ffca28',
        ],
    ],
];
