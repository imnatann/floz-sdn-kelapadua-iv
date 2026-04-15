<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class WelcomeController extends Controller
{
    public function index()
    {
        // Future Performance Optimization:
        // If we add dynamic data (stats, testimonials) here later,
        // wrap it in Cache::remember('welcome_data', 3600, fn() => ...);
        
        return inertia('Welcome');
    }
}
