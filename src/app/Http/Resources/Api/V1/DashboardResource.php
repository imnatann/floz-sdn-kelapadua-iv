<?php

namespace App\Http\Resources\Api\V1;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class DashboardResource extends JsonResource
{
    /**
     * The resource wraps the service-built array as-is.
     * Instantiation: new DashboardResource($serviceArray).
     */
    public function toArray(Request $request): array
    {
        // Resource receives the plain array from DashboardService; return it untouched.
        return (array) $this->resource;
    }
}
