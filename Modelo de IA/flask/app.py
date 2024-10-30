import pandas as pd
import joblib
from flask import Flask, render_template, request
import os

ROOT_DIR = os.path.dirname(__file__)

app = Flask(__name__)

# Verifique se o caminho do modelo está correto e se o arquivo 'model.joblib' existe na pasta
model_path = os.path.join(ROOT_DIR, 'pipeline.pkl')
pipeline_carregado = joblib.load(model_path)

@app.route('/', methods=['GET', 'POST'])
def home():
    if request.method == 'POST':
        # Captura os dados enviados pelo formulário
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

        # Realiza a predição com o modelo carregado
        prediction = pipeline_carregado.predict(input_features)

        # Renderiza a página de predição com o resultado
        return render_template("prediction.html", prediction=prediction[0])

    # Renderiza a página inicial
    return render_template("index.html")

if __name__ == '__main__':
    app.run(host="0.0.0.0", debug=True)
