
-- Selecting the data I'll be using
select PhoneName, Brand, OperatingSystem, Resolution, [Ram(GB)], [Weight(g)], [Storage(GB)], Video720p, Video1080p, Video8K, Video4K, Video960fps
from dbo.PhoneSpecs
order by 2

select * from dbo.PhonePrices
order by 2,5

-- How many phones has each brand announced?
select Brand, COUNT(PhoneName) as PhonesAnnounced
from PhonePrices
group by Brand
order by 2 desc

-- From phones announced in 2018, what is the most cost efficient phone per mAh of battery power?
select *, ([BatteryPower(mAh)]/[Price(USD)]) as 'BatteryPower(mAh) per dollar'
from dbo.PhonePrices
Where AnnouncementDate like '%2018%'
order by 8 desc

-- Which phone has the highest Storage(GB) per gram of weight?
select PhoneName, Brand, OperatingSystem, Resolution, [Ram(GB)], [Weight(g)], [Storage(GB)], ([Storage(GB)]/[Weight(g)]) as 'GB of Storage per Gram of Weight'
from dbo.PhoneSpecs
order by 8 desc

-- For each brand, what is the cost of the phone with the most battery power(mAh)?
select Brand, PhoneName, [BatteryPower(mAh)], [Price(USD)]
from (select *, ROW_NUMBER( ) over (Partition by Brand ORDER BY [BatteryPower(mAh)] desc) rn
from dbo.PhonePrices
) T
WHERE T.rn=1
Order by Brand

-- What is the cheapest phone with the highest video quality?
Select price.Brand, price.PhoneName, price.[Price(USD)], spec.Video8K
from PhonePrices price
join dbo.PhoneSpecs spec
	on price.PhoneName = spec.PhoneName
	and price.Brand = spec.Brand
Where spec.Video8K = 1
Order by [Price(USD)]

-- In chronological order of announcement date, how many of each brand's phones had Video 4K capabilities?
Select price.Brand, price.PhoneName, AnnouncementDate, SUM(CONVERT(int,Video4K)) OVER (Partition by price.Brand Order by AnnouncementDate, price.PhoneName) as Chronilogical4KPhoneQuantity
from PhonePrices price
join dbo.PhoneSpecs spec
	on price.PhoneName = spec.PhoneName
	and price.Brand = spec.Brand
Order by 1 desc, 3


-- Chronologically by date, what % of each brand's phones had 4k Video capabilities?
DROP TABLE IF EXISTS #PhoneVideoQuality
Create Table #PhoneVideoQuality
(
Brand nvarchar(255),
PhoneName nvarchar(255),
AnnouncementDate nvarchar(255),
Overall4KPerBrand int,
Chronilogical4KPhoneQuantity int
)
Insert into #PhoneVideoQuality
Select price.Brand, price.PhoneName, AnnouncementDate, COUNT(spec.Video4K) OVER (Partition by price.Brand), SUM(CONVERT(int,Video4K)) OVER (Partition by price.Brand Order by AnnouncementDate, price.PhoneName) as Chronilogical4KPhoneQuantity
from PhonePrices price
join dbo.PhoneSpecs spec
	on price.PhoneName = spec.PhoneName
	and price.Brand = spec.Brand
Order by 1 desc, 3

Select *, CAST(Chronilogical4KPhoneQuantity AS float) / CAST(Overall4KPerBrand AS float)*100 as 'RollingOverall4K%'
from #PhoneVideoQuality

-- Using a CTE to produce the same result as the above
;With PhoneQuality (Brand, PhoneName, AnnouncementDate, Overall4KPerBrand, Chronilogical4KPhoneQuantity)
as
(
Select price.Brand, price.PhoneName, AnnouncementDate, COUNT(spec.Video4K) OVER (Partition by price.Brand) as Overall4KPerBrand, SUM(CONVERT(int,Video4K)) OVER (Partition by price.Brand Order by AnnouncementDate, price.PhoneName) as Chronilogical4KPhoneQuantity
from PhonePrices price
join dbo.PhoneSpecs spec
	on price.PhoneName = spec.PhoneName
	and price.Brand = spec.Brand
)
Select *, CAST(Chronilogical4KPhoneQuantity AS float) / CAST(Overall4KPerBrand AS float)*100 as 'RollingOverall4K%'
from #PhoneVideoQuality


-- Creating view to store data for lata visualisations
Create View PhoneQuality as
Select price.Brand, price.PhoneName, AnnouncementDate, COUNT(spec.Video4K) OVER (Partition by price.Brand) as Overall4KPerBrand, SUM(CONVERT(int,Video4K)) OVER (Partition by price.Brand Order by AnnouncementDate, price.PhoneName) as Chronilogical4KPhoneQuantity
from PhonePrices price
join dbo.PhoneSpecs spec
	on price.PhoneName = spec.PhoneName
	and price.Brand = spec.Brand

Create View PhonesPerBrand as
select Brand, COUNT(PhoneName) as PhonesAnnounced
from PhonePrices
group by Brand

Create View MostBatteryPowerCost as
select Brand, PhoneName, [BatteryPower(mAh)], [Price(USD)]
from (select *, ROW_NUMBER( ) over (Partition by Brand ORDER BY [BatteryPower(mAh)] desc) rn
from dbo.PhonePrices
) T
WHERE T.rn=1