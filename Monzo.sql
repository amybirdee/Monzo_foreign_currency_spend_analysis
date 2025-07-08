-- first find total volumes for July
SELECT FORMAT_DATE('%b %Y', transaction_date) AS year_month,
       --multiply by -1 so we get positive values in charts
       SUM(amount_gbp) * -1 AS total_spend,
       COUNT(transaction_id) AS num_transactions,
       COUNT(DISTINCT user_id) AS num_customers,
       --get UK spend
       SUM(CASE WHEN merchant_country_alpha_3 = 'GBR' THEN amount_gbp * -1 ELSE 0 END) AS total_spend_uk,
       COUNT(CASE WHEN merchant_country_alpha_3 = 'GBR' THEN transaction_id ELSE NULL END) AS num_transactions_uk,
       COUNT(DISTINCT CASE WHEN merchant_country_alpha_3 = 'GBR' THEN user_id ELSE NULL END) AS num_customers_uk,
FROM monzo_product_ds_tech_screen.transactions
WHERE payment_scheme = 'mastercard'
AND EXTRACT(MONTH FROM transaction_date) = 7
AND amount_gbp < 0 --exclude refunds
GROUP BY year_month
ORDER BY year_month;

-- find currencies where total spend in July 2023 is over £5 million
SELECT B.currency_name,
       SUM(A.amount_gbp) * -1 AS total_spend
FROM monzo_product_ds_tech_screen.transactions A
INNER JOIN monzo_product_ds_tech_screen.currency_rates B
ON A.ISO4217_currency_code = B.ISO4217_currency_code
AND A.transaction_date = B.date
WHERE A.transaction_date BETWEEN DATE('2023-07-01') AND DATE('2023-07-31')
AND A.payment_scheme = 'mastercard'
AND A.amount_gbp < 0 --exclude refunds
GROUP BY B.currency_name
HAVING total_spend > 5000000
ORDER BY total_spend DESC;

-- find currencies where total spend in July 2023 is in the top 10
SELECT B.currency_name,
       SUM(A.amount_gbp) * -1 AS total_spend
FROM monzo_product_ds_tech_screen.transactions A
INNER JOIN monzo_product_ds_tech_screen.currency_rates B
ON A.ISO4217_currency_code = B.ISO4217_currency_code
AND A.transaction_date = B.date
WHERE A.transaction_date BETWEEN DATE('2023-07-01') AND DATE('2023-07-31')
AND A.payment_scheme = 'mastercard'
AND A.amount_gbp < 0 --exclude refunds
GROUP BY B.currency_name
ORDER BY total_spend DESC
LIMIT 10;

-- find currencies and spend where merchant is located in the UK for July 2023
SELECT B.currency_name,
       SUM(A.amount_gbp) * -1 AS total_spend
FROM monzo_product_ds_tech_screen.transactions A
INNER JOIN monzo_product_ds_tech_screen.currency_rates B
ON A.ISO4217_currency_code = B.ISO4217_currency_code
AND A.transaction_date = B.date
WHERE A.transaction_date BETWEEN DATE('2023-07-01') AND DATE('2023-07-31')
AND A.payment_scheme = 'mastercard'
AND A.amount_gbp < 0 --exclude refunds
AND A.merchant_country_alpha_3 = 'GBR'
GROUP BY B.currency_name
ORDER BY total_spend DESC
LIMIT 10;

--find 7 day rolling averages for three currencies
WITH avg_calculation AS
(SELECT date,
       currency_name,
       ISO4217_currency_code,
       ROUND(AVG(mid_market_rate) OVER (PARTITION BY currency_name ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 5) AS rolling_avg_rate_to_gbp
FROM monzo_product_ds_tech_screen.currency_rates
WHERE date BETWEEN DATE('2023-06-25') AND DATE('2023-07-31') --select wider window for initial calculation
AND ISO4217_currency_code IN ('392', '986', '356'))

SELECT date,
       currency_name,
       ISO4217_currency_code,
       rolling_avg_rate_to_gbp
FROM avg_calculation
WHERE date BETWEEN DATE('2023-07-01') AND DATE('2023-07-31')
ORDER BY currency_name,
         date;

