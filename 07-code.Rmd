<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-DKRGVPD7GE"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-DKRGVPD7GE');
</script>

# Code

The MOSAIC framework is open source. The implementation is split across two repositories: an R package that handles data assembly, parameter sampling, and Bayesian calibration, and a Python package that runs the metapopulation simulation engine.

## Source repositories

- **[MOSAIC-pkg](https://github.com/InstituteforDiseaseModeling/MOSAIC-pkg)** --- the R package that prepares data, samples from priors, runs ensembles, computes importance-sampling weights, and produces every figure and table on this site. Function reference and vignettes are published at [institutefordiseasemodeling.github.io/MOSAIC-pkg](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/).
- **[laser-cholera](https://github.com/InstituteforDiseaseModeling/laser-cholera)** --- the Python metapopulation transmission engine, built on the [LASER](https://github.com/InstituteforDiseaseModeling/laser) platform. MOSAIC-pkg calls it through `reticulate`.
- **[MOSAIC-data](https://github.com/InstituteforDiseaseModeling/MOSAIC-data)** --- processed inputs used by MOSAIC-pkg. Raw inputs are local-only.
- **[open-meteo-pipeline](https://github.com/InstituteforDiseaseModeling/open-meteo-pipeline)** and **[enso-data](https://github.com/InstituteforDiseaseModeling/enso-data)** --- upstream climate-data pipelines feeding MOSAIC (see the [Data](#data) chapter).

## Installation

A complete walk-through (R, Python, JAGS, geospatial dependencies) lives in the package's own [Installation vignette](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/articles/Installation.html). In brief:

```r
# Install MOSAIC-pkg from GitHub
remotes::install_github("InstituteforDiseaseModeling/MOSAIC-pkg")

# Install the laser-cholera Python wheel into the R-managed environment
MOSAIC::install_dependencies()

# Verify
MOSAIC::check_dependencies()
```

## Running the model

The two driver vignettes cover the typical workflows end-to-end:

- **[Running MOSAIC](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/articles/Running-MOSAIC.html)** --- the calibration pipeline: prior sampling, Dask-parallel forward simulation, importance-sampling weights, and best / medioid / ensemble forecasts.
- **[Running LASER](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/articles/Running-LASER.html)** --- a single deterministic or stochastic simulation of the metapopulation engine for a chosen configuration.

A minimal LASER call from R looks like this:

```r
lc <- reticulate::import("laser.cholera")
model <- lc$metapop$model$run_model(paramfile = params, seed = seed)
```

Note that the Python namespace is `laser.cholera` (since laser-cholera 0.11, when the package was migrated to a namespace package and the build system switched to `uv`). Older code using `laser_cholera` will need to be updated.

## Deployment at scale

Production-scale calibration runs are dispatched to a Dask cluster. The [Deployment vignette](https://institutefordiseasemodeling.github.io/MOSAIC-pkg/articles/Deployment.html) covers Azure-style parallel execution, including the threading-environment setup required to avoid fork-related deadlocks between Numba (in laser-cholera) and the Dask worker pool.
