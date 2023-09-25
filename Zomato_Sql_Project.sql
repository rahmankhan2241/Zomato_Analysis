## Q1 - What Is The Total Amount Spent By Each Customers On Zomato?
SELECT s.userid AS User_id, SUM(p.price) AS Total_Spend_Money
FROM sales AS s JOIN product AS p 
ON s.product_id = p.product_id
GROUP BY s.userid;

## Q2 - How many Days Has Each Customer Visited Zomato ??
SELECT userid , COUNT(DISTINCT created_date) AS `Days Visited `FROM sales
GROUP BY userid;

## Q3- What Was the First Product Purchased by Each Customer ??
# Since My Date data is behaving as a str that's why i was getting wrong answers by grouping it . So first let make it in correct format
-- UPDATE sales
-- SET created_date = STR_TO_DATE(created_date , '%m-%d-%Y')

# Now the date is in correct form for further process
WITH CTE AS
(SELECT * , DENSE_RANK() OVER(PARTITION BY userid ORDER BY created_date) AS rnk
FROM sales)

SELECT userid , product_id , rnk FROM CTE
WHERE rnk = 1;

## Q4 - What Is The Most Purchased Item On The Menu And How Many Times It Was Purchased By All Customer
SELECT userid , COUNT(*) AS 'Purchase Time'FROM sales
WHERE product_id = (SELECT  product_id  FROM Sales
GROUP BY  product_id
ORDER BY count(*) DESC
LIMIT 1)
GROUP BY userid;

## Q5 - Which Customer Is Most Popular For Customers ??
With cte as(SELECT userid ,product_id , count(*) As cnt
FROM sales 
GROUP BY userid , product_id)

SELECT userid , product_id
FROM (SELECT userid ,product_id,
DENSE_RANK() OVER(PARTITION BY userid ORDER BY cnt DESC) AS popularity
FROM cte) AS  final_table 
WHERE popularity = 1;

## Q6 - Which Item Was Purchased By The User After They Become A Gold Memeber ??
# Since My Signup_date is also not in date format . So Frst Convrtng it on Date form
-- UPDATE goldusers_signup
-- SET gold_signup_date = STR_TO_DATE(gold_signup_date , '%m-%d-%Y');
# Now it's in Correct format for further process
WITH Cte AS (SELECT g.userid , s.created_date , s.product_id,						
RANK() OVER(PARTITION BY g.userid ORDER BY s.created_date) AS rnk						
FROM goldusers_signup AS g						
JOIN sales AS s 						
ON g.userid = s.userid and g.gold_signup_date < s.created_date					
ORDER BY userid , created_date)	
					
SELECT userid , product_id FROM Cte						
WHERE rnk = 1;						

## Q7 - Which Item Was Purchased By Each Customer Just Before They Became A Gold Member ??
WITH Cte AS 
(SELECT g.userid , s.product_id , s.created_date, 
RANK() OVER(PARTITION BY g.userid ORDER BY s.created_date DESC) AS rnk 
FROM goldusers_signup AS g 
JOIN sales AS s ON g.userid = s.userid AND
s.created_date < g.gold_signup_date)

SELECT userid , product_id 
FROM Cte WHERE rnk = 1;

## Q8- What Is The Total Orders and Amount Spent For Each Member Before They Took GoldMembership ??
With CTE AS (SELECT g.userid , s.created_date , s.product_id , p.price  
FROM goldusers_signup AS g 
JOIN sales AS s ON g.userid = s.userid AND
g.gold_signup_date > s.created_date
JOIN product as p ON 
s.product_id = p.product_id)

SELECT userid , COUNT(*) AS Total_Orders, 
CONCAT(SUM(price),' ₹') AS Total_Money_Spent 
FROM CTE
GROUP BY userid
ORDER BY Total_Money_Spent DESC;

## Q9 -If Buying differnt differnt Products Generates some zomato points like for eg: p1 - 5rs = 1 zp, p2 - 10rs = 5zp , p3 - 5rs = 1 zp
# Where zp Means zomato points . Calculate The Total collected zomato points For Each Customer 
# And By Which Product Each Customer Got Most zp . And Every 100 Zomato Points is Equal To 10 rs So Calcuate How much Each 
# Customer Collected money through points.

With CTE AS (SELECT s.userid , s.product_id , p.price ,
CASE WHEN s.product_id = 2 then round(p.price/2)
WHEN s.product_id = 1 then round(p.price/5)
WHEN s.product_id = 3 then round(p.price/5)
END AS Zomato_Points
FROM SALES as s , PRODUCT as p
WHERE s.PRODUCT_ID = p.PRODUCT_ID)

# Query Which Tells Through Which Product EAch Customer Is Getting Most Zomato Points 
SELECT * FROM (SELECT userid , product_id , 
Sum(Zomato_Points) As Total_Zp,
RANK() OVER(Partition By userid order by SUM(Zomato_Points) DESC) As rnk 
FROM CTE 
Group By userid , product_id                                      ## Run The Table Along CTE Table 
Order By userid , Total_Zp DESC
) AS Ranked_TABLE
WHERE rnk = 1;

# Query Which Tells Total zomato Points Earned By Each Customers And Total Money Collected 
SELECT * ,
ROUND(Total_zp/10) AS Collected_Money FROM 
(SELECT userid , SUM(Zomato_Points) AS Total_zp     ## Run The Query Along CTE Table
FROM CTE      ## 100zp = 10rs Hence 10zp = 1rs 
GROUP BY userid) AS final_Table;

## Q10 - After The Customer Join Golden Membership. Each Customer Earned 5 zomato Points on each order of rs 10 . 
# Find Which Customer Earned More zomato Points , In the first year of joining??
With Cte As (SELECT g.userid , Sum(p.price) AS " Total Spent"
FROM goldusers_signup AS g
JOIN sales AS s 
ON g.userid = s.userid
JOIN product AS p 
ON s.product_id = p.product_id
Where g.gold_signup_date <= s.created_date
group by userid)
#Converting Total Earning into zomato points 
Select userid , round((`Total Spent` / 2)) As Zomato_Points
From Cte ;       # Clearly userid 3 earned more zomato points

## Q11 - Rank all transactions of gold members . If there is non goldenship member Rank them as NA.
WITH Cte AS
(SELECT s.userid AS user_id , s.created_date, g.userid AS userid , 
RANK() OVER(PARTITION BY s.userid ORDER BY s.created_date) As rnk 
FROM sales AS s 
LEFT JOIN goldusers_signup AS g
ON s.userid = g.userid)

SELECT user_id , created_date , 
CASE WHEN userid IS NOT NULL THEN rnk
ELSE "NA" END AS "Rank" FROM Cte;









