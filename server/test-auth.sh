#!/usr/bin/env bash
# Manual smoke test for the /api/auth routes.
# Usage: ./test-auth.sh   (run from the server/ directory, with `npm run dev` already running)

set -e

BASE_URL="${BASE_URL:-http://localhost:5001}"
JAR=$(mktemp)
EMAIL="test-$(date +%s)@example.com"
PASSWORD="secret123"

echo "== 1. Register (valid) =="
curl -s -c "$JAR" -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Test User\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\",\"role\":\"buyer\"}" | tee /tmp/register.json
echo

ACCESS_TOKEN=$(node -e "console.log(JSON.parse(require('fs').readFileSync('/tmp/register.json')).accessToken)")

echo "== 2. Register (invalid email -> expect 400) =="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"name":"Bad","email":"not-an-email","password":"secret123"}'
echo

echo "== 3. Register (short password -> expect 400) =="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Bad\",\"email\":\"other-$EMAIL\",\"password\":\"123\"}"
echo

echo "== 4. Register (duplicate email -> expect 409) =="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE_URL/api/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Dup\",\"email\":\"$EMAIL\",\"password\":\"secret123\"}"
echo

echo "== 5. GET /me with access token =="
curl -s -w "\nHTTP %{http_code}\n" "$BASE_URL/api/auth/me" \
  -H "Authorization: Bearer $ACCESS_TOKEN"
echo

echo "== 6. GET /me with no token -> expect 401 =="
curl -s -w "\nHTTP %{http_code}\n" "$BASE_URL/api/auth/me"
echo

echo "== 7. Login (wrong password -> expect 401) =="
curl -s -w "\nHTTP %{http_code}\n" -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"wrongpass\"}"
echo

echo "== 8. Login (valid) =="
curl -s -c "$JAR" -b "$JAR" -X POST "$BASE_URL/api/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}"
echo

echo "== 9. Refresh (uses refreshToken cookie from login) =="
curl -s -c "$JAR" -b "$JAR" -w "\nHTTP %{http_code}\n" -X POST "$BASE_URL/api/auth/refresh"
echo

echo "== 10. Logout =="
curl -s -c "$JAR" -b "$JAR" -w "\nHTTP %{http_code}\n" -X POST "$BASE_URL/api/auth/logout"
echo

echo "== 11. Refresh again after logout -> expect 401 (token was invalidated) =="
curl -s -b "$JAR" -w "\nHTTP %{http_code}\n" -X POST "$BASE_URL/api/auth/refresh"
echo

rm -f "$JAR" /tmp/register.json
