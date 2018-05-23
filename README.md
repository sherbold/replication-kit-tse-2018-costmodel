Introduction
============
Within this archive you find the replication package for the paper "On the costs and return on investment of software defect prediction" by Steffen Herbold which is currently under review. The aim of this replication package is to allow other researchers to replicate our results with minimal effort. 

Requirements
============
- R (tested with Version 3.3.3)

Contents
========
This archive contains:
- The directory R-Code with the R scripts for executing the simulation, generating plots for the simulation results, as well as the results from our simulation as an Rdata file.
- The directory result-plots with plots for all parameter combinations that were executed for our experiments. 

How does it work?
=================
To replicate our simulation experiment, you have to run the [simulations.R](R-Code/simulations.R) script contained within the R-Code folder. The only manual intervention required is the adoption of the working directory, which must be set to the location of the R-Code folder in your local environment. Similarly, plots can be generated by setting the working directory in the [plots.R](R-Code/plots.R) script and executing the R code. 

License
=======
This replication package as well as the CrossPare software that is used are licensed under the Apache License, Version 2.0. 
