<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-DKRGVPD7GE"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-DKRGVPD7GE');
</script>

# Code

The MOSAIC framework is open source. The implementation lives in an R package that handles data assembly, parameter sampling, simulation, and Bayesian calibration. The transmission engine is written in R; Python is used only by the environmental-suitability model (Keras/TensorFlow, called through `reticulate`).

## Source repositories

- **[MOSAIC-pkg](https://github.com/InstituteforDiseaseModeling/MOSAIC-pkg)** --- the R package that prepares data, samples from priors, runs the metapopulation transmission engine (`run_simulation()`), computes importance-sampling weights, and produces every figure and table on this site. Function reference and vignettes are published at [institutefordiseasemodeling.github.io/MOSAIC-pkg](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/).
- **[laser-cholera](https://github.com/InstituteforDiseaseModeling/laser-cholera)** --- the Python metapopulation engine, built on the [LASER](https://github.com/InstituteforDiseaseModeling/laser) platform, from which the R engine was ported. MOSAIC-pkg no longer calls it (from MOSAIC-pkg v0.69.0); it remains the historical reference implementation.
- **[MOSAIC-data](https://github.com/InstituteforDiseaseModeling/MOSAIC-data)** --- processed inputs used by MOSAIC-pkg. Raw inputs are local-only.
- **[open-meteo-pipeline](https://github.com/InstituteforDiseaseModeling/open-meteo-pipeline)** and **[enso-data](https://github.com/InstituteforDiseaseModeling/enso-data)** --- upstream climate-data pipelines feeding MOSAIC (see the [Data](#data) chapter).

## Installation

A complete walk-through (R, Python, JAGS, geospatial dependencies) lives in the package's own [Installation vignette](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/articles/Installation.html). In brief:

```r
# Install MOSAIC-pkg from GitHub
remotes::install_github("InstituteforDiseaseModeling/MOSAIC-pkg")

# Optional: the Python (Keras/TensorFlow) environment used only by the
# environmental-suitability model. Simulation and calibration do not need it.
MOSAIC::install_dependencies()

# Verify
MOSAIC::check_dependencies()
```

## Running the model

The driver vignettes cover the typical workflows end-to-end:

- **[Running simulations](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/articles/Running-simulations.html)** --- a single stochastic simulation of the metapopulation engine for a chosen configuration.
- **[Running MOSAIC](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/articles/Running-MOSAIC.html)** --- the calibration pipeline: prior sampling, parallel forward simulation, importance-sampling weights, and the medoid and ensemble forecasts.

A minimal simulation call from R looks like this:

```r
library(MOSAIC)
model <- run_simulation(config = MOSAIC::config_default, seed = 123)
reported_cases <- model$results$reported_cases
```

## Deployment at scale

Calibration runs are parallelised across the cores of one machine with a local PSOCK cluster of R worker processes; the BLAS and OpenMP thread-count environment variables are pinned to 1 in each worker so that the workers do not oversubscribe the cores. The [Deployment vignette](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/articles/Deployment.html) covers setting up a large virtual machine for production runs.
