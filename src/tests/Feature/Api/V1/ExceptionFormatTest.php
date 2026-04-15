<?php

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;

uses(RefreshDatabase::class);

beforeEach(function () {
    Route::prefix('api/__test__')->middleware('api')->group(function () {
        Route::get('/not-found', fn () => abort(404, 'Test not found'));
        Route::get('/forbidden', fn () => abort(403, 'Test forbidden'));
        Route::get('/server-error', fn () => throw new \RuntimeException('Boom'));
        Route::post('/validate', function () {
            request()->validate(['name' => 'required|string|min:3']);

            return ['ok' => true];
        });
    });
});

it('formats 404 errors with envelope', function () {
    $this->getJson('/api/__test__/not-found')
        ->assertStatus(404)
        ->assertJsonStructure(['message'])
        ->assertJsonPath('message', 'Test not found');
});

it('formats 403 errors with envelope', function () {
    $this->getJson('/api/__test__/forbidden')
        ->assertStatus(403)
        ->assertJsonStructure(['message']);
});

it('formats 422 validation errors with envelope', function () {
    $this->postJson('/api/__test__/validate', [])
        ->assertStatus(422)
        ->assertJsonStructure(['message', 'errors' => ['name']]);
});

it('formats 500 errors with envelope shape', function () {
    $this->getJson('/api/__test__/server-error')
        ->assertStatus(500)
        ->assertJsonStructure(['message', 'code']);
});
