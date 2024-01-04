                                             /*   Data Cleaning in SQL   */


--viewing first 100 rows of the data:
USE [SQL Data Cleaning Project ];
SELECT TOP(100) *
FROM [SQL Data Cleaning Project ].dbo.Nashville_Housing;
--Checking all 56,477 rows have successfully imported:
SELECT COUNT(*) AS 'Number of Rows'
FROM [SQL Data Cleaning Project ].dbo.Nashville_Housing;


--here will Clean and Process 'Nashville_Housing' Dataset so it is well prepared for any future analysis and data visualization.
/* OVERVIEW: Standardize Date Format, 
             Split PropertyAddress and OwnerAddress (into Address, City, State), 
			 Standardize 'Sold as Vacant' column, 
			 Remove Duplicates, 
			 Delete Unused Columns
*/

--                 Standardizing Date Columns (ensure they are 'DATE' Data Type)
SELECT CAST(SaleDate AS Date) AS 'SaleDate'
FROM [SQL Data Cleaning Project ].dbo.Nashville_Housing;
--Updating for ALL Rows of 'SaleDate' COLUMN in 'Nashvile_Housing' Table:
UPDATE Nashville_Housing
SET SaleDate = CAST(SaleDate AS Date)
--(Note: if UPDATE does not work, use 'ALTER TABLE Nashville_Housing' to 'ADD SalesDateConverted;' as NEW COLUMN. THEN UPDATE this New Column's values to CAST(SaleDate AS Date).


--              Identify and FILL IN (populate) Missing Values in 'PropertyAddress' Column:
-- 1. Identify NULL Values in 'PropertyAddress' Column
SELECT *
FROM [SQL Data Cleaning Project ].dbo.Nashville_Housing
WHERE PropertyAddress IS NULL    --29 Null/Missing Values
--PropertyAddress will STAY the SAME, so need REFERENCE POINT to BASE PropertyAddress off of!
-- 2. INVESTIGATE the DATA, see if Values for Missing PropertyAddress Data can be FOUND:
SELECT *
FROM [SQL Data Cleaning Project ].dbo.Nashville_Housing
--WHERE PropertyAddress IS NULL    
ORDER BY ParcelID;
--Notice than rows that have SAME 'ParcelID' = SAME 'PropertyAddress' (i.e. each ParcelID is for a SPECIFIC PropertyAddress ONLY, often repeated for different UniqueIDs)
--The NULL PropertyAddress values have the SAME 'ParcelID' as these! 
-- 3. So FILL IN Missing PropertyAddress using SELF JOIN (table with itself):
SELECT nh1.ParcelId, nh1.PropertyAddress, nh2.ParcelID, nh2.PropertyAddress,
       ISNULL(nh1.PropertyAddress,nh2.PropertyAddress) AS 'cleaned_PropertyAddress'
FROM Nashville_Housing nh1
INNER JOIN Nashville_Housing nh2
ON nh1.ParcelID = nh2.ParcelID
AND nh1.UniqueID != nh2.UniqueID  
WHERE nh1.PropertyAddress IS NULL;
--Here JOINED where UniqueIDs are NOT EQUAL (!=), since want matches with SAME ParcelID but DIFFERENT UniqueID - Makes Sense!
--used function 'ISNULL(column_value, replace_with)'
--(IF 'PropertyAddress' value in 1st join table is NULL, then REPLACES with 'PropertyAddress' value in 2nd join table)
-- 4. UPDATE 'Nashville_Housing' Table with Cleaned (filled-in) 'PropertyAddress' Column: 
UPDATE nh1       -- use 'Table ALIAS' here 
SET PropertyAddress = ISNULL(nh1.PropertyAddress,nh2.PropertyAddress) 
FROM Nashville_Housing nh1
JOIN Nashville_Housing nh2
ON nh1.ParcelID= nh2.ParcelID
AND nh1.UniqueID != nh2.UniqueID 
WHERE nh1.PropertyAddress IS NULL;
--Re-running the ABOVE Query, should be EMPTY (all NULLS have been REPLACED now!)
--also updated for the ORIGINAL Table (Nashville_Housing)



--                   Split Address into Individual Columns ('Address', 'City' and 'State' Columns)                                   
-- Comma within 'PropertyAddress' values SEPARATES the actual address from the actual Location/City (e.g. '1005 MERIDIAN ST, NASHVILLE')
SELECT PropertyAddress
FROM Nashville_Housing;
--can be done using 'SUBSTRING()' and 'CHARINDEX()':
SELECT PropertyAddress, 
       --extract substring from 'start' to '1 character BEFORE the Comma' (hence '-1') 
       SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1) AS 'Address',
	   --extract substring from '1 character AFTER Comma' to LENGTH/END of Property Address ('LEN' just ensures it goes ALL THE WAY to the END of the string)
       SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress)) AS 'Address'
FROM Nashville_Housing;
--ADD these as NEW COLUMNS to Nashville_Housing:
ALTER TABLE Nashville_Housing
ADD PropertySplitAddress nvarchar(255);
UPDATE Nashville_Housing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) - 1) 
ALTER TABLE Nashville_Housing
ADD PropertySplitCity nvarchar(255);
UPDATE Nashville_Housing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) + 1, LEN(PropertyAddress))
--viewing to verify columns were successfully added:
SELECT PropertySplitAddress, PropertySplitCity
FROM Nashville_Housing;     --much more usable data now!


--Similarly, SPLITTING 'OwnerAddress', now into 3 Separate Columns for 'Address, City and State':
SELECT OwnerAddress
FROM Nashville_Housing;  
--INSTEAD will use 'PARSENAME' Function (Another String Splitting Method - simpler to split when there are MULTIPLE DELIMITERS):
--PARSENAME() is ONLY useful with REPEATED 'PERIODS' (full-stop)
--So must use 'REPLACE' function to REPLACE ',' with a PERIOD '.' (full-stop):
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
       PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
       PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Nashville_Housing;
--(much quicker than using SUBSTRING Method)
--Adding these as new columns:
ALTER TABLE Nashville_Housing
ADD OwnerSplitAddress nvarchar(255);
UPDATE Nashville_Housing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3);
ALTER TABLE Nashville_Housing
ADD OwnerSplitCity nvarchar(255);
UPDATE Nashville_Housing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2);
ALTER TABLE Nashville_Housing
ADD OwnerSplitState nvarchar(255);
UPDATE Nashville_Housing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

--viewing to verify that split columns were successfully added:
SELECT OwnerSplitCity, OwnerSplitState, OwnerSplitAddress
FROM Nashville_Housing;      --much more usable data now!



--         Standardise 'SoldAsVacant' Column so contains 'Yes' and 'No' values (boolean)
SELECT SoldAsVacant, COUNT(SoldAsVacant) AS 'Count'
FROM Nashville_Housing
GROUP BY SoldAsVacant 
ORDER BY 2; 
--In ORIGINAL Excel file, 'SoldAsVacant' contained values 'Yes', 'No', 'Y' and 'N' 
--when imported, SQL Server cleverly converted to 'bit' data type (boolean values '1 = Yes or Y', '0 = No or N'
--must replace '1' and '0' with 'Yes' and 'No' (more readable)
--Could use using REPLACE Function:
SELECT SoldAsVacant, REPLACE(CAST(SoldAsVacant AS nvarchar(10)), '1', 'Yes') AS '1_replaced', REPLACE(CAST(SoldAsVacant AS nvarchar(10)), '0', 'No') AS '0_replaced'
FROM Nashville_Housing;   --(then create new column in the Table, with these replaced values)
--BETTER to use a CASE Statement to quickly create a new column with 'Yes' and 'No' Values:
SELECT SoldAsVacant, 
      CASE
	      WHEN SoldAsVacant = '1' THEN 'Yes'
		  WHEN SoldAsVacant = '0' THEN 'No'
	 END AS 'SoldAsVacant_Updated'
FROM Nashville_Housing;
--ADD this CASE Statement as a NEW COLUMN:
ALTER TABLE Nashville_Housing
ADD SoldAsVacant_Updated nvarchar(10);
UPDATE Nashville_Housing
SET SoldAsVacant_Updated = CASE
	      WHEN SoldAsVacant = '1' THEN 'Yes'
		  WHEN SoldAsVacant = '0' THEN 'No'
	 END; 
--Finally verifying that all rows successfully updated:
SELECT SoldAsVacant_Updated, COUNT(*)
FROM Nashville_Housing
GROUP BY SoldAsVacant_Updated
ORDER BY 2 DESC;



--                        REMOVE DUPLICATES
--not done as much in SQL (preferable to keep data, rather than delete it) 
--note: MUST be done WITH REASON (not standard practice) 
--Start by IDENTIFYING 'DUPLICATE ROWS' (using CTE and WINDOWS Functions):
--add 'ROW_NUMBER' column
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER (
         --Partition By Columns which SHOULD have UNIQUE VALUES in EACH ROW (note - here, excluded 'UniqueID', just for demonstration)
		 --(i.e. so IF any of these values happens to be DUPLICATED, will show up as another row_num)
         PARTITION BY ParcelID, 
		               PropertyAddress,
					   SalePrice,
					   SaleDate,
					   LegalReference
         ORDER BY UniqueID) AS 'row_num'
FROM Nashville_Housing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1      -- (i.e. where a Row is a DUPLICATE of another - makes sense!)
ORDER BY PropertyAddress;
--returns ALL Duplicate Rows (with row_num = 2) - have 104 duplicates. 
--now just repeat above, but as 'DELETE FROM' Statement:
WITH RowNumCTE AS(
SELECT *, ROW_NUMBER() OVER (
         --Partition By Columns which SHOULD have UNIQUE VALUES in EACH ROW (note - here, excluded 'UniqueID', just for demonstration)
		 --(i.e. so IF any of these values happens to be DUPLICATED, will show up as another row_num)
         PARTITION BY ParcelID, 
		               PropertyAddress,
					   SalePrice,
					   SaleDate,
					   LegalReference
         ORDER BY UniqueID) AS 'row_num'
FROM Nashville_Housing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1;      -- 104 rows affected - perfect!



--                   DELETE UNUSED COLUMNS:
-- Delete Columns like the original 'OwnerAddress', 'PropertyAddress' and 'TaxDistrict'
ALTER TABLE Nashville_Housing
DROP COLUMN SoldAsVacant, OwnerAddress, PropertyAddress, TaxDistrict;
--Check these Columns were removed:
SELECT *
FROM Nashville_Housing;
--Now, can RENAME some of the COLUMNS:
--in MS SQL Server, can simply right-click the Column in Object Explorer Menu and 'Modify'. 

--Now have much more USABLE Columns for any potential analysis.







