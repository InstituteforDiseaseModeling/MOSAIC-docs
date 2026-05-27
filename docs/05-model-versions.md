<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-DKRGVPD7GE"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-DKRGVPD7GE');
</script>

# Model versions

\begin{table}

\caption{(\#tab:unnamed-chunk-1)Current and future planned model versions with brief descriptions.}
\centering
\begin{tabular}[t]{l|l}
\hline
Version & Description\\
\hline
v0.1 & **Past:** Initial beta release in R. Established the SVEIWRS compartmental structure, the mobility and environmental transmission terms, and the observation process.  Used to scope data sources and parameter priors prior to the LASER port.\\
\hline
v1.0 & **Current:** First production implementation. The transmission engine runs in the Python [laser-cholera](https://github.com/InstituteforDiseaseModeling/laser-cholera) metapopulation model, driven by the R [MOSAIC](https://github.com/InstituteforDiseaseModeling/MOSAIC-pkg) package for data assembly, parameter sampling, and Bayesian calibration via Dask. Priors for all biological parameters are now literature-derived (shedding, ID\textasciitilde{}50\textasciitilde{}, decay, CFR), and the calibration pipeline produces best, medioid, and ensemble forecasts with importance-sampling weights, effective sample size, and agreement-index diagnostics.\\
\hline
v2.0 & **Future:** Maximizing the metapopulation approach. District-level data and improvements to model fitting via hierarchical likelihoods.\\
\hline
v3.0 & **Future:** Agent-based component with richer immune dynamics, including biphasic vaccine waning and individual-level exposure history.\\
\hline
\end{tabular}
\end{table}



