#-----------------------------------------------------------------------------
# LOADING PACKAGES:

library(dplyr)

library(tidyr)

#-----------------------------------------------------------------------------
# MERGING TEST AND TRAINING SETS:

test_set <- read.table("./UCI HAR Dataset/test/X_test.txt")

training_set <- read.table("./UCI HAR Dataset/train/X_train.txt")

total_set <- bind_rows(test_set, training_set)

rm(list = c("training_set", "test_set"))

#-----------------------------------------------------------------------------
# PROCESSING ACTIVITY LABELS:

test_activity <- read.table("./UCI HAR Dataset/test/y_test.txt", stringsAsFactors = FALSE)

training_activity <- read.table("./UCI HAR Dataset/train/y_train.txt", stringsAsFactors = FALSE)

activity_labels <- read.table("./UCI HAR Dataset/activity_labels.txt", stringsAsFactors = FALSE)

activities <- bind_rows(test_activity, training_activity)
activities <- inner_join(activities, activity_labels) %>% select(2)
activities <- tolower(activities[[1]])

rm(list = c("activity_labels", "training_activity", "test_activity"))

#-----------------------------------------------------------------------------
# PROCESSING SUBJECTS:

test_subjects <- read.table("./UCI HAR Dataset/test/subject_test.txt", stringsAsFactors = FALSE)

training_subjects <- read.table("./UCI HAR Dataset/train/subject_train.txt", stringsAsFactors = FALSE)

# the subjects tables have different names. For the bind_row function to work 
#properly it's necesseary to change the names so that they're equal:

names(test_subjects) <- "subject"
names(training_subjects) <- "subject"

subjects <- bind_rows(test_subjects, training_subjects)[[1]]

rm(list = c("training_subjects", "test_subjects"))

#-----------------------------------------------------------------------------
# EXTRACTING VARIABLES AND INDEXES OF THE MEAN AND STANDARD DEVIATION:

# as the second column contains the labels, the index [[2]] is used:
features <- read.table("./UCI HAR Dataset/features.txt", stringsAsFactors = FALSE)[[2]]

# this gets the indices for columns that contain "mean()" and "std()", later
# it will be used to select the columns from the sets:
mean_std_index <- grepl("mean()", features, fixed = TRUE) |
        grepl("std()", features, fixed = TRUE)

#-----------------------------------------------------------------------------
# PROCESSING VARIABLES - RENAMING: 

features <- tolower(features)
features <- gsub("^f", "frequency-", features)
features <- gsub("^t", "time-", features)
features <- gsub("\\()","", features)
features <- gsub("BodyBody","Body", features, ignore.case = TRUE)
features <- gsub("BodyAcc","body_acceleration", features, ignore.case = TRUE)
features <- gsub("GravityAcc","gravity_acceleration", features, ignore.case = TRUE)
features <- gsub("BodyGyro","body_gyroscope", features, ignore.case = TRUE)
features <- gsub("Mag-mean","_magnitude-mean-not_applicable", features, ignore.case = TRUE)
features <- gsub("Mag-std","_magnitude-std-not_applicable", features, ignore.case = TRUE)
features <- gsub("Jerk","_jerk", features, ignore.case = TRUE)

#-----------------------------------------------------------------------------
# APPLYING VARIABLES' LABELS TO SET, ADDING ACTIVITIES AND SUBJECTS COLUMNS:

# the labels can be applied to the merged sets:
names(total_set) <- features

# the indexes are used to parce the variables that contain "mean and std".
# Also, the activities and subjects vectors of variables are added:
total_set <- total_set[,mean_std_index] %>%
        mutate(activity = activities, subject = subjects)

rm(list = c("features",  "mean_std_index", "activities", "subjects"))

#-----------------------------------------------------------------------------
# TRANSFORMING VARIABLE NAMES IN OBSERVATIONS WITH TIDYR

tidy_data_1 <-
        pivot_longer(total_set, -c("activity", "subject"),
                     names_to = c("domain", "signal", "measure", "axis"),
                     names_pattern = "(frequency|time)-([bg][or]\\w+)-(std|mean)-([xyz]|n\\w+)",
                     values_to = "values") %>%
        select(subject, activity, domain, signal, axis, measure, values) %>%
        arrange(subject, activity, signal, desc(domain), measure, axis)

rm("total_set")

tidy_data_2 <- tidy_data_1 %>%
        group_by(subject, activity, domain, signal, axis, measure) %>%
        summarise(average = mean(values)) %>%
        arrange(subject, activity, signal, desc(domain))

#-----------------------------------------------------------------------------
# WRITING TIDY DATA

write.table(tidy_data_1, file = "./tidy_data_1.txt", row.name = FALSE)

write.table(tidy_data_2, file = "./tidy_data_2.txt", row.name = FALSE)
