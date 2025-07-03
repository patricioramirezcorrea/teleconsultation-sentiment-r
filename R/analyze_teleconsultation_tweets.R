# --- Script Header ---
# Project: Teleconsultation Sentiment Analysis in Chile
# Author: Patricio Ramírez Correa
# Date: July 2, 2025
# Description: This script processes Twitter data related to teleconsultation,
#              filters tweets by keywords and geographical location in Chile,
#              performs bot detection to remove likely fake accounts,
#              performs emotion and sentiment analysis using the Syuzhet package,
#              and operationalizes satisfaction as a binary valence variable.
#              Finally, it prepares the data for further statistical analysis (e.g., PLS-SEM).

# --- 1. Load Required Libraries ---
# `academictwitteR`: For binding tweet data collected via the Twitter Academic API.
# `dplyr`: For data manipulation and piping operations.
# `stringr`: For string manipulation, particularly for pattern detection.
# `xlsx`: For writing data frames to Excel files.
# `syuzhet`: For sentiment and emotion analysis using the NRC Emotion Lexicon.
# `TweetBotOrNot`: For detecting and filtering out bot accounts.
library(academictwitteR)
library(dplyr)
library(stringr)
library(xlsx)
library(syuzhet)
library(TweetBotOrNot)

# --- 2. Load Tweet Data ---
# Binds tweet data from specified JSON files into a single tidy dataframe.
# IMPORTANT: Update "data/" to the actual path where your tweet JSON files are located.
#            For a GitHub repository, it's recommended to place raw data in a 'data/' folder
#            relative to the script.
tweets <- bind_tweets(data_path = "data/", output_format = "tidy")

# --- 2.1. Bot Detection and Filtering ---
# This section uses the 'TweetBotOrNot' package to identify and remove tweets
# from accounts likely to be bots. This helps ensure the analysis is based on
# genuine human sentiment.

# IMPORTANT: To use TweetBotOrNot, you need to set up your Twitter API credentials.
# You can typically set these as environment variables or directly within your R session.
# Example (replace with your actual credentials):
# Sys.setenv(
#   "TWITTER_BEARER_TOKEN" = "YOUR_BEARER_TOKEN",
#   "TWITTER_CONSUMER_API_KEY" = "YOUR_CONSUMER_API_KEY",
#   "TWITTER_CONSUMER_API_SECRET" = "YOUR_CONSUMER_API_SECRET",
#   "TWITTER_ACCESS_TOKEN" = "YOUR_ACCESS_TOKEN",
#   "TWITTER_ACCESS_TOKEN_SECRET" = "YOUR_ACCESS_TOKEN_SECRET"
# )
# Ensure you have the necessary authentication set up for the TweetBotOrNot package
# to access the Twitter API.

# Get unique author IDs from the tweets to avoid redundant API calls.
unique_author_ids <- unique(tweets$author_id)

# Retrieve bot scores for each unique author ID.
# Be aware of Twitter API rate limits. For a large number of users, this might take time.
# The 'get_bot_scores' function queries the Twitter API for user characteristics.
message("Fetching bot scores for unique authors. This may take some time depending on the number of unique users and API rate limits.")
bot_scores_df <- tryCatch({
  get_bot_scores(users = unique_author_ids, user_id = TRUE)
}, error = function(e) {
  message("Error fetching bot scores: ", e$message)
  message("Proceeding without bot filtering. Please ensure Twitter API credentials are correctly set for bot detection.")
  return(NULL) # Return NULL if there's an error, so the script can continue
})

# If bot scores were successfully retrieved, merge them and filter.
if (!is.null(bot_scores_df) && nrow(bot_scores_df) > 0) {
  # Rename 'user_id' to 'author_id' in bot_scores_df for merging.
  bot_scores_df <- bot_scores_df %>% rename(author_id = user_id)
  
  # Merge bot scores back to the main tweets dataframe.
  # Use left_join to keep all tweets and add bot scores where available.
  tweets <- tweets %>%
    left_join(bot_scores_df %>% select(author_id, prob_bot), by = "author_id")
  
  # Filter out tweets from likely bot accounts.
  # A common threshold for 'prob_bot' (probability of being a bot) is > 0.5 or > 0.7.
  # Adjust the 'bot_threshold' as per your research's sensitivity requirements.
  bot_threshold <- 0.5 # Example threshold: remove users with >50% probability of being a bot
  initial_tweet_count <- nrow(tweets)
  tweets <- tweets %>%
    filter(is.na(prob_bot) | prob_bot <= bot_threshold) # Keep if prob_bot is NA (no score) or below threshold
  
  message(paste0("Removed ", initial_tweet_count - nrow(tweets), " tweets identified as likely bots (prob_bot > ", bot_threshold, ")."))
  message(paste0("Remaining tweets after bot filtering: ", nrow(tweets)))
  
} else {
  message("Bot scores could not be retrieved or were empty. Skipping bot filtering.")
}


# --- 3. Define Keywords and Geographical Filters ---
# `keywords`: A vector of keywords (in Spanish) related to teleconsultation.
keywords <- c("telemedicina","teleconsulta", "consulta virtual", "video consulta", "videoconsulta", "consulta electrónica", "consulta electronica")

# `chilean_cities`: A comprehensive list of Chilean cities to filter user locations.
#                   Includes variations and cities from different regions.
chilean_cities <- c("valparaiso","valparaíso","viña del mar", "vina del mar", "quilpué", "quilpue", "villa alemana", "concón", "concon",
                    "concepcion", "concepción", "coronel", "chiguayante", "hualpén", "hualpen", "hualqui", "lota", "penco", "san pedro de la paz", "talcahuano", "tomé", "tome",
                    "santiago", "cerrillos", "cerro navia", "conchali", "el bosque", "estacion central", "huechuraba", "independencia", "la cisterna", "la florida", "la granja", "la pintana", "la reina", "las condes", "lo barnechea", "lo espejo", "lo prado", "macul", "maipu", "ñuñoa", "padre hurtado", "paine", "pedro aguirre cerda", "peñaflor", "peñalolén", "pirque", "providencia", "pudahuel", "puente alto", "quilicura", "quinta normal", "recoleta", "renca", "san bernardo", "san joaquín", "san josé de maipo", "san miguel", "san ramón", "talagante", "vitacura",
                    "conchalí", "maipú", "ñuñoa", "peñalolén", "san joaquín", "san josé de maipo", "san ramón"
)

# Create a single regex pattern for all Chilean cities for efficient filtering.
city_pattern <- paste(chilean_cities, collapse = "|")

# --- 4. Filter Tweets by Keywords and Location ---
# Filters the `tweets` dataframe (which now may have bot scores):
# 1. Keeps tweets where the lowercase `text` contains any of the `keywords`.
# 2. Keeps tweets where the lowercase `user_location` contains any of the `chilean_cities`.
filtered_tweets <- tweets %>%
  filter(str_detect(tolower(text), paste(keywords, collapse = "|")) &
           str_detect(tolower(user_location), city_pattern))

# --- 5. Categorize Cities into Groups ---
# Defines specific lists of cities for three distinct geographical groups.
# These lists are subsets of `chilean_cities` and represent different regions.
group1_cities <- c("valparaiso","valparaíso","viña del mar", "vina del mar", "quilpué", "quilpue", "villa alemana", "concón", "concon")
group2_cities <- c("concepcion", "concepción", "coronel", "chiguayante", "hualpén", "hualpen", "hualqui", "lota", "penco", "san pedro de la paz", "talcahuano", "tomé", "tome")
group3_cities <- c("santiago", "cerrillos", "cerro navia", "conchali", "el bosque", "estacion central", "huechuraba", "independencia", "la cisterna", "la florida", "la granja", "la pintana", "la reina", "las condes", "lo barnechea", "lo espejo", "lo prado", "macul", "maipu", "ñuñoa", "padre hurtado", "paine", "pedro aguirre cerda", "peñaflor", "peñalolén", "pirque", "providencia", "pudahuel", "puente alto", "quilicura", "quinta normal", "recoleta", "renca", "san bernardo", "san joaquín", "san josé de maipo", "san miguel", "san ramón", "talagante", "vitacura",
                   "conchalí", "maipú", "ñuñoa", "peñalolén", "san joaquín", "san josé de maipo", "san ramón")

# Create regex patterns for each city group.
group1_pattern <- paste(group1_cities, collapse = "|")
group2_pattern <- paste(group2_cities, collapse = "|")
group3_pattern <- paste(group3_cities, collapse = "|")

# Initialize a new column for city groups in the filtered_tweets dataframe.
filtered_tweets$city_group <- NA

# Assign city group based on `user_location` matching the defined patterns.
# Note: Tweets might match multiple patterns if a city name is part of another,
#       but `grepl` will assign to the first match in this sequential assignment.
#       For mutually exclusive groups, consider using `case_when` from `dplyr`.
filtered_tweets$city_group[grepl(group1_pattern, tolower(filtered_tweets$user_location))] <- 1
filtered_tweets$city_group[grepl(group2_pattern, tolower(filtered_tweets$user_location))] <- 2
filtered_tweets$city_group[grepl(group3_pattern, tolower(filtered_tweets$user_location))] <- 3

# --- 6. Perform Emotion and Sentiment Analysis ---
# Uses the `get_nrc_sentiment` function from `syuzhet` package to extract
# scores for eight basic emotions (anger, anticipation, disgust, fear, joy,
# sadness, surprise, trust) and two sentiment polarities (positive, negative).
# `language = "spanish"` is crucial for using the Spanish NRC lexicon.
sentiment_scores <- get_nrc_sentiment(filtered_tweets$text, language = "spanish")

# Combine the original filtered tweets dataframe with the sentiment scores.
# The `result_df` now contains all original tweet data plus emotion and sentiment scores.
result_df <- cbind(filtered_tweets, sentiment_scores)

# Display a summary of the combined results, including new sentiment columns.
summary(result_df)

# --- 7. Operationalize Satisfaction as Binary Valence ---
# Creates a new column `satisfaction_valence` to represent satisfaction as a binary variable (0 or 1).
# This operationalizes "satisfaction" as a measure of overall positive valence based on
# the predominance of positive emotions over negative emotions.
# If the `positive` sentiment score is strictly greater than the `negative` sentiment score,
# `satisfaction_valence` is set to 1 (indicating a predominant positive valence).
# Otherwise (if `positive` is less than or equal to `negative`), `satisfaction_valence` is set to 0.
result_df$satisfaction_valence <- 0 # Initialize with 0
result_df$satisfaction_valence[result_df$positive > result_df$negative] <- 1

# --- 8. Export Results to Excel ---
# Ensure the 'output' directory exists before writing the file.
# If it doesn't exist, create it.
if (!dir.exists("output")) {
  dir.create("output")
}

# Saves the final `result_df` dataframe to an Excel file named "tele-ciudades.xlsx"
# within the 'output' directory.
# `sheetName = "data"` specifies the sheet name within the Excel file.
# `append = FALSE` ensures a new file is created or overwritten if it exists.
write.xlsx(result_df, file = "output/tele-ciudades.xlsx", sheetName = "data", append = FALSE)

# --- Script End ---
