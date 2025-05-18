const AWS = require('aws-sdk');
const { Pool } = require('pg');
const { createHash } = require('crypto');
const { v4: uuidv4 } = require('uuid');

// 🎯 Conexão com Aurora PostgreSQL
const pool = new Pool({
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  port: 5432,
  ssl: { rejectUnauthorized: false },
});

// 🌐 Cliente da API Gateway Management
const getApiClient = (event) => {
  const domain = event.requestContext.domainName;
  const stage = event.requestContext.stage;
  return new AWS.ApiGatewayManagementApi({ endpoint: `${domain}/${stage}` });
};

exports.handler = async (event) => {
  console.info("📥 Evento recebido:", JSON.stringify(event));

  const senderConnectionId = event.requestContext.connectionId;
  const apiClient = getApiClient(event);

  try {
    const body = JSON.parse(event.body || '{}');
    console.info("📦 Body parseado:", body);

    const { receiverId, to, content, type } = body;
    const realReceiverId = receiverId || to;
    if (!realReceiverId || !content || typeof realReceiverId !== 'string' || typeof content !== 'string') {
      console.warn("⚠️ Campos inválidos.");
      return {
        statusCode: 400,
        body: 'Campos inválidos: receiverId/to e content são obrigatórios',
      };
    }

    // 🔍 Busca user_id do remetente pela connection_id
    console.log("🔍 Buscando user_id do sender pela connection_id:", senderConnectionId);
    const senderRes = await pool.query(
      'SELECT user_id FROM connections WHERE connection_id = $1',
      [senderConnectionId]
    );

    if (senderRes.rowCount === 0) {
      console.warn("🚫 Remetente não autenticado ou conexão expirada.");
      return { statusCode: 401, body: 'Remetente não autenticado' };
    }

    const senderId = senderRes.rows[0].user_id;
    console.info("🆔 Sender ID:", senderId);

    // 🛡️ Verifica se os usuários são amigos
    console.log(`🔍 Verificando amizade entre ${senderId} e ${realReceiverId}...`);
    const friendshipCheck = await pool.query(`
      SELECT 1 FROM friends
      WHERE ((user_id = $1 AND friend_id = $2) OR (user_id = $2 AND friend_id = $1))
        AND status = 'accepted'
      LIMIT 1
    `, [senderId, realReceiverId]);

    if (friendshipCheck.rowCount === 0) {
      console.warn("⛔ Usuários não são amigos.");
      return { statusCode: 403, body: 'Você não pode enviar mensagens para esse usuário' };
    }

    // 🧠 Gera conversation_id determinístico
    const orderedIds = [senderId, realReceiverId].sort();
    const conversationId = createHash('sha256')
      .update(orderedIds.join('-'))
      .digest('hex');
    console.log("🧠 conversation_id gerado:", conversationId);

    // 📨 Cria a mensagem, reutilizando o id do cliente se enviado
    const message = {
      id: body.id || uuidv4(),
      conversation_id: conversationId,
      from: senderId,
      to: realReceiverId,
      type: type || 'text',
      content: content.trim(),
      timestamp: new Date().toISOString(),
    };

    console.log("📤 Payload final:", JSON.stringify(message));

    // Sempre salva a mensagem no banco, independente do status do destinatário
    await pool.query(`
      INSERT INTO messages (id, conversation_id, sender_id, content, type, created_at, delivered, read)
      VALUES ($1, $2, $3, $4, $5, $6, false, false)
    `, [
      message.id,
      conversationId,
      senderId,
      message.content,
      message.type,
      message.timestamp,
    ]);

    // 🔎 Verifica se o destinatário está online
    const receiverRes = await pool.query(`
      SELECT connection_id FROM connections
      WHERE user_id = $1
      ORDER BY connected_at DESC
      LIMIT 1
    `, [realReceiverId]);

    if (receiverRes.rowCount === 0) {
      console.warn("⚠️ Usuário está offline. Mensagem salva no banco.");
      return { statusCode: 200, body: 'Usuário offline. Mensagem salva.' };
    }

    // ✅ Envia via WebSocket
    const connectionId = receiverRes.rows[0].connection_id;

    try {
      console.info(`📡 Enviando mensagem para conexão ativa: ${connectionId}`);
      await apiClient.postToConnection({
        ConnectionId: connectionId,
        Data: JSON.stringify(message),
      }).promise();

      console.info("✅ Mensagem enviada com sucesso.");
      return {
        statusCode: 200,
        body: 'Mensagem enviada com sucesso',
      };
    } catch (err) {
      console.error("❌ Erro ao enviar mensagem:", err);
      if (err.statusCode === 410) {
        console.warn(`🗑️ Conexão expirada (${connectionId}), removendo.`);
        await pool.query('DELETE FROM connections WHERE connection_id = $1', [connectionId]);
      }
      // Mensagem já está salva, não precisa salvar de novo
      return {
        statusCode: 200,
        body: 'Erro ao enviar. Mensagem salva para entrega futura.',
      };
    }
  } catch (error) {
    console.error("❌ Erro inesperado na Lambda:", error);
    return {
      statusCode: 500,
      body: 'Erro interno ao processar mensagem',
    };
  }
};
