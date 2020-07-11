library("wordcloud")
library("RColorBrewer")
library("ggplot2")

depressed <- read.csv(file="word_count_depressed.csv", header=TRUE, sep=",")

depressed <- depressed[1:250,]

#affichage du bar plot
ggplot(data=depressed[1:50,], aes(x=reorder(word,count), y=count, fill=word)) +
  geom_bar(colour="black", fill="#DD8888", width=.8, stat="identity") +
  coord_flip() +
  guides(fill=FALSE) +
  xlab("Word") + ylab("Count") +
  ggtitle("Depressed")


#affichage du word cloud
set.seed(1234)
wordcloud(words = depressed$word, freq = depressed$count, min.freq = 1,
          max.words=250, random.order=FALSE, rot.per=0.35,
          colors=brewer.pal(8, "Dark2"))


undepressed <- read.csv(file="word_count_undepressed.csv", header=TRUE, sep=",")

undepressed <- undepressed[1:250,]

#affichage du bar plot
ggplot(data=undepressed[1:50,], aes(x=reorder(word,count), y=count, fill=word)) +
  geom_bar(colour="black", fill="#88DD88", width=.8, stat="identity") +
  coord_flip() +
  guides(fill=FALSE) +
  xlab("Word") + ylab("Count") +
  ggtitle("Undepressed")


#affichage du word cloud
set.seed(1234)
wordcloud(words = undepressed$word, freq = undepressed$count, min.freq = 1,
          max.words=250, random.order=FALSE, rot.per=0.35,
          colors=brewer.pal(8, "Dark2"))
