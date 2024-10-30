-- Drop inicial

-- Removendo Funções de Trigger
DROP TRIGGER IF EXISTS trigger_log_customer ON Customer;
DROP TRIGGER IF EXISTS trigger_log_advertisement ON Advertisement;
DROP TRIGGER IF EXISTS trigger_log_announcement ON Announcement;
DROP TRIGGER IF EXISTS trigger_log_publication ON Publication;
DROP TRIGGER IF EXISTS trigger_log_community ON Community;
DROP TRIGGER IF EXISTS trigger_log_plan ON Plan;

-- Removendo Funções de Log
DROP FUNCTION IF EXISTS log_customer_action() CASCADE;
DROP FUNCTION IF EXISTS log_advertisement_action() CASCADE;
DROP FUNCTION IF EXISTS log_announcement_action() CASCADE;
DROP FUNCTION IF EXISTS log_publication_action() CASCADE;
DROP FUNCTION IF EXISTS log_community_action() CASCADE;
DROP FUNCTION IF EXISTS log_plan_action() CASCADE;
DROP FUNCTION IF EXISTS check_administrator(VARCHAR, INT) CASCADE;

-- Removendo as Procedures
DROP PROCEDURE IF EXISTS insert_customer(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP PROCEDURE IF EXISTS update_customer(INT, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP PROCEDURE IF EXISTS delete_customer(INT) CASCADE;
DROP PROCEDURE IF EXISTS insert_advertisement(VARCHAR, DATE, VARCHAR, VARCHAR, VARCHAR, VARCHAR, TEXT) CASCADE;
DROP PROCEDURE IF EXISTS update_advertisement(INT, VARCHAR, VARCHAR, FLOAT) CASCADE;
DROP PROCEDURE IF EXISTS delete_advertisement(INT) CASCADE;
DROP PROCEDURE IF EXISTS insert_announcement(INT, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR) CASCADE;
DROP PROCEDURE IF EXISTS update_announcement(INT, INT, VARCHAR, VARCHAR, TEXT, VARCHAR, VARCHAR) CASCADE;
DROP PROCEDURE IF EXISTS delete_announcement(INT) CASCADE;
DROP PROCEDURE IF EXISTS insert_publication(DATE, INT, VARCHAR, VARCHAR) CASCADE;
DROP PROCEDURE IF EXISTS update_publication(INT, DATE, INT, VARCHAR) CASCADE;
DROP PROCEDURE IF EXISTS delete_publication(INT) CASCADE;
DROP PROCEDURE IF EXISTS insert_community(VARCHAR, DATE, TEXT, VARCHAR) CASCADE;
DROP PROCEDURE IF EXISTS update_community(INT, VARCHAR, DATE, TEXT) CASCADE;
DROP PROCEDURE IF EXISTS delete_community(INT) CASCADE;
DROP PROCEDURE IF EXISTS add_customer_to_community(VARCHAR, INT) CASCADE;
DROP PROCEDURE IF EXISTS add_administrator(VARCHAR, INT) CASCADE;

-- Removendo as tabelas caso já existam
DROP TABLE IF EXISTS Log_Advertisement CASCADE;
DROP TABLE IF EXISTS Log_Plan CASCADE;
DROP TABLE IF EXISTS Log_Community CASCADE;
DROP TABLE IF EXISTS Log_Publication CASCADE;
DROP TABLE IF EXISTS Log_Announcement CASCADE;
DROP TABLE IF EXISTS Log_Customer CASCADE;
DROP TABLE IF EXISTS RestricArea_Admin CASCADE;
DROP TABLE IF EXISTS Administrator CASCADE;
DROP TABLE IF EXISTS Community_Customer CASCADE;
DROP TABLE IF EXISTS Publication CASCADE;
DROP TABLE IF EXISTS Announcement CASCADE;
DROP TABLE IF EXISTS Advertisement CASCADE;
DROP TABLE IF EXISTS Community CASCADE;
DROP TABLE IF EXISTS Plan CASCADE;
DROP TABLE IF EXISTS Category CASCADE;
DROP TABLE IF EXISTS Address CASCADE;
DROP TABLE IF EXISTS Phone_Customer CASCADE;
DROP TABLE IF EXISTS Customer CASCADE;
DROP TABLE IF EXISTS Gender CASCADE;

-- Tabelas

CREATE TABLE Gender (
    ID INT PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Interest(
    ID INT PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE DEFAULT 'Nenhum'
);

CREATE TABLE Customer (
    ID INT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE CHECK (email LIKE '%@%'),
    password VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    cpf VARCHAR(14) NOT NULL UNIQUE,
    profile_image TEXT,
    gender_id INT,
    interest_id INT,
    FOREIGN KEY (gender_id) REFERENCES Gender(ID),
    FOREIGN KEY (interest_id) REFERENCES Interest(ID)
);

CREATE TABLE Phone_Customer (
    ID INT PRIMARY KEY,
    phone VARCHAR(15) NOT NULL,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(ID)
);

CREATE TABLE Address (
    ID INT PRIMARY KEY,
    neighborhood VARCHAR(255),
    state VARCHAR(255),
    municipality VARCHAR(255),
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(ID)
);

CREATE TABLE Category (
    ID INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE Plan (
    ID INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    value FLOAT CHECK (value >= 0)
);

CREATE TABLE Community (
    ID INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    start_date DATE,
    neighborhood VARCHAR(255) DEFAULT 'Não especificado',
    image TEXT
);

CREATE TABLE Advertisement (
    ID INT PRIMARY KEY,
    title VARCHAR(255),
    description VARCHAR(255),
    publication_date DATE DEFAULT CURRENT_DATE,
    price FLOAT,
    category INT,
    image TEXT,
    user_id INT,
    plan_id INT,
    FOREIGN KEY (category) REFERENCES Category(ID),
    FOREIGN KEY (user_id) REFERENCES Customer(ID) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES Plan(ID)
);

CREATE TABLE Announcement (
    ID INT PRIMARY KEY,
    community_id INT,
    sender_id VARCHAR,
    sender_name VARCHAR,
    image TEXT,
    description VARCHAR,
    tag VARCHAR,
    FOREIGN KEY (community_id) REFERENCES Community(ID) ON DELETE CASCADE
);

CREATE TABLE Publication (
    ID INT PRIMARY KEY,
    publication_date DATE,
    likes INT,
    description VARCHAR(255),
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(ID) ON DELETE CASCADE
);

CREATE TABLE Community_Customer (
    ID SERIAL PRIMARY KEY,
    customer_id INT,
    community_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(ID) ON DELETE CASCADE,
    FOREIGN KEY (community_id) REFERENCES Community(ID) ON DELETE CASCADE
);

CREATE TABLE Administrator (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    community_id INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(ID) ON DELETE CASCADE,
    FOREIGN KEY (community_id) REFERENCES Community(ID) ON DELETE CASCADE
);

CREATE TABLE Admin (
    ID INT PRIMARY KEY,
    username VARCHAR(255),
    password VARCHAR(255)
);

CREATE TABLE Log_Customer (
    id SERIAL PRIMARY KEY,
    action_type VARCHAR(50),
    customer_id INT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Log_Announcement (
    id SERIAL PRIMARY KEY,
    action_type VARCHAR(50),
    announcement_id INT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Log_Publication (
    id SERIAL PRIMARY KEY,
    action_type VARCHAR(50),
    publication_id INT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Log_Community (
    id SERIAL PRIMARY KEY,
    action_type VARCHAR(50),
    community_id INT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Log_Plan (
    id SERIAL PRIMARY KEY,
    action_type VARCHAR(50),
    plan_id INT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Log_Advertisement (
    id SERIAL PRIMARY KEY,
    action_type VARCHAR(50),
    advertisement_id INT,
    action_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Procedures e Functions

-- Tabela: Customer
CREATE OR REPLACE PROCEDURE insert_customer(
    p_email VARCHAR,
    p_password VARCHAR,
    p_name VARCHAR,
    p_surname VARCHAR,
    p_cpf VARCHAR,
    p_gender_name VARCHAR,
    p_interest_name VARCHAR,
    p_profile_image TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_gender_id INT;
    v_interest_id INT;
    v_new_id INT;
BEGIN
    IF EXISTS (SELECT 1 FROM Customer WHERE cpf = p_cpf) THEN
        RAISE EXCEPTION 'Customer already exists with CPF: %', p_cpf;
    END IF;

    SELECT ID INTO v_gender_id FROM Gender WHERE name = p_gender_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Gender not found: %', p_gender_name;
    END IF;

    SELECT ID INTO v_interest_id FROM Interest WHERE name = p_interest_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Interest not found: %', p_interest_name;
    END IF;

    -- Calcula o próximo ID
    SELECT COALESCE(MAX(ID), 0) + 1 INTO v_new_id FROM Customer;

    INSERT INTO Customer (ID, email, password, name, surname, cpf, gender_id, interest_id, profile_image)
    VALUES (v_new_id, p_email, p_password, p_name, p_surname, p_cpf, v_gender_id, v_interest_id, p_profile_image);
END;
$$;

CREATE OR REPLACE PROCEDURE update_customer(
    p_customer_id INT,
    p_email VARCHAR,
    p_name VARCHAR,
    p_surname VARCHAR,
    p_cpf VARCHAR,
    p_gender_name VARCHAR,
    p_profile_image TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_gender_id INT;
BEGIN
    SELECT ID INTO v_gender_id FROM Gender WHERE name = p_gender_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Gender not found: %', p_gender_name;
    END IF;

    UPDATE Customer
    SET email = p_email,
        name = p_name,
        surname = p_surname,
        cpf = p_cpf,
        gender_id = v_gender_id,
        profile_image = p_profile_image
    WHERE ID = p_customer_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_customer(
    p_customer_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM Customer WHERE ID = p_customer_id;
END;
$$;

-- Tabela: Advertisement
CREATE OR REPLACE PROCEDURE insert_advertisement(
    p_description VARCHAR,
    p_date DATE,
    p_category_name VARCHAR,
    p_title VARCHAR,
    p_plan_name VARCHAR,
    p_customer_cpf VARCHAR,
    p_image TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_category INT;
    v_customer_id INT;
    v_plan_id INT;
    v_new_id INT;
BEGIN
    SELECT ID INTO v_customer_id FROM Customer WHERE cpf = p_customer_cpf;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer not found with CPF: %', p_customer_cpf;
    END IF;

    SELECT ID INTO v_category FROM Category WHERE name = p_category_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Category not found: %', p_category_name;
    END IF;

    SELECT ID INTO v_plan_id FROM Plan WHERE name = p_plan_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Plan not found: %', p_plan_name;
    END IF;

    -- Calcula o próximo ID
    SELECT COALESCE(MAX(ID), 0) + 1 INTO v_new_id FROM Advertisement;

    INSERT INTO Advertisement (ID, description, publication_date, category, title, user_id, plan_id, image)
    VALUES (v_new_id, p_description, p_date, v_category, p_title, v_customer_id, v_plan_id, p_image);
END;
$$;

CREATE OR REPLACE PROCEDURE update_advertisement(
    p_advertisement_id INT,
    p_description VARCHAR,
    p_title VARCHAR,
    p_price FLOAT
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Advertisement
    SET description = p_description,
        title = p_title,
        price = p_price
    WHERE ID = p_advertisement_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_advertisement(
    p_advertisement_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM Advertisement WHERE ID = p_advertisement_id;
END;
$$;

-- Tabela: Announcement
CREATE OR REPLACE PROCEDURE insert_announcement(
    p_community_id INT,
    p_sender_id VARCHAR,
    p_sender_name VARCHAR,
    p_image TEXT,
    p_description VARCHAR,
    p_tag VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_new_id INT;
BEGIN
    -- Calcula o próximo ID
    SELECT COALESCE(MAX(ID), 0) + 1 INTO v_new_id FROM Announcement;

    INSERT INTO Announcement (ID, community_id, sender_id, sender_name, image, description, tag)
    VALUES (v_new_id, p_community_id, p_sender_id, p_sender_name, p_image, p_description, p_tag);
END;
$$;

CREATE OR REPLACE PROCEDURE update_announcement(
    p_announcement_id INT,
    p_community_id INT,
    p_sender_id VARCHAR,
    p_sender_name VARCHAR,
    p_image TEXT,
    p_description VARCHAR,
    p_tag VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Announcement
    SET community_id = p_community_id,
        sender_id = p_sender_id,
        sender_name = p_sender_name,
        image = p_image,
        description = p_description,
        tag = p_tag
    WHERE ID = p_announcement_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_announcement(
    p_announcement_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM Announcement WHERE ID = p_announcement_id;
END;
$$;

-- Tabela: Publication
CREATE OR REPLACE PROCEDURE insert_publication(
    p_date DATE,
    p_likes INT,
    p_description VARCHAR,
    p_customer_cpf VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_customer_id INT;
    v_new_id INT;
BEGIN
    SELECT ID INTO v_customer_id FROM Customer WHERE cpf = p_customer_cpf;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer not found with CPF: %', p_customer_cpf;
    END IF;

    -- Calcula o próximo ID
    SELECT COALESCE(MAX(ID), 0) + 1 INTO v_new_id FROM Publication;

    INSERT INTO Publication (ID, publication_date, likes, description, customer_id)
    VALUES (v_new_id, p_date, p_likes, p_description, v_customer_id);
END;
$$;

CREATE OR REPLACE PROCEDURE update_publication(
    p_publication_id INT,
    p_publication_date DATE,
    p_likes INT,
    p_description VARCHAR
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Publication
    SET publication_date = p_publication_date,
        likes = p_likes,
        description = p_description
    WHERE ID = p_publication_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_publication(
    p_publication_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM Publication WHERE ID = p_publication_id;
END;
$$;

-- Tabela: Community
CREATE OR REPLACE PROCEDURE insert_community(
    p_name VARCHAR,
    p_date DATE,
    p_image TEXT,
    p_customer_cpf VARCHAR
)
LANGUAGE plpgsql AS $$
DECLARE
    v_community_id INT;
    v_new_id INT;
BEGIN
    -- Calcula o próximo ID
    SELECT COALESCE(MAX(ID), 0) + 1 INTO v_new_id FROM Community;

    INSERT INTO Community (ID, name, start_date, image)
    VALUES (v_new_id, p_name, p_date, p_image)
    RETURNING ID INTO v_community_id;

    CALL add_administrator(p_customer_cpf, v_community_id);
END;
$$;

CREATE OR REPLACE PROCEDURE update_community(
    p_community_id INT,
    p_name VARCHAR,
    p_date DATE,
    p_image TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE Community
    SET name = p_name,
        start_date = p_date,
        image = p_image
    WHERE ID = p_community_id;
END;
$$;

CREATE OR REPLACE PROCEDURE delete_community(
    p_community_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    DELETE FROM Community WHERE ID = p_community_id;
END;
$$;

CREATE OR REPLACE PROCEDURE add_customer_to_community(
    p_cpf VARCHAR,
    p_community_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_customer_id INT;
BEGIN
    SELECT ID INTO v_customer_id FROM Customer WHERE cpf = p_cpf;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer not found with CPF: %', p_cpf;
    END IF;

    INSERT INTO Community_Customer (customer_id, community_id)
    VALUES (v_customer_id, p_community_id);
END;
$$;

CREATE OR REPLACE PROCEDURE add_administrator(
    p_customer_cpf VARCHAR,
    p_community_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_customer_id INT;
BEGIN
    -- Obter o ID do cliente com base no CPF fornecido
    SELECT ID INTO v_customer_id FROM Customer WHERE cpf = p_customer_cpf;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer not found with CPF: %', p_customer_cpf;
    END IF;

    -- Inserir o ID do cliente na tabela Administrator
    INSERT INTO Administrator (customer_id, community_id)
    VALUES (v_customer_id, p_community_id);
END;
$$;

CREATE OR REPLACE FUNCTION check_administrator(
    p_customer_cpf VARCHAR,
    p_community_id INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM Administrator 
        WHERE customer_cpf = p_customer_cpf AND community_id = p_community_id
    ) INTO v_exists;

    RETURN v_exists;
END;
$$ LANGUAGE plpgsql;

-- Triggers

CREATE OR REPLACE FUNCTION log_customer_action() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Log_Customer (action_type, customer_id)
    VALUES (TG_OP, NEW.ID);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_customer
AFTER INSERT OR UPDATE OR DELETE ON Customer
FOR EACH ROW EXECUTE FUNCTION log_customer_action();

CREATE OR REPLACE FUNCTION log_advertisement_action() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Log_Advertisement (action_type, advertisement_id)
    VALUES (TG_OP, NEW.ID);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_advertisement
AFTER INSERT OR UPDATE OR DELETE ON Advertisement
FOR EACH ROW EXECUTE FUNCTION log_advertisement_action();

CREATE OR REPLACE FUNCTION log_announcement_action() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Log_Announcement (action_type, announcement_id)
    VALUES (TG_OP, NEW.ID);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_announcement
AFTER INSERT OR UPDATE OR DELETE ON Announcement
FOR EACH ROW EXECUTE FUNCTION log_announcement_action();

CREATE OR REPLACE FUNCTION log_publication_action() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Log_Publication (action_type, publication_id)
    VALUES (TG_OP, NEW.ID);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_publication
AFTER INSERT OR UPDATE OR DELETE ON Publication
FOR EACH ROW EXECUTE FUNCTION log_publication_action();

CREATE OR REPLACE FUNCTION log_community_action() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Log_Community (action_type, community_id)
    VALUES (TG_OP, NEW.ID);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_community
AFTER INSERT OR UPDATE OR DELETE ON Community
FOR EACH ROW EXECUTE FUNCTION log_community_action();

CREATE OR REPLACE FUNCTION log_plan_action() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Log_Plan (action_type, plan_id)
    VALUES (TG_OP, NEW.ID);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_log_plan
AFTER INSERT OR UPDATE OR DELETE ON Plan
FOR EACH ROW EXECUTE FUNCTION log_plan_action();

-- -- Inserindo dados iniciais

-- INSERT INTO Gender (id, name) VALUES
-- (1, 'Feminino'),
-- (2, 'Masculino'),
-- (3, 'Outro');

-- INSERT INTO Category (id, name) VALUES
-- (1, 'Doações'),
-- (2, 'Venda'),
-- (3, 'Serviços');
    
-- INSERT INTO Plan (id, name, value) VALUES
-- (1, 'Semideus', 4.9),
-- (2, 'Deus', 9.9),
-- (3, 'Titã', 14.9);

-- INSERT INTO Interest (id, name) VALUES
-- (1, 'Tecnologia'),
-- (2, 'Estética'),
-- (3, 'Saúde'),
-- (4, 'Educação'),
-- (5, 'Esportes'),
-- (6, 'Música'),
-- (7, 'Culinária'),
-- (8, 'Viagens');

-- -- Exemplos de inserções
-- CALL insert_customer('test@example.com', 'password', 'Test', 'User', '12345678900', 'Masculino', 'Tecnologia', 'base64_image_string');
-- CALL insert_community('Community Test', CURRENT_DATE, 'base64_image_string', '12345678900');
-- CALL insert_publication(CURRENT_DATE, 5, 'Descrição da nova publicação', '12345678900');
-- CALL insert_announcement(1, 'Sender ID', 'Sender Name', 'base64_image_string', 'announcement description', 'doação');
-- CALL insert_advertisement('Ad description', CURRENT_DATE, 'Venda', 'Product Name', 'Semideus', '12345678900', 'base64_image_string');

-- -- Exemplos de atualização
-- CALL update_customer(1, 'new_email@example.com', 'New Name', 'New Surname', '12345678900', 'Feminino', 'new_base64_image_string');
-- CALL update_announcement(1, 1, 'new_sender_id', 'New Sender Name', 'new_base64_image_string', 'Updated description', 'nova_tag');
-- CALL update_publication(1, CURRENT_DATE, 10, 'Updated publication description');
-- CALL update_advertisement(1, 'Updated Ad Description', 'Updated Title', 99.99);
-- CALL update_community(1, 'Updated Community Name', CURRENT_DATE, 'new_base64_image_string');

-- -- Exemplos de remoção
-- CALL delete_customer(1);
-- CALL delete_announcement(1);
-- CALL delete_publication(1);
-- CALL delete_advertisement(1);
-- CALL delete_community(1);

-- SELECT * FROM Log_Customer;
-- SELECT * FROM Log_Announcement;
-- SELECT * FROM Log_Publication;
-- SELECT * FROM Log_Community;
-- SELECT * FROM Log_Plan;
-- SELECT * FROM Log_Advertisement;

-- SELECT check_administrator('12345678900', 1);
-- CALL add_customer_to_community('12345678900', 1);