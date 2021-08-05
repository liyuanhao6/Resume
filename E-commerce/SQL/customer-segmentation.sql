-- 1. 选择字段
CREATE TABLE ecommerce
(
    InvoiceNo   VARCHAR(10)  NULL,
    StockCode   VARCHAR(200) NULL,
    Description VARCHAR(200) NULL,
    Quantity    INT          NULL,
    InvoiceDate DATETIME     NULL,
    UnitPrice   FLOAT        NULL,
    CustomerID  VARCHAR(10)  NULL,
    Country     VARCHAR(100) NULL
);
-- 2. 删除重复值
CREATE TABLE new_ecommerce
SELECT DISTINCT *
FROM ecommerce;
-- 3. 缺失值处理
SELECT  SUM(CASE WHEN CustomerID IS NULL THEN 1 ELSE 0 END)   AS "客户编号",
        SUM(CASE WHEN InvoiceNo IS NULL THEN 1 ELSE 0 END )   AS "发票编号",
        SUM(CASE WHEN StockCode IS NULL THEN 1 ELSE 0 END )   AS "产品编号",
        SUM(CASE WHEN Quantity IS NULL THEN 1 ELSE 0 END )    AS "发票编号",
        SUM(CASE WHEN InvoiceDate IS NULL THEN 1 ELSE 0 END ) AS "数量",
        SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END )   AS "单价",
        SUM(CASE WHEN Description IS NULL THEN 1 ELSE 0 END ) AS "产品描述",
        SUM(CASE WHEN Country IS NULL THEN 1 ELSE 0 END )     AS "国家"
FROM new_ecommerce;

DELETE
FROM new_ecommerce
WHERE CustomerID IS NULL;
-- 4. 异常值处理
SELECT  MAX(InvoiceDate),
        MIN(InvoiceDate)
FROM new_ecommerce;

SELECT  MAX(UnitPrice) AS "最高价格",
        MIN(UnitPrice) AS "最低价格",
        MAX(Quantity)  AS "最高销量",
        MIN(Quantity)  AS "最低销量"
FROM new_ecommerce;

DELETE
FROM new_ecommerce
WHERE quantity < 0
AND InvoiceNo NOT LIKE 'C%';

DELETE
FROM new_ecommerce
WHERE UnitPrice <= 0;
-- 5. 一致化处理
UPDATE new_ecommerce
SET InvoiceDate = DATE_FORMAT(InvoiceDate, '%Y-%m-%d');
-- 6. R值计算
SELECT `CustomerID`,
        DATEDIFF(max_date, max_date_per) AS `R`
FROM (
    SELECT `CustomerID`,
            MAX(InvoiceDate) AS `max_date_per`,
            (
                SELECT MAX(InvoiceDate)
                FROM new_ecommerce
            ) AS `max_date`
    FROM new_ecommerce
    GROUP BY CustomerID
) AS t;
-- 7. F值计算
SELECT  `CustomerID`,
        COUNT(DISTINCT InvoiceNo) AS `F`
FROM new_ecommerce
GROUP BY CustomerID;
-- 8. M值计算
SELECT  `CustomerID`,
        ROUND(SUM(Quantity * UnitPrice), 2) AS `M`
FROM new_ecommerce
GROUP BY CustomerID;
-- 9. RFM数据汇总
CREATE TABLE rfm
SELECT  `CustomerID`,
        DATEDIFF('2011-12-09', MAX(InvoiceDate)) AS `R`,
        COUNT(DISTINCT InvoiceNo)                AS `F`,
        ROUND(SUM(Quantity * UnitPrice), 2)      AS `M`
FROM new_ecommerce
GROUP BY CustomerID;
-- 10. RFM评分
CREATE TABLE rfm_score
SELECT  `CustomerID`,
        `R`,
        `F`,
        `M`,
        (
            CASE
                WHEN R <= 30 THEN 5
                WHEN R <= 90 THEN 4
                WHEN R <= 180 THEN 3
                WHEN R <= 365 THEN 2
                ELSE 1
            END
        ) AS `R_score`,
        (
            CASE
                WHEN F <= 10 THEN 1
                WHEN F <= 30 THEN 2
                WHEN F <= 50 THEN 3
                WHEN F <= 80 THEN 4
                ELSE 5
            END
        ) AS `F_score`,
        (
            CASE
                WHEN M <= 1000 THEN 1
                WHEN M <= 3000 THEN 2
                WHEN M <= 5000 THEN 3
                WHEN M <= 8000 THEN 4
                ELSE 5
            END
        ) AS `M_score`
FROM rfm;
-- 11. 客户分层阈值
SELECT  ROUND(AVG(R_score), 1) AS `R_avg`,
        ROUND(AVG(F_score), 1) AS `F_avg`,
        ROUND(AVG(M_score), 1) AS `M_avg`
FROM rfm_score;

CREATE TABLE rfm_values
SELECT  `CustomerID`,
        IF(R_score > 3.8, 1, 0) AS `R_value`,
        IF(F_score > 1.1, 1, 0) AS `F_value`,
        IF(M_score > 1.6, 1, 0) AS `M_value`
FROM rfm_score;
-- 12. 客户分层
SELECT `CustomerID`,
        (
            CASE
                WHEN R_value = 1 AND F_value = 1 AND M_value = 1 THEN '重要价值客户'
                WHEN R_value = 0 AND F_value = 1 AND M_value = 1 THEN '重要唤回客户'
                WHEN R_value = 1 AND F_value = 0 AND M_value = 1 THEN '重要发展客户'
                WHEN R_value = 0 AND F_value = 0 AND M_value = 1 THEN '重要挽留客户'
                WHEN R_value = 1 AND F_value = 1 AND M_value = 0 THEN '一般价值客户'
                WHEN R_value = 1 AND F_value = 0 AND M_value = 0 THEN '一般发展客户'
                WHEN R_value = 0 AND F_value = 1 AND M_value = 0 THEN '一般保持客户'
                ELSE '一般挽留客户'
            END
        ) AS `customer_segment`
FROM rfm_values;
-- 13. 新老客户
SELECT  `mon`,
        SUM(new),
        SUM(total) AS `mon_total`,
        ROUND(SUM(new) / SUM(total), 2) AS `first_per`
FROM
(
    SELECT  `CustomerID`,
            `mon`,
            MAX(is_new) AS `new`,
            COUNT(DISTINCT CustomerID) AS `total`
    FROM
    (
        SELECT  t1.CustomerID AS `CustomerID`,
                t2.first_purchase AS `first_purchase`,
                DATE_FORMAT(InvoiceDate, '%Y-%m') AS `mon`,
                IF(t2.first_purchase = DATE_FORMAT(InvoiceDate, '%Y-%m'), 1, 0) AS `is_new`
        FROM new_ecommerce AS t1 JOIN (
            SELECT  `CustomerID`,
                    MIN(DATE_FORMAT(InvoiceDate, '%Y-%m')) AS `first_purchase`
            FROM new_ecommerce
            GROUP BY CustomerID
        ) AS t2 ON t1.CustomerID = t2.CustomerID
    ) AS t
    GROUP BY  CustomerID,
              mon
) AS t
GROUP BY mon
ORDER BY mon;

SELECT
        `mon`,
        `is_new`,
        SUM(Quantity) AS `total_q`,
        SUM(Quantity * UnitPrice) AS `total_a`
FROM
(
    SELECT  t1.Quantity AS `Quantity`,
            t1.UnitPrice AS `UnitPrice`,
            t2.first_purchase AS `first_purchase`,
            DATE_FORMAT(InvoiceDate, '%Y-%m') AS `mon`,
            IF(t2.first_purchase = DATE_FORMAT(InvoiceDate, '%Y-%m'), 1, 0) AS `is_new`
    FROM new_ecommerce AS t1 JOIN (
        SELECT  `CustomerID`,
                MIN(DATE_FORMAT(InvoiceDate, '%Y-%m')) AS `first_purchase`
        FROM new_ecommerce
        GROUP BY CustomerID
    ) AS t2
    ON t1.CustomerID = t2.CustomerID
) AS t
GROUP BY  mon,
          is_new;
-- 14. 用户生命周期
SELECT  `CustomerID`,
        MIN(InvoiceDate) AS `first_time`,
        MAX(InvoiceDate) AS `last_time`,
        DATEDIFF(MAX(InvoiceDate), MIN(InvoiceDate)) AS `life_time`
FROM new_ecommerce
GROUP BY CustomerID;
-- 15. 用户复购率分析
SELECT  `mon`,
        ROUND(SUM(IF(user_mon_buy_times > 1, 1, 0)) / COUNT(*), 2) AS `repurchase_rate`
FROM
(
    SELECT  `CustomerID`,
            DATE_FORMAT(InvoiceDate, '%Y-%m') AS `mon`,
            COUNT(DISTINCT InvoiceNo) AS `user_mon_buy_times`
    FROM new_ecommerce
    WHERE Quantity > 0
    GROUP BY  DATE_FORMAT(InvoiceDate, '%Y-%m'),
              CustomerID
) AS t
GROUP BY mon;
-- 16. 商品销量与单价
SELECT  `StockCode`,
        SUM(Quantity)  AS `sales`,
        MAX(UnitPrice) AS `price` --销售价格存在折扣，取原价（最大值）
FROM new_ecommerce
WHERE Quantity > 0 --销量存在退货
GROUP BY StockCode;
-- 17. 商品ABC分类
CREATE TABLE product_cumulative_per
SELECT  `StockCode`,
        `sales`,
        SUM(sales / total_sales) OVER(ORDER BY sales DESC) `per_sales`,
        row_number() OVER(ORDER BY sales DESC) `t_rank`
FROM
(
    SELECT  `StockCode`,
            SUM(Quantity * UnitPrice) `sales`,
            (
               SELECT  SUM(Quantity * UnitPrice)
                FROM new_ecommerce
            ) AS `total_sales`
    FROM new_ecommerce
    WHERE Quantity > 0
    GROUP BY StockCode
) AS t;

CREATE TABLE product_class
SELECT  `StockCode`,
        `sales`,
        `per_sales`,
        CASE
            WHEN per_sales < 0.7 THEN 'A'
            WHEN per_sales < 0.9 THEN 'B'
            ELSE 'C'
        END AS `class`
FROM product_cumulative_per;

SELECT  `class`,
        SUM(sales) AS `total_sales`,
        COUNT(class) AS `total_class`
FROM
(
    SELECT  `StockCode`,
            `sales`,
            `per_sales`,
            CASE
                WHEN per_sales < 0.7 THEN 'A'
                WHEN per_sales < 0.9 THEN 'B'
                ELSE 'C'
            END AS `class`
    FROM product_cumulative_per
) AS t
GROUP BY class;
-- 18. 商品退货分析
CREATE TABLE product_return_rate
SELECT  `StockCode`,
        COUNT(*) AS `sales_times`,
        SUM(IF(InvoiceNo LIKE 'C%', 1, 0)) AS `return_times`,
        SUM(IF(InvoiceNo LIKE 'C%', 1, 0)) / COUNT(*) AS `return_rate`
FROM new_ecommerce
GROUP BY StockCode
ORDER BY sales_times DESC;

SELECT  DATE_FORMAT(InvoiceDate, '%Y-%m') AS `mon`,
        SUM(IF(InvoiceNo LIKE 'C%', Quantity * UnitPrice, 0)) AS `return_amount`,
        SUM(IF(InvoiceNo NOT LIKE 'C%', Quantity * UnitPrice, 0)) AS `sales`
FROM new_ecommerce
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m');

SELECT  prr.stockcode AS `stockcode`,
        prr.sales_times AS `sales_times`,
        prr.return_times AS `return_times`,
        prr.return_rate AS `return_rate`
FROM product_class AS pc JOIN product_return_rate AS prr ON pc.stockcode = prr.stockcode
WHERE class = 'A'
AND return_rate > (
    SELECT AVG(return_rate)
    FROM product_return_rate
);












