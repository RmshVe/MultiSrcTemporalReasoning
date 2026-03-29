#!/bin/bash

set -u

BASE_URL="http://localhost:8080"
OUT_DIR="validation-output"
RESULT_FILE="$OUT_DIR/summary.txt"
RESP_FILE="$OUT_DIR/responses.txt"
ERROR_FILE="$OUT_DIR/errors.txt"

mkdir -p "$OUT_DIR"
: > "$RESULT_FILE"
: > "$RESP_FILE"
: > "$ERROR_FILE"

PASS_COUNT=0
FAIL_COUNT=0

log_pass() {
  echo "[PASS] $1" | tee -a "$RESULT_FILE"
  PASS_COUNT=$((PASS_COUNT + 1))
}

log_fail() {
  echo "[FAIL] $1" | tee -a "$RESULT_FILE"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

record_response() {
  echo "----- $1 -----" >> "$RESP_FILE"
  echo "$2" >> "$RESP_FILE"
  echo >> "$RESP_FILE"
}

record_error() {
  echo "----- $1 -----" >> "$ERROR_FILE"
  echo "$2" >> "$ERROR_FILE"
  echo >> "$ERROR_FILE"
}

echo "Validating app at $BASE_URL"
echo "Started at: $(date)" >> "$RESULT_FILE"
echo >> "$RESULT_FILE"

# 1. Basic connectivity check
HTTP_CODE=$(curl -s -o /tmp/validate_home.out -w "%{http_code}" "$BASE_URL/accounts/99999" || echo "000")
BODY=$(cat /tmp/validate_home.out 2>/dev/null)

record_response "GET /accounts/99999" "$BODY"

if [ "$HTTP_CODE" != "000" ]; then
  log_pass "Application is reachable on port 8080 (HTTP $HTTP_CODE)"
else
  log_fail "Application is not reachable on port 8080"
  record_error "CONNECTIVITY" "curl could not connect to $BASE_URL"
fi

# Stop early if app is not reachable
if [ "$HTTP_CODE" = "000" ]; then
  echo >> "$RESULT_FILE"
  echo "Validation stopped due to connectivity failure." >> "$RESULT_FILE"
  exit 1
fi

# 2. Create account
CREATE_BODY='{"id":1,"name":"Ramesh"}'
CREATE_CODE=$(curl -s -o /tmp/create.out -w "%{http_code}" \
  -X POST "$BASE_URL/accounts" \
  -H "Content-Type: application/json" \
  -d "$CREATE_BODY")
CREATE_RESP=$(cat /tmp/create.out)

record_response "POST /accounts" "$CREATE_RESP"

if [[ "$CREATE_CODE" == "200" || "$CREATE_CODE" == "201" ]] && echo "$CREATE_RESP" | grep -q '"id":1'; then
  log_pass "Create account API works"
else
  log_fail "Create account API failed (HTTP $CREATE_CODE)"
  record_error "CREATE_ACCOUNT" "Expected account creation success, got HTTP $CREATE_CODE and response: $CREATE_RESP"
fi

# 3. Get account
GET_CODE=$(curl -s -o /tmp/get.out -w "%{http_code}" "$BASE_URL/accounts/1")
GET_RESP=$(cat /tmp/get.out)

record_response "GET /accounts/1" "$GET_RESP"

if [ "$GET_CODE" = "200" ] && echo "$GET_RESP" | grep -q '"name":"Ramesh"'; then
  log_pass "Get account API works"
else
  log_fail "Get account API failed (HTTP $GET_CODE)"
  record_error "GET_ACCOUNT" "Expected name=Ramesh, got HTTP $GET_CODE and response: $GET_RESP"
fi

# 4. Update account
UPDATE_BODY='{"id":1,"name":"UpdatedName"}'
UPDATE_CODE=$(curl -s -o /tmp/update.out -w "%{http_code}" \
  -X PUT "$BASE_URL/accounts/1" \
  -H "Content-Type: application/json" \
  -d "$UPDATE_BODY")
UPDATE_RESP=$(cat /tmp/update.out)

record_response "PUT /accounts/1" "$UPDATE_RESP"

if [ "$UPDATE_CODE" = "200" ] && echo "$UPDATE_RESP" | grep -q '"name":"UpdatedName"'; then
  log_pass "Update account API works"
else
  log_fail "Update account API failed (HTTP $UPDATE_CODE)"
  record_error "UPDATE_ACCOUNT" "Expected updated name, got HTTP $UPDATE_CODE and response: $UPDATE_RESP"
fi

# 5. Delete account
DELETE_CODE=$(curl -s -o /tmp/delete.out -w "%{http_code}" -X DELETE "$BASE_URL/accounts/1")
DELETE_RESP=$(cat /tmp/delete.out)

record_response "DELETE /accounts/1" "$DELETE_RESP"

if [[ "$DELETE_CODE" == "200" || "$DELETE_CODE" == "204" ]]; then
  log_pass "Delete account API returned success"
else
  log_fail "Delete account API failed (HTTP $DELETE_CODE)"
  record_error "DELETE_ACCOUNT" "Expected successful delete, got HTTP $DELETE_CODE and response: $DELETE_RESP"
fi

# 6. Verify delete semantics for baseline
VERIFY_DELETE_CODE=$(curl -s -o /tmp/verify_delete.out -w "%{http_code}" "$BASE_URL/accounts/1")
VERIFY_DELETE_RESP=$(cat /tmp/verify_delete.out)

record_response "GET /accounts/1 after delete" "$VERIFY_DELETE_RESP"

# Baseline expectation: deleted account should not be returned
if [ "$VERIFY_DELETE_CODE" != "200" ] || ! echo "$VERIFY_DELETE_RESP" | grep -q '"id":1'; then
  log_pass "Deleted account is no longer retrievable (baseline behavior)"
else
  log_fail "Deleted account still retrievable after delete"
  record_error "VERIFY_DELETE" "Expected deleted account to be absent, but got HTTP $VERIFY_DELETE_CODE and response: $VERIFY_DELETE_RESP"
fi

echo >> "$RESULT_FILE"
echo "Pass count: $PASS_COUNT" | tee -a "$RESULT_FILE"
echo "Fail count: $FAIL_COUNT" | tee -a "$RESULT_FILE"

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo >> "$RESULT_FILE"
  echo "VALIDATION_STATUS=FAIL" | tee -a "$RESULT_FILE"
  exit 1
else
  echo >> "$RESULT_FILE"
  echo "VALIDATION_STATUS=PASS" | tee -a "$RESULT_FILE"
  exit 0
fi
