<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    public function createApplication()
    {
        $app = parent::createApplication();

        // Detiene RefreshDatabase antes de tocar una base ajena a las pruebas.
        if ($app['config']->get('database.default') !== 'pgsql'
            || $app['db']->connection()->getDatabaseName() !== 'yoltec_test') {
            throw new \RuntimeException('Las pruebas requieren la base aislada yoltec_test.');
        }

        return $app;
    }
}
