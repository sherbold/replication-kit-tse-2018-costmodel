Introduction
============
Within this archive you find the replication package for the paper "On the costs and return on investment of software defect prediction" by Steffen Herbold which is currently under review. The aim of this replication package is to allow other researchers to replicate our results with minimal effort. 

Requirements
============
- R (tested with Version 3.5.1)

Contents
========
This archive contains:
- The directory R-Code with the R script for executing the simulation and generating plots for the simulation results.
- The directory result-plots with plots for all parameter combinations that were executed for our experiments. 
- The directory data with CSV files that contain the bug data for 16 projects for the year 2017 on file level
- The directory raw-data-collection that contains information on how the CSV files with the bug data can be generated from scratch

How does it work?
=================
To replicate our simulation experiment, you have to run the [simulation.R](R-Code/simulation.R) script contained within the R-Code folder. The only manual intervention required is the adoption of the directories, where the data is located and where the plots should be generated to. These should be set to the location of the replication kit in your local environment. 

License
=======
This replication package is used are licensed under the Apache License, Version 2.0. 
