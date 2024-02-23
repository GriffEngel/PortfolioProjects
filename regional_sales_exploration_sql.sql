-- Regional sales data exploration
-- Some comments I put in are me thinking out loud about visualizing the data/reporting it in some way
-- Dataset Source: 

select * from US_Regional_Sales_Data

-- I originally wanted the Discount_Applied column to look like 7.5 instead of 0.075, but the latter might be better for calculations

UPDATE US_Regional_Sales_Data
SET Discount_Applied = Discount_Applied / 100

-- Looking at online sales specifically

-- Adding in a Profit Column
select *, (Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100) AS Profit 
from US_Regional_Sales_Data
where Sales_Channel like '%online%'


-- Only querying required columns
select OrderNumber, Sales_Channel, Order_Quantity, (Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100) AS Profit
from US_Regional_Sales_Data
where Sales_Channel like '%online%'

-- Making the same query for the other values of Sales_Channel
-- These could made to be views in some situations for quicker access

select OrderNumber, Sales_Channel, Order_Quantity, (Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Profit
from US_Regional_Sales_Data
where Sales_Channel like '%In-Store%'

select OrderNumber, Sales_Channel, Order_Quantity, Discount_Applied, Unit_Price, Unit_Cost, (Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100) AS Profit
from US_Regional_Sales_Data
where Sales_Channel like '%Wholesale%'

select OrderNumber, Sales_Channel, Order_Quantity, Discount_Applied, Unit_Price, Unit_Cost, (Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100) AS Profit
from US_Regional_Sales_Data
where Sales_Channel like '%Distributor%'

select SalesTeamID, Sales_Channel, SUM(Order_Quantity) AS Total_Quantity, 
    AVG(Discount_Applied) AS Average_Discount, 
    SUM((Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Total_Profit
from US_Regional_Sales_Data
group by SalesTeamID, Sales_Channel
order by Total_Profit desc
-- Sales Team 26 has made the most profit of any team through any of the three channels 

-- What about each channel specifically?
-- We know Wholesale already

-- Online Sales
select SalesTeamID, Sales_Channel, SUM(Order_Quantity) AS Total_Quantity, 
    AVG(Discount_Applied) AS Average_Discount, 
    SUM((Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Total_Profit
from US_Regional_Sales_Data
where Sales_Channel like '%Online%'
group by SalesTeamID, Sales_Channel
order by Total_Profit desc
-- Yes, team 13 did sell the second most quantity, but team 18 sold the most and they are fifth in the list; also all average discounts are from 11-12% so not a massive difference there.

-- In Store Sales
select SalesTeamID, Sales_Channel, SUM(Order_Quantity) AS Total_Quantity, 
    AVG(Discount_Applied) AS Average_Discount, 
    SUM((Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Total_Profit
from US_Regional_Sales_Data
where Sales_Channel like '%In-Store%'
group by SalesTeamID, Sales_Channel
order by Total_Profit desc
-- Team 1 are the slight victors here despite offering a 12.6% average discount. 

-- Distributor Sales
select SalesTeamID, Sales_Channel, SUM(Order_Quantity) AS Total_Quantity, 
    AVG(Discount_Applied) AS Average_Discount, 
    SUM((Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Total_Profit
from US_Regional_Sales_Data
where Sales_Channel like '%Distributor%'
group by SalesTeamID, Sales_Channel
order by Total_Profit desc
-- Team 24 comes in with the highest profit 

-- Showing PARTITION BY 
select * from US_Regional_Sales_Data

select OrderDate, Order_Quantity, Sales_Channel, SUM(Order_Quantity) OVER (PARTITION BY OrderDate Order by Sales_Channel, OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS DailyRunningTotalSold,
SUM(Order_Quantity) OVER (PARTITION BY OrderDate, Sales_Channel Order by Sales_Channel, OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ChannelRunningTotalSold
from US_Regional_Sales_Data

-- Making CTE

With RunningTotals (OrderDate, Sales_Channel, Order_Quantity, DailyRunningTotalSold, ChannelRunningTotalSold)
AS
(
select OrderDate, Sales_Channel, Order_Quantity, SUM(Order_Quantity) OVER (PARTITION BY OrderDate Order by Sales_Channel, OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS DailyRunningTotalSold,
SUM(Order_Quantity) OVER (PARTITION BY OrderDate, Sales_Channel Order by Sales_Channel, OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ChannelRunningTotalSold
from US_Regional_Sales_Data
)
Select * From RunningTotals

-- Temp Table
DROP Table if exists #RunningTotals
Create Table #RunningTotals
(
OrderDate date,
Sales_Channel nvarchar(255),
OrderQuantity Int,
DailyRunningTotalSold Int,
ChannelRunningTotalSold Int
)
insert into #RunningTotals
select OrderDate, Sales_Channel, Order_Quantity, SUM(Order_Quantity) OVER (PARTITION BY OrderDate Order by Sales_Channel, OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS DailyRunningTotalSold,
SUM(Order_Quantity) OVER (PARTITION BY OrderDate, Sales_Channel Order by Sales_Channel, OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ChannelRunningTotalSold
from US_Regional_Sales_Data

Select * from #RunningTotals


-- Creating View for visualizations
Create View RunningTotals as
select OrderDate, Sales_Channel, Order_Quantity, SUM(Order_Quantity) OVER (PARTITION BY OrderDate Order by Sales_Channel, OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS DailyRunningTotalSold,
SUM(Order_Quantity) OVER (PARTITION BY OrderDate, Sales_Channel Order by Sales_Channel, OrderDate ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS ChannelRunningTotalSold
from US_Regional_Sales_Data

Create View DistributorSales as
select SalesTeamID, Sales_Channel, SUM(Order_Quantity) AS Total_Quantity, 
    AVG(Discount_Applied) AS Average_Discount, 
    SUM((Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Total_Profit
from US_Regional_Sales_Data
where Sales_Channel like '%Distributor%'
group by SalesTeamID, Sales_Channel

Create View OnlineSales as 
select SalesTeamID, Sales_Channel, SUM(Order_Quantity) AS Total_Quantity, 
    AVG(Discount_Applied) AS Average_Discount, 
    SUM((Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Total_Profit
from US_Regional_Sales_Data
where Sales_Channel like '%In-Store%'
group by SalesTeamID, Sales_Channel

Create View InStoreSales as 
select SalesTeamID, Sales_Channel, SUM(Order_Quantity) AS Total_Quantity, 
    AVG(Discount_Applied) AS Average_Discount, 
    SUM((Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Total_Profit
from US_Regional_Sales_Data
where Sales_Channel like '%In-Store%'
group by SalesTeamID, Sales_Channel

Create View SalesTeamPerformance as
select SalesTeamID, Sales_Channel, SUM(Order_Quantity) AS Total_Quantity, 
    AVG(Discount_Applied) AS Average_Discount, 
    SUM((Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Total_Profit
from US_Regional_Sales_Data
group by SalesTeamID, Sales_Channel

Create View WholeSaleSales as 
select SalesTeamID, Sales_Channel, SUM(Order_Quantity) AS Total_Quantity, 
    AVG(Discount_Applied) AS Average_Discount, 
    SUM((Unit_Price - Unit_Cost) * Order_Quantity * (1 - Discount_Applied/100)) AS Total_Profit
from US_Regional_Sales_Data
where Sales_Channel like '%WholeSale%'
group by SalesTeamID, Sales_Channel



