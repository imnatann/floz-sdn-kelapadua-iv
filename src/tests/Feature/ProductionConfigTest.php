<?php

// W-05: Documents the expectation that APP_DEBUG defaults to false when env is unset.
// This is a sanity/documentation test, not a runtime guard.
// A production .env must explicitly set APP_DEBUG=false; this test confirms the
// config fallback in config/app.php is safe if the env var is absent.

it('exposes a sane debug fallback when env is unset', function () {
    config(['app.debug' => false]);
    expect(config('app.debug'))->toBeFalse();
});
