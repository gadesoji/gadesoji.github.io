

--1. Count male vs female patients and calculate their percentage share.
SELECT 
    [Sex],
    COUNT(*) AS patient_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage_share
FROM 
    [dbo].[Dataset$]
WHERE 
    [Sex] IN ('Male', 'Female')
GROUP BY 
    [Sex];

--2. Find the average age at diagnosis using Primary_Diagnosis_Date - Date_of_Birth.
SELECT AVG (DATEDIFF(YEAR, [Date_of_Birth], [Primary_Diagnosis_Date])) AS 'avg_diagnostic_age'
FROM [dbo].[Dataset$];

--3. Identify GP practices with the highest number of registered cancer patients.
SELECT  TOP 10
        [GP_Practice_Code], COUNT([NHS_Number]) AS number_of_patients
FROM [dbo].[Dataset$]
GROUP BY [GP_Practice_Code] 
ORDER BY number_of_patients DESC;

--4. List postcode areas (first 1–2 characters) and count patients in each.
SELECT 
    CASE 
        WHEN SUBSTRING(LTRIM([Postcode]), 2, 1) LIKE '[0-9]' THEN LEFT(LTRIM([Postcode]), 1)
        ELSE LEFT(LTRIM([Postcode]), 2)
    END AS postcode_area,
    COUNT(Local_Patient_ID) AS patient_count
FROM [dbo].[Dataset$]
WHERE [postcode] IS NOT NULL AND [postcode] <> ''
GROUP BY 
    CASE 
        WHEN SUBSTRING(LTRIM([postcode]), 2, 1) LIKE '[0-9]' THEN LEFT(LTRIM([postcode]), 1)
        ELSE LEFT(LTRIM([postcode]), 2)
    END
ORDER BY patient_count DESC;    

--5. Detect duplicate NHS_Number values and list all rows involved.
SELECT [NHS_Number], COUNT(*) AS 'occurences' 
FROM [dbo].[Dataset$]
GROUP BY [NHS_Number]
HAVING COUNT(*)>1;

--🧫 Tumour site, morphology, and staging

--1. Count patients by Primary_Tumour_Site_ICD10 and return the top five.
SELECT  TOP 5
        [Primary_Tumour_Site_ICD10], 
        COUNT(*) AS 'occurences' 
FROM [dbo].[Dataset$]
GROUP BY [Primary_Tumour_Site_ICD10]
ORDER BY 2 DESC;

--2. Count distinct Morphology_ICDO3 codes and list their frequencies.
SELECT  [Morphology_ICDO3], 
        COUNT(*) AS 'frequencies' 
FROM [dbo].[Dataset$]
GROUP BY [Morphology_ICDO3]
ORDER BY 2 DESC;

--3. Calculate the number of patients in each Stage_Group_TNM category.
SELECT  TOP 5
        [Stage_Group_TNM], 
        COUNT(*) AS 'number_of_patients' 
FROM [dbo].[Dataset$]
GROUP BY [Stage_Group_TNM]
ORDER BY 2 DESC;
--4. Identify the tumour site with the highest proportion of Stage IV cases.
SELECT  TOP 1
        [Primary_Tumour_Site_ICD10], 
        [Stage_Group_TNM],
        COUNT([Stage_Group_TNM]) AS 'number_of_patients' 
FROM [dbo].[Dataset$]
GROUP BY [Primary_Tumour_Site_ICD10], [Stage_Group_TNM]
HAVING [Stage_Group_TNM] = 'Stage IV'
ORDER BY 3 DESC;
