from flask import Flask, request, jsonify

app = Flask(__name__)

# "Banco de dados" em memória
users = {

}  # {username: password}
messages = []  # lista de dicts: {from, to, message}

@app.route('/')
def hello():
    return "API Python funcionando"

# Registro de usuário
@app.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({"error": "username e password são obrigatórios"}), 400
    if username in users:
        return jsonify({"error": "usuário já existe"}), 409
    users[username] = password
    return jsonify({"message": f"Usuário {username} registrado com sucesso"}), 201

# Autenticação (login simples)
@app.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    if users.get(username) == password:
        return jsonify({"message": "Autenticado com sucesso"})
    return jsonify({"error": "Usuário ou senha inválidos"}), 401

# Enviar mensagem
@app.route('/messages', methods=['POST'])
def send_message():
    data = request.json
    from_user = data.get('from')
    to_user = data.get('to')
    message = data.get('message')
    if not from_user or not to_user or not message:
        return jsonify({"error": "from, to e message são obrigatórios"}), 400
    messages.append({"from": from_user, "to": to_user, "message": message})
    return jsonify({"message": "Mensagem enviada com sucesso"}), 201

# Consultar mensagens de um usuário (enviadas ou recebidas)
@app.route('/messages', methods=['GET'])
def get_messages():
    user = request.args.get('user')
    if not user:
        return jsonify({"error": "Parâmetro user é obrigatório"}), 400
    if user not in users:
        return jsonify({"error": "Usuário não existe"}), 404
    user_msgs = [m for m in messages if m['from'] == user or m['to'] == user]
    return jsonify(user_msgs)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
