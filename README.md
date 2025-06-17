# lmwn_ae_exam
lmwn - Pachara Jaito (Nice) : Submission Data Models (ae exam)


 * Vocabs 
 * - Tier 0 >> transaction level
 * - Tier 1 >> prepared report rawdata level
 * - Tier 2 >> report data level

# **=== List tables - Performance Marketing Section ===**
*ERD : https://drive.google.com/file/d/1--6EbfdICK8hwMKIZfKo1YdF3-RtEnux/view?usp=sharing*
 * 
 * 	1. ae_exam_db.main.model_temp01_cpo_daily 
 * 		::> staging layer (tier 0) - customer overview summary using further purpose for reporting tools
 * 
 *  2. ae_exam_db.model_temp02_fct_pmk_daily 
 * 		::> staging layer (tier 0) for the rest 3 reports (CER / CAR / RPR) 
 *      can you this layer to create performance dashboard
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


# **=== List tables - Fleet Management Section ===**
*ERD : https://drive.google.com/file/d/1gVimf7spD1kpnj3CUaVdnqKh-yWVzRre/view?usp=sharing*
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

 # **=== List tables - Customer Service Section ===**
 *ERD : https://drive.google.com/file/d/1h75A0eMeCy-Avo0YWAW1faiu6Z1krrVv/view?usp=sharing*
 * 
 * 	1. ae_exam_db.main.report_csr_complaint_summary
 * 		::> report layer (tier 2) - Complaint summary report daily transaction level for dashboard
 * 		
 *  2. ae_exam_db.main.report_csr_driver_summary
 * 		::> report layer (tier 2) - Driver Complaint summary report
 * 
 *  3. ae_exam_db.main.report_csr_restaurant_summary
 * 		::> report layer (tier 2) - Restaurant Complaint summary report