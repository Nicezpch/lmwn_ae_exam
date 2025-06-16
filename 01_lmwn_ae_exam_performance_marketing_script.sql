/* ======================================================== */
/*  PERFORMANCE MARKETING TEAM (Abbreviation = PMT/pmt)  */
/* ======================================================== */

/*	List tables
 * Vocabs 
 * - Tier 0 >> transaction level
 * - Tier 1 >> prepared report rawdata level
 * - Tier 2 >> report data level
 * 
 * 	1. ae_exam_db.main.model_temp01_cpo_daily 
 * 		::> staging layer (tier 0) - customer overview summary using further purpose for reporting tools
 * 
 *  2. ae_exam_db.model_temp02_fct_pmk_daily 
 * 		::> staging layer (tier 0) for the rest 3 reports (CER / CAR / RPR) - can you this layer to create performance dashboard
 * 
 *  3. ae_exam_db.main.model_temp03_fct_cer_cmpgn_daily 
 * 		::> staging layer (tier 1) [Prepared] Campaign Effectiveness report rawdata
 * 
 *  4. ae_exam_db.main.report_cer_cmpgn_summary 
 * 		::> report layer (tier 2) [Aggregate] Campaign Effectiveness report 
 * 
 *  5. ae_exam_db.main.model_fct_car_daily 
 * 		::> staging layer (tier 1) [Prepared] Customer Acquisition Report rawdata
 * 
 *  6. ae_exam_db.main.report_car_custacq_summary_1 
 * 		::> report layer (tier 2) [Aggregate] Customer Acquisition report (answer Qustions 1,2,6)
 * 
 *  7. ae_exam_db.main.report_car_custacq_summary_2
 * 		::> report layer (tier 2) [Aggregate] Customer Acquisition report (answer Qustions 3,4,5) 
 * 
 * */

/* ======================================================== 
 * 01. [Model] Monitor Summary - Customer Profile Overview (Abbreviation = CPO/cpo)
 * Table Name : model_temp01_cpo_daily (updated by DROP/CREATE method)
 * ======================================================== */

DROP TABLE IF EXISTS ae_exam_db.main.model_temp01_fct_cpo_daily; 

CREATE TABLE ae_exam_db.main.model_temp01_fct_cpo_daily as 
select 
	CAST(STRFTIME(order_datetime, '%Y%m%d') AS INTEGER) 													as tm_key_day
	,customer_id																							as customer_id
	,CAST(sum(total_amount) as DECIMAL(10,2)) 																as tot_amt_ordr
	,CAST(sum(case when order_status = 'completed' then total_amount else 0 end) as DECIMAL(10,2)) 			as tot_amt_ordr_comp
	,count(order_id) 																						as tot_ordr
	,count(case when order_status = 'completed' then order_id else null end) 								as tot_ordr_comp
from ae_exam_db.main.order_transactions
group by 
	CAST(STRFTIME(order_datetime, '%Y%m%d') AS INTEGER)
	,customer_id
order by 
	CAST(STRFTIME(order_datetime, '%Y%m%d') AS INTEGER)
	,customer_id;


/* Monthly Summary Aggregate Report Query - Monthly Customer Overall Spending Performance */

select 
	SUBSTRING(CAST(tm_key_day AS VARCHAR(8)),1,6) 															as tm_key_mth
	,customer_id
	,sum(tot_amt_ordr_comp)																					as tot_ordr_rev_mth
	,CAST(avg(tot_amt_ordr_comp) as DECIMAL(10,2))															as avg_ordr_rev_mth
	,sum(tot_ordr_comp)																						as tot_ordr_mth
from ae_exam_db.main.model_temp01_fct_cpo_daily
group by
	SUBSTRING(CAST(tm_key_day AS VARCHAR(8)),1,6)
	,customer_id
order by 
	SUBSTRING(CAST(tm_key_day AS VARCHAR(8)),1,6)
	,customer_id
;

/* Summary Overview by Customers - Overall Performance */

select 
	customer_id
	,sum(tot_amt_ordr)																						as tot_ordr_rev_placed
	,sum(tot_amt_ordr_comp)																					as tot_ordr_rev_completed
	,CAST(avg(tot_amt_ordr_comp) as DECIMAL(10,2))															as avg_ordr_rev_mth
	,sum(tot_ordr)																							as tot_ordr_placed
	,sum(tot_ordr_comp)																						as tot_ordr_completed
	,min(tm_key_day)    																					as oldest_order 
	,max(tm_key_day)    																					as latest_order 
from ae_exam_db.main.model_temp01_fct_cpo_daily
group by
	customer_id
order by
	customer_id;

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */

/* ======================================================== 
 * 02. [Model] Tier 0 (Raw) - Performance Marketing Fact/Transaction Table (Abbreviation = PMK/pmk)
 * Table Name : ae_exam_db.model_temp02_fct_pmk_daily (updated by DROP/CREATE method)
 * ======================================================== */

DROP TABLE IF EXISTS ae_exam_db.main.model_temp02_fct_pmk_daily; 

CREATE TABLE ae_exam_db.main.model_temp02_fct_pmk_daily AS
select 
	CI.interaction_id
	,CI.campaign_id
/* CMPGN_M : Cmpgn Master fields - Cmpgn Details*/
	,CMPGN_M.campaign_name
	,CMPGN_M.campaign_type
	,CMPGN_M.objective
	,CMPGN_M.cost_model
/* CI : Cmpgn Interaction fields */
	,CI.interaction_id
	,CI.customer_id
	,CI.interaction_datetime
	,CI.event_type
	,CI.platform
	,CI.device_type 
	,CI.ad_cost
	,CI.order_id
	,CI.is_new_customer
	,CI.revenue
	,CI.session_id
/* OT : Ordr Tnx fields - Mapped Ordr Status */
	,OT.driver_id
	,OT.order_datetime
	,OT.pickup_datetime
	,OT.delivery_datetime
	,OT.order_status
	,OT.delivery_zone
	,OT.total_amount
	,OT.payment_method
	,OT.is_late_delivery
	,OT.delivery_distance_km
/* CUST_M : Cust Master fields - Mapped Cust Profile */
	,CUST_M.customer_segment
	,CUST_M.status
	,CUST_M.signup_date
	,CUST_M.referral_source
	,CUST_M.gender
from ae_exam_db.main.campaign_interactions 		CI -- # Campaign_interaction table
left join ae_exam_db.main.order_transactions 	OT -- # Order_transactions table
	on CI.order_id = OT.order_id
left join ae_exam_db.main.customers_master 		CUST_M -- # Customers_master table
	on CI.customer_id = CUST_M.customer_id
left join ae_exam_db.main.campaign_master 		CMPGN_M -- # Campaign_master table
	on CI.campaign_id = CMPGN_M.campaign_id;

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */
	
/* ======================================================== 
 * 03. [Report] Campaign Effectiveness Report (Abbreviation = CER/cer)
 * [Tier 1] Table Name : ae_exam_db.main.model_temp03_fct_cer_cmpgn_daily (updated by DROP/CREATE method)
 * [Tier 2] Table Name : ae_exam_db.main.report_cer_cmpgn_summary (updated by DROP/CREATE method)
 * 
 * * Requirements *
 * 1 - Volume of exposure (e.g., ad impressions) for each campaign across time.  
 * 2 - Level of user interaction with the ads (e.g., clicks).  
 * 3 - Number of users who completed a purchase after interacting with the ad.
 * 4 - Cost associated with running the campaign.
 * 5 - Total revenue attributed to each campaign.
 * 6 - Marketing efficiency metrics (e.g., cost per acquired customer and return on advertising spend).>> (CPA / CPM / CPV / CPC)
 * ======================================================== */

/* 03.1 Campaign Effectiveness Report - Transaction Layer (Tier 1)  */

DROP TABLE IF EXISTS ae_exam_db.main.model_temp03_fct_cer_cmpgn_daily;

CREATE TABLE ae_exam_db.main.model_temp03_fct_cer_cmpgn_daily AS
select 
	CAST(STRFTIME(interaction_datetime, '%Y%m%d') AS INTEGER) 																as par_key
	,campaign_id
	,campaign_name
	,campaign_type
	,objective
	,cost_model
	,sum(ad_cost) 																										as tot_ad_cost
	,count(customer_id) 																								as tot_cust
	,count(case when order_status = 'completed' then customer_id else null end) as tot_comp_cust
	,count(distinct case when is_new_customer = 0 and order_status = 'completed' then customer_id else null end) 		as tot_old_cust
	,count(distinct case when is_new_customer = 1 and order_status = 'completed' then customer_id else null end) 		as tot_new_cust
	,NULLIF(count(case when order_status = 'completed' and event_type = 'impression' then customer_id else null end),0) 	as tot_imp
	,NULLIF(count(case when order_status = 'completed' and event_type = 'conversion' then customer_id else null end),0)	as tot_cvs
	,NULLIF(count(case when order_status = 'completed' and event_type = 'click' then customer_id else null end),0) 		as tot_click
	,NULLIF(CAST(sum(case when order_status = 'completed' then total_amount else 0 end) as DECIMAL(10,2)),0) 				as tot_rev
from ae_exam_db.main.model_temp02_fct_pmk_daily
group by
	CAST(STRFTIME(interaction_datetime, '%Y%m%d') AS INTEGER)
	,campaign_id
	,campaign_name
	,campaign_type
	,objective
	,cost_model
order by 
	CAST(STRFTIME(interaction_datetime, '%Y%m%d') AS INTEGER)
	,campaign_id;

/* 03.2 Campaign Effectiveness Report - Aggregate Report Layer (Tier 2) */

DROP TABLE IF EXISTS ae_exam_db.main.report_cer_cmpgn_summary; 

CREATE TABLE ae_exam_db.main.report_cer_cmpgn_summary AS
select 
	campaign_id
	,campaign_type
	,objective
	,cost_model
	,sum(tot_rev)																as tot_cmpgn_rev
	,sum(tot_ad_cost)															as tot_cmpgn_adcost
	,sum(tot_cust)																as tot_interact_cust
	,sum(tot_imp)																as tot_impression
	,sum(tot_cvs)																as tot_conversion
	,sum(tot_click)																as tot_click
	,CAST((sum(tot_ad_cost)/sum(tot_cvs)) as DECIMAL(10,2)) 					as CPA
	,CAST((sum(tot_ad_cost)/sum(tot_imp)) as DECIMAL(10,2)) 					as CPM
	,CAST((sum(tot_ad_cost)/sum(tot_cust)) as DECIMAL(10,2)) 					as CPV
	,CAST((sum(tot_ad_cost)/sum(tot_click)) as DECIMAL(10,2)) 					as CPC
from ae_exam_db.main.model_temp03_fct_cer_cmpgn_daily
group by
	campaign_id
	,campaign_type
	,objective
	,cost_model
order by
	campaign_id
	,campaign_type
	,objective
	,cost_model;

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */

/* ======================================================== 
 * 04. [Report] Customer Acquisition Report (Abbreviation = CAR/car)
 * [Tier 1] Table Name : ae_exam_db.main.model_fct_car_daily (updated by DROP/CREATE method)
 * [Tier 2] Table Name : ae_exam_db.main.report_car_custacq_summary_1 (updated by DROP/CREATE method)
 * [Tier 2] Table Name : ae_exam_db.main.report_car_custacq_summary_2 (updated by DROP/CREATE method)
 * 
 * * Requirements *
 * 1 - Number of first-time customers attributed to a specific campaign.   
 * 2 - Spending behavior of those customers (e.g., average purchase value, number of repeat orders).
 * 3 - How long customers remain active after their first purchase.
 * 4 - Average time between first interaction and first purchase.
 * 5 - Total marketing cost spent to acquire these customers.
 * 6 - Segmentation by channel/platform for comparison.
 * ======================================================== */

DROP TABLE IF EXISTS ae_exam_db.main.model_temp04_fct_car_daily;

CREATE TABLE ae_exam_db.main.model_temp04_fct_car_daily AS
select 
	CAST(STRFTIME(interaction_datetime, '%Y%m%d') AS INTEGER) 		as par_key
	,campaign_id
	,order_id
	,platform
	,customer_id
	,is_new_customer
	,ad_cost
	,interaction_datetime
	,order_datetime
	,DATEDIFF('minute',interaction_datetime,order_datetime) 		as time_before_purchase
	,revenue
	,order_status
from ae_exam_db.main.model_temp02_fct_pmk_daily
order by 
	CAST(STRFTIME(interaction_datetime, '%Y%m%d') AS INTEGER)
	,customer_id 
	,platform;

/* CAR ANS1 Campaign / Platform new acquisition performance - 
 * 1. Total new acquisition for each campaign 
 * ANS : Total new customers with completed purchase order = 6,336
 * Query : select sum(tot_new_cust) from ae_exam_db.main.report_car_custacq_summary_1; 
 * 
 * 2. Total marketing cost spent to acquire these customers.
 * ANS : total ad_cost spending to acquire value nw customers = 166,811.52
 * Query : select sum(tot_ad_cost) from ae_exam_db.main.report_car_custacq_summary_1; 
 * 
 * 3. Segmentation by channel/platform for comparison. 
 * ANS :	
 * 	google		|	2105	|	55728.06	|	26.46
 *	facebook	|	2126	|	55835.51	|	26.26 
 *	tiktok		|	2105	|	55247.94	|	26.23
 * 
 * Quey : select platform, sum(tot_new_cust), sum(tot_ad_cost), avg(cost_per_new_cust)  from ae_exam_db.main.report_car_custacq_summary_1 group by platform; 
 * */
	
DROP TABLE IF EXISTS ae_exam_db.main.report_car_custacq_summary_1;

CREATE TABLE ae_exam_db.main.report_car_custacq_summary_1 AS
select 
	campaign_id
	,platform
	,count(case when order_status = 'completed' AND is_new_customer = 1 then customer_id else null end) 			as tot_new_cust
	,sum(case when order_status = 'completed' AND is_new_customer = 1 then ad_cost else 0 end) 						as tot_ad_cost
	,CAST(sum(case when order_status = 'completed' AND is_new_customer = 1 then ad_cost else 0 end)/
		count(case when order_status = 'completed' AND is_new_customer = 1 then customer_id else null end)
		as DECIMAL(10,2))																							as cost_per_new_cust
from ae_exam_db.main.model_temp04_fct_car_daily
group by 
	campaign_id
	,platform
order by 	
	campaign_id
	,platform;
	
/* CAR ANS2 Customer behavior performance - 
 * 1. Spending behavior of those customers (e.g., average purchase value, number of repeat orders).
 * ANS : from all customers, average purchase value = 405 THB / average repeat orders = 13 (12.6) orders
 * Query : select avg(avg_rev),avg(tot_rep_ordr) from ae_exam_db.main.report_car_custacq_summary_2;
 * 
 * 2. How long customers remain active after their first purchase.
 * ANS : average remain active all customers = 305 Days
 * Query : select avg(remain_actv) from ae_exam_db.main.report_car_custacq_summary_2;
 * 
 * 3. Average time between first interaction and first purchase. 
 * ANS : average time between first interaction and first purchase from all customers = 27 mins
 * Query : select avg(avg_tm_before_ordr_min) from ae_exam_db.main.report_car_custacq_summary_2;
 * */

DROP TABLE IF EXISTS ae_exam_db.main.report_car_custacq_summary_2;

CREATE TABLE ae_exam_db.main.report_car_custacq_summary_2 AS	
select 
	customer_id
	,CAST(avg(case when order_status = 'completed' then time_before_purchase else 0 end) as DECIMAL(10,2)) 			as avg_tm_before_ordr_min	-- # time before campaign interaction & make order
	,CAST(avg(case when order_status = 'completed' then revenue else 0 end) as DECIMAL(10,2))						as avg_rev		-- # total revenue generated (only completed orders)
	,count(case when order_status = 'completed' then order_id else null end)										as tot_rep_ordr -- # total repeat order 
	,DATEDIFF('day'
		,min(case when order_status = 'completed' then order_datetime else null end)
		,max(case when order_status = 'completed' then order_datetime else null end)) 								as remain_actv
from (select 
	customer_id
	,interaction_datetime
	,order_datetime
	,order_id
	,time_before_purchase
	,revenue
	,order_status
from ae_exam_db.main.model_temp04_fct_car_daily
where
	is_new_customer = 1) CAR2
group by 
	customer_id
order by 
	customer_id;

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */

/* ======================================================== 
 * 05. [Report] Retargeting Performance Report (Abbreviation = RPR/rpr) / retargeting - reactivate_lapsed
 * Table Name : ae_exam_db.main.model_fct_car_daily (updated by APPEND/INSERT method)
 * 
 * * Requirements *
 * 1 - Number of previously active customers targeted in each retargeting campaign.  
 * 2 - Proportion who returned and placed another order.  
 * 3 - Total spend generated by retargeted customers.  
 * 4 - Time gap between original and returning orders. << need more information >> since 1 customers happen to have reactivate_lapsed many time
 * 5 - Retention behavior after retargeting (do they continue to use the platform?). << need more information >> 
 * 6 - Comparison across campaign types or targeting segments. 
 * ======================================================== */

DROP TABLE IF EXISTS ae_exam_db.main.report_rpr_reactv_summary;

CREATE TABLE ae_exam_db.main.report_rpr_reactv_summary AS 
select 
	campaign_id
	,campaign_name
	,campaign_type
	,count(distinct customer_id)																						as tot_cust
	,count(distinct case when status = 'active' then customer_id else null end) 										as cnt_prev_actv -- # count number of customer who previously active
	,CAST(sum(case when status = 'active' and order_status = 'completed' then revenue else 0 end) as DECIMAL(10,2))		as tot_cmpgn_rev
from ae_exam_db.main.model_temp02_fct_pmk_daily
group by
	campaign_id
	,campaign_name
	,campaign_type;
	



