# ETISdbaseRCode
R scripts for use in the Elephant Trade Information System [(ETIS) database](https://www.etis-testing.org). 

These scripts carry out data manipulations to obtain summary tables and plots of ETIS data for ETIS administrators and ETIS country reports.

These scripts were originally written by RW Burn under [Darwin Initiative Project 17-020](http://www.darwininitiative.org.uk/project/17020/) 

A major revision has been carried out by [Fiona M Underwood](http://www.fmunderwood.com)

The main revision is that the core set of manipulations - to calculate seizures and weights in and out for each country - now takes into consideration seizures with multiple countries of origin. This is complex and the code for this is now in a separate R package - [ETISdbase](https://github.com/fmunderwood/ETISdbase). The R scripts in this repository have been revised to use this new R package to create relevant plots and tables. In addition the R scripts have been updated to use RPostgreSQL rather than RODBC.

