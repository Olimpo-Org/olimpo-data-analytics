CREATE TABLE Categoria 
(
    ID INT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL UNIQUE,
    isUpdated BOOLEAN DEFAULT false,
    isDeleted BOOLEAN DEFAULT false
);

CREATE TABLE Interesse 
(
    ID INT PRIMARY KEY,
    nome VARCHAR(255) NOT NULL UNIQUE,
    isUpdated BOOLEAN DEFAULT false,
    isDeleted BOOLEAN DEFAULT false
);

CREATE TABLE Cliente 
( 
    ID SERIAL PRIMARY KEY, 
    email VARCHAR(255), 
    senha VARCHAR(255),  
    nome VARCHAR(255), 
    sobrenome VARCHAR(255),  
    cpf VARCHAR(15) NOT NULL UNIQUE,
    genero VARCHAR(255),  
    interesse INT, 
    imagem TEXT,
    FOREIGN KEY (interesse) REFERENCES Interesse(ID)
); 

CREATE TABLE Endereco 
( 
    ID SERIAL PRIMARY KEY,  
    estado VARCHAR(255),
	municipio VARCHAR(255),
	bairro VARCHAR(255),
    idCliente INT NOT NULL,
    FOREIGN KEY (idCliente) REFERENCES Cliente(ID)
);

CREATE TABLE Telefone_Cliente 
( 
    ID SERIAL PRIMARY KEY,  
    telefone VARCHAR(15) NOT NULL,  
    idCliente INT NOT NULL,
    FOREIGN KEY (idCliente) REFERENCES Cliente(ID)
); 

CREATE TABLE Plano 
( 
    ID INT PRIMARY KEY,  
    nome VARCHAR(255),  
    valor FLOAT CHECK (valor >= 0),
    isUpdated BOOLEAN DEFAULT false,
    isDeleted BOOLEAN DEFAULT false
); 

CREATE TABLE Anuncio 
( 
    ID SERIAL PRIMARY KEY,  
    titulo VARCHAR(255),
    descricao VARCHAR(255),  
    dataDivulgacao DATE DEFAULT CURRENT_DATE,  
	preco FLOAT CHECK (preco >= 0),
    categoria INT,  
    linkImagem TEXT,  
    idCliente INT NOT NULL,
    idPlano INT NOT NULL,
    FOREIGN KEY (categoria) REFERENCES Categoria(ID),
    FOREIGN KEY (idCliente) REFERENCES Cliente(ID),
    FOREIGN KEY (idPlano) REFERENCES Plano(ID)
); 

CREATE TABLE Admin
(
	ID INT PRIMARY KEY,
	usuario VARCHAR(255),
    senha VARCHAR(255),
	isUpdated BOOLEAN DEFAULT false,
    isDeleted BOOLEAN DEFAULT false
);

INSERT INTO Categoria (id, nome) VALUES
(1, 'Doações'),
(2, 'Venda'),
(3, 'Serviços');
    
INSERT INTO Plano (id, nome, valor) VALUES
(1, 'Semideus', 4.9),
(2, 'Deus', 9.9),
(3, 'Titã', 14.9);

INSERT INTO Interesse (id, nome) VALUES
(1, 'Tecnologia'),
(2, 'Estética'),
(3, 'Saúde'),
(4, 'Educação'),
(5, 'Esportes'),
(6, 'Música'),
(7, 'Culinária'),
(8, 'Viagens');

INSERT INTO Admin (id, usuario, senha) VALUES
(1, 'Sofia', '111'),
(2, 'Raphael', '222'),
(3, 'Joaquim', '333'),
(4, 'Stalberg', '444');