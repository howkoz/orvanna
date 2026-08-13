-- load_seed.sql part 6 of 6: run parts IN ORDER.
begin;
select setval(pg_get_serial_sequence('app.products', 'id'), (select max(id) from app.products));
select setval(pg_get_serial_sequence('app.members', 'id'), (select max(id) from app.members));
select setval(pg_get_serial_sequence('app.customers', 'id'), (select max(id) from app.customers));
select setval(pg_get_serial_sequence('app.subscriptions', 'id'), (select max(id) from app.subscriptions));
select setval(pg_get_serial_sequence('app.orders', 'id'), (select max(id) from app.orders));
select setval(pg_get_serial_sequence('app.order_lines', 'id'), (select max(id) from app.order_lines));
commit;
