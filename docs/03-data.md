<!-- Google tag (gtag.js) -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-DKRGVPD7GE"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){dataLayer.push(arguments);}
  gtag('js', new Date());

  gtag('config', 'G-DKRGVPD7GE');
</script>

# Data

The MOSAIC model requires a diverse set of data sources, some of which are directly used to define model parameters (e.g., birth and death rates), while others help fit models a priori and provide informative priors for the transmission model. As additional data sources become available, future versions of the model will adapt to incorporate them. For now, the following data sources represent the minimum requirements to initiate a viable first model.

## Historical Incidence and Deaths

Data on historical cholera incidence and deaths are crucial for establishing baseline transmission patterns. We compiled the annual total reported cases and deaths for all AFRO region countries from January 1970 to August 2024. These data comes from several sources which include:


1. **Our World in Data (1970-2021)**: [Number of Reported Cases of Cholera (1949-2021)](https://ourworldindata.org/grapher/number-reported-cases-of-cholera) and the [Number of Reported Deaths of Cholera from (1949-2021)](https://ourworldindata.org/grapher/number-of-reported-cholera-deaths). The Our World in Data group compiled these data from previously published annual WHO reports. 
2. **WHO Annual Report 2022**: These data were manually extracted from the World Health Organization's [Weekly Epidemiological Record](https://www.who.int/publications/journals/weekly-epidemiological-record) No 38, 2023, 98, 431–452.
3. **Global Cholera and Acute Watery Diarrhea Dashboard (2023-2024)**: Unofficial tallies of reported cases and deaths for 2023 and part of 2024 are available at the [WHO Global Cholera and AWD Dashboard](https://who-global-cholera-and-awd-dashboard-1-who.hub.arcgis.com/).


## Recent Incidence and Deaths

To capture recent cholera trends, we retrieved reported cases and deaths data from the [WHO Global Cholera and Acute Watery Diarrhea Dashboard](https://who-global-cholera-and-awd-dashboard-1-who.hub.arcgis.com/) REST API. These data provide weekly incidence and deaths from January 2023 to August 2024 which provides up-to-date counts at the country level.

## Vaccinations

Accurate data on oral cholera vaccine (OCV) campaigns and vaccination history are vital for understanding the impact of vaccination efforts. These data come from:

- **WHO Cholera Vaccine Dashboard**: This resource ([link](https://www.who.int/groups/icg/cholera)) provides detailed information on OCV distribution and vaccination campaigns from 2016 to 2024.
- **GTFCC OCV Dashboard**: Managed by Médecins Sans Frontières, this dashboard ([link](https://apps.epicentre-msf.org/public/app/gtfcc)) tracks OCV deployments globally, offering granular insights into vaccination efforts from 2013 to 2024.

## Human Mobility Data

Human mobility patterns significantly influence cholera transmission. Relevant data include:

- **OAG Passenger Booking Data**: This dataset ([link](https://www.oag.com/passenger-booking-data)) offers insights into air passenger movements, which can be used to model the spread of cholera across regions.
- **Namibia Call Data Records**: An additional source from Giles et al. (2020) ([link](https://www.pnas.org/content/117/36/22572)) provides detailed mobility data based on mobile phone records, useful for localized modeling.

## Climate Data

Climate conditions, including temperature, precipitation, and extreme weather events, play a critical role in cholera dynamics. These are captured through:

- **OpenMeteo Historical Weather Data API**: This API ([link](https://open-meteo.com/en/docs/historical-weather-api)) offers access to historical climate data, which is essential for modeling the environmental factors influencing cholera outbreaks.

### Storms and Floods

Data on extreme weather events, specifically storms and floods, are obtained from:

- **EM-DAT International Disaster Database**: Maintained by the Centre for Research on the Epidemiology of Disasters (CRED) at UCLouvain, this database ([link](https://www.emdat.be/)) provides comprehensive records of disasters from 2000 to the present, including those affecting African countries.

## WASH (Water, Sanitation, and Hygiene)

Data on water, sanitation, and hygiene (WASH) are critical for understanding the environmental and infrastructural factors that influence cholera transmission. These data are sourced from:

- **WHO UNICEF Joint Monitoring Program (JMP) Database**: This resource ([link](https://washdata.org/data/household)) offers detailed information on household-level access to clean water and sanitation, which is integral to cholera prevention efforts.

## Demographics

Demographic data, including population size, birth rates, and death rates, are foundational for accurate disease modeling. These data are sourced from:

- **UN World Population Prospects 2024**: This database ([link](https://population.un.org/wpp/Download/)) provides probabilistic projections of key demographic metrics, essential for estimating population-level impacts of cholera.

