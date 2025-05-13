--- 
title: "MOSAIC: a spatial model of endemic cholera"
author: "John R Giles"
#date: "2024-08-16"
site: bookdown::bookdown_site
documentclass: book
bibliography: references.bib
# url: your book url like https://bookdown.org/yihui/bookdown
# cover-image: path to the social sharing image like images/cover.jpg
description: |
  This is a minimal example of using the bookdown package to write a book.
  The HTML output format for this example is bookdown::bs4_book,
  set in the _output.yml file.
biblio-style: apalike
csl: chicago-fullnote-bibliography.csl
nocite: '@*'
---

<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-DKRGVPD7GE"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-DKRGVPD7GE');
</script>

# {-}

<center><img src="./logo/logo.jpg" width="450" style="box-shadow: 3px 3px 3px lightgray; border: 0.1px solid gray;"></center>

\

<center><span style="color:#FF6347; font-size:13px;">*
Website under development. Last compiled on 2025-05-12 at  05:20 PM PDT.
*</span></center>

## Welcome {-}

Welcome to the **Metapopulation Outbreak Simulation with Agent-based Implementation for Cholera (MOSAIC)**. The MOSAIC framework simulates the transmission dynamics of cholera in Sub-Saharan Africa (SSA) and provides tools to understand the impact of interventions, such as vaccination, as well as large-scale drivers like climate change. MOSAIC is built using the Light-agent Spatial Model for ERadication (LASER) platform, and this site serves as documentation for the model's methods and associated analyses. Please note that MOSAIC is currently under development, so content may change regularly. We are sharing it here to increase visibility and welcome feedback on any aspect of the model.

## Contact {-}

MOSAIC is developed by a team of researchers at the Institute for Disease Modeling (IDM) dedicated to developing modeling methods and software tools that help decision-makers understand and respond to infectious disease outbreaks. This website is currently maintained by John Giles ([`@gilesjohnr`](https://github.com/gilesjohnr)). For general questions, contact John Giles (john.giles@gatesfoundation.org), Jillian Gauld (jillian.gauld@gatesfoundation.org), and/or Rajiv Sodhi (rajiv.sodhi@gatesfoundation.org). 

## Funding {-}

This work was developed at the Institute for Disease Modeling in support of funded research grants made by the Bill & Melinda Gates Foundation.

<center>
<img src="./logo/idmod-logo-1.jpg" width="300" style="margin: 20px 20px;">
<img src="./logo/Logotype_dark.png" width="300" style="margin: 20px 20px;">
</center>

<center><span style="color:#808080; font-size:13px;">
&copy; 2024 Bill & Melinda Gates Foundation. All rights reserved.
</span></center>
