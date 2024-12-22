# Drupal Benchmark

This project is based on the [Wunder template for Drupal projects](https://github.com/wunderio/drupal-project) and is designed for benchmarking a local Drupal development environment using the [Apache HTTP server benchmarking tool](https://httpd.apache.org/docs/2.4/programs/ab.html).

## Requirements

- Apache Benchmark (ab) tool
  - Ubuntu/Debian: `sudo apt-get install apache2-utils`
  - macOS: Included with macOS
- Either [DDEV](https://ddev.com/) or [Lando](https://lando.dev/)
- curl
- bc

## Getting Started

1. Clone the project locally
2. Optionally checkout a specific version: `git checkout tags/v0.1`
3. Start your environment and install Drupal using one of the methods below

### DDEV Setup
```sh
ddev start
ddev composer install
ddev drush si --yes --existing-config
./benchmark.sh ddev
```

### Lando Setup
```sh
lando start
lando drush si --yes --existing-config
./benchmark.sh lando
```

## Running Benchmarks

The benchmark script supports several parameters:

```sh
./benchmark.sh <ddev|lando> [concurrent] [requests] [urls_file]
```

Parameters:
- `ddev|lando`: Required. Specifies which local development environment to use
- `concurrent`: Optional. Number of concurrent users (default: 10)
- `requests`: Optional. Total number of requests per URL (default: 2000)
- `urls_file`: Optional. Path to file containing URLs to test (default: urls.txt)

Examples:
```sh
# Basic usage
./benchmark.sh ddev

# Custom concurrent users (20) and requests (1000)
./benchmark.sh lando 20 1000

# Using a custom URLs file
./benchmark.sh ddev 10 500 my-custom-urls.txt
```

## URLs Configuration

By default, the script tests these URLs:
- /admin/modules
- /admin/config
- /admin/content
- /node/add
- /admin/people

You can create a custom URLs file to test different paths:
```txt
# my-custom-urls.txt
/admin/modules
/node/1
/user
# Lines starting with # are ignored
```

## Results

Benchmark results are saved in a timestamped directory `benchmark_results_YYYYMMDD_HHMMSS` containing:
- Individual test results for each URL
- A summary file with key metrics including:
  - Requests per second
  - Mean time per request
  - Failed requests count
  - Total execution time

## Performance Tips

### DDEV Performance
[DDEV comes with Mutagen for file syncing built in](https://ddev.readthedocs.io/en/latest/users/performance/), which can make an environment on macOS multiple times faster. You can enable Mutagen for your local DDEV globally with:
```sh
ddev config global --mutagen-enabled
```

### Common Issues

If the benchmark script fails with "Failed to get login URL", ensure that:
1. You're in the correct project directory
2. Drupal is properly installed
3. Your development environment (DDEV/Lando) is running

## Contributing

Feel free to submit issues and pull requests for improvements to the benchmark script or documentation.
