import time
import pandas as pd
import numpy as np
import os
from sqlalchemy import create_engine, Table, MetaData, select, insert, update, delete
from sqlalchemy.exc import SQLAlchemyError
from dotenv import load_dotenv

# Funções
def tratamento_tabela(df):
    if 'isupdated' in df.columns and 'isdeleted' in df.columns:
        df_novo = pd.DataFrame({
            'isupdated': df['isupdated'],
            'isdeleted': df['isdeleted']
        })
        df = df.drop(columns=['isupdated', 'isdeleted'])
    else:
        df_novo = pd.DataFrame(columns=['isupdated', 'isdeleted'])
    return df, df_novo

def carregar_dados(engine, tabela_nome):
    try:
        df = pd.read_sql_table(tabela_nome, con=engine)
        print(f"Dados carregados com sucesso da tabela: {tabela_nome}.")
        return df
    except SQLAlchemyError as e:
        print(f"Erro ao carregar dados da tabela: {tabela_nome}: {e}")
        return None

def sync_table(engine_dest, engine_source, df_all, df_changes, tabela_nome_dest, tabela_nome_source):
    conn_dest = engine_dest.connect()
    conn_source = engine_source.connect()
    metadata = MetaData()

    table_dest = Table(tabela_nome_dest, metadata, autoload_with=engine_dest)
    table_source = Table(tabela_nome_source, metadata, autoload_with=engine_source)
    
    try:
        for idx, row in df_changes.iterrows():
            record = df_all.iloc[idx]
            record_dict = {col: int(record[col]) if isinstance(record[col], (np.integer, np.floating)) else record[col] for col in df_all.columns}
            
            # Verifica se o registro existe no destino
            stmt_check = select(table_dest.c.id).where(table_dest.c.id == int(record['id']))
            record_exists = conn_dest.execute(stmt_check).fetchone() is not None
            
            if 'isdeleted' in row and row['isdeleted']:
                if record_exists:
                    stmt_delete = delete(table_dest).where(table_dest.c.id == int(record['id']))
                    conn_dest.execute(stmt_delete)
                    print(f"Registro com ID {record['id']} deletado da tabela {tabela_nome_dest}.")
            elif 'isupdated' in row and row['isupdated']:
                if record_exists:
                    stmt_update = update(table_dest).values(record_dict).where(table_dest.c.id == int(record['id']))
                    conn_dest.execute(stmt_update)
                    print(f"Registro com ID {record['id']} atualizado na tabela {tabela_nome_dest}.")
                else:
                    stmt_insert = insert(table_dest).values(record_dict)
                    conn_dest.execute(stmt_insert)
                    print(f"Registro com ID {record['id']} criado (update) na tabela {tabela_nome_dest}.")
            else:
                if not record_exists:
                    stmt_insert = insert(table_dest).values(record_dict)
                    conn_dest.execute(stmt_insert)
                    print(f"Registro com ID {record['id']} criado (insert) na tabela {tabela_nome_dest}.")
        
        # Deletar registros marcados como deletados, se a coluna 'isdeleted' existir
        if 'isdeleted' in table_source.c:
            stmt_delete_source = delete(table_source).where(table_source.c.isdeleted == True)
            conn_source.execute(stmt_delete_source)
            print(f"Registros deletados da tabela {tabela_nome_source} onde isdeleted é True.")

    except SQLAlchemyError as e:
        print(f"Erro ao sincronizar dados: {e}")
    finally:
        conn_dest.commit()
        conn_source.commit()
        conn_dest.close()
        conn_source.close()


load_dotenv()
# Configurações dos bancos de dados
source_db_url = os.getenv("DB_PRIMEIRO_ANO")
dest_db_url = os.getenv("DB_SEGUNDO_ANO")

engine_source = create_engine(source_db_url)
engine_dest = create_engine(dest_db_url)

# Definindo as tabelas de origem e destino
tabelas_origem_destino = {
    "interesse": "interest",
    "categoria": "category",
    "plano": "plan",
    "admin": "admin"
}

# Carregando e sincronizando dados para cada tabela
for tabela_origem, tabela_dest in tabelas_origem_destino.items():
    df = carregar_dados(engine_source, tabela_origem)
    
    if tabela_origem == "interesse" or tabela_origem == "categoria":
        df.columns = ['name' if col == 'nome' else col for col in df.columns]
    elif tabela_origem == "plano":
        df.columns = ['name' if col == 'nome' else 'value' if col == 'valor' else col for col in df.columns]
    elif tabela_origem == "admin":
        df.columns = ['username' if col == 'usuario' else 'password' if col == 'senha' else col for col in df.columns]

    df, df_changes = tratamento_tabela(df)
    
    sync_table(engine_dest, engine_source, df, df_changes, tabela_dest, tabela_origem)
