drop table if exists tmp1;
create temp table tmp1 as 
select receipt_id, 
    product_id, 
    receipt_timestamp, 
    quantity, 
    discount_price, 
    user_id, 
    shop_id, 
    case 
    when discount_price = sell_price then 10
    when discount_price > 0.9*sell_price then 9 
    when discount_price > 0.8*sell_price then 8
    when discount_price > 0.7*sell_price then 7
    when discount_price > 0.6*sell_price then 6
    when discount_price > 0.5*sell_price then 5
    else 4 end as price_flag
from receipts 
    join receipt_item using (receipt_id)
    join shops using (shop_id)
    join tmp_product_price using (product_id)
where region_block_code = 'sh-lawson' 
    and promotion_type = 0 
    and discount_price <= sell_price
    and receipt_timestamp::date between '2021-05-01' and '2021-05-31';



select a.product_id, 
    b1.sales_shop_num/1936 as cover_range, -- 铺货率
    rank() over(order by a.quantity desc) as quantity_rank, -- 某个sku在所有商品的销量排名
    a.quantity/sum(a.quantity) over () as quantity_percent, -- 销量占比
    (c.max_quantity - c.min_quantity) / date_part('day', c.max_receipt_date-c.min_receipt_date) as surge_index, -- 飙升系数
    (d.max_price_quantity - d.min_price_quantity)*d.max_price/((d.max_price-d.min_price)*d.max_price_quantity) as burst_index, -- 爆发系数
    e.quantity_june / e.quantity_may as season_index, -- 季节变化
    f.quantity_10, f.quantity_9, f.quantity_8,f.quantity_7,f.quantity_6,f.quantity_5,f.quantity_4,-- 折扣影响
    g.quantity as quantity_last_may 
from 
(select product_id, sum(quantity) as quantity 
from tmp1 
group by 1) a 

left join -- 铺货率，售卖店铺数
(select product_id, count(distinct shop_id) as sales_shop_num 
from tmp1 
group by 1) b1 
on a.product_id = b1.product_id 

left join -- 飙升系数
(select c1.product_id, 
c1.receipt_date as max_receipt_date, 
c1.quantity as max_quantity,
c2.receipt_date as min_receipt_date, 
c2.quantity as min_quantity
from 
(select a.product_id, a.receipt_date, a.quantity, 
rank() over (partition by a.product_id order by a.quantity desc) as max_quantity_rank
from 
(select product_id, receipt_timestamp::date as receipt_date, sum(quantity) as quantity
from tmp1
group by 1,2) a 
) c1 
left join 
(select a.product_id, a.receipt_date, a.quantity, 
rank() over (partition by a.product_id order by a.quantity asc) as min_quantity_rank
from 
(select product_id, receipt_timestamp::date as receipt_date, sum(quantity) as quantity
from tmp1
group by 1,2) a ) c2 
on c1.product_id = c2.product_id
where c1.max_quantity_rank = 1 and c2.min_quantity_rank = 1 ) c 
on a.product_id = c.product_id

left join -- 爆发系数
(select d1.product_id, d1.quantity as max_price_quantity, d1.discount_price as max_price, 
d2.quantity as min_price_quantity, d2.discount_price as min_price
from 
(select product_id, quantity, discount_price, rank() over (partition by product_id order by discount_price desc) as max_price_rank
from 
(select product_id, discount_price, sum(quantity) as quantity from tmp1
group by 1,2) d where d.quantity>= 100) d1 
left join 
(select product_id, quantity, discount_price, rank() over (partition by product_id order by discount_price asc) as min_price_rank
from 
(select product_id, discount_price, sum(quantity) as quantity from tmp1
group by 1,2) d where d.quantity>= 100) d2 
on d1.product_id = d2.product_id 
where d1.max_price_rank =1 and d2.min_price_rank = 1) d 
on a.product_id = d.product_id 

left join -- 立地变化
(select e1.product_id, e2.quantity as quantity_june, e1.quantity as quantity_may
from 
(select product_id, sum(quantity) as quantity
from receipts 
join receipt_item using (receipt_id)
join shops using (shop_id)
where region_block_code = 'sh-lawson' and promotion_type = 0
and receipt_timestamp::date between '2020-05-01' and '2020-05-31'
group by 1) e1
left join 
(select product_id, sum(quantity) as quantity
from receipts 
join receipt_item using (receipt_id)
join shops using (shop_id)
where region_block_code = 'sh-lawson' and promotion_type = 0
and receipt_timestamp::date between '2020-05-01' and '2020-05-31'
group by 1) e2 
on e1.product_id = e2.product_id) e 
on a.product_id = e.product_id 

left join -- 折扣占比
(select product_id, 
sum(case when price_flag = 10 then quantity else 0 end) as quantity_10,
sum(case when price_flag = 9 then quantity else 0 end) as quantity_9,
sum(case when price_flag = 8 then quantity else 0 end) as quantity_8,
sum(case when price_flag = 7 then quantity else 0 end) as quantity_7,
sum(case when price_flag = 6 then quantity else 0 end) as quantity_6,
sum(case when price_flag = 5 then quantity else 0 end) as quantity_5,
sum(case when price_flag = 4 then quantity else 0 end) as quantity_4
from tmp1 
group by 1 ) f 
on a.product_id = f.product_id 

left join -- 返场商品
(select product_id, sum(quantity) as quantity
from receipts 
join receipt_item using (receipt_id)
join shops using (shop_id)
where region_block_code = 'sh-lawson' and promotion_type = 0
and receipt_timestamp::date between '2020-05-01' and '2020-05-31'
group by 1) g
on a.product_id = g.product_id 



-- -- 立地类型数据：竖变横【old】
-- -- 立地类型
-- drop table if exists tmp2;
-- create temp table tmp2 as 
-- (select e1.product_id, 
-- e2.quantity_integration as quantity_integration_june,
-- e2.quantity_traffic as quantity_traffic_june,
-- e2.quantity_house as quantity_house_june,
-- e2.quantity_office as quantity_office_june,
-- e2.quantity_hospital as quantity_hospital_june,
-- e2.quantity_shopping as quantity_shopping_june,
-- e2.quantity_school as quantity_school_june,
-- e2.quantity_spot as quantity_spot_june,
-- e1.quantity_integration as quantity_integration_may,
-- e1.quantity_traffic as quantity_traffic_may,
-- e1.quantity_house as quantity_house_may,
-- e1.quantity_office as quantity_office_may,
-- e1.quantity_hospital as quantity_hospital_may,
-- e1.quantity_shopping as quantity_shopping_may,
-- e1.quantity_school as quantity_school_may,
-- e1.quantity_spot as quantity_spot_may
-- from 
-- (select product_id, 
-- sum(case when shop_type = '综合' then quantity else 0 end) as quantity_integration,
-- sum(case when shop_type = '交通枢纽' then quantity else 0 end) as quantity_traffic,
-- sum(case when shop_type = '住宅' then quantity else 0 end) as quantity_house,
-- sum(case when shop_type = '办公' then quantity else 0 end) as quantity_office,
-- sum(case when shop_type = '医院' then quantity else 0 end) as quantity_hospital,
-- sum(case when shop_type = '商业街' then quantity else 0 end) as quantity_shopping,
-- sum(case when shop_type = '学校' then quantity else 0 end) as quantity_school,
-- sum(case when shop_type = '旅游景点' then quantity else 0 end) as quantity_spot
-- from receipts 
-- join receipt_item using (receipt_id)
-- join shops using (shop_id)
-- join external.lawson_shop_site_type using (shop_id)
-- where region_block_code = 'sh-lawson' and promotion_type = 0
-- and receipt_timestamp::date between '2020-05-01' and '2020-05-31'
-- group by 1) e1
-- left join 
-- (select product_id, sum(case when shop_type = '综合' then quantity else 0 end) as quantity_integration,
-- sum(case when shop_type = '交通枢纽' then quantity else 0 end) as quantity_traffic,
-- sum(case when shop_type = '住宅' then quantity else 0 end) as quantity_house,
-- sum(case when shop_type = '办公' then quantity else 0 end) as quantity_office,
-- sum(case when shop_type = '医院' then quantity else 0 end) as quantity_hospital,
-- sum(case when shop_type = '商业街' then quantity else 0 end) as quantity_shopping,
-- sum(case when shop_type = '学校' then quantity else 0 end) as quantity_school,
-- sum(case when shop_type = '旅游景点' then quantity else 0 end) as quantity_spot
-- from receipts 
-- join receipt_item using (receipt_id)
-- join shops using (shop_id)
-- join external.lawson_shop_site_type using (shop_id)
-- where region_block_code = 'sh-lawson' and promotion_type = 0
-- and receipt_timestamp::date between '2020-06-01' and '2020-06-30'
-- group by 1) e2 
-- on e1.product_id = e2.product_id);

-- -- 立地类型【新】
-- select product_id, shop_type,
-- to_date(receipt_timestamp::text,'YYYY-MM') as receipt_month,
-- sum(quantity) as quantity 
-- from receipts 
-- join receipt_item using (receipt_id)
-- join shops using (shop_id)
-- join external.lawson_shop_site_type using (shop_id)
-- where region_block_code = 'sh-lawson' and promotion_type = 0
-- and receipt_timestamp::date between '2020-05-01' and '2020-06-30'
-- group by 1,2,3

-- -- 返场商品
-- select product_id, to_date(receipt_timestamp::text,'YYYY-MM') as receipt_month,sum(quantity) as quantity
-- from receipts 
-- join receipt_item using (receipt_id)
-- join shops using (shop_id)
-- where region_block_code = 'sh-lawson' and promotion_type = 0
-- and receipt_timestamp::date between '2020-05-01' and '2020-05-31'
-- group by 1,2
-- union all 
-- select product_id, to_date(receipt_timestamp::text,'YYYY-MM') as receipt_month,sum(quantity) as quantity
-- from receipts 
-- join receipt_item using (receipt_id)
-- join shops using (shop_id)
-- where region_block_code = 'sh-lawson' and promotion_type = 0
-- and receipt_timestamp::date between '2021-05-01' and '2021-05-31'
-- group by 1,2