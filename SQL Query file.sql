CREATE TABLE day_wise_user_activity (
    activity_datetime TIMESTAMP,
    user_id VARCHAR(50),
    unit_id VARCHAR(50),
    unit_type VARCHAR(50),
	day_completion_percentage FLOAT,
    overall_completion_percentage FLOAT
);
COPY day_wise_user_activity FROM 'D:\PROJECTS\Courses - SQL\day_wise_user_activity.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE user_basic_details (
	user_id VARCHAR(10),
	gender VARCHAR(10),
	current_city VARCHAR(50),
	batch_start_datetime TIMESTAMP,
	referral_source VARCHAR(50),
	highest_qualification VARCHAR(30)
);
COPY user_basic_details FROM 'D:\PROJECTS\Courses - SQL\users_basic_details.csv' DELIMITER ',' CSV HEADER;

CREATE TABLE learning_resource_details (
	program_id  VARCHAR(10),
	program_title  VARCHAR(50),
	course_id  VARCHAR(10),
	course_title  VARCHAR(30),
	topic_id  VARCHAR(10),
	unit_id  VARCHAR(10),
	unit_type VARCHAR(30),
	unit_duration_in_mins INT
);
COPY learning_resource_details FROM 'D:\PROJECTS\Courses - SQL\learning_resource_details.csv' DELIMITER ',' CSV HEADER;


-- ----------------------------------
-- Find the average completion percentage of units for each user.

SELECT 
	t1.user_id,
	ROUND(AVG(t2.overall_completion_percentage)::NUMERIC,2) as Average_completion
FROM 
	user_basic_details t1 JOIN
	day_wise_user_activity t2 ON t1.user_id=t2.user_id
GROUP BY 1
ORDER BY 2 DESC;
	
-- Calculate the total number of units completed in LEARNING_SET by users residing in HYDERABAD location.
WITH cte AS(
		SELECT 
		t1.USER_ID, t2.UNIT_ID, t2.OVERALL_COMPLETION_PERCENTAGE,t1.CURRENT_CITY
		FROM 
			user_basic_details t1 JOIN
			day_wise_user_activity t2 ON t1.user_id=t2.user_id 
				AND t2.overall_completion_percentage=100 
				AND t1.CURRENT_CITY ='Hyderabad'
				AND t2.unit_type ='LEARNING_SET')
SELECT user_id,COUNT(unit_id) units_completed 
FROM cte
GROUP BY 1
ORDER BY COUNT(unit_id) DESC;

-- Find the programs with the highest completion rates from each city.
WITH cte AS
	(SELECT 
		t3.current_city,t1.program_title,t2.overall_completion_percentage
	FROM
		learning_resource_details t1
		JOIN day_wise_user_activity t2 on t1.unit_id=t2.unit_id
		JOIN user_basic_details t3 on t2.user_id=t3.user_id
),
cte2 as(
	SELECT current_city,program_title,
		AVG(overall_completion_percentage) OVER (PARTITION by current_city,program_title ) as average_completion
	FROM cte),
cte3 as
	(select 
		current_city,program_title,average_completion,ROW_NUMBER() OVER (PARTITION BY current_city ORDER BY average_completion desc) as rn
	from cte2)
SELECT current_city as city,program_title from cte3
where rn=1;

-- Count the number of units of each type within each course.

SELECT 
	course_title,
	SUM(CASE WHEN unit_type='QUESTION_SET' THEN 1 ELSE 0 END) as Question_set,
	SUM(CASE WHEN unit_type='PRACTISE' THEN 1 ELSE 0 END) as PRACTISE,
	SUM(CASE WHEN unit_type='LEARNING_SET' THEN 1 ELSE 0 END) as LEARNING_TYPE,
	SUM(CASE WHEN unit_type='PROJECT' THEN 1 ELSE 0 END) as PROJECT,
	SUM(CASE WHEN unit_type='EXAM' THEN 1 ELSE 0 END) as EXAM
FROM learning_resource_details
GROUP BY course_title;


-- Identify users who have completed the most units within the last month.
WITH cte AS
	(SELECT 
		EXTRACT ( DAYS from ((SELECT MAX(activity_datetime) FROM day_wise_user_activity)-t2.activity_datetime) ) as days,
		t1.user_id,t2.unit_id,t2.overall_completion_percentage
	FROM 
		user_basic_details t1
		JOIN day_wise_user_activity t2 ON t2.user_id=t1.user_id
		AND t2.overall_completion_percentage=100
		AND t2.activity_datetime >= (SELECT MAX(activity_datetime) FROM day_wise_user_activity) - INTERVAL '1 month')

SELECT user_id,COUNT(DISTINCT unit_id) AS number_of_units_completed
FROM cte
GROUP BY 1
ORDER BY 2 DESC;

-- Determine the percentage of users belonging to each educational qualification category.

with cte as
	(select highest_qualification,count(user_id) as no_of_users
	from user_basic_details
	group by 1)
select 
	highest_qualification,
	concat(round((no_of_users/(select sum(no_of_users) FROM cte)*100),1),' %') as percentage
from cte
order by no_of_users desc



