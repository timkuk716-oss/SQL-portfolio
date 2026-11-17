-- schema.sql — учебная схема небольшого интернет-магазина.
-- Пять таблиц: клиенты, сотрудники, товары, заказы и позиции заказов.
-- Данные подобраны так, чтобы на них были видны джойны, оконные функции,
-- NULL, ничьи в ранжировании и т.д.

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id   INTEGER PRIMARY KEY,
    name          TEXT,
    city          TEXT,
    gender        TEXT,          -- 'm' / 'f'
    registered_at TEXT           -- дата в формате 'YYYY-MM-DD'
);

CREATE TABLE employees (
    employee_id INTEGER PRIMARY KEY,
    name        TEXT,
    department  TEXT,
    salary      INTEGER,
    manager_id  INTEGER          -- ссылка на employee_id руководителя (для self-join)
);

CREATE TABLE products (
    product_id INTEGER PRIMARY KEY,
    name       TEXT,
    category   TEXT,
    price      REAL
);

CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY,
    customer_id INTEGER,          -- внешний ключ на customers
    created_at  TEXT,             -- дата заказа 'YYYY-MM-DD'
    status      TEXT,             -- 'paid' / 'cancelled'
    amount      REAL
);

CREATE TABLE order_items (
    order_id   INTEGER,           -- внешний ключ на orders
    product_id INTEGER,           -- внешний ключ на products
    quantity   INTEGER
);

-- --- данные ---

INSERT INTO customers (customer_id, name, city, gender, registered_at) VALUES
 (1, 'Анна',     'Москва', 'f', '2023-11-05'),
 (2, 'Борис',    'Казань', 'm', '2024-01-10'),
 (3, 'Виктория', 'Москва', 'f', '2024-01-22'),
 (4, 'Георгий',  'Сочи',   'm', '2023-12-30'),
 (5, 'Дарья',    'Казань', 'f', '2024-02-14'),
 (6, 'Егор',     'Москва', 'm', '2024-02-20');   -- без заказов (пригодится для anti-join)

INSERT INTO employees (employee_id, name, department, salary, manager_id) VALUES
 (1, 'Иван',  'Руководство', 400000, NULL),
 (2, 'Пётр',  'Аналитика',   180000, 1),
 (3, 'Мария', 'Аналитика',   150000, 2),
 (4, 'Олег',  'Продажи',     160000, 1),
 (5, 'Нина',  'Продажи',      90000, 4);

INSERT INTO products (product_id, name, category, price) VALUES
 (1, 'Кофемашина', 'Техника',    25000),
 (2, 'Наушники',   'Техника',     8000),
 (3, 'Книга',      'Книги',       1200),
 (4, 'Рюкзак',     'Аксессуары',  5000),
 (5, 'Чайник',     'Техника',     3000);

INSERT INTO orders (order_id, customer_id, created_at, status, amount) VALUES
 (101, 1, '2024-01-05', 'paid',      33000),
 (102, 1, '2024-02-11', 'paid',       8000),
 (103, 2, '2024-01-15', 'paid',       1200),
 (104, 3, '2024-01-20', 'cancelled',  5000),
 (105, 3, '2024-02-02', 'paid',      25000),
 (106, 4, '2024-01-28', 'paid',       3000),
 (107, 4, '2024-02-18', 'paid',       9200),
 (108, 5, '2024-02-05', 'paid',       6200),
 (109, 1, '2024-03-01', 'paid',      11000),
 (110, 2, '2024-03-10', 'paid',       5000);

INSERT INTO order_items (order_id, product_id, quantity) VALUES
 (101, 1, 1), (101, 2, 1),
 (102, 2, 1),
 (103, 3, 1),
 (104, 4, 1),
 (105, 1, 1),
 (106, 5, 1),
 (107, 2, 1), (107, 3, 1),
 (108, 4, 1), (108, 3, 1),
 (109, 2, 1), (109, 5, 1),
 (110, 4, 1);
