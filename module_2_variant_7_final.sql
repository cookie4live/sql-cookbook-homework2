-- ФИО студента: Московцева Анна Евгеньевна
-- Вариант 7. Электронная поваренная книга.
-- Условия: заполнить таблицы первого задания не менее чем пятью осмысленными
-- записями; найти блюда, в инструкциях которых слово «сыр» завершает предложение,
-- отсортировать по времени приготовления; подсчитать количество блюд для каждого
-- ингредиента и отсортировать по убыванию.
-- PostgreSQL 15+. Запускать в новой пустой базе данных: таблицы создаются заново.
-- Если таблицы первого модуля уже существуют, повторный CREATE TABLE вызовет ошибку.

-- Структура таблиц из первого модуля (для самостоятельного запуска файла).

BEGIN;

CREATE TABLE categories (
    category_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    parent_category_id INTEGER REFERENCES categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT category_not_own_parent CHECK (parent_category_id IS NULL OR parent_category_id <> category_id),
    CONSTRAINT category_name_per_parent UNIQUE NULLS NOT DISTINCT (parent_category_id, name)
);

CREATE TABLE ingredients (
    ingredient_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE ingredient_images (
    ingredient_id INTEGER NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    image_id VARCHAR(255) NOT NULL,
    PRIMARY KEY (ingredient_id, image_id)
);

CREATE TABLE ingredient_alternative_names (
    ingredient_id INTEGER NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    alternative_name VARCHAR(150) NOT NULL,
    PRIMARY KEY (ingredient_id, alternative_name)
);

CREATE TABLE standard_units (
    unit_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE nonstandard_units (
    nonstandard_unit_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE unit_conversions (
    ingredient_id INTEGER NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE CASCADE,
    nonstandard_unit_id INTEGER NOT NULL REFERENCES nonstandard_units(nonstandard_unit_id) ON DELETE RESTRICT,
    standard_unit_id INTEGER NOT NULL REFERENCES standard_units(unit_id) ON DELETE RESTRICT,
    standard_quantity NUMERIC(12, 4) NOT NULL CHECK (standard_quantity > 0),
    PRIMARY KEY (ingredient_id, nonstandard_unit_id, standard_unit_id)
);

CREATE TABLE dishes (
    dish_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    cooking_time_minutes INTEGER NOT NULL CHECK (cooking_time_minutes >= 0),
    instructions TEXT NOT NULL
);

CREATE TABLE dish_categories (
    dish_id INTEGER NOT NULL REFERENCES dishes(dish_id) ON DELETE CASCADE,
    category_id INTEGER NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
    PRIMARY KEY (dish_id, category_id)
);

CREATE TABLE dish_images (
    dish_id INTEGER NOT NULL REFERENCES dishes(dish_id) ON DELETE CASCADE,
    image_id VARCHAR(255) NOT NULL,
    PRIMARY KEY (dish_id, image_id)
);

CREATE TABLE equipment (
    equipment_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(150) NOT NULL UNIQUE
);

CREATE TABLE dish_equipment (
    dish_id INTEGER NOT NULL REFERENCES dishes(dish_id) ON DELETE CASCADE,
    equipment_id INTEGER NOT NULL REFERENCES equipment(equipment_id) ON DELETE RESTRICT,
    PRIMARY KEY (dish_id, equipment_id)
);

CREATE TABLE dish_ingredients (
    dish_id INTEGER NOT NULL REFERENCES dishes(dish_id) ON DELETE CASCADE,
    ingredient_id INTEGER NOT NULL REFERENCES ingredients(ingredient_id) ON DELETE RESTRICT,
    quantity NUMERIC(12, 4) NOT NULL CHECK (quantity > 0),
    standard_unit_id INTEGER NOT NULL REFERENCES standard_units(unit_id) ON DELETE RESTRICT,
    PRIMARY KEY (dish_id, ingredient_id)
);

COMMIT;

BEGIN;

INSERT INTO categories (name, parent_category_id) VALUES
('Основные блюда', NULL), ('Закуски', NULL), ('Завтраки', NULL),
('Выпечка', NULL), ('Салаты', NULL);

INSERT INTO ingredients (description) VALUES
('Сыр твёрдый'), ('Яйцо куриное'), ('Помидор свежий'),
('Хлеб пшеничный'), ('Молоко коровье'), ('Мука пшеничная'),
('Масло сливочное'), ('Картофель'), ('Соль поваренная');

INSERT INTO ingredient_images (ingredient_id, image_id) VALUES
(1, 'cheese_01'), (2, 'egg_01'), (3, 'tomato_01'),
(4, 'bread_01'), (5, 'milk_01');

INSERT INTO ingredient_alternative_names (ingredient_id, alternative_name) VALUES
(1, 'Твёрдый сыр'), (2, 'Куриные яйца'), (3, 'Томат'),
(4, 'Белый хлеб'), (7, 'Сливочное масло');

INSERT INTO standard_units (name) VALUES
('г'), ('мл'), ('шт'), ('кг'), ('л');

INSERT INTO nonstandard_units (name) VALUES
('столовая ложка'), ('чайная ложка'), ('стакан'), ('щепотка'), ('кусочек');

INSERT INTO unit_conversions (ingredient_id, nonstandard_unit_id, standard_unit_id, standard_quantity) VALUES
(5, 1, 2, 15),  -- столовая ложка молока = 15 мл
(5, 3, 2, 250), -- стакан молока = 250 мл
(6, 1, 1, 15),  -- столовая ложка муки ~ 15 г
(9, 4, 1, 0.5), -- щепотка соли ~ 0.5 г
(7, 5, 1, 10);  -- кусочек масла ~ 10 г

INSERT INTO dishes (name, cooking_time_minutes, instructions) VALUES
('Горячие бутерброды с сыром', 10,
 'Положите на хлеб помидоры. Сверху добавьте сыр. Запекайте до готовности.'),
('Омлет с сыром', 15,
 'Взбейте яйца с молоком. На сковороду вылейте смесь и добавьте сыр!'),
('Салат с помидорами и сыром', 12,
 'Нарежьте помидоры. Добавьте нарезанный сыр. Перемешайте.'),
('Картофельная запеканка', 50,
 'Нарежьте картофель. Выложите в форму и посыпьте сверху сыр.'),
('Сырные лепёшки', 30,
 'Смешайте муку, молоко и яйца. В тесто добавьте сыр. Обжарьте лепёшки.'),
('Яичница с помидорами', 10,
 'Нарежьте помидоры и обжарьте. Добавьте яйца и соль.'),
('Молочные гренки', 15,
 'Смешайте молоко и яйца. Обмакните хлеб и обжарьте на масле.');

INSERT INTO dish_categories (dish_id, category_id) VALUES
(1, 2), (1, 3), (2, 3), (3, 5), (4, 1),
(5, 4), (5, 3), (6, 3), (7, 3);

INSERT INTO dish_images (dish_id, image_id) VALUES
(1, 'toast_01'), (2, 'omelet_01'), (3, 'salad_01'),
(4, 'casserole_01'), (5, 'flatbread_01');

INSERT INTO equipment (name) VALUES
('Духовка'), ('Сковорода'), ('Нож'), ('Миска'), ('Тёрка');

INSERT INTO dish_equipment (dish_id, equipment_id) VALUES
(1, 1), (1, 3), (2, 2), (2, 4), (3, 3),
(4, 1), (4, 3), (5, 2), (5, 4), (6, 2), (7, 2);

INSERT INTO dish_ingredients (dish_id, ingredient_id, quantity, standard_unit_id) VALUES
(1, 4, 2, 3), (1, 3, 80, 1), (1, 1, 50, 1),
(2, 2, 2, 3), (2, 5, 40, 2), (2, 1, 30, 1),
(3, 3, 150, 1), (3, 1, 70, 1), (3, 9, 2, 1),
(4, 8, 400, 1), (4, 1, 100, 1), (4, 7, 20, 1),
(5, 6, 200, 1), (5, 5, 100, 2), (5, 2, 1, 3), (5, 1, 80, 1),
(6, 2, 2, 3), (6, 3, 100, 1), (6, 9, 2, 1),
(7, 4, 3, 3), (7, 5, 100, 2), (7, 2, 1, 3), (7, 7, 15, 1);

COMMIT;

-- Задание 1. Все поля блюд, где «сыр» завершает предложение.
-- Учитываем точку, вопросительный и восклицательный знаки.
SELECT *
FROM dishes
WHERE instructions ~* '(^|[^[:alpha:]])сыр[[:space:]]*[.!?]'
ORDER BY cooking_time_minutes ASC, dish_id ASC;

-- Задание 2. Все ингредиенты, в том числе не используемые ни в одном блюде.
SELECT i.ingredient_id, i.description,
       COUNT(di.dish_id) AS dish_count
FROM ingredients AS i
LEFT JOIN dish_ingredients AS di ON di.ingredient_id = i.ingredient_id
GROUP BY i.ingredient_id, i.description
ORDER BY dish_count DESC, i.ingredient_id ASC;
