db-turnout
==========

Приложение позволяет предоставлять доступ к СУБД посредством HTTP-запросов. Сделано на [Sinatra](www.sinatrarb.com/intro.html)
Параметры запроса позволяют управлять ограничениями, списком выбора и сортировкой.

Соответствие http-параметров структурам данных ruby:
```
x=<значение> - строка
x[]=<значение> - [<значение>]
x[value]=<значение> - { value: <значение> }
x[]=<значение1>&x[value]=<значение2> - некорректная комбинация
```

Формирование SQL-запросов производится с помощью [AREL](https://github.com/rails/arel)

Формирование списка выбора
--------------------------
За список выбора отвечает параметр s.
Примеры
```
tables/table_name
SELECT * FROM table

tables/table_name?s=name
SELECT name FROM table

tables/table_name?s[]=name&s[]=t
SELECT name, t FROM table

tables/table_name?s[name]=new_name&s[t]=t1
SELECT name AS name, t AS t1 FROM table
```

Управление сортировкой
--------------------------
За сортировку отвечает параметр o.
Примеры
```
tables/table_name?o=name
SELECT * FROM table ORDER BY name asc

tables/table_name?o[]=name&o[]=t
SELECT * FROM table ORDER BY name asc, t asc

tables/table_name?s[name]=desc&s[t]=asc
SELECT * FROM table ORDER BY name desc, t asc
```

Задание ограничений
--------------------------
За ограничения отвечает параметр q. Наименования параметров могут быть или предикатами условий AREL, или логическими операторами. Параметры обрабатываются в том порядке, в котором встречаются в строке запроса.
Параметр может содержать вложенные значения для ключей and и or. Параметры на первом уровне трактуются как значения ключа со значением AND.

Примеры
```
HTTP tables/table_name?q[name_eq]=a
RUBY { name: 'a' }
AREL TableName.where(TableName[:name].eq('a'))
SQL SELECT * FROM table WHERE name = 'a'

HTTP /tables/spree_users?s[email]=mail&s[login]=login&order[email]=desc&q[id_eq]=1&q[or][id_lt]=5&q[or][id_gt]=8&q[or][and][id_gt]=0&q[or][and][or][id_lt]=1&q[or][and][or][id_gt]=2&q[or][and][email_not_eq]=bt&q[or][email_eq]=1
RUBY {
      s: {email: :mail, login: :login },
      order: {email: :desc },
      q: {
        id_eq: 1,
        or: {
          id_lt: 5,
          id_gt: 8,
          and: {
            id_gt: 0,
            or: { id_lt: 1, id_gt: 2 },
            email_not_eq: 'bt' },
          email_eq: '1'
        }
      }
    }
SELECT
  "spree_users"."email" AS "mail",
  "spree_users"."login" AS "login"
FROM
  "spree_users"
WHERE
  ("spree_users"."id" = 1
  OR
  (
    ("spree_users"."id" < 5
    OR
    "spree_users"."id" > 8)
    AND
    ("spree_users"."id" > 0
    OR
    ("spree_users"."id" < 1 OR "spree_users"."id" > 2)) AND "spree_users"."email" != 'bt' OR "spree_users"."email" = '1'))  ORDER BY "email" desc
```
