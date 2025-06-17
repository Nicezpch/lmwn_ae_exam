/* ======================================================== */
/*  CUSTOMER SERVICE TEAM (Abbreviation = CST/cst)  */
/* ======================================================== */

/*	List tables
 * Vocabs 
 * - Tier 0 >> transaction level
 * - Tier 1 >> prepared report rawdata level
 * - Tier 2 >> report data level
 * 
 * 	1. ae_exam_db.main.report_csr_complaint_summary
 * 		::> report layer (tier 2) - Complaint summary report daily transaction level for dashboard
 * 		
 *  2. ae_exam_db.main.report_csr_driver_summary
 * 		::> report layer (tier 2) - Driver Complaint summary report
 * 
 *  3. ae_exam_db.main.report_csr_restaurant_summary
 * 		::> report layer (tier 2) - Restaurant Complaint summary report
 * 
 * */

/* ======================================================== 
 * 01. [REPORT] Complaint Summary Report for Dashboard  (Abbreviation = CSR/csr)
 * Table Name : ae_exam_db.main.report_csr_complaint_summary (updated by DROP/CREATE method)
 * 
 * * Requirements *
 * 1 - Total number of issues reported during a period.  
 * 2 - Most common categories of complaints.  
 * 3 - Time taken on average to resolve an issue.  
 * 4 - Volume of unresolved or escalated tickets.  
 * 5 - Compensation or refunds issued as part of complaint resolution.  
 * 6 - Trends over time in volume or resolution time.  
 * ======================================================== */

DROP TABLE IF EXISTS ae_exam_db.main.report_csr_complaint_summary;

CREATE TABLE ae_exam_db.main.report_csr_complaint_summary AS
select 
	CAST(STRFTIME(TKT_STG.opened_datetime, '%Y%m%d') AS INTEGER)																as tkt_tm_key_day
	,OT.delivery_zone																											as region
	,sum(compensation_amount)																									as tot_compensation
/* Main category issue_type calculated fields */
	,count(distinct TKT_STG.ticket_id)																							as tot_tkt
	,count(distinct case when TKT_STG.issue_type = 'food' then TKT_STG.ticket_id else null end)									as tot_tkt_food
	,CAST(avg(case when TKT_STG.issue_type = 'food' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))					as avg_min_tkt_food
	,count(distinct case when TKT_STG.issue_type = 'payment' then TKT_STG.ticket_id else null end)								as tot_tkt_payment
	,CAST(avg(case when TKT_STG.issue_type = 'payment' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))				as avg_min_tkt_payment	
	,count(distinct case when TKT_STG.issue_type = 'rider' then TKT_STG.ticket_id else null end)								as tot_tkt_rider
	,CAST(avg(case when TKT_STG.issue_type = 'rider' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))					as avg_min_tkt_rider
	,count(distinct case when TKT_STG.issue_type = 'delivery' then TKT_STG.ticket_id else null end)								as tot_tkt_delivery
	,CAST(avg(case when TKT_STG.issue_type = 'delivery' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))				as avg_min_tkt_delivery
/* Main category sub-issue_type calculated fields */
	,count(distinct case when TKT_STG.issue_sub_type = 'overcharged' then TKT_STG.ticket_id else null end)						as tot_tkt_overcharge
	,CAST(avg(case when TKT_STG.issue_sub_type = 'overcharged' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))		as avg_min_tkt_overcharge
	,count(distinct case when TKT_STG.issue_sub_type = 'wrong_item' then TKT_STG.ticket_id else null end)						as tot_tkt_wrong_item
	,CAST(avg(case when TKT_STG.issue_sub_type = 'wrong_item' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))		as avg_min_tkt_wrong_item
	,count(distinct case when TKT_STG.issue_sub_type = 'refund' then TKT_STG.ticket_id else null end)							as tot_tkt_refund
	,CAST(avg(case when TKT_STG.issue_sub_type = 'refund' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))			as avg_min_tkt_refund
	,count(distinct case when TKT_STG.issue_sub_type = 'not_delivered' then TKT_STG.ticket_id else null end)					as tot_tkt_not_deli
	,CAST(avg(case when TKT_STG.issue_sub_type = 'not_delivered' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))		as avg_min_tkt_not_deli
	,count(distinct case when TKT_STG.issue_sub_type = 'no_mask' then TKT_STG.ticket_id else null end)							as tot_tkt_no_mask
	,CAST(avg(case when TKT_STG.issue_sub_type = 'no_mask' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))			as avg_min_tkt_no_mask
	,count(distinct case when TKT_STG.issue_sub_type = 'cold' then TKT_STG.ticket_id else null end)								as tot_tkt_cold
	,CAST(avg(case when TKT_STG.issue_sub_type = 'cold' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))				as avg_min_tkt_cold
	,count(distinct case when TKT_STG.issue_sub_type = 'rude' then TKT_STG.ticket_id else null end)								as tot_tkt_rude
	,CAST(avg(case when TKT_STG.issue_sub_type = 'rude' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))				as avg_min_tkt_rude
	,count(distinct case when TKT_STG.issue_sub_type = 'late' then TKT_STG.ticket_id else null end)								as tot_tkt_late
	,CAST(avg(case when TKT_STG.issue_sub_type = 'late' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))				as avg_min_tkt_late
from (select 
	*
	,DATEDIFF('minute',opened_datetime,resolved_datetime)																		as tm_resolved_min
	,DATEDIFF('hour',opened_datetime,resolved_datetime)																			as tm_resolved_hr
from ae_exam_db.main.support_tickets ) TKT_STG
left join ae_exam_db.main.order_transactions OT
	on TKT_STG.order_id = OT.order_id
group by 
	CAST(STRFTIME(TKT_STG.opened_datetime, '%Y%m%d') AS INTEGER)
	,OT.delivery_zone
order by 
	CAST(STRFTIME(TKT_STG.opened_datetime, '%Y%m%d') AS INTEGER)
	,OT.delivery_zone;

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */

/* ======================================================== 
 * 02. [REPORT] Driver Complaint Summary Report (Abbreviation = DCS/dcs)
 * [Tier 2] Table Name : ae_exam_db.main.report_csr_driver_summary (updated by DROP/CREATE method)
 * 
 * * Requirements *
 * 1 - Frequency of complaints tied to specific drivers.  
 * 2 - Type of issues raised (e.g., lateness, unprofessional conduct).  
 * 3 - Time required to resolve driver-related cases.  
 * 4 - Customer satisfaction scores following complaint resolution.  
 * 5 - Ratio of complaints to total orders handled by each driver.  
 * 6 - Driver ratings before and after complaints. << pending need more information >>
 * ======================================================== */

/* recheck driver_master to make sure all drivers details stored in unique (200 drivers) */
select count(*), count(distinct driver_id) from ae_exam_db.main.drivers_master;

DROP TABLE IF EXISTS ae_exam_db.main.report_csr_driver_summary;

CREATE TABLE ae_exam_db.main.report_csr_driver_summary AS
select 
	concat('DRV',right(TKT_STG.driver_id,3)) 																																				as driver_id
	,DM.join_date
	,DM.vehicle_type
	,DM.region
	,DM.active_status
	,DM.driver_rating
	,DM.bonus_tier
	,count(OT.order_id)																																										as tot_ordr
	,count(case when TKT_STG.issue_type = 'rider' or TKT_STG.issue_type = 'delivery' then TKT_STG.ticket_id else null end)																	as tot_complaint
	,CAST(count(case when TKT_STG.issue_type = 'rider' or TKT_STG.issue_type = 'delivery' then TKT_STG.ticket_id else null end)/count(OT.order_id) as DECIMAL(10,2))						as perc_complaint
	,CAST(count(case when TKT_STG.issue_type = 'rider' or TKT_STG.issue_type = 'delivery' then TKT_STG.ticket_id else null end)/
		count(distinct CAST(STRFTIME(TKT_STG.opened_datetime, '%Y%m') AS INTEGER)) as DECIMAL(10,2))																						as avg_mth_complaint
/* issue type = 'rider' */
	,count(case when TKT_STG.issue_type = 'rider' and issue_sub_type = 'no_mask' then TKT_STG.ticket_id else null end)																		as tot_tkt_no_mask
	,CAST(avg(case when  TKT_STG.issue_type = 'rider' and TKT_STG.issue_sub_type = 'no_mask' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))										as avg_min_tkt_no_mask	
	,count(case when TKT_STG.issue_type = 'rider' and issue_sub_type = 'rude' then TKT_STG.ticket_id else null end)																			as tot_tkt_rude
	,CAST(avg(case when  TKT_STG.issue_type = 'rider' and TKT_STG.issue_sub_type = 'rude' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))										as avg_min_tkt_rude
/* issue type = 'delivery' */
	,count(case when TKT_STG.issue_type = 'delivery' and issue_sub_type = 'not_delivered' then TKT_STG.ticket_id else null end)																as tot_tkt_not_deli
	,CAST(avg(case when  TKT_STG.issue_type = 'delivery' and TKT_STG.issue_sub_type = 'not_delivered' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))							as avg_min_tkt_not_deli
	,count(case when TKT_STG.issue_type = 'delivery' and issue_sub_type = 'late' then TKT_STG.ticket_id else null end)																		as tot_tkt_late
	,CAST(avg(case when  TKT_STG.issue_type = 'delivery' and TKT_STG.issue_sub_type = 'late' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))										as avg_min_tkt_late
	,CAST(avg(case when TKT_STG.issue_type = 'rider' or TKT_STG.issue_type = 'delivery' then TKT_STG.csat_score else 0 end) as DECIMAL(10,2)) 												as csat_score
from (select 
	*
	,DATEDIFF('minute',opened_datetime,resolved_datetime)																																	as tm_resolved_min
	,DATEDIFF('hour',opened_datetime,resolved_datetime)																																		as tm_resolved_hr
from ae_exam_db.main.support_tickets ) TKT_STG
left join ae_exam_db.main.order_transactions OT
on 
	TKT_STG.order_id = OT.order_id
left join (select distinct * from ae_exam_db.main.drivers_master) DM
on
	concat('DRV',right(TKT_STG.driver_id,3)) = concat('DRV',right(DM.driver_id,3))
group by
	concat('DRV',right(TKT_STG.driver_id,3))
	,DM.join_date
	,DM.vehicle_type
	,DM.region
	,DM.active_status
	,DM.driver_rating
	,DM.bonus_tier
order by 
	concat('DRV',right(TKT_STG.driver_id,3));

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */

/* ======================================================== 
 * 03. [REPORT] Restaurant Complaint Summary Report (Abbreviation = RCS/rcs)
 * [Tier 2] Table Name : ae_exam_db.main.report_csr_restaurant_summary (updated by DROP/CREATE method)
 * 
 * * Requirements *
 * 1 - Volume of complaints linked to individual restaurants.  
 * 2 - Nature of issues raised (e.g., food quality, wrong items, missing items).  
 * 3 - Time to resolve restaurant-related issues.  
 * 4 - Total customer compensation linked to each restaurant.  
 * 5 - Ratio of complaints to total orders from the restaurant.  
 * 6 - Impact on repeat purchase behavior from customers after such issues. << pending need more information >>
 * ======================================================== */

/* recheck restaurant_master to make sure all restaurant details stored in unique (105 rest) */
select count(*), count(distinct restaurant_id) from ae_exam_db.main.restaurants_master;

DROP TABLE IF EXISTS ae_exam_db.main.report_csr_restaurant_summary;

CREATE TABLE ae_exam_db.main.report_csr_restaurant_summary AS
select 
	CONCAT('REST',right(TKT_STG.restaurant_id,3))
	,RM.name
	,RM.category
	,RM.city
	,RM.average_rating
	,RM.active_status
	,RM.prep_time_min
	,count(OT.order_id)																																										as tot_ordr
	,count(case when TKT_STG.issue_type = 'food' or TKT_STG.issue_type = 'payment' then TKT_STG.ticket_id else null end)																	as tot_complaint
	,CAST(count(case when TKT_STG.issue_type = 'food' or TKT_STG.issue_type = 'payment' then TKT_STG.ticket_id else null end)/count(OT.order_id) as DECIMAL(10,2))							as perc_complaint
	,CAST(count(case when TKT_STG.issue_type = 'food' or TKT_STG.issue_type = 'payment' then TKT_STG.ticket_id else null end)/
		count(distinct CAST(STRFTIME(TKT_STG.opened_datetime, '%Y%m') AS INTEGER)) as DECIMAL(10,2))																						as avg_mth_complaint
/* issue type = 'food' */
	,count(case when TKT_STG.issue_type = 'food' and issue_sub_type = 'wrong_item' then TKT_STG.ticket_id else null end)																	as tot_tkt_wrong_item
	,CAST(avg(case when  TKT_STG.issue_type = 'food' and TKT_STG.issue_sub_type = 'wrong_item' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))									as avg_min_tkt_wrong_item	
	,count(case when TKT_STG.issue_type = 'food' and issue_sub_type = 'cold' then TKT_STG.ticket_id else null end)																			as tot_tkt_cold
	,CAST(avg(case when  TKT_STG.issue_type = 'food' and TKT_STG.issue_sub_type = 'cold' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))											as avg_min_tkt_cold
/* issue type = 'payment' */
	,count(case when TKT_STG.issue_type = 'payment' and issue_sub_type = 'overcharged' then TKT_STG.ticket_id else null end)																as tot_tkt_overcharged
	,CAST(avg(case when  TKT_STG.issue_type = 'payment' and TKT_STG.issue_sub_type = 'overcharged' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))								as avg_min_tkt_overcharged
	,count(case when TKT_STG.issue_type = 'payment' and issue_sub_type = 'refund' then TKT_STG.ticket_id else null end)																		as tot_tkt_refund
	,CAST(avg(case when  TKT_STG.issue_type = 'payment' and TKT_STG.issue_sub_type = 'refund' then TKT_STG.tm_resolved_min else 0 end) as DECIMAL(10,2))									as avg_min_tkt_refund
	,CAST(avg(case when TKT_STG.issue_type = 'food' or TKT_STG.issue_type = 'payment' then TKT_STG.csat_score else 0 end) as DECIMAL(10,2)) 												as csat_score
from (select 
	*
	,DATEDIFF('minute',opened_datetime,resolved_datetime)																																	as tm_resolved_min
	,DATEDIFF('hour',opened_datetime,resolved_datetime)																																		as tm_resolved_hr
from ae_exam_db.main.support_tickets ) TKT_STG
left join ae_exam_db.main.order_transactions OT
on 
	TKT_STG.order_id = OT.order_id
left join (select distinct * from ae_exam_db.main.restaurants_master) RM
on
	CONCAT('REST',right(TKT_STG.restaurant_id,3)) = CONCAT('REST',right(RM.restaurant_id,3))
group by
	CONCAT('REST',right(TKT_STG.restaurant_id,3))
	,RM.name
	,RM.category
	,RM.city
	,RM.average_rating
	,RM.active_status
	,RM.prep_time_min
order by 
	CONCAT('REST',right(TKT_STG.restaurant_id,3));