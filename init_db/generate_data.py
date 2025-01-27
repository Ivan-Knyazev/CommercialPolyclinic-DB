import psycopg2
from faker import Faker

# Подключение к базе данных
conn = psycopg2.connect(
    database="your_database",
    user="your_user",
    password="your_password",
    host="your_host",
    port="5432"
)

# Создание курсора
cur = conn.cursor()

# Генератор случайных данных
fake = Faker()

# Функция для вставки данных в таблицу
def insert_data(table_name, columns, data):
    placeholders = ', '.join(['%s'] * len(columns))
    sql = f"INSERT INTO {table_name} ({', '.join(columns)}) VALUES ({placeholders})"
    cur.executemany(sql, data)

# Генерация данных для таблицы Contacts
contacts_data = [
    (fake.phone_number(), fake.email(), fake.user_name(), fake.user_name()) for _ in range(10)
]
insert_data('Contacts', ['Phone', 'Email', 'TelegramNickname', 'VKNickname'], contacts_data)

# Генерация данных для таблицы Patient
patient_data = [
    (fake.name(), fake.last_name(), fake.last_name(), fake.date_between(start_date='-30y', end_date='-18y'),
     fake.random_element(['мужской', 'женский']), fake.ssn(), contact_id)
    for contact_id in range(1, 11)
]
insert_data('Patient', ['Name', 'Surname', 'Patronymic', 'BirthDate', 'Gender', 'PassportDetails', 'ContactID'], patient_data)

# ... аналогично для остальных таблиц

# Сохранение изменений
conn.commit()

# Закрытие соединения
cur.close()
conn.close()