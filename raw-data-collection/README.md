# Collection of defect data

We used [SmartSHARK](https://smartshark.github.io) for the collection of defect paper for the experiments of this projects. SmartSHARK uses various plug-ins for data collection and stores all data in a MongoDB, which can then be used to run analysis. This allows convenient linking between different parts of a project, e.g., the issue tracker and the version control system. Unfortunetely, we cannot publish the collected raw data due to data privacy concerns as it contains email addresses of developers. However, we can describe the step-by-step procedure to replicate our data collection. 

# Step 1: Collect version control data

We used the [vcsSHARK](https://github.com/smartshark/vcsSHARK) to collect data about the commit history. The README of the vcsSHARK descibes how the tool can be [installed](https://github.com/smartshark/vcsSHARK#installation) and how data can be [collected for a project](https://github.com/smartshark/vcsSHARK#tutorial). 

Through the vcsSHARK, we get the commit messages as well as the files that were changed as part of each commit. 

# Step 2: Collect the issue tracking data

We used the [issueSHARK](https://github.com/smartshark/issueSHARK) to collect data about the issues of a project. The README of the issueSHARK describes how the tool can be [installed](https://github.com/smartshark/issueSHARK#installation) and how data can be [collected from JIRA](https://github.com/smartshark/issueSHARK#tutorial).

Through the issueSHARK, we get the issues, most importantly their IDs, their type, and their status. 

# Step 3: Link commits to issues

We used the [linkSHARK](https://github.com/smartshark/linkSHARK) to create links between issues and commits based on the commit message. The README of the linkSHARK describes how the tool can be [installed](https://github.com/smartshark/linkSHARK#install) and how [links can be created for a project](https://github.com/smartshark/linkSHARK#execution-for-smartshark). 

We use a regular expression to identify candidate terms in commit messages for issue links: 
```
'(?P<ID>[A-Z][A-Z0-9_]+-[0-9]+)'
```

We then check for each matched term, if we find an issue with a matching id. If we find the issue, we create the link. The linkSHARK can deal with broken links through typos or otherwise wrong usage of the issue IDs, to improve the issue linking. To following broken links were fixed for the projects in our case study. 

| Project | Correct Key | Broken Keys |
|---------|-------------|-------------|
| zeppelin | ZEPPELIN | ZPPELIN,ZZEPPELIN,ZEPPELING,ZPEPELIN,ZEPELIN,ZEP,ZEPPEILN |
| falcon | FALCON | FACLON,FACON |
| nutch | NUTCH | NJTCH,NUTH,UTCH |
| kylin | KYLIN | KYILN |
| deltaspike | DELTASPIKE | DELSTASPIKE,DELTASSPIKE,DELTASPILE,DELTAPIKE,DELTESPIKE |
| tez | TEZ | EZ |
| storm | STORM | STROM,YSTROM,TORM,STRM,STOMR |

# Step 4: Identify bugfixing commits

We used the [labelSHARK](https://github.com/smartshark/labelSHARK) to identify bugfixing commits. The README of the labelSHARK describes how the tool can be [installed](https://github.com/smartshark/labelSHARK#install) and how [labels can be created for a project](https://github.com/smartshark/labelSHARK#execution-for-smartshark). 

We are interested in the issueonly_bugfix label that the labelSHARK generates. These are generated using the following rule:
- The issue type is of type BUG and
- The status of the issue was closed or resolved at any point in its history.
- The issue resolution is FIXED.

# Step 5: Get the size of files

We used the [mecoSHARK](https://github.com/smartshark/mecoSHARK) to collect software metrics, because we required the lines of code to allow simulations of the size-aware cost model. The README of the mecoSHARK descibes how the tool can be [installed](https://github.com/smartshark/mecoSHARK#installation) and how [metric data can be collected for a project](https://github.com/smartshark/mecoSHARK#tutorial).

# Step 6: Extract CSV files from the database

We wrote a [python script](generate_csvfiles.py) that uses the collected data and creates the CSV files we use from the case study. The script traverses the main branch of each project and collects the latest commit for each project in the year 2017. For this commit, the JAVA files are collected from the database. These files are the foundation of the defect data set, and the lines in the CSV files. We then traverse all commits for the project from the year 2017 and identify the bugfixing commit. For each bugfixing commit that actually touched a JAVA file, we added a column to the CSV file, which contains a 1 for each file that was changed during a bugfix, and 0 for each file that was not touched. This is similar to a standard SZZ approach, except that we do not look into the past to determine when the bug was introduced and, thereby, try to create a defect prediction data set for concrete revision.
