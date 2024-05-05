------------------------------------------------------------------------------------------------
--
-- E3 b)
--
------------------------------------------------------------------------------------------------
create or replace function erp.fn_send_medication_stock_forecast (
 category CHAR(8)
)
returns jsonb
language plpgsql
set search_path TO 'erp'
as $$
declare 
	send_info jsonb; 
begin
	send_info:= (
      select 
        jsonb_agg(
            json_build_object(
                'med_id', mfs.mfs_id,
                'med_name', mfs.mfs_name,
                'timestamp', mfs.mfs_timestamp,
                'stock', mfs.mfs_stock,
                'daily_consumption', mfs.mfs_daily_consumption,
                'days_of_stock', mfs.mfs_days_of_stock,
                'category', mfs.mfs_category
        	)
        ) send_list
        from erp.tb_medication_stock_forecast mfs
		where mfs.mfs_category = category
    );

	return send_info;
end; $$