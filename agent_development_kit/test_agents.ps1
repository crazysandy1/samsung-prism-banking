# Samsung Prism Multi-Agent System Test Script
# Run this in PowerShell while the server is running

Write-Host "🧪 Testing Samsung Prism Multi-Agent System" -ForegroundColor Green
Write-Host "=" * 50

# Test 1: Health Check
Write-Host "`n🏥 Testing Health Endpoint..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET
    Write-Host "✅ Health Check Success!" -ForegroundColor Green
    $healthResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Get Agent Capabilities
Write-Host "`n🤖 Testing Agent Capabilities..." -ForegroundColor Yellow
try {
    $capabilitiesResponse = Invoke-RestMethod -Uri "http://localhost:8000/agents/capabilities" -Method GET
    Write-Host "✅ Agent Capabilities Success!" -ForegroundColor Green
    $capabilitiesResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Agent Capabilities Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Account Agent Query
Write-Host "`n💰 Testing Account Agent..." -ForegroundColor Yellow
$accountQuery = @{
    user_id = "test_user"
    query_text = "What is my account balance?"
    context = @{}
} | ConvertTo-Json

try {
    $accountResponse = Invoke-RestMethod -Uri "http://localhost:8000/query" -Method POST -Body $accountQuery -ContentType "application/json"
    Write-Host "✅ Account Agent Success!" -ForegroundColor Green
    $accountResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Account Agent Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Loan Agent Query
Write-Host "`n🏦 Testing Loan Agent..." -ForegroundColor Yellow
$loanQuery = @{
    user_id = "test_user"
    query_text = "Am I eligible for a personal loan?"
    context = @{}
} | ConvertTo-Json

try {
    $loanResponse = Invoke-RestMethod -Uri "http://localhost:8000/query" -Method POST -Body $loanQuery -ContentType "application/json"
    Write-Host "✅ Loan Agent Success!" -ForegroundColor Green
    $loanResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Loan Agent Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Card Agent Query
Write-Host "`n💳 Testing Card Agent..." -ForegroundColor Yellow
$cardQuery = @{
    user_id = "test_user"
    query_text = "What is my credit card limit?"
    context = @{}
} | ConvertTo-Json

try {
    $cardResponse = Invoke-RestMethod -Uri "http://localhost:8000/query" -Method POST -Body $cardQuery -ContentType "application/json"
    Write-Host "✅ Card Agent Success!" -ForegroundColor Green
    $cardResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Card Agent Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Support Agent Query
Write-Host "`n🆘 Testing Support Agent..." -ForegroundColor Yellow
$supportQuery = @{
    user_id = "test_user"
    query_text = "How do I reset my password?"
    context = @{}
} | ConvertTo-Json

try {
    $supportResponse = Invoke-RestMethod -Uri "http://localhost:8000/query" -Method POST -Body $supportQuery -ContentType "application/json"
    Write-Host "✅ Support Agent Success!" -ForegroundColor Green
    $supportResponse | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Support Agent Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🎉 Testing Complete!" -ForegroundColor Green
Write-Host "📝 Note: Make sure the server is running with 'python main.py' before running this script." -ForegroundColor Cyan
