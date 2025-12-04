# API Testing Script for CaseCobra
Write-Host "=== Testing CaseCobra API Endpoints ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Auth endpoint
Write-Host "1. Testing /api/auth/login..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/auth/login" -Method GET -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✓ Status: $($response.StatusCode) - Auth endpoint is working" -ForegroundColor Green
} catch {
    Write-Host "   ✗ Auth endpoint error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: UploadThing endpoint
Write-Host "2. Testing /api/uploadthing..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/uploadthing" -Method GET -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✓ Status: $($response.StatusCode) - UploadThing endpoint is working" -ForegroundColor Green
} catch {
    if ($_.Exception.Response.StatusCode -eq 500) {
        Write-Host "   ✗ Status: 500 - Sharp module installation issue detected" -ForegroundColor Red
        Write-Host "   → Fix: Run 'npm install --platform=win32 --arch=x64 sharp'" -ForegroundColor Yellow
    } else {
        Write-Host "   ✗ UploadThing endpoint error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 3: Checkout endpoint (POST)
Write-Host "3. Testing /api/checkout (POST)..." -ForegroundColor Yellow
try {
    $body = @{ configId = "test-config-id" } | ConvertTo-Json
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/checkout" -Method POST -ContentType "application/json" -Body $body -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✓ Status: $($response.StatusCode) - Checkout endpoint is working" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 401) {
        Write-Host "   ✓ Status: 401 - Endpoint working (authentication required)" -ForegroundColor Green
    } elseif ($statusCode -eq 400) {
        Write-Host "   ✓ Status: 400 - Endpoint working (invalid configId expected)" -ForegroundColor Green
    } elseif ($statusCode -eq 404) {
        Write-Host "   ✗ Status: 404 - Route not found" -ForegroundColor Red
    } else {
        Write-Host "   ✗ Checkout endpoint error: Status $statusCode - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# Test 4: Webhooks endpoint
Write-Host "4. Testing /api/webhooks (POST)..." -ForegroundColor Yellow
try {
    $body = "test"
    $response = Invoke-WebRequest -Uri "http://localhost:3000/api/webhooks" -Method POST -ContentType "text/plain" -Body $body -UseBasicParsing -ErrorAction Stop
    Write-Host "   ✓ Status: $($response.StatusCode) - Webhooks endpoint is working" -ForegroundColor Green
} catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    if ($statusCode -eq 400) {
        Write-Host "   ✓ Status: 400 - Endpoint working (invalid signature expected)" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Webhooks endpoint error: Status $statusCode" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== API Test Summary ===" -ForegroundColor Cyan
Write-Host "Server is running on http://localhost:3000" -ForegroundColor Green

