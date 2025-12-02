# Drupal Benchmark

This project is based on the [template for Drupal projects](https://github.com/wunderio/drupal-project) by [Wunder](https://wunder.io/) and meant for benchmarking a local Drupal development environment (either [Lando](https://lando.dev/) or [DDEV](https://ddev.com/)) with the open source load testing tool [Locust](https://locust.io/).

**View the live results on the [Public Dashboard](https://drupal-benchmark.vercel.app/).**

See the aforementioned mentioned template for more detailed documentation.

## Requirements

- [Python 3.13.1](https://www.python.org/downloads/release/python-3131/) (recommended install via [pyenv](https://github.com/pyenv/pyenv) with `pyenv install`)
- [Locust](https://locust.io/) (install with `pip install locust`)
- [Lando](https://lando.dev/) or [DDEV](https://ddev.com/)

## Getting started

- Clone the project locally
- Optionally checkout a specific version, for example: `git checkout tags/v1.0`
- Start your environment (Drupal will be automatically installed)

## Benchmark Scripts

This project provides two different benchmark scripts:

### `benchmark.sh` - Local Benchmark Only
Runs a simple benchmark locally without submitting results anywhere. Perfect for quick testing.

```sh
./benchmark.sh ddev
# or
./benchmark.sh lando
```

### `benchmark-submit.sh` - Benchmark with Submission
Runs a benchmark and submits results to the [Public Dashboard](https://drupal-benchmark.vercel.app/). This script:
- Collects system metadata (OS, CPU, memory, versions, etc.)
- Prompts for computer model and additional comments
- Submits results automatically
- Clears cache to refresh the dashboard

```sh
./benchmark-submit.sh ddev
# or
lando start && ./benchmark-submit.sh lando
```

This project comes with [Lando](https://lando.dev/) and [DDEV](https://ddev.com/) environments preconfigured. Please find more detailed examples for running the benchmark in these environments below.

### Lando

```sh
lando start
./benchmark.sh lando          # Local testing only
./benchmark-submit.sh lando   # Submit to dashboard
```

### DDEV

```sh
./benchmark.sh ddev           # Local testing only
./benchmark-submit.sh ddev    # Submit to dashboard
```

> **Note:** Both DDEV and Lando automatically installs Composer dependencies and
set up Drupal with existing configuration via post-start hooks. No manual setup
required!

## Developing frontend

### Enable development mode.

By default, benchmark results are sent to the public dashboard. For development, you can enable local mode:

```sh
echo "BENCHMARK_ENV=dev" >> .ddev/.env && ddev restart
```

This will make the benchmark-submit script send data to your local Next.js frontend instead of the public endpoint.

Data is still sent to [Supabase](https://supabase.com/), but into a separate dev database.

### Install frontend

```sh
cd next && ddev npm install
```

### Run frontend

```sh
ddev npm run dev
```

### Visit frontend

Visit at: https://frontend.drupal-benchmark.ddev.site/
