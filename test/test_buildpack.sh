#!/usr/bin/env bash

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Test directory setup
TEST_DIR="/app"
BUILD_DIR="$TEST_DIR/build"
CACHE_DIR="$TEST_DIR/cache"
ENV_DIR="$TEST_DIR/env"
mkdir -p "$BUILD_DIR" "$CACHE_DIR" "$ENV_DIR"

# Function to verify cache contents
verify_cache() {
    local cache_type=$1
    local file_path=$2
    local description=$3

    if [ "$cache_type" = "apt/archives" ]; then
        # Special handling for APT archives directory
        if ls "$CACHE_DIR/$cache_type"/*.deb >/dev/null 2>&1; then
            echo -e "${GREEN}✓ $description are cached${NC}"
        else
            echo -e "${RED}✗ $description are not cached${NC}"
            return 1
        fi
    else
        # Normal file check
        if [ -f "$CACHE_DIR/$cache_type/$file_path" ]; then
            echo -e "${GREEN}✓ $description is cached${NC}"
        else
            echo -e "${RED}✗ $description is not cached${NC}"
            return 1
        fi
    fi
}

# Function to run a test
run_test() {
    local test_name=$1
    local script=$2
    local expected_exit=$3
    local expected_output=$4

    echo "Running test: $test_name"

    # Run the script and capture output and exit code
    output=$($script "$BUILD_DIR" "$CACHE_DIR" "$ENV_DIR" 2>&1)
    exit_code=$?

    # Check exit code
    if [ $exit_code -eq $expected_exit ]; then
        echo -e "${GREEN}✓ Exit code matches${NC}"
    else
        echo -e "${RED}✗ Exit code mismatch. Expected $expected_exit, got $exit_code${NC}"
        return 1
    fi

    # Check output if expected_output is provided
    if [ -n "$expected_output" ]; then
        if echo "$output" | grep -q "$expected_output"; then
            echo -e "${GREEN}✓ Output matches${NC}"
        else
            echo -e "${RED}✗ Output mismatch. Expected to find: $expected_output${NC}"
            echo "Actual output:"
            echo "$output"
            return 1
        fi
    fi

    echo -e "${GREEN}✓ Test passed!${NC}"
    echo "---"
}

# Test detect script
echo "Testing detect script..."
run_test "detect" "/buildpack/bin/detect" 0 "AppSignal Collector"

# Test compile script with valid API key
echo "Testing compile script with valid API key..."
echo "test-key-123" > "$ENV_DIR/APPSIGNAL_PUSH_API_KEY"
run_test "compile with valid API key" "/buildpack/bin/compile" 0 "AppSignal collector installed successfully"

# Simulate dyno boot (source the profile.d script) so that the collector is started
echo "Simulating dyno boot (sourcing .profile.d/appsignal-buildpack-collector.sh) to start the collector..."
if [ -f "$BUILD_DIR/.profile.d/appsignal-buildpack-collector.sh" ]; then
  source "$BUILD_DIR/.profile.d/appsignal-buildpack-collector.sh"
  echo -e "${GREEN}✓ Sourced .profile.d/appsignal-buildpack-collector.sh (simulating dyno boot)${NC}"
else
  echo -e "${RED}✗ .profile.d/appsignal-buildpack-collector.sh not found (simulation failed)${NC}"
  exit 1
fi

# Verify that the collector is running immediately after starting it
echo "Verifying that the AppSignal collector (exporter) is running..."
if ps aux | grep appsignal-collector | grep -v grep > /dev/null; then
  echo -e "${GREEN}✓ Collector (exporter) process is running${NC}"
else
  echo -e "${RED}✗ Collector (exporter) process is not running${NC}"
  exit 1
fi

# Test compile script with missing API key
echo "Testing compile script with missing API key..."
rm -f "$ENV_DIR/APPSIGNAL_PUSH_API_KEY"
set +e  # Temporarily disable exit on error
run_test "compile with missing API key" "/buildpack/bin/compile" 1 "APPSIGNAL_PUSH_API_KEY environment variable is required"
set -e  # Re-enable exit on error

# Verify generated files
echo "Verifying generated files..."
if [ -f "$BUILD_DIR/.profile.d/appsignal-buildpack-collector.sh" ]; then
    echo -e "${GREEN}✓ Profile.d script created${NC}"
    if grep -q "appsignal-collector start" "$BUILD_DIR/.profile.d/appsignal-buildpack-collector.sh"; then
        echo -e "${GREEN}✓ Profile.d script contains correct collector start command${NC}"
    else
        echo -e "${RED}✗ Profile.d script missing collector start command${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Profile.d script not created${NC}"
    exit 1
fi

# Verify collector installation
echo "Verifying collector installation..."
if [ -f "/usr/bin/appsignal-collector" ]; then
    echo -e "${GREEN}✓ Collector installed${NC}"
else
    echo -e "${RED}✗ Collector not installed${NC}"
    exit 1
fi

# Verify configuration
echo "Verifying collector configuration..."
if [ -f "/etc/appsignal-collector.conf" ]; then
    if grep -q "push_api_key = \"test-key-123\"" "/etc/appsignal-collector.conf"; then
        echo -e "${GREEN}✓ Configuration file created with correct API key${NC}"
    else
        echo -e "${RED}✗ Configuration file missing or incorrect API key${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Configuration file not created${NC}"
    exit 1
fi

# Test caching functionality
echo "Testing caching functionality..."

# First run - should create cache
echo "First run - creating cache..."
echo "test-key-123" > "$ENV_DIR/APPSIGNAL_PUSH_API_KEY"
run_test "compile with caching" "/buildpack/bin/compile" 0 "AppSignal collector installed successfully"

# Verify cache was created
echo "Verifying cache contents after first run..."
verify_cache "gpg" "appsignal_collector-ubuntu-jammy-archive-keyring.gpg" "GPG key"
verify_cache "apt" "appsignal-collector.list" "Repository configuration"
verify_cache "apt/archives" "*.deb" "APT packages"

# Clean build directory but keep cache
echo "Cleaning build directory for second run..."
rm -rf "$BUILD_DIR"/*
mkdir -p "$BUILD_DIR"

# Second run - should use cache
echo "Second run - using cache..."
run_test "compile with cached files" "/buildpack/bin/compile" 0 "Using cached GPG key"

# Verify cache was used
echo "Verifying cache was used in second run..."
if grep -q "Using cached GPG key" <<< "$output"; then
    echo -e "${GREEN}✓ Second run used cached GPG key${NC}"
else
    echo -e "${RED}✗ Second run did not use cached GPG key${NC}"
    exit 1
fi

if grep -q "Using cached repository configuration" <<< "$output"; then
    echo -e "${GREEN}✓ Second run used cached repository configuration${NC}"
else
    echo -e "${RED}✗ Second run did not use cached repository configuration${NC}"
    exit 1
fi

echo "All tests completed!"
echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}✅ All AppSignal buildpack tests passed! ✅${NC}"
echo -e "${GREEN}==========================================${NC}\n"
