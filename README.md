# Product Recommendation System with PCA generated weights

This repository contains the implementation of a product recommendation system for a convenience store chain, based on a combination of SQL and Principal Component Analysis (PCA) to compute weighted scores for products.

## Project Overview

### Background
A convenience chain store would like to promote products for different timeframes in the upcoming month based on product level performance from last month. 

### 1. SQL Data Summarization
The project starts with a SQL script that summarizes data at the product level. The SQL script (`20210531_POS_summary.sql`) was used to extract and aggregate the relevant product information from a database, providing a detailed summary of key metrics, including these for further PCA:
- Shopper coverage: percentage of total stores that this product was sold
- sales volume as a percentage of: percentage of total sales for this product
- surge factor: the sales growth from month-start average to month-end average
- burst factor: how much sales can be bursted given a certain unit of discount

### 2. Principal Component Analysis (PCA)
After summarizing the data, PCA was applied to assign weights to above 4 computed variables. These weights reflect the significance of each variable in relation to the overall product evaluation.

### 3. Weighted Score Calculation
The final step involved calculating a weighted score for each product. The scores were derived from the PCA weights, allowing for an objective ranking of products based on multiple factors.

## Files

- **20210531_POS_summary.sql**: SQL script used to summarize data at the product level.
- **pca_weighting.py**: Python script that applies PCA and calculates the weighted scores for each product.
- **202106_POS_Summary_Morning en.xlsx**: Excel file containing the translated version of the SQL output. This is a sample file only, with details modified to preserve confidentiality.

## Result Interpretation

### PCA Output
Principal Component Analysis (PCA) is a dimensionality reduction technique that helps us understand the importance of various variables in the data by transforming them into a set of uncorrelated components, ordered by the amount of variance they explain.

- **Principal Components (PCs)**: Each principal component is a linear combination of the original variables. The first few PCs explain most of the variance in the data, meaning they capture the most important underlying patterns.
  
- **Explained Variance**: The explained variance ratio shows how much of the total variance in the data is captured by each principal component. A higher explained variance for the first few PCs indicates that these components are key contributors in distinguishing between products.

### Weighted Scores
After PCA is performed, each important variable is assigned a weight based on its contribution to the principal components. These weights are then used to calculate a **weighted score** for each product.

- **Interpreting the Scores**: 
  - Higher scores indicate products that perform well across the key variables identified by the PCA.
  - Products with lower scores might not be performing as well in the dimensions deemed most important by the analysis.
  - These scores can be used to make recommendations or highlight top-performing products for further analysis.

## Usage
1. Run the SQL script `20210531_POS_summary.sql` to extract and summarize product data. However, without credentials to connect to our DB, Excel file `202106_POS_Summary_Morning en.xlsx` is provided as a sample output from sql.
2. Use `pca_weighting.py` to perform PCA on the summarized data and compute the weighted product scores.
