/* ======================================================== */
/*  FLEET MANAGEMENT TEAM (Abbreviation = FMT/fmt)  */
/* ======================================================== */

/*	List tables
 * Vocabs 
 * - Tier 0 >> transaction level
 * - Tier 1 >> prepared report rawdata level
 * - Tier 2 >> report data level
 * 
 * 	1. ae_exam_db.main.model_temp05_fct_fmt_daily
 * 		::> staging layer (tier 0) - fleet management transaction rawdata
 * 
 *  2. ae_exam_db.main.model_temp06_dim_driver_feedbacks
 * 		::> dimension layer (tier 1) - feedback each driver provided by customers 
 * 
 *  3. ae_exam_db.main.report_dpr_summary
 * 		::> report layer (tier 2) - Driver Peformance Report summary
 * 
 *  4. ae_exam_db.main.report_dzh_summary
 * 		::> report layer (tier 2) - Delivery Zone Heatmap Report transaction
 * 
 *  5. ae_exam_db.main.model_temp07_pvt_ordr_incentive
 * 		::> staging layer (tier 1) - pivot summary from process incentive log from order created to order completed
 * 
 *  6. ae_exam_db.main.report_dir_incentive_summary
 * 		::> report layer (tier 2) - Driver Incentive Impact Report transaction
 * 
 * */

/* ======================================================== 
 * 01. [Model] Tier 0 (Raw) - Driver Performance Overview/Transaction Table (Abbreviation = DPO/dpo)
 * Table Name : ae_exam_db.main.model_temp05_fct_fmt_daily (updated by DROP/CREATE method)
 * ======================================================== */

DROP TABLE IF EXISTS ae_exam_db.main.model_temp05_fct_fmt_daily;

CREATE TABLE ae_exam_db.main.model_temp05_fct_fmt_daily as 
select 
	CAST(STRFTIME(OT.order_datetime, '%Y%m%d') AS INTEGER) 								as tm_key_day
	,OT.driver_id
	,OT.customer_id
	,OT.order_id
	,OT.total_amount
	,OT.order_datetime
/* Calculation timespent per order */
	,DATEDIFF('minute',OT.order_datetime,OT.pickup_datetime) 							as tm_ordr_pickup
	,DATEDIFF('minute',OT.order_datetime,OT.delivery_datetime) 							as tm_ordr_delivery
	,OT.pickup_datetime
	,OT.delivery_datetime
	,OT.order_status
	,OT.delivery_zone
	,OT.is_late_delivery
/* Driver details */
	,DM.region
	,DM.vehicle_type 
	,DM.active_status
	,DM.driver_rating
	,DM.bonus_tier
from ae_exam_db.main.order_transactions OT
left join ae_exam_db.main.drivers_master DM
	on OT.driver_id = DM.driver_id;

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */

/* ======================================================== 
 * 02. [Model] Tier 1 - Driver Performance Overview/Dimension feedback reviews from customers to each drivers (Abbreviation = DDF/ddf)
 * Table Name : ae_exam_db.main.model_temp06_dim_driver_feedbacks (updated by DROP/CREATE method)
 * ======================================================== */

DROP TABLE IF EXISTS ae_exam_db.main.model_temp06_dim_driver_feedbacks;

CREATE TABLE ae_exam_db.main.model_temp06_dim_driver_feedbacks as 
select 
	driver_id
	,count(ticket_id) 																	as tot_tkt
	,count(case when issue_sub_type = 'rude' then ticket_id else null end) 				as tot_tkt_rude
	,count(case when issue_sub_type = 'no_mask' then ticket_id else null end) 			as tot_tkt_nomask
	,CAST(avg(csat_score) AS DECIMAL(10,2)) 											as avg_csat
from ae_exam_db.main.support_tickets
where 
	issue_type = 'rider'
group by
	driver_id;

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */
	
/* ======================================================== 
 * 03. [Report] Driver Performance Report (Abbreviation = DPR/dpr)
 * [Tier 2] Table Name : ae_exam_db.main.report_dpr_summary (updated by DROP/CREATE method)
 * 
 * * Requirements *
 * 1 - Number of tasks assigned vs completed by each driver.  
 * 2 - Responsiveness in accepting jobs.  
 * 3 - Average time taken to complete a delivery. 
 * 4 - Frequency of late or delayed deliveries.  
 * 5 - Feedback provided by customers for each driver.  
 * 6 - Optional: Compare performance across vehicle types or geographic zones.  
 * ======================================================== */
	
DROP TABLE IF EXISTS ae_exam_db.main.report_dpr_summary;

CREATE TABLE ae_exam_db.main.report_dpr_summary AS
select
	FFD.driver_id
	,FFD.tot_ordr
	,FFD.tot_ordr_comp
	,FFD.avg_tm_resp_pickup
	,FFD.avg_tm_completion
	,FFD.tot_ordr_late
	,DDF.tot_tkt
	,DDF.tot_tkt_rude
	,DDF.tot_tkt_nomask
	,DDF.avg_csat
from (select
	driver_id
	,count(distinct order_id) as tot_ordr
	,count(distinct case when order_status = 'completed' then order_id end) 										as tot_ordr_comp
	,CAST(AVG(tm_ordr_pickup) as DECIMAL(10,2)) 																	as avg_tm_resp_pickup
	,CAST(AVG(tm_ordr_delivery) as DECIMAL(10,2)) 																	as avg_tm_completion
	,count(distinct case when order_status = 'completed' AND is_late_delivery = 1 then order_id else null end) 		as tot_ordr_late
from ae_exam_db.main.model_temp05_fct_fmt_daily
group by
	driver_id ) FFD
left join ae_exam_db.main.model_temp06_dim_driver_feedbacks DDF
on
	FFD.driver_id = DDF.driver_id
order by 
	FFD.driver_id;

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */
	
/* ======================================================== 
 * 04. [Report] Delivery Zone Heatmap Report (Abbreviation = DZH/dzh)
 * [Tier 2] Table Name : ae_exam_db.main.report_dzh_summary (updated by DROP/CREATE method)
 * 
 * * Requirements *
 * 1 - Total volume of deliveries requested in each zone.  
 * 2 - Completion rates within each area.  
 * 3 - Average delivery time in different areas or cities.  
 * 4 - Areas with high job rejection or cancellation due to unavailable drivers.  
 * 5 - Ratio of drivers available to delivery requests (supply vs demand tension). (need more information)
 * 6 - Delivery speed vs customer expectations per zone. (need more information)
 * ======================================================== */

DROP TABLE IF EXISTS ae_exam_db.main.report_dzh_summary; 

CREATE TABLE ae_exam_db.main.report_dzh_summary AS
select
	tm_key_day
	,delivery_zone
	,count(order_id) as tot_ordr
	,count(distinct case when order_status = 'completed' then order_id else null end) as ordr_completed
	,count(case when order_status = 'failed' then order_id else null end) as sys_canceled
	,CAST(count(distinct case when order_status = 'completed' then order_id else null end)/count(order_id) as DECIMAL(10,2)) as rt_completion
	,CAST(AVG(tm_ordr_delivery) as DECIMAL(10,2)) as avg_tm_completion
	,count(distinct customer_id) as tot_customer
	,count(distinct driver_id) as tot_driver
from ae_exam_db.main.model_temp05_fct_fmt_daily
group by
	tm_key_day
	,delivery_zone
order by
	tm_key_day
	,delivery_zone;

/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */

/* ======================================================== 
 * 05. [Model] Tier 1 - driver incentive pivot summary (Abbreviation = PVIC/pvic) >>> Monitor throughout incentive process
 * Table Name : ae_exam_db.main.model_temp07_pvt_ordr_incentive (updated by DROP/CREATE method)
 * ======================================================== */

/* Create pivot summary -- #94,593 Orders */
DROP TABLE IF EXISTS ae_exam_db.main.model_temp07_pvt_ordr_incentive; 

CREATE TABLE ae_exam_db.main.model_temp07_pvt_ordr_incentive as 
select 
	T_MAIN.order_id
	,T_CREATE.status_datetime as ordr_create
	,T_CREATE.updated_by as upd_create
	,T_ACCEPTED.status_datetime as ordr_accepted
	,T_ACCEPTED.updated_by as upd_accepted
	,T_PICKUP.status_datetime as ordr_pickup
	,T_PICKUP.updated_by as upd_pickup
	,T_CANCELED.status_datetime as ordr_canceled
	,T_CANCELED.updated_by as upd_canceled
	,T_COMPLETED.status_datetime as ordr_completed
	,T_COMPLETED.updated_by as upd_completed
	,T_FAILED.status_datetime as ordr_failed
	,T_FAILED.updated_by as upd_failed
from (select distinct order_id from ae_exam_db.main.order_log_incentive_sessions_order_status_logs order by order_id) T_MAIN
/* ============ 01 Join to get create datetime ============  */
left join (select 
	order_id
	,status_datetime
	,updated_by
from ae_exam_db.main.order_log_incentive_sessions_order_status_logs 
where
	status = 'created') T_CREATE
on
	T_MAIN.order_id = T_CREATE.order_id	
/* ============  02 Join to get canceled datetime ============  */
left join (select 
	order_id
	,status_datetime
	,updated_by
from ae_exam_db.main.order_log_incentive_sessions_order_status_logs 
where
	status = 'canceled') T_CANCELED
on
	T_MAIN.order_id = T_CANCELED.order_id	
/* ============  03 Join to get completed datetime ============  */
left join (select 
	order_id
	,status_datetime
	,updated_by
from ae_exam_db.main.order_log_incentive_sessions_order_status_logs 
where
	status = 'completed') T_COMPLETED
on
	T_MAIN.order_id = T_COMPLETED.order_id	
/* ============  04 Join to get failed datetime ============  */
left join (select 
	order_id
	,status_datetime
	,updated_by
from ae_exam_db.main.order_log_incentive_sessions_order_status_logs 
where
	status = 'failed') T_FAILED
on
	T_MAIN.order_id = T_FAILED.order_id	
/* ============  05 Join to get accepted datetime ============  */
left join (select 
	order_id
	,status_datetime
	,updated_by
from ae_exam_db.main.order_log_incentive_sessions_order_status_logs 
where
	status = 'accepted') T_ACCEPTED
on
	T_MAIN.order_id = T_ACCEPTED.order_id	
/* ============  06 Join to get picked_up datetime ============  */
left join (select 
	order_id
	,status_datetime
	,updated_by
from ae_exam_db.main.order_log_incentive_sessions_order_status_logs 
where
	status = 'picked_up') T_PICKUP
on
	T_MAIN.order_id = T_PICKUP.order_id	
order by
	T_MAIN.order_id;


/* ====================================================================================================================================================================== */
/* ====================================================================================================================================================================== */
	
/* ======================================================== 
 * 06. [Report] Driver Incentive Impact Report (Abbreviation = DIIR/diir)
 * [Tier 2] Table Name : ae_exam_db.main.report_dir_incentive_summary (updated by DROP/CREATE method)
 * 
 * * Requirements *
 * 1 - Driver participation in each incentive program.  
 * 2 - Volume of completed deliveries during incentive periods.  
 * 3 - Change in delivery times and acceptance rates while incentives are active.  
 * 4 - Driver satisfaction and feedback (if collected).  
 * 5 - Bonus amount paid out to each driver.  
 * 6 - Revenue generated or operational efficiency gains from these programs.
 * ======================================================== */

/* Remarks :: some drivers and incentive program found 0 revenue while in incentive sessions have actual delivery amount */

DROP TABLE IF EXISTS ae_exam_db.main.report_dir_incentive_summary; 

CREATE TABLE ae_exam_db.main.report_dir_incentive_summary as 
select 
	ordrlog.applied_date
	,ordrlog.incentive_program
	,ordrlog.driver_id
	,concat('DRV',substring(ordrlog.driver_id,4,3)) fmt_ordr_id
	,sum(case when ordrlog.bonus_qualified = 1 then ordrlog.bonus_amount else 0 end) 			as bonus_received
	,sum(ordrlog.delivery_target)																as target_delivery
	,sum(ordrlog.actual_deliveries) 															as actual_delivery
	,CAST(sum(ordrlog.actual_deliveries)/sum(ordrlog.delivery_target) as DECIMAL(10,2))			as proportion_success
	,sum(case when OT.order_status = 'completed' then OT.total_amount else 0 end) 				as tot_rev
	,CAST(avg(DATEDIFF('minute',OT.order_datetime,OT.delivery_datetime)) as DECIMAL(10,2))		as tm_completion
	,sum(case when OT.order_status = 'completed' then OT.total_amount else 0 end) -
		sum(case when ordrlog.bonus_qualified = 1 then ordrlog.bonus_amount else 0 end)			as company_profit
from ae_exam_db.main.order_log_incentive_sessions_driver_incentive_logs ordrlog
left join ae_exam_db.main.order_transactions OT
on
	ordrlog.applied_date = cast(OT.order_datetime as date)
	and concat('DRV',substring(ordrlog.driver_id,4,3)) = OT.driver_id
group by
	ordrlog.applied_date
	,ordrlog.incentive_program
	,ordrlog.driver_id
order by
	ordrlog.applied_date
	,ordrlog.incentive_program
	,ordrlog.driver_id;

	