# DiaseqBox
A collection of functions to execute molecular genetics analysis based on Illumina short reads panels.
To install it you can use use **devtools**, after you have requested an access token to raffaele[dot]calogero[at]unito[dot]it:
```
install.packages("devtools")
library(devtools)
install_github("kendomaniac/DiaseqBox", ref="master", auth_token="replace this text with the token")
```

## Requirements
You need to have docker installed on your machine, for more info see this document:
https://docs.docker.com/engine/installation/. 
**DiaseqBox** package is expected to run on 64 bits linux machine with at least 4 cores and 16 Gb RAM.
A scratch folder should be present, e.g. /data/scratch and it should be writable from everybody:
```
chmod 777 /data/scratch
```
The functions in DiaseqBox package require that user is sudo or part of a docker group.
See the following document for more info:
https://docs.docker.com/engine/installation/linux/ubuntulinux/#/manage-docker-as-a-non-root-user

**IMPORTANT** The first time *DiaseqBox* is installed the **downloadContainers** needs to be executed  to download to the local repository the containers that are needed for the use of *DiaseqBox*


