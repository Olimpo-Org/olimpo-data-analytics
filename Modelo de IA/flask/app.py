import pandas as pd
import joblib
from flask import Flask, render_template, request
from sqlalchemy import create_engine, Table, Column, Integer, String, MetaData
import os
from dotenv import load_dotenv
import traceback
 
load_dotenv()

DB_HOST = os.getenv('DB_HOST')
DB_USER = os.getenv('DB_USER')
DB_PASSWORD = os.getenv('DB_PASSWORD')
DB_NAME = os.getenv('DB_NAME')
DB_PORT = os.getenv('DB_PORT')
 
engine = create_engine(f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}")
 
ROOT_DIR = os.path.dirname(__file__)
app = Flask(__name__)
 
model_path = os.path.join(ROOT_DIR, 'pipeline.pkl')
pipeline_carregado = joblib.load(model_path)
 
@app.route('/', methods=['GET', 'POST'])
def home():
    if request.method == 'POST':
        cidade = request.form['cidade']
        tipo_moradia = request.form['tipo_moradia']
        pessoas_casa = request.form['pessoas_casa']
        satisfacao_comunicacao_comunidade = request.form['satisfacao_comunicacao_comunidade']
        frequencia_contato = request.form['frequencia_contato']
        comunicacao_importante = request.form['comunicacao_importante']
        usa_plataforma = request.form['usa_plataforma']
        faixa_etaria = request.form['faixa_etaria']
        qualidade_vida = request.form['qualidade_vida']
        situacao_trabalho = request.form['situacao_trabalho']
        renda_familiar = request.form['renda_familiar']
        animais = request.form['animais']
 
        # Criação do DataFrame com as entradas do formulário
        input_features = pd.DataFrame([{
            'cidade': cidade,
            'tipo_moradia': tipo_moradia,
            'pessoas_casa': pessoas_casa,
            'satisfacao_comunicacao_comunidade': satisfacao_comunicacao_comunidade,
            'frequencia_contato': frequencia_contato,
            'comunicacao_importante': comunicacao_importante,
            'usa_plataforma': usa_plataforma,
            'faixa_etaria': faixa_etaria,
            'qualidade_vida': qualidade_vida,
            'situacao_trabalho': situacao_trabalho,
            'renda_familiar': renda_familiar,
            'animais': animais
        }])
 
        prediction = pipeline_carregado.predict(input_features)
 
        try:
            with engine.connect() as connection:
                metadata = MetaData()
                predictions_table = Table(
                    'predictions', metadata,
                    Column('id', Integer, primary_key=True, autoincrement=True),
                    Column('cidade', String(50)),
                    Column('tipo_moradia', String(50)),
                    Column('pessoas_casa', String(50)),
                    Column('satisfacao_comunicacao_comunidade', String(50)),
                    Column('frequencia_contato', String(50)),
                    Column('comunicacao_importante', String(50)),
                    Column('usa_plataforma', String(50)),
                    Column('faixa_etaria', String(50)),
                    Column('qualidade_vida', String(50)),
                    Column('situacao_trabalho', String(50)),
                    Column('renda_familiar', String(50)),
                    Column('animais', String(50)),
                    Column('prediction', String(50))
                )
                metadata.create_all(engine)
 
                insert_query = predictions_table.insert().values(
                    cidade=cidade,
                    tipo_moradia=tipo_moradia,
                    pessoas_casa=pessoas_casa,
                    satisfacao_comunicacao_comunidade=satisfacao_comunicacao_comunidade,
                    frequencia_contato=frequencia_contato,
                    comunicacao_importante=comunicacao_importante,
                    usa_plataforma=usa_plataforma,
                    faixa_etaria=faixa_etaria,
                    qualidade_vida=qualidade_vida,
                    situacao_trabalho=situacao_trabalho,
                    renda_familiar=renda_familiar,
                    animais=animais,
                    prediction=prediction[0]
                )
 
                connection.execute(insert_query)
                connection.commit()  
                print("Data inserted successfully.")
 
                df = pd.read_sql("SELECT * FROM predictions ORDER BY id DESC LIMIT 10", connection)
                print(df)
                print("Prediction result:", prediction)

 
        except Exception as e:
            print(f"Error inserting data: {e}")
            traceback.print_exc()  
 
        return render_template("prediction.html", prediction=prediction[0])
 
    return render_template("index.html")
 
if __name__ == '__main__':
    app.run(host="0.0.0.0", debug=True)
 