-- Tabelas

CREATE TABLE Gender (
    ID INT PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE Interest (
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
    interest_id INT DEFAULT 0,
    FOREIGN KEY (gender_id) REFERENCES Gender(ID) ON DELETE CASCADE,
    FOREIGN KEY (interest_id) REFERENCES Interest(ID) ON DELETE CASCADE
);

CREATE TABLE Phone_Customer (
    ID SERIAL PRIMARY KEY,
    phone VARCHAR(15) NOT NULL,
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(ID) ON DELETE CASCADE
);

CREATE TABLE Address (
    ID SERIAL PRIMARY KEY,
    neighborhood VARCHAR(255),
    state VARCHAR(255),
    municipality VARCHAR(255),
    customer_id INT,
    FOREIGN KEY (customer_id) REFERENCES Customer(ID) ON DELETE CASCADE
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
    ID SERIAL PRIMARY KEY,
    title VARCHAR(255),
    description VARCHAR(255),
    publication_date DATE DEFAULT CURRENT_DATE,
    price FLOAT,
    category_id INT,
    image TEXT,
    user_id INT,
    plan_id INT,
    FOREIGN KEY (category_id) REFERENCES Category(ID) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES Customer(ID) ON DELETE CASCADE,
    FOREIGN KEY (plan_id) REFERENCES Plan(ID) ON DELETE CASCADE
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

CREATE OR REPLACE PROCEDURE insert_customer(
    p_email VARCHAR,
    p_password VARCHAR,
    p_name VARCHAR,
    p_surname VARCHAR,
    p_cpf VARCHAR,
    p_gender_name VARCHAR,
    p_profile_image TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_gender_id INT;
    v_new_id INT;
BEGIN
    IF EXISTS (SELECT 1 FROM Customer WHERE cpf = p_cpf) THEN
        RAISE EXCEPTION 'Customer already exists with CPF: %', p_cpf;
    END IF;

    SELECT ID INTO v_gender_id FROM Gender WHERE name = p_gender_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Gender not found: %', p_gender_name;
    END IF;

    -- Calcula o próximo ID
    SELECT COALESCE(MAX(ID), 0) + 1 INTO v_new_id FROM Customer;

    INSERT INTO Customer (ID, email, password, name, surname, cpf, gender_id, profile_image)
    VALUES (v_new_id, p_email, p_password, p_name, p_surname, p_cpf, v_gender_id, p_profile_image);
END;
$$;

CREATE OR REPLACE PROCEDURE update_customer(
    p_field VARCHAR,   
    p_new_value VARCHAR,    
    p_customer_id INT  
)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('UPDATE Customer SET %I = $1 WHERE ID = $2', p_field)
    USING p_new_value, p_customer_id;
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
    p_customer_id INT,
    p_price FLOAT,
    p_image TEXT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_category_id INT;
    v_plan_id INT;
BEGIN
    SELECT ID INTO v_category_id FROM Category WHERE name = p_category_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Category not found: %', p_category_name;
    END IF;

    SELECT ID INTO v_plan_id FROM Plan WHERE name = p_plan_name;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Plan not found: %', p_plan_name;
    END IF;

    INSERT INTO Advertisement (title, description, publication_date, price, category_id, image, user_id, plan_id)
    VALUES (p_title, p_description, current_date, p_price, v_category_id, p_image, p_customer_id, v_plan_id);
END;
$$;

CREATE OR REPLACE PROCEDURE update_advertisement(
    p_field VARCHAR,   
    p_new_value VARCHAR,    
    p_advertisement_id INT  
)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('UPDATE Advertisement SET %I = $1 WHERE ID = $2', p_field)
    USING p_new_value, p_advertisement_id;
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
    p_field VARCHAR,   
    p_new_value VARCHAR,    
    p_announcement_id INT  
)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('UPDATE Announcement SET %I = $1 WHERE ID = $2', p_field)
    USING p_new_value, p_announcement_id;
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
    p_field VARCHAR,   
    p_new_value VARCHAR,    
    p_publication_id INT  
)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('UPDATE Publication SET %I = $1 WHERE ID = $2', p_field)
    USING p_new_value, p_publication_id;
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
    p_customer_id INT
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

    CALL add_administrator(p_customer_id, v_community_id);
    CALL add_customer_to_community(p_customer_id, v_community_id);
END;
$$;

CREATE OR REPLACE PROCEDURE insert_community(
    p_name VARCHAR,
    p_date DATE,
    p_image TEXT,
    p_neighbourhood VARCHAR,
    p_customer_id INT
)
LANGUAGE plpgsql AS $$
DECLARE
    v_community_id INT;
    v_new_id INT;
BEGIN
    -- Calcula o próximo ID
    SELECT COALESCE(MAX(ID), 0) + 1 INTO v_new_id FROM Community;

    INSERT INTO Community (ID, name, start_date, neighborhood, image)
    VALUES (v_new_id, p_name, p_date, p_neighbourhood, p_image)
    RETURNING ID INTO v_community_id;

    CALL add_administrator(p_customer_id, v_community_id);
    CALL add_customer_to_community(p_customer_id, v_community_id);
END;
$$;

CREATE OR REPLACE PROCEDURE update_community(
    p_field VARCHAR,   
    p_new_value VARCHAR,    
    p_community_id INT  
)
LANGUAGE plpgsql AS $$
BEGIN
    EXECUTE format('UPDATE Community SET %I = $1 WHERE ID = $2', p_field)
    USING p_new_value, p_community_id;
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
    p_customer_id INT,
    p_community_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM ID FROM Customer WHERE ID = p_customer_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer not found with ID: %', p_customer_id;
    END IF;

    INSERT INTO Community_Customer (customer_id, community_id)
    VALUES (p_customer_id, p_community_id);
END;
$$;

CREATE OR REPLACE PROCEDURE add_administrator(
    p_customer_id INT,
    p_community_id INT
)
LANGUAGE plpgsql AS $$
BEGIN
    PERFORM ID FROM Customer WHERE ID = p_customer_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Customer not found with ID: %', p_customer_id;
    END IF;

    -- Inserir o ID do cliente na tabela Administrator
    INSERT INTO Administrator (customer_id, community_id)
    VALUES (p_customer_id, p_community_id);
END;
$$;

CREATE OR REPLACE FUNCTION check_administrator(
    p_customer_id INT,
    p_community_id INT
) RETURNS BOOLEAN AS $$
DECLARE
    v_exists BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM Administrator 
        WHERE customer_id = p_customer_id AND community_id = p_community_id
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

INSERT INTO Gender (id, name) VALUES
(1, 'Feminino'),
(2, 'Masculino'),
(3, 'Outro');