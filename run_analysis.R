library(data.table)
library(dplyr)

path <- getwd()

#download data
url <- 'https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip'
f <- 'Dataset.zip'
if(!file.exists(f)) {download.file(url,f)}
d <- 'UCI HAR Dataset'
if(!file.exists(d)) {unzip(f)}

#read subjects
dtSubjTrain <- data.table(read.table(file.path(path, d, 'train', 'subject_train.txt')))
dtSubjTest <- data.table(read.table(file.path(path, d, 'test', 'subject_test.txt')))
dtSubj <- rbind(dtSubjTrain, dtSubjTest)
names(dtSubj) <- c('Subject')
remove(dtSubjTrain,dtSubjTest)

#read activities
dtActTrain <- data.table(read.table(file.path(path, d, 'train','Y_train.txt')))
dtActTest <- data.table(read.table(file.path(path,d,'test','Y_test.txt')))
dtAct <- rbind(dtActTrain,dtActTest)
names(dtAct) <- c('Activity')
remove(dtActTrain,dtActTest)

#combine subject and activity
dtSubj <- cbind(dtSubj,dtAct)
remove(dtAct)

#read feature data
dtTrain <- data.table(read.table(file.path(path,d,'train','X_train.txt')))
dtTest <- data.table(read.table(file.path(path,d,'test','X_test.txt')))
dt <- rbind(dtTrain,dtTest)
remove(dtTrain,dtTest)

#merge into one table
dt <- cbind(dtSubj,dt)
setkey(dt,Subject,Activity)
remove(dtSubj)

#read feature names
dtFeats <- data.table(read.table(file.path(path,d,'features.txt'))) 
names(dtFeats) <- c('ftNum','ftName')
dtFeats <- dtFeats[grepl("mean\\(\\)|std\\(\\)",ftName)]
dtFeats$ftCode <- paste('V', dtFeats$ftNum, sep = "")
dt <- dt[,c(key(dt), dtFeats$ftCode),with=F]

#rename columns
setnames(dt, old=dtFeats$ftCode, new=as.character(dtFeats$ftName))

#read activity names
dtActNames <- data.table(read.table(file.path(path, d, 'activity_labels.txt')))
names(dtActNames) <- c('Activity','ActivityName')
dt <- merge(dt,dtActNames,by='Activity')
remove(dtActNames)

dtTidy <- dt %>% group_by(Subject, ActivityName) %>% summarise_each(funs(mean))
dtTidy$Activity <- NULL

names(dtTidy) <- gsub('^t', 'time', names(dtTidy))
names(dtTidy) <- gsub('^f', 'frequency', names(dtTidy))
names(dtTidy) <- gsub('Acc', 'Accelerometer', names(dtTidy))
names(dtTidy) <- gsub('Gyro','Gyroscope', names(dtTidy))
names(dtTidy) <- gsub('mean[(][)]','Mean',names(dtTidy))
names(dtTidy) <- gsub('std[(][)]','Std',names(dtTidy))
names(dtTidy) <- gsub('-','',names(dtTidy))

write.table(dtTidy, file.path(path, 'tidy.txt'), row.names=FALSE)
