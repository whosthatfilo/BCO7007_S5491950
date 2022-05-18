install.packages("paws")
install.packages("purrr")
install.packages("tibble")
install.packages("readr")
install.packages("magick")
#install.packages("aws.s3")

library(paws)
library(purrr)
library(tibble)
library(readr)
library(magick)
#library(aws.s3)

# This opens the .Renviron file
usethis::edit_r_environ('ap-southeast-2'):
  
  # Set up your keys and region here:
  # Fill the information below on the .Renviron file
  Sys.setenv("AWS_ACCESS_KEY_ID" = "AKIAXPQYVOA3M6THPGEO",
             "AWS_SECRET_ACCESS_KEY" = "F5YlC1xLui5OeH/rAbpXcnaY4wyl6fnUfsMfxXWy",
             "AWS_REGION" = "ap-southeast-2")

# Create the dataframe called s3
s3 <- s3()

# List the available buckets below
buckets <- s3$list_buckets()
length(buckets$Buckets)

# Create the bucket called "kris-s4591950-aws-bucket"
s3$create_bucket(Bucket = "kris-s4591950-aws-bucket",
                 CreateBucketConfiguration = list(
                   LocationConstraint = "ap-southeast-2"
                 ))


# Specify the bucket name 
buckets <- s3$list_buckets()
buckets <- map_df(buckets[[1]],
                  ~tibble(name = .$Name, creationDate = .$CreationDate))
buckets

# Store the name of our newly created bucket in a separate variable
my_bucket <- buckets$name[buckets$name == "kris-s4591950-aws-bucket"]

# Text in image detection 
# Download this image from: https://maria-pro.github.io/bco7007/data/aws_text.jpeg
# Referencing an image: upload the image to the s3 bucket we just created
s3$put_object(Bucket = my_bucket, 
              Body = read_file_raw("aws_text.jpg"), 
              Key = "aws_text.jpg")

# Check if the image resides in your bucket
bucket_objects <- s3$list_objects(my_bucket) %>% 
  .[["Contents"]] %>% 
  map_chr("aws_text.jpg") 
bucket_objects


# Create a rekognition client 
rekognition <- rekognition()

# Referencing an image in an Amazon S3 bucket
resp <- rekognition$detect_text(
  Image = list(
    S3Object = list(
      Bucket = my_bucket,
      Name = bucket_objects
    )
  )
)

# Parsing the response
resp %>%
  .[["TextDetections"]] %>%
  keep(~.[["Type"]] == "WORD") %>%
  map_char("DetectedTexts") 