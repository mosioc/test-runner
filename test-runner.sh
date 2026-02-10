#!/bin/bash

set -e

# colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# function to print colored output
print_status() {
    echo -e "${BLUE}[TEST-RUNNER]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# function to detect test framework
detect_framework() {
    local test_dir=${1:-.}
    
    print_status "Detecting test framework in: $test_dir"
    
    # check for Node.js/Jest
    if [ -f "$test_dir/package.json" ]; then
        if grep -q "jest" "$test_dir/package.json" 2>/dev/null; then
            echo "jest"
            return 0
        fi
    fi
    
    # check for Python/pytest
    if [ -f "$test_dir/pytest.ini" ] || [ -f "$test_dir/setup.cfg" ] || [ -f "$test_dir/pyproject.toml" ]; then
        echo "pytest"
        return 0
    fi
    
    # check for files with test patterns
    if find "$test_dir" -type f \( -name "test_*.py" -o -name "*_test.py" \) 2>/dev/null | grep -q .; then
        echo "pytest"
        return 0
    fi
    
    if find "$test_dir" -type f \( -name "*.test.js" -o -name "*.test.ts" \) 2>/dev/null | grep -q .; then
        echo "jest"
        return 0
    fi
    
    # check for Go tests
    if [ -f "$test_dir/go.mod" ] || find "$test_dir" -type f -name "*_test.go" 2>/dev/null | grep -q .; then
        echo "gotest"
        return 0
    fi
    
    echo "unknown"
}

# function to run Jest tests
run_jest() {
    print_status "Running Jest tests..."
    
    # install dependencies if package.json exists
    if [ -f "package.json" ]; then
        print_status "Installing npm dependencies..."
        npm install
    fi
    
    # run tests with JSON output
    if npx jest --json --outputFile=/tmp/jest-results.json --coverage 2>&1 | tee /tmp/jest-output.log; then
        print_success "Jest tests passed!"
        EXIT_CODE=0
    else
        print_error "Jest tests failed!"
        EXIT_CODE=1
    fi
    
    # generate report
    generate_report "jest" "$EXIT_CODE"
    return $EXIT_CODE
}

# function to run pytest tests
run_pytest() {
    print_status "Running pytest tests..."
    
    # install requirements if they exist
    if [ -f "requirements.txt" ]; then
        print_status "Installing Python dependencies..."
        pip3 install -r requirements.txt
    fi
    
    # run tests with HTML reports
    if python3 -m pytest \
        --html=/tmp/pytest-report.html --self-contained-html \
        -v 2>&1 | tee /tmp/pytest-output.log; then
        print_success "Pytest tests passed!"
        EXIT_CODE=0
    else
        print_error "Pytest tests failed!"
        EXIT_CODE=1
    fi
    
    # Generate report
    generate_report "pytest" "$EXIT_CODE"
    return $EXIT_CODE
}

# function to run Go tests
run_gotest() {
    print_status "Running Go tests..."
    
    # download dependencies if go.mod exists
    if [ -f "go.mod" ]; then
        print_status "Downloading Go dependencies..."
        go mod download
    fi
    
    # run tests with verbose output and JSON
    if go test -v -json ./... 2>&1 | tee /tmp/gotest-output.log | grep -q '"Action":"pass"'; then
        print_success "Go tests passed!"
        EXIT_CODE=0
    else
        print_error "Go tests failed!"
        EXIT_CODE=1
    fi
    
    # generate report
    generate_report "gotest" "$EXIT_CODE"
    return $EXIT_CODE
}

# function to generate unified report
generate_report() {
    local framework=$1
    local exit_code=$2
    
    print_status "Generating test report..."
    
    cat > /tmp/test-report.txt <<EOF
╔═══════════════════════════════════════════════════════════════╗
║              UNIVERSAL TEST RUNNER - REPORT                   ║
╚═══════════════════════════════════════════════════════════════╝

Framework: $framework
Status: $([ $exit_code -eq 0 ] && echo "PASSED ✓" || echo "FAILED ✗")
Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

═══════════════════════════════════════════════════════════════

EOF
    
    # append framework-specific output
    if [ -f "/tmp/${framework}-output.log" ]; then
        cat "/tmp/${framework}-output.log" >> /tmp/test-report.txt
    fi
    
    # display report
    cat /tmp/test-report.txt
    
    # save reports to output directory if mounted
    if [ -d "/output" ] && [ -w "/output" ]; then
        cp /tmp/test-report.txt /output/ 2>/dev/null || print_warning "Could not write test-report.txt to /output"
        [ -f "/tmp/jest-results.json" ] && cp "/tmp/jest-results.json" /output/ 2>/dev/null
        [ -f "/tmp/pytest-report.html" ] && cp "/tmp/pytest-report.html" /output/ 2>/dev/null
        [ -f "/tmp/gotest-output.log" ] && cp "/tmp/gotest-output.log" /output/gotest-results.log 2>/dev/null
        print_status "Reports saved to /output directory"
    elif [ ! -d "/output" ]; then
        print_status "No /output directory mounted, reports not saved"
    fi
}

# show help
show_help() {
    cat <<EOF
Universal Test Runner Container

USAGE:
    docker run -v \$(pwd):/workspace ghcr.io/mosioc/test-runner [OPTIONS]

OPTIONS:
    --help              Show this help message
    --detect            Only detect the framework (don't run tests)
    --framework NAME    Force a specific framework (jest, pytest, gotest)

EXAMPLES:
    # Auto-detect and run tests
    docker run -v \$(pwd):/workspace ghcr.io/mosioc/test-runner

    # Run with output directory for reports
    docker run -v \$(pwd):/workspace -v \$(pwd)/reports:/output ghcr.io/mosioc/test-runner

    # Force a specific framework
    docker run -v \$(pwd):/workspace ghcr.io/mosioc/test-runner --framework pytest

SUPPORTED FRAMEWORKS:
    - Jest (JavaScript/TypeScript)
    - PyTest (Python)
    - Go test (Go)

The test runner auto-detects your testing framework and runs tests accordingly.
EOF
}

# main execution
main() {
    local framework=""
    local test_dir="/workspace"
    
    # parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --help)
                show_help
                exit 0
                ;;
            --detect)
                framework=$(detect_framework "$test_dir")
                print_status "Detected framework: $framework"
                exit 0
                ;;
            --framework)
                framework="$2"
                shift 2
                ;;
            *)
                test_dir="$1"
                shift
                ;;
        esac
    done
    
    # change to test directory if it exists
    if [ -d "$test_dir" ]; then
        cd "$test_dir"
    else
        print_error "Directory not found: $test_dir"
        exit 1
    fi
    
    # auto-detect framework if not specified
    if [ -z "$framework" ]; then
        framework=$(detect_framework ".")
    fi
    
    print_status "Using framework: $framework"
    
    # run tests based on framework
    case $framework in
        jest)
            run_jest
            ;;
        pytest)
            run_pytest
            ;;
        gotest)
            run_gotest
            ;;
        unknown)
            print_error "Could not detect test framework!"
            print_warning "Supported frameworks: Jest, PyTest, Go test"
            exit 1
            ;;
        *)
            print_error "Unknown framework: $framework"
            exit 1
            ;;
    esac
}

main "$@"
