<?php

namespace App\Traits;

trait UsesTenantConnection
{
    /**
     * Single-school system — uses the default DB connection.
     * This trait is kept for compatibility with model classes.
     */
    public function getConnectionName(): ?string
    {
        return null; // use default connection from .env DB_CONNECTION
    }
}
