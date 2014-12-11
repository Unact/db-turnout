db-turnout
==========

Приложение позволяет предоставлять доступ к СУБД посредством HTTP-запросов.

Сделано на [Sinatra](www.sinatrarb.com/intro.html)

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
SELECT name AS new_name, t AS t1 FROM table
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

Более подробные примеры можно посмотреть здесь: [Примеры](https://github.com/sov-87/db-turnout/blob/master/test/tables_test.rb)

Вызов процедур
--------------------------
Процедуры вызываются по ссылкам вида ```/procedures/procedure_name```

Параметры передаются или в строке, или в теле запроса в виде массива. Параметры, представляющие из себя объекты, будут переданы в процедуру как xml.
