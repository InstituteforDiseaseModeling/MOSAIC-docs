# MOSAIC-docs Style Guide

**Audience:** anyone (human or AI) editing the MOSAIC-docs bookdown site.
**Authority:** this document is binding. All `.Rmd` edits must conform.
**Maintained by:** John Giles.

The corpus has been written by one author with a strong, consistent voice and a meticulous math system. **Do not improvise on math or notation.** When in doubt, match the surrounding section verbatim and ask before introducing a new symbol.

---

## 1. Math conventions

### 1.1 Variable assignments — fixed and not to be reused

These are the canonical assignments used throughout the model description. Do not repurpose any of these symbols for a new quantity without explicit approval.

**State variables (Latin italic):**

| Symbol | Meaning |
|---|---|
| $S$ | Susceptible |
| $E$ | Exposed |
| $I_1$ | Symptomatic infectious |
| $I_2$ | Asymptomatic infectious |
| $R$ | Recovered |
| $V_1, V_2$ | One-/two-dose vaccinated |
| $V^{\text{imm}}_{1,jt}, V^{\text{sus}}_{1,jt}, V^{\text{inf}}_{1,jt}$ | Vaccinated sub-compartments (immune, still-susceptible, infected-tracking-only) |
| $W$ | Environmental reservoir |
| $N$ | Total population |
| $C, D, y$ | Observed cases, deaths, generic counts |

**Demographic rates:**

| Symbol | Meaning |
|---|---|
| $b_{jt}$ | Birth rate (lowercase) |
| $d_{jt}$ | Background mortality (lowercase) |
| $\mu_j$ | Cholera-specific CFR (subscript $j$ only, no $t$) |

**Parameters (Greek, fixed assignment):**

| Symbol | Role |
|---|---|
| $\beta_{jt}^{\text{hum}}, \beta_{jt}^{\text{env}}$ | Transmission rates (baseline $\beta_{j0}^{\text{hum}}, \beta_{j0}^{\text{env}}$) |
| $\gamma_1, \gamma_2$ | Recovery rates; $\gamma_{\mathrm{eff}}$ is the effective removal rate |
| $\sigma$ | Proportion symptomatic |
| $\iota$ | Incubation rate |
| $\omega_1, \omega_2$ | Vaccine waning rates |
| $\varepsilon$ | Natural-immunity waning rate — **always `\varepsilon`, never `\epsilon`** |
| $\phi_1, \phi_2$ | Vaccine effectiveness |
| $\nu_{1,jt}, \nu_{2,jt}$ | Vaccination delivery rates |
| $\zeta_1, \zeta_2$ | Shedding rates |
| $\delta_{jt}$ | Environmental decay rate |
| $\theta_j$ | WASH-mediated contact (subscript $j$ only) |
| $\tau_i$ | Departure probability (subscript $i$ = origin) |
| $\pi_{ij}$ | Diffusion $i\!\to\!j$ |
| $\rho$ | Proportion of suspected cases that are true infections |
| $\psi_{jt}$ | Environmental suitability |
| $\kappa$ | Concentration for 50% infection probability (ID₅₀) |
| $\alpha_1, \alpha_2$ | Force-of-infection exponents |
| $\Lambda_{j,t+1}, \Psi_{j,t+1}$ | Human / environmental force of infection (uppercase) |
| $\boldsymbol{\Theta}$ | Parameter vector (bold italic uppercase theta) |
| $\mathcal{L}, \mathcal{B}, \mathcal{H}_{jt}, \mathcal{C}_{ij}, \mathcal{G}, \mathcal{z}$ | Calligraphic: likelihood, best subset, hazard, coupling, generation interval, shedding ratio |

**Rule on introducing new symbols.** When MOSAIC-pkg adds a parameter without an existing math symbol (e.g., `rho_deaths`, `nu_jt_sources`), **propose** a candidate in the editing thread and **pause for approval** before writing it into a `.Rmd`. Do not silently invent notation.

**Rule on apparent symbol collisions.** When MOSAIC-pkg introduces a new prior for a parameter that already has a documented symbol (e.g., the new `kappa` literature-derived prior shares the role of the existing $\kappa$ for ID₅₀ concentration), treat it as the **same symbol** with an updated prior — do not introduce a parallel notation.

### 1.2 Subscript / superscript order — strict

- **Adjacent location + time**: no comma. $S_{jt}$, $N_{jt}$, $\beta_{jt}$.
- **Next-step time index**: comma inserted before $t+1$. $S_{j,t+1}$, $\Lambda_{j,t+1}$.
- **Multi-index parameters**: comma between the discrete index and the spatiotemporal index. $V^{\text{imm}}_{1,jt}$, $I_{1,jt}$, $\nu_{1,jt}$.
- **Origin–destination pairs**: no comma, no space. $\pi_{ij}$, $d_{ij}$.
- $J, T$ uppercase = total counts. Sums run $\sum_{j=1}^{J}$, $\sum_{t=1}^{T}$.

### 1.3 `\text{}` vs `\mathrm{}` — preserve section-local convention

The corpus is not uniform on this. Match the local section rather than retroactively standardize.

- **`\text{}`** dominates in older / system equations for compartment and transmission-rate superscripts (`\text{imm}`, `\text{sus}`, `\text{inf}`, `\text{hum}`, `\text{env}`, `\text{obs}`, `\text{est}`) and for units (`\text{days}`, `\text{cells}`).
- **`\mathrm{}`** dominates in newer sections (R-effective, spatial hazard, generation-time) for derived-quantity tags (`\gamma_{\mathrm{eff}}`, $R_{jt}^{\mathrm{intr}}$, $R_{jt}^{\mathrm{extr}}$) and for statistics ($\mathrm{VMR}$, $\mathrm{CV}$, $\mathrm{Var}$, $\mathrm{Mean}$). It also appears for distribution names in newer prose ($\mathrm{Exp}$, $\mathrm{Gamma}$).

**Rule:** when adding to an existing section, copy that section's choice. When writing an entirely new section, prefer `\text{}` for compartment/transmission-rate superscripts and units, and `\mathrm{}` for derived-quantity tags and statistical operators.

### 1.4 Hats / bars / tildes / stars

| Decoration | Meaning | Example |
|---|---|---|
| $\hat{x}$ / $\widehat{x}$ | Best-fit / estimated | $\hat{\boldsymbol{\Theta}}$, $\widehat{\text{ESS}}$, $\widehat{\delta}_j$ |
| $\bar{x}$ | Mean | $\bar y_{jt}, \bar\psi_j, \bar w, \bar\varepsilon$ |
| $\tilde{x}$ | Truncated / normalized weight | $\tilde{w}_i$, $\mathbf{\tilde{w}}$ |
| $x^{*}$ or $x^{\ast}$ | Pooled / effective compound quantity | $S^{*}_{jt}$, $I_{jt}^{\ast}$ |

Use `\widehat` for multi-letter hats; `\hat` for single letters.

### 1.5 Distribution notation

- $X \sim \text{Beta}(a, b)$ — **positional args, no $\alpha,\beta$ labels**
- $\sim \text{Uniform}(a, b)$
- $\sim \text{Gamma}(s, r)$ — Gamma is (shape, rate)
- $\sim \text{Lognormal}(\mu, \sigma)$
- $\sim \text{Binom}(n, p)$, $\sim \text{Pois}(\lambda)$
- $\sim \mathrm{Exp}(\lambda)$ in newer prose
- $\sim \text{Truncnorm}(\mu, \sigma, a, b)$ when adding truncated-normal priors (mean, sd, lower, upper)
- Density notation: $f(y \mid \mu)$, $P(\cdot \mid \cdot)$, $\log P(\cdot)$

### 1.6 Functions and operators

- $\log\mathcal{L}$, $\log\Gamma$, $\arg\max_{\boldsymbol{\Theta}}$, $\arg\min$
- $\mathbb{E}[\cdot]$ expectation, $\mathbb{V}[\cdot]$ variance, $\Pr(\cdot)$ probability
- $Q^{(\tilde w)}_p$ weighted quantile
- $\text{pbeta}(\psi_{jt}\mid s_1, s_2)$ Beta CDF
- $\text{Sigmoid}(\cdot)$, $\text{LSTM}(\cdot)$
- The shedding ratio is $\mathcal{z}$ (calligraphic z) — preserve, do not "fix" to italic $z$.

### 1.7 Units

- Full form, in math: `\text{cells}~\text{mL}^{-1}~\text{person}^{-1}~\text{day}^{-1}` (tildes for spaces, negative-exponent form, **never slashes**).
- Short form after a numeric: `0.2 \ \text{day}^{-1}`.
- Days inside fractions/composite expressions: `\text{days}_{\text{short}}`, `\text{days}_{\max}`.
- Confidence intervals in prose: `value (lo–hi 95% CI)` — e.g., `$0.64$ ($0.32$–$0.96$ 95% CI)`.

### 1.8 Equation environments

| Pattern | When to use |
|---|---|
| `\begin{equation} ... (\#eq:label) \end{equation}` | Labeled, cross-referenced equation |
| `\begin{equation}\begin{aligned} ... \end{aligned}\end{equation}` | Multi-line aligned system (e.g., the SVEIRWS difference equations, FOI partitions) |
| `\begin{cases} ... \end{cases}` | Piecewise definitions (gravity-model diagonal, AIC weight truncation) |
| `$$ ... $$` | Unlabeled inline display math (commonly prior specifications) |
| `\[ ... \]` | Used in newer sections (R-effective, generation time) for unlabeled displays — both forms are accepted |
| `\@ref(eq:name)` | In-text cross-reference to a labeled equation |

Section labels inside aligned systems use `\mathbf{\text{Label:}}` followed by spacing such as `\\[3mm]`.

---

## 2. Voice and prose

### 2.1 First-person plural — non-negotiable

Methodology is narrated in first-person plural: *"we describe", "we used", "we estimated", "we modeled", "we calculated", "our model", "our approach"*. The corpus is academic-paper voice with active verbs. Passive voice appears only where natural English requires it; never as a stylistic default.

### 2.2 Standard sentence frames

- After an equation: **"Where, $X$ is..."** or **"Where $X$ is..."** (the comma is optional — preserve whichever appears in the surrounding section)
- Caveats: **"Note that..."**
- Detail: **"Specifically..."**
- Conclusion: **"Therefore..."** / **"Thus..."**
- Construction: **"In this formulation..."** / **"This formulation..."**
- Hedging vocabulary: *approximately*, *likely*, *may*, *potentially*, *generally*, *typically*

### 2.3 Italics

- Scientific names always italicized: *V. cholerae*, *Vibrio cholerae*
- Defined-term emphasis: *brute-force random sampling*, *likelihood function*, *equi-dispersion*, *over-dispersed*
- Method names: *Markov-Chain Monte Carlo*, *Latin-hypercube*, *importance sampling*

### 2.4 Bold

- Equation system labels: `\mathbf{\text{Susceptible population:}}`
- Parameter sub-headings in prose: `**Symptomatic individuals ($\gamma_1$):**`
- Stochastic-transitions row headers: `**$\mathbf{S}$ (susceptible)**`
- Interpretation emphasis on a single word: `**slowest**`, `**high**`, `**low**`

### 2.5 Citations

**The corpus uses inline Markdown hyperlinks, not bookdown `[@key]` BibTeX citations**, even though `references.bib` exists. New citations must follow this pattern.

| Form | Example |
|---|---|
| `[Author Year](URL)` | `[Codeço 2001](https://doi.org/10.1186/1471-2334-1-1)` |
| `[Author (Year)](URL)` | `[Fung (2014)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3926264/)` |
| `[Author et al. Year](URL)` | `[Azman et al 2013](http://...)` |
| `[Author *et al.* Year](URL)` | `[Elvira *et al.* 2022](https://...)` — italicized in calibration section |
| `[Author & Coauthor Year](URL)` | `[Kahn & Marshall 1953](...)` |

Both `Author Year` and `Author (Year)` appear in the corpus. **Match the prevailing form in each surrounding paragraph** rather than impose one globally.

URL preference order: DOI > PMC > publisher landing > journal abstract > preprint.

### 2.6 Paragraph rhythm

- 2–5 sentences typical
- Long compound sentences with semicolons and em-dashes are normal
- Pattern: one idea → display equation or figure → defining/interpreting paragraph
- After an equation: a paragraph identifying its symbols and (often) a follow-up paragraph interpreting it

---

## 3. Document structure

### 3.1 Headings hierarchy

```
# Chapter title (one per .Rmd)
## Major section
### Subsection
#### Sub-subsection (rare)
```

### 3.2 Cross-references

- Equations: `Equation \@ref(eq:label)` or `Equations \@ref(eq:a) and \@ref(eq:b)`
- Figures: `Figure \@ref(fig:label)`
- Tables: `Table \@ref(tab:label)`
- Sections: prefer direct URL links to other pages of the site over `Section \@ref(label)` (current corpus practice)
- A code-chunk's label is also the figure/table label

### 3.3 Manual anchors for non-chapter links

```html
<div id="parameters-table"></div>
## Table of model parameters
```

Linked from prose as `[Table of model parameters](#parameters-table)`.

### 3.4 Figure chunks

```r
{r label, echo=FALSE, message=FALSE, warning=FALSE, cache=TRUE, fig.align='center', out.width="100%", fig.cap="Caption. Reference equations with \\@ref(eq:name) and inline math with \\$\\psi_{jt}\\$. Italicize *V. cholerae*."}
knitr::include_graphics("figures/filename.png")
```

- Captions: 1–3 sentences.
- Re-reference relevant equation.
- Italicize *V. cholerae* and use math symbols inline.
- `out.width` typically `"100%"`; occasionally `"95%"`, `"102%"`, `"103%"` for specific figures.

### 3.5 Tables

- Built with `knitr::kable` + `kableExtra::kable_styling`
- Options: `bootstrap_options = c("striped"/"hover", "condensed")`, `full_width = FALSE`
- Math inside cells requires `escape = FALSE` and `$...$` delimiters
- `add_header_above()` for grouped columns
- Captions match figure-caption tone

### 3.6 Cautions and notes

- An italicized standalone paragraph is used for important model caveats:
  *"Note that this initial version of the model is fitted to a rather small amount of data..."*
- A blockquote `> **Interpretation.** ...` appears in newer sections; reserved for short interpretive footnotes after multi-step derivations.

---

## 4. Hard rules — do NOT do these without asking

1. **Do not invent a math symbol** for a parameter that has only a code-name in MOSAIC-pkg. Propose a candidate and pause for approval.
2. **Do not re-derive an equation** beyond what the source code dictates. If MOSAIC-pkg or laser-cholera implements a formula, the docs version must match the implementation (modulo notation).
3. **Do not change an existing symbol** that's already documented. No retroactive rewrites of established notation.
4. **Do not switch citation style** to BibTeX (`[@key]`). The corpus is 100% inline Markdown links.
5. **Do not standardize the `\text{}` vs `\mathrm{}` choice retroactively.** Match the surrounding section.
6. **Do not use citation forms without a URL.** Every citation in the corpus is hyperlinked.
7. **Do not skip the "Where, $X$ is..." pattern** after introducing a new equation. Symbols must be defined immediately.
8. **Do not write to `references.bib` alone** when adding a citation — also add the inline Markdown hyperlink in the body.

---

## 5. Pre-flight checklist for every doc edit

Before committing a change to any `.Rmd`:

- [ ] All new symbols appear in the parameter table or are explicitly defined in prose with a "Where, $X$ is..." sentence.
- [ ] No existing symbol has been silently re-purposed.
- [ ] Equations match the implementation in MOSAIC-pkg or laser-cholera (verify by reading the relevant source file).
- [ ] Citations are inline Markdown hyperlinks with a DOI/PMC/publisher URL.
- [ ] Scientific names are italicized: *V. cholerae*, *Vibrio cholerae*.
- [ ] Figure/table cross-references use `\@ref(fig:name)` / `\@ref(tab:name)` / `\@ref(eq:name)`.
- [ ] First-person plural ("we") is used for methodology choices.
- [ ] `\varepsilon` is used (not `\epsilon`) for natural-immunity waning.
- [ ] Units are in negative-exponent form (`\text{day}^{-1}`), never slash form.
- [ ] Bookdown builds without errors: `Rscript -e "bookdown::render_book('index.Rmd')"`.

---

## 6. Reference exemplars

When unsure about voice or rigor, model new prose on these sections of `04-model-description.Rmd`:

- **Transmission dynamics** — canonical equation introduction, "Where, $X$ is..." pattern
- **Shedding of *V. cholerae*** — prior specification with literature table and uncertainty rationale
- **Spatial dynamics** (recently refreshed) — multi-equation derivation with interpretation
- **The spatial hazard** (recently refreshed) — newer `\mathrm{}` convention and `\[ \]` displays

For calibration-style writing, model on `05-model-calibration.Rmd` in full.

---

**End of style guide.** When in doubt, ask the maintainer before editing.
