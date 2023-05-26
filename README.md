# procedures_NextData

In the framework of the National Project of Interest NextData, we developed procedures for the flagging and formatting of trace gases, atmospheric aerosols and meteorological data to be submitted to the World Data Centers (WDCs) of the Global Atmosphere Watch program of the World Meteorological Organization (WMO/GAW). In particular, the atmospheric Essential Climate Variables (ECVs) covered in this work are observations of near-surface trace gas concentrations, aerosol properties and meteorological
variables, which are under the umbrella of the World Data Center for Greenhouse Gases (WDCGG), the World Data Center for Reactive Gases, and the World Data Center for Aerosol (WDCRG and WDCA). We developed an overarching processing chain to create a number of data products (data files and reports) starting from the raw data, finally contributing to increase the maturity of these measurements. To this aim, we implemented specific routines for data filtering, flagging, format harmonization, and creation of
data products, useful for detecting instrumental problems, particular atmospheric events and quick data dissemination towards stakeholders or citizens. Currently, the automatic data processing is active for a subset of ECVs at 5 measurement sites in Italy. The system represents a valuable tool to facilitate data originators towards a more efficient data production. Our effort is expected to accelerate the process of data submission to WMO/GAW or to other reference data centers or repositories. Moreover, the adoption of automatic procedures for data flagging and data correction allows to keep track of the process that led to the final validated data, and makes data evaluation and revisions more efficient by improving the traceability of the data production process.

Three different data levels are produces according with WMO/GAW WCDRG and WCDA data reporting guidelines (see also https://ebas-submit.nilu.no/Submit-Data/Data-Reporting):
*	Level-0: annotated raw data; format instrument specific; contains all parameters provided by the instrument; contains all parameters/info needed for processing to final value; "native" time resolution;
*	Level-1: data processed to final parameter (calibration and correction implemented to data series), invalid data and calibration episodes removed, "native" time resolution, normalization to standard temperature and pressure (i.e., 273.15 K, 1013.25 hPa) if necessary;
*	Level-2: data aggregated to hourly averages, atmospheric variability quantified by standard deviation or percentiles.
Generated Level-0, Level-1 and Level-2 files are formatted according to the NASA-Ames standard. The list of flags adopted is defined in the framework of ACTRIS-2 project (see https://ebas-submit.nilu.no/Submit-Data/Data-Reporting/Templates/Category/).

The automatic processing is executed by a set of three "R" scripts specifically designed for each instrument/ECV:
*	"P20" is the script devoted to the production of Level-0 data files
*	"P21" is the script devoted to the production of Level-1 and Level-2 data files
*	"P22" is the script devoted to the generation of data products 

All the developed scripts are virtually stand-alone and any hypotetical user, after installing an "R" environment, can use them on his/her own PC (both Linux or Windows) or server, for automatic and on-demand application. Of course, some activity of customization is needed by the users to properly set current directory paths, file names, etc etc.

All the developed procedures are further explained in the following publication:
Naitza, L., Cristofanelli, P., Marinoni, A., Calzolari, F., Roccato, F., Busetto, M., Sferlazzo, D., Aruffo, E., Di Carlo, P., Bencardino, M., D'Amore, F., Sprovieri, F., Pirrone, N., Dallo, F., Gabrieli, J., Vardè, M., Resci, G., Barbante, C., Bonasoni, P., and Putero, D.: Increasing the maturity of measurements of essential climate variables (ECVs) at Italian Atmospheric WMO/GAW Observatories by implementing automated data elaboration chains, Computers and Geosciences, 137, 104432, https://doi.org/10.1016/j.cageo.2020.104432, 2020.
