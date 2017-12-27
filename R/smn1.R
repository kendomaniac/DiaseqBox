#' @title A function to handle the detection of mutation in SMN1 gene
#' @description This function executes a docker that produces as output for the PG SMN1 pipeline
#' @param group, a character string. Two options: sudo or docker, depending to which group the user belongs
#' @param scratch.folder, a character string indicating the path of the scratch folder
#' @param data.folder, a character string indicating the folder where input data are located and where output will be written
#' @param threads, number of processors to be used in the analysis
#' @author Raffaele Calogero,raffaele.calogero [at] unito [dot] com, University of Torino
#' 
#' @examples
#' \dontrun{
#'     system("wget http://130.192.119.59/public/smn1_test.zip")
#'     unzip(smn1_test.zip)
#'     system("cd smn1_test/110259_deleted")
#'     #running smn1
#'     smn1(group="docker", scratch.folder="/data/scratch", data.folder=getwd(), threads=4)
#' }
#'
#' @export
smn1 <- function(group=c("sudo","docker"), scratch.folder, data.folder, threads=4){

  #testing if docker is running
  test <- dockerTest()
  if(!test){
    cat("\nERROR: Docker seems not to be installed in your system\n")
    return(1)
  }
  #storing the position of the home folder  
  home <- getwd()
  
  #running time 1
  ptm <- proc.time()
  #setting the data.folder as working folder
  if (!file.exists(data.folder)){
    cat(paste("\nIt seems that the ",data.folder, " folder does not exist\n"))
    return(2)
  }
  setwd(data.folder)
  #check  if scratch folder exist
  if (!file.exists(scratch.folder)){
    cat(paste("\nIt seems that the ",scratch.folder, " folder does not exist\n"))
    return(3)
  }
  #getting info on data 
  dir <- dir(data.folder)
  if(length(grep("fastq.gz$", dir))!=2){
    cat("It seems that fastq.gz files are missing")
    return(4)
  }else{
    fastq.names <- NULL
    fastq.loc <- grep("fastq.gz$", dir)
    for(i in 1:length(fastq.loc)){
      fastq.names[i] <- dir[fastq.loc[i]]
    }
  }
  if(length(grep("idinfo.txt$", dir))!=1){
    cat("It seems that idinfo.txt file is missing")
    return(5)
  }  
  tmp.folder <- gsub(":","-",gsub(" ","-",date()))
  scrat_tmp.folder=file.path(scratch.folder, tmp.folder)
  writeLines(scrat_tmp.folder,paste(data.folder,"/tempFolderID", sep=""))
  cat("\ncreating a folder in scratch folder\n")
  dir.create(file.path(scrat_tmp.folder))
  system(paste("cp *.fastq.gz ", scrat_tmp.folder,sep=""))
  system(paste("cp idinfo.txt ", scrat_tmp.folder,sep=""))
  #executing the docker job
  if(group=="sudo"){
    params <- paste("--cidfile ",data.folder,"/dockerID -v ",scrat_tmp.folder,":/scratch -v ", data.folder, ":/data -d docker.io/rcaloger/diaseqbox.2017.01 sh /bin/SMN1_CNV/bin/mapNEB.sh /bin/SMN1_CNV/ref/panel_1_merged_6_noSMN2.slop250.fasta ", fastq.names[1], " ", fastq.names[2], " ", threads, sep="")
    resultRun <- runDocker(group="sudo",container="docker.io/rcaloger/diaseqbox.2017.01", params=params)
  }else{
    params <- paste("--cidfile ",data.folder,"/dockerID -v ",scrat_tmp.folder,":/scratch -v ", data.folder, ":/data -d docker.io/rcaloger/diaseqbox.2017.01 sh /bin/SMN1_CNV/bin/mapNEB.sh /bin/SMN1_CNV/ref/panel_1_merged_6_noSMN2.slop250.fasta ", fastq.names[1], " ", fastq.names[2], " ", threads, sep="")
    resultRun <- runDocker(group="docker",container="docker.io/rcaloger/diaseqbox.2017.01", params=params)
  }
  #waiting for the end of the container work
  if(resultRun=="false"){
    system(paste("rm ", scrat_tmp.folder, "/*.fastq.gz ", sep=""))
    system(paste("cp ", scrat_tmp.folder, "/* ", data.folder, sep=""))
  }
  #running time 2
  ptm <- proc.time() - ptm
  dir <- dir(data.folder)
  dir <- dir[grep("run.info",dir)]
  if(length(dir)>0){
    con <- file("run.info", "r")
    tmp.run <- readLines(con)
    close(con)
    tmp.run[length(tmp.run)+1] <- paste("SMN1 user run time mins ",ptm[1]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("SMN1 system run time mins ",ptm[2]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("SMN1 elapsed run time mins ",ptm[3]/60, sep="")
    writeLines(tmp.run,"run.info")
  }else{
    tmp.run <- NULL
    tmp.run[1] <- paste("SMN1 run time mins ",ptm[1]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("SMN1 system run time mins ",ptm[2]/60, sep="")
    tmp.run[length(tmp.run)+1] <- paste("SMN1 elapsed run time mins ",ptm[3]/60, sep="")

    writeLines(tmp.run,"run.info")
  }

  #saving log and removing docker container
  container.id <- readLines(paste(data.folder,"/dockerID", sep=""), warn = FALSE)
  system(paste("docker logs ", substr(container.id,1,12), " &> ",data.folder,"/", substr(container.id,1,12),".log", sep=""))
  system(paste("docker rm ", container.id, sep=""))
  #removing temporary folder
  cat("\n\nRemoving the temporary file ....\n")
  system(paste("rm -R ",scrat_tmp.folder))
  system("rm -fR out.info")
  system("rm -fR dockerID")
  system("rm  -fR tempFolderID")
  system(paste("cp ",paste(path.package(package="DiaseqBox"),"containers/containers.txt",sep="/")," ",data.folder, sep=""))
  setwd(home)
}
