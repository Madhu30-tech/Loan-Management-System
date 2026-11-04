create database project;
use project;
select * from country_state;
select * from customer_det;
select * from customer_income;
select * from loan_status;
select * from region_info;


select * from customer_category;
select * from customer_interest;
select * from loan_cibil_score_status_details;



ALTER TABLE loan_status
DROP COLUMN `MyUnknownColumn`,
DROP COLUMN `MyUnknownColumn_[0]`,
DROP COLUMN `MyUnknownColumn_[1]`,
DROP COLUMN `MyUnknownColumn_[2]`,
DROP COLUMN `MyUnknownColumn_[3]`,
DROP COLUMN `MyUnknownColumn_[4]`,
DROP COLUMN `MyUnknownColumn_[5]`,
DROP COLUMN `MyUnknownColumn_[6]`,
DROP COLUMN `MyUnknownColumn_[7]`,
DROP COLUMN `MyUnknownColumn_[8]`,
DROP COLUMN `MyUnknownColumn_[9]`,
DROP COLUMN `Remarks Criteria`;

-- customer income status
create table customer_category as
select `Customer ID`,ApplicantIncome,
case when ApplicantIncome >15000 then 'Grade A'
	when ApplicantIncome >9000 then 'Grade B'
    when ApplicantIncome >5000 then 'Middle Class'
    else 'Low Class'
end as customer_grade
from customer_income;

select * from customer_category;


-- Monthly interest percentage 
create table customer_interest as
select c.*,l.LoanAmount,
	case when ApplicantIncome <5000 and Property_Area='Rural' then 3
		when ApplicantIncome < 5000 and Property_Area='Semirural' then 3.5
        when ApplicantIncome <5000 and Property_Area='Urban' then 5
        when ApplicantIncome <5000 and Property_Area='Semiurban' then 2.5
        else 7
	end as interest_rate
    from customer_income c inner join loan_status l
    on c.`Customer ID`=l.Customer_id;
    
drop table customer_interest;


alter table customer_interest
add monthly_interest decimal(15,2),
add annual_interest decimal(15,2);

set sql_safe_updates=0;

update customer_interest 
set monthly_interest = LoanAmount * interest_rate /100,
annual_interest = LoanAmount * interest_rate/100 *12;

select * from customer_interest;
-- loan status
drop table loan_cibil_score_status_details;

create table loan_cibil_score_status_details as 
select * from loan_status;

select * from loan_cibil_score_status_details;
alter table loan_cibil_score_status_details
add loan_processing_status varchar(50),
add cibil_status varchar(50);

-- Update Loan Processing Status
update loan_cibil_score_status_details
set loan_processing_status = 'loan still processing'
where LoanAmount is null;

-- Update CIBIL Status
update loan_cibil_score_status_details
set cibil_status =
case when `Cibil Score` >900 then 'high cibil score'
when `Cibil Score` > 750 then 'no penalty'
when `Cibil score` > 0 then 'penalty customer'
else 'reject customer'
end;

-- delete reject customer

delete from loan_cibil_score_status_details
where cibil_status='reject customer';

-- delete loan still processing customer

delete from loan_cibil_score_status_details
where loan_processing_status='loan still processing';

desc loan_cibil_score_status_details;

-- Convert Loan Amount to Integer
alter table loan_cibil_score_status_details
modify LoanAmount int;

-- row-level-trigger

delimiter $$

create trigger trg_loan_processing
before insert
on loan_cibil_score_status_details
for each row
begin
	if new.LoanAmount is null then
		set new.loan_processing_status='loan still processing';
	end if;
end $$

delimiter ;

-- row-level trigger
delimiter $$
create trigger trg_cibil_status
before insert
on loan_cibil_score_status_details 
for each row 
begin 
	if new.`Cibil Score` >900 then set new.cibil_status= 'high cibil score';
    elseif 
		new.`Cibil Score`>750 then set new.cibil_status= 'no penalty';
    elseif 
		new.`Cibil Score`>0 then set new.cibil_status='penalty customer';
    else 
		set new.cibil_status = 'reject customer';
end if;

end $$

delimiter ;
select * from loan_cibil_score_status_details;
desc loan_cibil_score_status_details;

ALTER TABLE loan_cibil_score_status_details
DROP COLUMN `MyUnknownColumn`,
DROP COLUMN `MyUnknownColumn_[0]`,
DROP COLUMN `MyUnknownColumn_[1]`,
DROP COLUMN `MyUnknownColumn_[2]`,
DROP COLUMN `MyUnknownColumn_[3]`,
DROP COLUMN `MyUnknownColumn_[4]`,
DROP COLUMN `MyUnknownColumn_[5]`,
DROP COLUMN `MyUnknownColumn_[6]`,
DROP COLUMN `MyUnknownColumn_[7]`,
DROP COLUMN `MyUnknownColumn_[8]`,
DROP COLUMN `MyUnknownColumn_[9]`,
DROP COLUMN `Remarks Criteria`;

-- customer info update gender and age based on customer id
ALTER TABLE loan_cibil_score_status_details
ADD Gender VARCHAR(20),
ADD Age INT;

UPDATE loan_cibil_score_status_details l
JOIN customer_det c
ON l.Customer_id = c.`Customer ID`
SET
    l.Gender = c.Gender,
    l.Age = c.Age;
    
-- country state and region
select cs.customer_id, cs.Customer_name,cs.State,cs.Region_id,r.Region 
from country_state cs 
join region_info r
on cs.Region_id = r.Region_id;

-- Join all the 5 tables without repeating the fields 
select cd.`Customer ID`, cd.Customer_name,cd.Gender,cd.Age,cd.Married,cd.Education,
ci.ApplicantIncome,ci.CoapplicantIncome,
ls.LoanAmount,ls.Loan_amount_term,ls.`Cibil Score`,ls.cibil_status,
cs.State,cs.Postal_code, cs.Segment,
r.region
from customer_det cd 
join customer_income ci 
on cd.`Customer ID`=ci.`Customer ID`
join loan_cibil_score_status_details ls
on cd.Loan_ID=ls.Loan_ID
join country_state cs
on cd.`Customer ID`=cs.Customer_id
join region_info r
on cs.Region_id=r.Region_id;

-- DESC customer_det;
-- DESC customer_income;

 -- find the mismatch details using joins 
 
    SELECT cd.`Customer ID`, cd.Customer_name
    FROM customer_det cd
    LEFT JOIN loan_cibil_score_status_details ls
    ON cd.Loan_Id = ls.Loan_ID
    WHERE ls.Loan_ID IS NULL;

-- Filter high cibil score 
    SELECT *
    FROM loan_cibil_score_status_details
    WHERE cibil_status = 'high cibil score';

-- Filter Home Office and Corporate
select * from country_state
where segment in ('home office','corporate');

delimiter $$

create procedure final_output()
begin
-- Join all the 5 tables without repeating the fields
	select cd.`Customer ID`, cd.Customer_name,cd.Gender,cd.Age,cd.Married,cd.Education,
ci.ApplicantIncome,ci.CoapplicantIncome,
ls.LoanAmount,ls.Loan_amount_term,ls.`Cibil Score`,ls.cibil_status,
cs.State,cs.Postal_code, cs.Segment,
r.region
from customer_det cd 
join customer_income ci 
on cd.`Customer ID`=ci.`Customer ID`
join loan_cibil_score_status_details ls
on cd.Loan_ID=ls.Loan_ID
join country_state cs
on cd.`Customer ID`=cs.Customer_id
join region_info r
on cs.Region_id=r.Region_id;

-- find the mismatch details using joins
SELECT cd.`Customer ID`, cd.Customer_name
    FROM customer_det cd
    LEFT JOIN loan_cibil_score_status_details ls
    ON cd.Loan_Id = ls.Loan_ID
    WHERE ls.Loan_ID IS NULL;

-- Filter high cibil score    
 SELECT *
    FROM loan_cibil_score_status_details
    WHERE cibil_status = 'high cibil score';

-- Filter Home Office and Corporate
select * from country_state
where segment in ('home office','corporate');

end $$

delimiter ;

call final_output();
   




