# --- Script Header ---
# Project: Teleconsultation Sentiment Analysis in Chile
# Author: Patricio Ramírez Correa 
# Date: July 2, 2025
# Description: This script processes Twitter data related to teleconsultation,
#              filters tweets by keywords and geographical location in Chile,
#              performs emotion and sentiment analysis using the Syuzhet package,
#              and operationalizes satisfaction as a binary valence variable.
#              Finally, it prepares the data for further statistical analysis (e.g., PLS-SEM).

# --- 1. Load Required Libraries ---
# `academictwitteR`: For binding tweet data collected via the Twitter Academic API.
# `dplyr`: For data manipulation and piping operations.
# `stringr`: For string manipulation, particularly for pattern detection.
# `xlsx`: For writing data frames to Excel files.
# `syuzhet`: For sentiment and emotion analysis using the NRC Emotion Lexicon.
library(academictwitteR)
library(dplyr)
library(stringr)
library(xlsx)
library(syuzhet)

# --- 2. Load Tweet Data ---
# Binds tweet data from specified JSON files into a single tidy dataframe.
# IMPORTANT: Update "data/" to the actual path where your tweet JSON files are located.
#            For a GitHub repository, it's recommended to place raw data in a 'data/' folder
#            relative to the script.
tweets <- bind_tweets(data_path = "data/", output_format = "tidy")

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

# --- 4. Filter Tweets ---
# Filters the `tweets` dataframe:
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
