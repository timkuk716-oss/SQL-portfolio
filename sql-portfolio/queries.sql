-- queries.sql — витрина SQL-навыков на учебной схеме магазина.
-- Каждый блок начинается с "-- #N. Заголовок" — так его читает run.py.
-- Диалект: стандартный SQL (проверено на SQLite). Где в MySQL/PostgreSQL
-- синтаксис отличается — это отмечено в комментарии.

-- #1. Выборка и фильтрация: WHERE, AND/OR, IN, BETWEEN, DISTINCT
-- Клиентки (f) из Москвы или Казани, зарегистрированные за 2024 год.
SELECT DISTINCT name, city, registered_at
FROM customers
WHERE gender = 'f'
  AND city IN ('Москва', 'Казань')
  AND registered_at BETWEEN '2024-01-01' AND '2024-12-31'
ORDER BY registered_at;

-- #2. Поиск по тексту: LIKE и шаблоны
-- Товары, в названии которых есть "а"; и имена клиентов на букву "В".
SELECT name, category FROM products WHERE name LIKE '%а%';

-- #3. Агрегация: COUNT(*) vs COUNT(колонка), SUM, AVG, MAX, ROUND
-- Сводка по оплаченным заказам.
SELECT
    COUNT(*)                     AS orders_count,       -- все строки
    COUNT(DISTINCT customer_id)  AS unique_customers,   -- уникальные клиенты
    SUM(amount)                  AS revenue,
    ROUND(AVG(amount), 2)        AS avg_check,
    MAX(amount)                  AS biggest_order
FROM orders
WHERE status = 'paid';

-- #4. Группировка и фильтр групп: GROUP BY + HAVING
-- Выручка по городам, только города с выручкой больше 10 000.
-- (WHERE не умеет фильтровать по агрегатам — для этого есть HAVING.)
SELECT c.city, SUM(o.amount) AS revenue
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'paid'
GROUP BY c.city
HAVING SUM(o.amount) > 10000
ORDER BY revenue DESC;

-- #5. Условная логика: CASE WHEN
-- Категоризация заказов по сумме.
SELECT order_id, amount,
       CASE
           WHEN amount >= 20000 THEN 'крупный'
           WHEN amount >= 5000  THEN 'средний'
           ELSE 'мелкий'
       END AS size_bucket
FROM orders
WHERE status = 'paid'
ORDER BY amount DESC;

-- #6. Сортировка и лимит: многоуровневый ORDER BY + LIMIT
-- Топ-3 заказа: сначала по сумме (убыв.), при равенстве — по дате.
-- (В SQLite/MySQL — LIMIT; в PostgreSQL тоже LIMIT, в старом MS SQL — TOP.)
SELECT order_id, amount, created_at
FROM orders
WHERE status = 'paid'
ORDER BY amount DESC, created_at ASC
LIMIT 3;

-- #7. INNER JOIN: только совпадения в обеих таблицах
-- Оплаченные заказы с именами клиентов.
SELECT o.order_id, c.name, o.amount
FROM orders o
INNER JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'paid'
ORDER BY o.order_id;

-- #8. LEFT JOIN: все клиенты + их заказы (у кого нет — NULL/0)
-- Количество заказов по каждому клиенту, включая тех, у кого их нет.
SELECT c.name,
       COUNT(o.order_id) AS orders_count   -- COUNT по колонке игнорирует NULL => 0 у клиентов без заказов
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY orders_count DESC;

-- #9. Anti-Join: LEFT JOIN + IS NULL — чего нет в другой таблице
-- Клиенты, которые не сделали ни одного заказа.
SELECT c.customer_id, c.name
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE o.order_id IS NULL;

-- #10. Self-Join: таблица сама с собой
-- Сотрудник и его руководитель + сравнение зарплат.
SELECT e.name AS employee, e.salary AS emp_salary,
       m.name AS manager,  m.salary AS mgr_salary
FROM employees e
LEFT JOIN employees m ON m.employee_id = e.manager_id
ORDER BY e.employee_id;

-- #11. Соединение 3+ таблиц через связующую таблицу
-- Какие товары были в каждом оплаченном заказе (orders -> order_items -> products).
SELECT o.order_id, c.name AS customer, p.name AS product, oi.quantity
FROM orders o
JOIN customers   c  ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id   = o.order_id
JOIN products    p  ON p.product_id  = oi.product_id
WHERE o.status = 'paid'
ORDER BY o.order_id;

-- #12. Работа с NULL: COALESCE и IS NULL
-- Сумма заказов по каждому клиенту; у кого заказов нет — показать 0, а не NULL.
SELECT c.name,
       COALESCE(SUM(o.amount), 0) AS total_spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'paid'
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;

-- #13. Подзапрос: сравнение со средним
-- Клиенты, потратившие больше среднего чека по всем оплаченным заказам.
SELECT c.name, SUM(o.amount) AS total_spent
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'paid'
GROUP BY c.customer_id, c.name
HAVING SUM(o.amount) > (SELECT AVG(amount) FROM orders WHERE status = 'paid')
ORDER BY total_spent DESC;

-- #14. EXISTS: есть ли хотя бы одна связанная строка
-- Клиенты, у которых есть хотя бы один заказ.
SELECT c.name
FROM customers c
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.customer_id)
ORDER BY c.name;

-- #15. UNION / UNION ALL: склейка результатов по вертикали
-- Единый список городов клиентов и категорий товаров (UNION убирает дубликаты).
SELECT city AS value, 'город'    AS kind FROM customers
UNION
SELECT category, 'категория товара' FROM products
ORDER BY kind, value;

-- #16. Оконные функции: ROW_NUMBER / RANK / DENSE_RANK
-- Ранжирование клиентов по сумме покупок. Видна разница при ничьей
-- (Борис и Дарья тратят одинаково) — RANK пропускает номер, DENSE_RANK нет.
-- (Оконные функции есть в SQLite 3.25+, MySQL 8+, PostgreSQL.)
SELECT c.name,
       SUM(o.amount) AS total_spent,
       ROW_NUMBER() OVER (ORDER BY SUM(o.amount) DESC) AS row_num,
       RANK()       OVER (ORDER BY SUM(o.amount) DESC) AS rank_pos,
       DENSE_RANK() OVER (ORDER BY SUM(o.amount) DESC) AS dense_rank_pos
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.status = 'paid'
GROUP BY c.customer_id, c.name;

-- #17. Остаток от деления (%) — чётные/нечётные
-- Пометим заказы по чётности номера.
SELECT order_id,
       CASE WHEN order_id % 2 = 0 THEN 'чётный' ELSE 'нечётный' END AS parity
FROM orders
ORDER BY order_id;

-- #18. Работа с датами: фильтр по периоду
-- Оплаченные заказы за январь 2024.
-- Здесь используем сравнение дат-строк (работает везде).
-- В MySQL то же можно так: WHERE YEAR(created_at)=2024 AND MONTH(created_at)=1
-- В PostgreSQL: WHERE date_trunc('month', created_at::date) = DATE '2024-01-01'
SELECT order_id, created_at, amount
FROM orders
WHERE status = 'paid'
  AND created_at BETWEEN '2024-01-01' AND '2024-01-31'
ORDER BY created_at;
