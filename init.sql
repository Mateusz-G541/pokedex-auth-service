-- Initialize auth database
CREATE DATABASE IF NOT EXISTS auth_db;
USE auth_db;

-- Grant privileges to auth_user
GRANT ALL PRIVILEGES ON auth_db.* TO 'auth_user'@'%';
FLUSH PRIVILEGES;
