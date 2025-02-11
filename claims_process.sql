--Data Cleaning

--Check for Missing Values
SELECT * 
FROM claims 
WHERE claim_id IS NULL 
   OR policy_id IS NULL 
   OR claim_type IS NULL 
   OR provider_id IS NULL 
   OR staff_id IS NULL 
   OR claim_amount IS NULL 
   OR submission_date IS NULL 
   OR status IS NULL 
   OR num_customer_contacts IS NULL;
   
SELECT * 
FROM policies 
WHERE policy_id IS NULL 
   OR policyholder_name IS NULL 
   OR policy_type IS NULL;
   
SELECT * 
FROM providers 
WHERE provider_id IS NULL 
   OR provider_name IS NULL 
   OR provider_type IS NULL 
   OR location IS NULL;
   
SELECT * 
FROM staff 
WHERE staff_id IS NULL 
   OR staff_name IS NULL 
   OR job_grade IS NULL;

--processing table with time stamps queries
 SELECT * 
FROM processing_stages_time 
WHERE stage_id IS NULL 
   OR claim_id IS NULL 
   OR stage_name IS NULL 
   OR start_time IS NULL 
   OR end_time = ' ' ;
   
   --check total null values
SELECT COUNT(*) AS NullCount
FROM processing_stages_time
WHERE end_time = '';


--converts to yyyy-mm-dd hh:mi:ss format
UPDATE processing_stages_time
SET end_time = CONVERT(VARCHAR(19), GETDATE(), 120)
WHERE end_time = '';



--Query to Identify Duplicate values
SELECT policy_id, policyholder_name, policy_type, COUNT(*) 
FROM policies 
GROUP BY policy_id, policyholder_name, policy_type 
HAVING COUNT(*) > 1;

SELECT stage_id, claim_id, stage_name, start_time, end_time, COUNT(*) 
FROM processing_stages_time 
GROUP BY stage_id, claim_id, stage_name, start_time, end_time 
HAVING COUNT(*) > 1;

SELECT provider_id, provider_name, provider_type, location, COUNT(*) 
FROM providers 
GROUP BY provider_id, provider_name, provider_type, location 
HAVING COUNT(*) > 1;

SELECT staff_id, staff_name, job_grade, COUNT(*) 
FROM staff 
GROUP BY staff_id, staff_name, job_grade 
HAVING COUNT(*) > 1;

SELECT claim_id, policy_id, claim_type, provider_id, staff_id, claim_amount, submission_date, status, num_customer_contacts, 
       COUNT(*) 
FROM claims
GROUP BY claim_id, policy_id, claim_type, provider_id, staff_id, claim_amount, submission_date, status, num_customer_contacts
HAVING COUNT(*) > 1;

select * from claims
--Formatting submission date to mm-dd-yyyy format
UPDATE claims
SET submission_date = REPLACE(submission_date, '-', '/')

UPDATE claims
SET submission_date = CONVERT(VARCHAR(10), TRY_CONVERT(DATE, submission_date, 110), 111);


-- Number of Approvals and Denials per Staff
SELECT 
    s.staff_id,
    s.staff_name,
    s.job_grade,
    COUNT(CASE WHEN c.status = 'Approved' THEN 1 END) AS ApprovedClaims,
    COUNT(CASE WHEN c.status = 'Denied' THEN 1 END) AS DeniedClaims,
    COUNT(CASE WHEN c.status = 'Pending' THEN 1 END) AS PendingClaims
FROM claims c
JOIN staff s ON c.staff_id = s.staff_id
GROUP BY s.staff_id, s.staff_name, s.job_grade
ORDER BY ApprovedClaims DESC, DeniedClaims DESC;

-- Days to process claims 

SELECT 
    c.claim_id,
    DATEDIFF(DAY, c.submission_date, p.end_date) AS Claim_Processing_Days
FROM claims c
JOIN processing_stages p ON c.claim_id = p.claim_id
WHERE p.stage_name = 'close';


--Time taken for processing by staff

SELECT 
    c.claim_id,
    c.claim_type,
    s.staff_name,
    DATEDIFF(DAY, c.submission_date, p.end_time) AS Claim_Processing_Days
FROM claims c
JOIN processing_stages_time p ON c.claim_id = p.claim_id
JOIN staff s ON c.staff_id = s.staff_id
WHERE p.stage_name = 'Close'
ORDER BY Claim_Processing_Days DESC;

--Total cout of approved ,denied and pending claims
SELECT 
    claim_type,
    status,
    COUNT(*) AS claim_count
FROM claims
GROUP BY claim_type, status
ORDER BY claim_type, status;

--Average claim amount by claim type
SELECT 
    claim_type, 
    AVG(CONVERT(REAL, claim_amount)) AS avg
FROM claims
GROUP BY claim_type
ORDER BY claim_type;

--Denial rate for claims between July 2023 and August 2023
SELECT 
    c.claim_type,
    COUNT(CASE WHEN c.status = 'Denied' THEN 1 END) * 100.0 / COUNT(*) AS denied_rate_percentage
FROM claims c
WHERE c.claim_type IN ('Basic', 'Premium')
    AND c.submission_date BETWEEN '07/01/2023' AND '08/31/2023'
GROUP BY c.claim_type;


--Processing time for claims for July and August 2023 by staff
SELECT 
    c.claim_type, c.staff_id,s.staff_name,
    AVG(DATEDIFF(HOUR, pst.start_time, pst.end_time)) AS avg_processing_hours
FROM claims c
JOIN processing_stages_time pst
    ON c.claim_id = pst.claim_id
	JOIN staff s ON s.staff_id=c.staff_id
WHERE c.claim_type IN ('Basic', 'Premium')
    AND pst.stage_name IN ('intake', 'review', 'close')
    AND c.submission_date BETWEEN '07/01/2023' AND '08/31/2023'
GROUP BY c.claim_type,s.staff_name,c.staff_id;

--Average claim processing times overall
SELECT 
    c.claim_type,
    AVG(DATEDIFF(HOUR, pst.start_time, pst.end_time)) AS avg_processing_time_days
FROM claims c
JOIN processing_stages_time pst
    ON c.claim_id = pst.claim_id
WHERE c.claim_type IN ('Basic', 'Premium')
    AND pst.stage_name IN ('intake', 'review', 'close')
	AND c.submission_date BETWEEN '07/01/2023' AND '08/31/2023'
GROUP BY c.claim_type;

--status of claims  according to locaton
SELECT status,claim_type ,location,count(*) as number_of_claims
FROM claims c
JOIN providers p ON  c.provider_id = p.provider_id
GROUP BY c.status ,p.location,c.claim_type
ORDER BY p.location;

--providers with maximum approvals
SELECT provider_name,count(*) as approvals
FROM providers p
JOIN claims c ON c.provider_id=p.provider_id
where status='approved'
GROUP BY provider_name
ORDER BY approvals desc;

--providers with max denials
SELECT provider_name,count(*) as denials
FROM providers p
JOIN claims c ON c.provider_id=p.provider_id
where status='denied'
GROUP BY provider_name
ORDER BY denials desc;

--Max claim amount as per claim type using CTE
WITH ClaimMax AS (
    SELECT 
        claim_type,
        MAX(claim_amount) AS max_claim_amount	
    FROM claims
    GROUP BY claim_type
)
SELECT 
    claim_type,
    max_claim_amount
FROM ClaimMax
ORDER BY claim_type;




--claim processing time by job grade in days
SELECT 
    c.claim_type,
    s.job_grade,
    AVG(DATEDIFF(DAY, ps.start_date, ps.end_date)) AS avg_processing_time_days
FROM claims c
JOIN processing_stages ps
    ON c.claim_id = ps.claim_id
JOIN staff s
    ON c.staff_id = s.staff_id
WHERE c.claim_type IN ('Basic', 'Premium')
    AND ps.stage_name IN ('intake', 'review', 'close')
GROUP BY c.claim_type, s.job_grade;


--claim processing time by job grade in hours
SELECT 
    c.claim_type,
    s.job_grade,
    AVG(DATEDIFF(HOUR, pst.start_time, pst.end_time)) AS avg_processing_hours
FROM claims c
JOIN processing_stages_time pst
    ON c.claim_id = pst.claim_id
JOIN staff s
    ON c.staff_id = s.staff_id
WHERE c.claim_type IN ('Basic', 'Premium')
    AND pst.stage_name IN ('intake', 'review', 'close')
GROUP BY c.claim_type, s.job_grade;


--time taken by staff to process claims based on staff id and job grade
SELECT 
    c.claim_id,
    s.staff_id,
    s.job_grade,
    DATEDIFF(HOUR, c.submission_date, p.end_time) AS Claim_Processing_Hours
FROM claims c
JOIN processing_stages_time p ON c.claim_id = p.claim_id
JOIN staff s ON c.staff_id = s.staff_id  -- Ensuring staff ID is included
WHERE p.stage_name = 'close';



--average processing times as per seniority/job grade

SELECT 
    s.job_grade,
	 COUNT(s.staff_id) * 1.0 / (SELECT COUNT(*) FROM staff)/100 AS job_grade_percentage,
    AVG(DATEDIFF(HOUR, c.submission_date, pst.end_time)) AS avg_processing_hours
FROM staff s
JOIN claims c ON s.staff_id = c.staff_id  
JOIN processing_stages_time pst ON c.claim_id = pst.claim_id
WHERE pst.stage_name = 'close'
GROUP BY s.job_grade

--coorelation between processing time and number of times customer contacted
SELECT 
    c.num_customer_contacts,
    AVG(DATEDIFF(HOUR, c.submission_date, pst.end_time)) AS avg_processing_hours
FROM claims c
JOIN processing_stages_time pst ON c.claim_id = pst.claim_id
WHERE pst.stage_name = 'close'
GROUP BY c.num_customer_contacts
ORDER BY c.num_customer_contacts;


--number of customer contacts in July and August 2023
SELECT 
    claim_type,
    SUM(CAST(num_customer_contacts AS INT)) AS total_customer_contacts
FROM claims
WHERE claim_type IN ('Basic', 'Premium')
  AND submission_date BETWEEN '2023/07/01' AND '2023/08/31'
GROUP BY claim_type
ORDER BY claim_type


----number of customer contacts a month before policy change
SELECT 
    claim_type,
    SUM(CAST(num_customer_contacts AS INT)) AS total_customer_contacts
FROM claims
WHERE claim_type IN ('Basic', 'Premium')
  AND submission_date BETWEEN '06-30-2023' AND '07-31-2023'
GROUP BY claim_type
ORDER BY claim_type;

----number of customer contacts a month after policy change
SELECT 
    claim_type,
    SUM(CAST(num_customer_contacts AS INT)) AS total_customer_contacts
FROM claims
WHERE claim_type IN ('Basic', 'Premium')
  AND submission_date BETWEEN '08-31-2023' AND '09-30-2023'
GROUP BY claim_type
ORDER BY claim_type;








