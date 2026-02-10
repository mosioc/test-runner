# Universal Test Runner Container

A universal test runner Docker container that auto-detects your testing framework and runs tests with clean, formatted reports.

## Supported Frameworks

- **Jest** - JavaScript/TypeScript testing
- **PyTest** - Python testing  
- **Go test** - Go testing

## Quick Start

```bash
# Run tests in current directory
docker run -v $(pwd):/workspace ghcr.io/mosioc/test-runner

# Save reports to a reports directory
docker run -v $(pwd):/workspace -v $(pwd)/reports:/output ghcr.io/mosioc/test-runner
```

## Features

- **Auto-detection**: Automatically detects your test framework
- **Clean Reports**: Generates formatted test reports
- **Multi-language**: Supports JavaScript, Python, and Go
- **CI/CD Ready**: Perfect for GitHub Actions and other CI systems
- **Export Reports**: Save JSON and HTML reports to output directory

## Usage

### Auto-detect and Run Tests

```bash
docker run -v $(pwd):/workspace ghcr.io/mosioc/test-runner
```

### Force Specific Framework

```bash
docker run -v $(pwd):/workspace ghcr.io/mosioc/test-runner --framework pytest
```

### Detect Framework Only

```bash
docker run -v $(pwd):/workspace ghcr.io/mosioc/test-runner --detect
```

### Get Help

```bash
docker run ghcr.io/mosioc/test-runner --help
```

## Framework Detection

The test runner automatically detects your framework by looking for:

- **Jest**: `package.json` with jest dependency, `*.test.js` files
- **PyTest**: `pytest.ini`, `test_*.py` or `*_test.py` files
- **Go test**: `go.mod`, `*_test.go` files

## Output Reports

When you mount an `/output` volume, the container will save:

- `test-report.txt` - Formatted text report
- `*-results.json` - JSON test results
- `pytest-report.html` - HTML report (PyTest only)

## GitHub Actions Example

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Tests
        run: |
          docker run -v ${{ github.workspace }}:/workspace \
            -v ${{ github.workspace }}/reports:/output \
            ghcr.io/mosioc/test-runner
      
      - name: Upload Reports
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-reports
          path: reports/
```

## Building Locally

```bash
docker build -t test-runner .
docker run -v $(pwd):/workspace test-runner
```

## License

MIT License - Feel free to use and modify
