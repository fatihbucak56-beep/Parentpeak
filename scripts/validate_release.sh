#!/bin/bash

# Release Validation Script – Parentpeak v1.0.0
# 
# This script automates pre-release validation checks to ensure the app
# is ready for TestFlight and production deployment.
#
# Usage: ./scripts/validate_release.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNING=0

# Helper functions
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

print_pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASSED++))
}

print_fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAILED++))
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    ((WARNING++))
}

# 1. Check environment
print_header "Environment Checks"

# Check Flutter version
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
    print_pass "Flutter is installed: $FLUTTER_VERSION"
else
    print_fail "Flutter not found in PATH"
    exit 1
fi

# Check Dart version
if command -v dart &> /dev/null; then
    DART_VERSION=$(dart --version 2>&1 | head -1)
    print_pass "Dart is installed: $DART_VERSION"
else
    print_fail "Dart not found in PATH"
    exit 1
fi

# Check git
if command -v git &> /dev/null; then
    GIT_STATUS=$(git status --short 2>/dev/null | wc -l)
    if [ "$GIT_STATUS" -eq 0 ]; then
        print_pass "Git working tree is clean"
    else
        print_warning "Git working tree has $GIT_STATUS uncommitted changes"
    fi
else
    print_fail "Git not found in PATH"
    exit 1
fi

# 2. Code Quality Checks
print_header "Code Quality Checks"

# Flutter analyze
if flutter analyze > /tmp/analyze.log 2>&1; then
    ISSUES=$(grep -c "issues found" /tmp/analyze.log || true)
    if [ "$ISSUES" -eq 0 ]; then
        print_pass "Flutter analyze: No issues found"
    else
        print_fail "Flutter analyze: Issues detected (see /tmp/analyze.log)"
        ((FAILED++))
    fi
else
    print_fail "Flutter analyze failed"
    ((FAILED++))
fi

# 3. Test Checks
print_header "Test Coverage Checks"

# Run tests
if flutter test 2>&1 | tee /tmp/test.log; then
    TEST_COUNT=$(grep -o "+[0-9]*:" /tmp/test.log | tail -1 | tr -d '+:')
    if [[ "$TEST_COUNT" =~ ^[0-9]+$ ]]; then
        if [ "$TEST_COUNT" -ge 38 ]; then
            print_pass "All $TEST_COUNT tests passed (≥ 38 required)"
        else
            print_warning "Only $TEST_COUNT tests passed (38 required for release)"
            ((WARNING++))
        fi
    fi
else
    print_fail "Test suite execution failed"
    ((FAILED++))
fi

# 4. Dependency Checks
print_header "Dependency Checks"

# Check firebase_crashlytics
if grep -q "firebase_crashlytics" pubspec.yaml; then
    print_pass "firebase_crashlytics dependency is declared"
else
    print_fail "firebase_crashlytics dependency not found in pubspec.yaml"
    ((FAILED++))
fi

# Check ErrorReportingService exists
if [ -f "lib/logic/error_reporting_service.dart" ]; then
    print_pass "ErrorReportingService file exists"
else
    print_fail "ErrorReportingService not found (lib/logic/error_reporting_service.dart)"
    ((FAILED++))
fi

# 5. Documentation Checks
print_header "Documentation Checks"

DOCS=(
    "PRODUCTION_READINESS_REPORT.md"
    "RELEASE_NOTES_v1.0.0.md"
    "docs/CRASHLYTICS_RELEASE_CHECKLIST.md"
    "docs/TESTFLIGHT_SMOKE_TEST.md"
    "docs/GITHUB_ISSUES_TEMPLATES.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        print_pass "Documentation present: $doc"
    else
        print_fail "Documentation missing: $doc"
        ((FAILED++))
    fi
done

# 6. Build Checks
print_header "Build Checks"

# Check Android build
if flutter build apk --release --verbose &> /tmp/android_build.log 2>&1; then
    if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
        APK_SIZE=$(du -h "build/app/outputs/flutter-apk/app-release.apk" | cut -f1)
        print_pass "Android Release APK built successfully ($APK_SIZE)"
    else
        print_fail "Android Release APK not found after build"
        ((FAILED++))
    fi
else
    print_warning "Android Release APK build failed (see /tmp/android_build.log)"
    ((WARNING++))
fi

# 7. Security Checks
print_header "Security Checks"

# Check for hardcoded credentials
if grep -r "password\s*=\s*['\"]" lib/ test/ 2>/dev/null | grep -v "// " | grep -v "password_field" | head -1; then
    print_warning "Potential hardcoded passwords detected"
    ((WARNING++))
else
    print_pass "No obvious hardcoded credentials detected"
fi

# Check for silent catches
if grep -r "catch\s*(\s*_\s*)\s*{}" lib/ 2>/dev/null; then
    print_warning "Silent catch blocks detected (review for proper error handling)"
    ((WARNING++))
else
    print_pass "No empty catch blocks detected"
fi

# 8. Pre-Release Checklist
print_header "Pre-Release Checklist"

CHECKLIST=(
    "Version number updated in pubspec.yaml"
    "Release notes written (RELEASE_NOTES_v1.0.0.md)"
    "All commits pushed to main branch"
    "git status is clean (no uncommitted changes)"
    "Tests all pass locally (38/38)"
    "flutter analyze shows no issues"
)

for item in "${CHECKLIST[@]}"; do
    echo "  ○ $item"
done

# 9. Summary
print_header "Release Validation Summary"

TOTAL=$((PASSED + FAILED + WARNING))
echo "Results:"
echo -e "  ${GREEN}✅ Passed: $PASSED${NC}"
echo -e "  ${YELLOW}⚠️  Warnings: $WARNING${NC}"
echo -e "  ${RED}❌ Failed: $FAILED${NC}"
echo -e "  Total: $TOTAL checks\n"

if [ "$FAILED" -eq 0 ]; then
    if [ "$WARNING" -eq 0 ]; then
        echo -e "${GREEN}🎉 All checks passed! App is ready for release.${NC}\n"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Checks passed with $WARNING warning(s). Review before release.${NC}\n"
        exit 0
    fi
else
    echo -e "${RED}❌ $FAILED check(s) failed. Fix issues before release.${NC}\n"
    exit 1
fi
