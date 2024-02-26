with group_data_xyz as (
	select 
		month, 
		name, 
		sum(quantity) as quantity
	from pizza_trim_data
	where year = 2015
	group by month, name
	order by name
), xyz as (
	select 
	month, 
	name, 
	quantity,
	stddev_pop(quantity) over (partition by name), 
	avg(quantity) over (partition by name),
	round(stddev_pop(quantity) over (partition by name) / avg(quantity) over (partition by name), 3) as covar
from group_data_xyz
), xyz_total as (
select 
	name, 
	min(covar) as cov
from xyz
group by name
)
select
	name,
	cov,
	case
		when cov <= 0.1 then 'X'
		when cov <= 0.20 then 'Y'
		else 'Z'
	end xyz
from xyz_total