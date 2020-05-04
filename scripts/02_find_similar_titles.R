library(data.table)
library(magrittr)

dt <- fread("outputs/preregs.csv", header = T, encoding = "UTF-8")

# i want to find which titles are the most similar in terms of the words they contain
# create dt of all titles compared to each other and their matches

clean_str <- function(string){
  string <- tolower(string)
  # remove punctuation that comes before or after a word
  string <- gsub(" [[:punct:]]{1,}|[[:punct:]]{1,} |^[[:punct:]]{1,}|[[:punct:]]{1,}$", " ", string)
  # remove multiple spaces
  string <- gsub("[[:space:]]{2,}", " ", string)
}

dt <- dt[, "title_clean" := clean_str(title)]

test <- setcolorder(dt, c("title", "title_clean"))

pairs <- list()
n <- 1

for(i in dt$title_clean){
  string_2 <- dt$title_clean[dt$title_clean != i]
  string_1 <- rep(i, length(string_2))
  length(string_1) <- dt[,.N]
  length(string_2) <- dt[,.N]
  df <- data.frame(string_1 = string_1, string_2 = string_2, stringsAsFactors = F)
  pairs[[n]] <- df
  n <- n +1
}

test <- rbindlist(pairs) %>%
  # remove duplicate rows
  unique()

stopwords <- c("and", "the", "of", "a", "for", "to", "by", "in", "on", "amp", "from", "an")

matches <- list()

for(i in 1:length(test$string_1)){
  a <- unlist(strsplit(test[i, string_1], " "))
  a <- a[!(a %in% stopwords)]
  b <- unlist(strsplit(test[i, string_2], " "))
  b <- b[!(b %in% stopwords)]
  matches[[i]] <- intersect(a, b)
  print(paste(i, "done"))
}

copy <- matches %>%
  as.character() 

length(copy) <- test[,.N]
copy[copy == "character(0)"] <- NA

copy <- copy %>%
  gsub("c\\(", "", .) %>%
  gsub("[[:punct:]]", " ", .) %>%
  gsub("[[:space:]]{2,}", " ", .)

test$matches <- copy

paste(strsplit(copy[!is.na(copy)], " "))
