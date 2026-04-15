<?php

use App\Http\Requests\Api\V1\Auth\LoginRequest;
use Illuminate\Support\Facades\Validator;

it('requires email and password', function () {
    $rules = (new LoginRequest())->rules();
    $v = Validator::make([], $rules);
    expect($v->fails())->toBeTrue();
    expect($v->errors()->keys())->toContain('email');
    expect($v->errors()->keys())->toContain('password');
});

it('requires email to be a valid email', function () {
    $rules = (new LoginRequest())->rules();
    $v = Validator::make(['email' => 'not-an-email', 'password' => 'secret123'], $rules);
    expect($v->fails())->toBeTrue();
    expect($v->errors()->has('email'))->toBeTrue();
});

it('requires password to be at least 6 characters', function () {
    $rules = (new LoginRequest())->rules();
    $v = Validator::make(['email' => 'a@b.co', 'password' => '123'], $rules);
    expect($v->fails())->toBeTrue();
    expect($v->errors()->has('password'))->toBeTrue();
});

it('passes for valid input', function () {
    $rules = (new LoginRequest())->rules();
    $v = Validator::make(['email' => 'a@b.co', 'password' => 'secret123'], $rules);
    expect($v->fails())->toBeFalse();
});
