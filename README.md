# Drupal Benchmark

This project is based on the [template for Drupal projects](https://github.com/wunderio/drupal-project) by [Wunder](https://wunder.io/) and meant for benchmarking a local Drupal development environment (either [Lando](https://lando.dev/) or [DDEV](https://ddev.com/)) with the open source load testing tool [Locust](https://locust.io/).

See the aforementioned mentioned template for more detailed documentation.

## Requirements

- [Python 3.13.1](https://www.python.org/downloads/release/python-3131/) (recommended install via [pyenv](https://github.com/pyenv/pyenv) with `pyenv install`)
- [Locust](https://locust.io/) (install with `pip install locust`)
- [Lando](https://lando.dev/) or [DDEV](https://ddev.com/)

## Getting started

- Clone the project locally
- Optionally checkout a specific version, for example: `git checkout tags/v1.0`
- Start your environment and build Drupal
- Run a benchmark with `./benchmark.sh lando` or `./benchmark.sh ddev`

This project comes with [Lando](https://lando.dev/) and [DDEV](https://ddev.com/) environments preconfigured. Please find more detailed examples for running the benchmark in these environments below.

### Lando

```sh
lando start && lando drush si --yes --existing-config
./benchmark.sh lando
```

### DDEV

```sh
ddev start && ddev composer install && ddev drush si --yes --existing-config
./benchmark.sh ddev
```

## Developing frontend

### Enable development mode.

By default, benchmark results are sent to the public dashboard. For development, you can enable local mode:

```sh
echo "BENCHMARK_ENV=dev" >> .ddev/.env && ddev restart
```

This will make the benchmark script send data to your local Next.js frontend instead of the public endpoint.

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
