
  title: "text analysis"
author: "Matt Sterkel"
output: html_document

library(twitteR)
library(graphics)
library(purrr)
library(stringr) 
library(tm)
library(syuzhet)


api_key<- "xxxxx"
api_secret <- "xxxxx"
access_token <- "xxxxx"
access_token_secret <- "xxxxx"
setup_twitter_oauth(api_key,api_secret,access_token,access_token_secret)





prat_tweets <- userTimeline("prattprattpratt", n = 250)

oprah_tweets <- userTimeline("Oprah", n = 250)

neil_tweets <- userTimeline("neiltyson", n = 250)

mar_tweets <- userTimeline("billmaher", n = 250)

kutch_tweets <- userTimeline("aplusk", n = 250)



tweets<- tbl_df(map_df(c(prat_tweets,oprah_tweets,neil_tweets,
                         mar_tweets,kutch_tweets),as.data.frame))  

write.csv(tweets, file="tweets.csv", row.names=FALSE)  


setwd("C:/Users/Prasad/Documents/twitter2")

tweets<-read.csv("tweets.csv")


twitterCorpus <-Corpus(VectorSource(tweets$text))

inspect(twitterCorpus[1:10])

twitterCorpus<- tm_map(twitterCorpus, content_transformer(tolower))
twitterCorpus<- tm_map(twitterCorpus,removeWords,stopwords("en"))
twitterCorpus<- tm_map( twitterCorpus,removeNumbers)
twitterCorpus<- tm_map( twitterCorpus,removePunctuation)

removeURL<- function(x) gsub("http[[:alnum:]]*", "", x)   
twitterCorpus<- tm_map(twitterCorpus,content_transformer(removeURL))

removeURL<- function(x) gsub("edua[[:alnum:]]*", "", x)   
twitterCorpus<- tm_map(twitterCorpus,content_transformer(removeURL))

# remove non "American standard code for information interchange (curly quotes and ellipsis)"
#  using function from package "textclean"            

removeNonAscii<-function(x) textclean::replace_non_ascii(x) 
twitterCorpus<-tm_map(twitterCorpus,content_transformer(removeNonAscii))

twitterCorpus<- tm_map(twitterCorpus,removeWords,c("amp","ufef",
                                                   "ufeft","uufefuufefuufef","uufef","s"))  

twitterCorpus<- tm_map(twitterCorpus,stripWhitespace)

inspect(twitterCorpus[1:10])



# stem corpus after sentiment analysis(given my sentiment dictionary choice), but before cluster analysis


# find count of 8 emotional sentiments

emotions<-get_nrc_sentiment(twitterCorpus$content)

barplot(colSums(emotions),cex.names = .7,
        col = rainbow(10),
        main = "Sentiment scores for tweets"
)







# sentiment positiviy rating

get_sentiment(twitterCorpus$content[1:10])

sent<-get_sentiment(twitterCorpus$content)
sentimentTweets<-dplyr::bind_cols(tweets,data.frame(sent))

# mean of sentiment positivity

meanSent<-function(i,n){
  mean(sentimentTweets$sent[i:n])
}

(scores<-c(prat=meanSent(1,250),
           oprah=meanSent(251,500),
           neil=meanSent(501,750),
           maher=meanSent(751,849),
           astk=meanSent(850,1002)))


# convert to stem words
twitterCorpus<-tm_map(twitterCorpus,stemDocument)

# build document term matrix

dtm<-DocumentTermMatrix(twitterCorpus)
dtm
mat<-as.matrix(dtm)

# create distance matrix

d<-dist(mat)

# input distance matrix into hclust function using method "ward.D"

groups<-hclust(d,method="ward.D")
plot(groups,hang=-1)

cut<-cutree(groups,k=6)
newMat<-dplyr::bind_cols(tweets,data.frame(cut))

table(newMat$screenName,newMat$cut)



