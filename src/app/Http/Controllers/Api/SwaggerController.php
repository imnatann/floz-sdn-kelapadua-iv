<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use OpenApi\Attributes as OA;

#[OA\Info(
    version: '1.0.0',
    title: 'FLOZ Platform API',
    description: 'API documentation for FLOZ Platform and Tenant specific features'
)]
#[OA\Server(
    url: 'http://localhost:8000/api',
    description: 'Primary API Server'
)]
#[OA\SecurityScheme(
    securityScheme: 'bearerAuth',
    type: 'http',
    scheme: 'bearer',
    bearerFormat: 'Sanctum'
)]
class SwaggerController extends Controller
{
    #[OA\Get(
        path: '/api/health',
        tags: ['System'],
        summary: 'Health Check',
        description: 'Check if the API is running'
    )]
    #[OA\Response(
        response: 200,
        description: 'API is healthy',
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: 'status', type: 'string', example: 'ok'),
            ]
        )
    )]
    public function health()
    {
        return response()->json(['status' => 'ok']);
    }
}
