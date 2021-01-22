use pharmacy_claims;

#############
#I have used table data import wizard to directly create tables, columns and import data from csv in default format. 
#updating all the columns data types to the   types mentioned in the final project csv
alter table dim_drug_brand
modify drug_brand_generic_desc VARCHAR(10);

alter table dim_drug_form
modify drug_form_code CHAR(2),
modify drug_form_desc VARCHAR(100);

alter table dim_drug_details
modify drug_name VARCHAR(100),
modify drug_form_code CHAR(2);

UPDATE dim_patient_desc 
SET member_birth_date = STR_TO_DATE(member_birth_date, '%m/%d/%Y');
alter table dim_patient_desc
modify member_id int,
modify member_first_name VARCHAR(100),
modify member_last_name VARCHAR(100),
modify member_birth_date date,
modify member_age int,
modify member_gender CHAR(1);

UPDATE fact_payment 
SET fill_date = STR_TO_DATE(fill_date, '%m/%d/%Y');
alter table fact_payment
modify fill_date date;


############
#added primary key and secondary key> clicked setting icon on each table and updated column and foreign key tabs. 
#Below are the queries for the same taken from DDL tab

#primary key for dim_drug_brand table
ALTER TABLE `pharmacy_claims`.`dim_drug_brand` 
CHANGE COLUMN `drug_brand_generic_code` `drug_brand_generic_code` INT(11) NOT NULL ,
ADD PRIMARY KEY (`drug_brand_generic_code`);

#primary key for dim_drug_form table
ALTER TABLE `pharmacy_claims`.`dim_drug_form` 
CHANGE COLUMN `drug_form_code` `drug_form_code` CHAR(2) NOT NULL ,
ADD PRIMARY KEY (`drug_form_code`);

#primary key for dim_patient_desc table
ALTER TABLE `pharmacy_claims`.`dim_patient_desc` 
CHANGE COLUMN `member_id` `member_id` INT(11) NOT NULL ,
ADD PRIMARY KEY (`member_id`);

#Primary key for dim_drug_details table
ALTER TABLE `pharmacy_claims`.`dim_drug_details` 
CHANGE COLUMN `drug_ndc` `drug_ndc` INT(11) NOT NULL ,
ADD PRIMARY KEY (`drug_ndc`),
ADD INDEX `dim_drug_form_idx` (`drug_form_code` ASC) VISIBLE,
ADD INDEX `drug_brand_generic_code_idx` (`drug_brand_generic_code` ASC) VISIBLE;
;
#Foreign key for dim_drug_details table
ALTER TABLE `pharmacy_claims`.`dim_drug_details` 
ADD CONSTRAINT `dim_drug_form`
  FOREIGN KEY (`drug_form_code`)
  REFERENCES `pharmacy_claims`.`dim_drug_form` (`drug_form_code`)
  ON DELETE SET NULL
  ON UPDATE RESTRICT,
ADD CONSTRAINT `drug_brand_generic_code`
  FOREIGN KEY (`drug_brand_generic_code`)
  REFERENCES `pharmacy_claims`.`dim_drug_brand` (`drug_brand_generic_code`)
  ON DELETE SET NULL
  ON UPDATE RESTRICT;

#Primary key for fact_payment table
ALTER TABLE `pharmacy_claims`.`fact_payment` 
ADD COLUMN `payment_id` INT NOT NULL AUTO_INCREMENT AFTER `insurancepaid`,
ADD PRIMARY KEY (`payment_id`);

#Foreign key for fact_payment table
ALTER TABLE `pharmacy_claims`.`fact_payment` 
ADD INDEX `member_id_idx` (`member_id` ASC) VISIBLE,
ADD INDEX `drug_ndc_idx` (`drug_ndc` ASC) VISIBLE;
;
ALTER TABLE `pharmacy_claims`.`fact_payment` 
ADD CONSTRAINT `member_id`
  FOREIGN KEY (`member_id`)
  REFERENCES `pharmacy_claims`.`dim_patient_desc` (`member_id`)
  ON DELETE SET NULL
  ON UPDATE RESTRICT,
ADD CONSTRAINT `drug_ndc`
  FOREIGN KEY (`drug_ndc`)
  REFERENCES `pharmacy_claims`.`dim_drug_details` (`drug_ndc`)
  ON DELETE SET NULL
  ON UPDATE RESTRICT;

##################
#Analytics and Reporting

#Write a SQL query that identifies the number of prescriptions grouped by drug name. 
select dd.drug_name, count(*) as no_of_prescriptions 
from dim_drug_details dd 
left join fact_payment fp
on dd.drug_ndc = fp.drug_ndc
group by drug_name
order by count(*) desc;

#Write a SQL query that counts total prescriptions, counts unique (i.e. distinct) members, 
#sums copay $$, and sums insurance paid $$, for members grouped as either ‘age 65+’ or ’ < 65’. 
select count(*) as total_prescriptions, 
count(distinct fp.member_id) as total_members, 
sum(fp.copay) as total_copay, 
sum(fp.insurancepaid) as total_insurance_paid, 
case 
when pd.member_age<65 then 'age <= 65'
when pd.member_age> 65 then 'age 65+'
end as age_group
from fact_payment fp
left join dim_patient_desc pd
on fp.member_id = pd.member_id
group by age_group;

#Write a SQL query that identifies the amount paid by the insurance for the most recent prescription fill date. 
#Your output should be a table with member_id, member_first_name, member_last_name, drug_name, fill_date (most recent), and most recent insurance paid. 
with temp_table as
(
select *, row_number() over (partition by member_id order by fill_date desc) as recent
from fact_payment
)
select cte.member_id, pd.member_first_name, pd.member_last_name, dd.drug_name, cte.fill_date as recent_fill_date, cte.insurancepaid as recent_insurance_paid
from temp_table cte
left join dim_patient_desc pd
on cte.member_id = pd.member_id
left join dim_drug_details dd
on cte.drug_ndc = dd.drug_ndc
where recent = 1
order by cte.member_id;
