<?php

namespace Tests\Feature;

use Tests\TestCase;

class HealthEndpointTest extends TestCase
{
    /** @test */
    public function up_endpoint_returns_200(): void
    {
        $response = $this->get('/up');
        $response->assertStatus(200);
    }

    /** @test */
    public function healthz_returns_json_with_db_and_redis_keys(): void
    {
        $response = $this->get('/healthz');

        $response->assertStatus(200);
        $response->assertJsonStructure([
            'status',
            'db',
            'redis',
            'queue',
            'timestamp',
        ]);
    }

    /** @test */
    public function healthz_returns_ok_status_in_test_environment(): void
    {
        $response = $this->get('/healthz');

        // In test env, DB is always available (SQLite or configured test DB)
        $response->assertJson(['status' => 'ok']);
        $response->assertStatus(200);
    }
}
