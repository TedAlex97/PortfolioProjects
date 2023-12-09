Select * from NashvilleHousing

Select SaleDate
from NashvilleHousing

-- Standardising the date format
Select SaleDate, CONVERT(Date,SaleDate)
from NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- Alternative to the above
ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

-- Checking columns for NULL values
Select *
from NashvilleHousing
Where PropertyAddress is NULL
Order by ParcelID

-- Using duplicate ParcelID then UniqueID to identify Property Address NULLs
Select NullProp.ParcelID, NullProp.PropertyAddress, NonNullProp.ParcelID, NonNullProp.PropertyAddress
from PortfolioProject.dbo.NashvilleHousing as NullProp
JOIN PortfolioProject.dbo.NashvilleHousing as NonNullProp
	on NullProp.ParcelID = NonNullProp.ParcelID
	AND NullProp.[UniqueID ] <> NonNullProp.[UniqueID ]
WHERE NullProp.PropertyAddress is null

-- Using duplicate ParcelID then UniqueID to populate Property Address NULLs
UPDATE NullProp
SET PropertyAddress = ISNULL(NullProp.PropertyAddress, NonNullProp.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing as NullProp
JOIN PortfolioProject.dbo.NashvilleHousing as NonNullProp
	on NullProp.ParcelID = NonNullProp.ParcelID
	AND NullProp.[UniqueID ] <> NonNullProp.[UniqueID ]
WHERE NullProp.PropertyAddress is null


-- Using Substrings to split the Address column into two separate columns
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) as Address,

SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) as Address
FROM NashvilleHousing


-- Adding two new columns containing each part of the separated Address
ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)


ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))



--Using PARSENAME to spit OwnerAddress into 3 separate columns - Address, City and State
ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)

--Using distinct to identify outlier values
Select Distinct(SoldAsVacant)
from NashvilleHousing

--Standardising outlier values
UPDATE NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
	When SoldAsVacant = 'N' Then 'No'
	Else SoldAsVacant
	End
from NashvilleHousing

--Using a CTE to identify duplicates
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	Partition By ParcelID,
				PropertyAddress, 
				SalePrice, 
				SaleDate, 
				LegalReference
				ORDER BY UniqueID
				) row_num
from NashvilleHousing
)

SELECT *
from RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

--Using a CTE to delete duplicates
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	Partition By ParcelID,
				PropertyAddress, 
				SalePrice, 
				SaleDate, 
				LegalReference
				ORDER BY UniqueID
				) row_num
from NashvilleHousing
)

DELETE
from RowNumCTE
WHERE row_num > 1

--Deleting irrelevant columns
ALTER TABLE NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

