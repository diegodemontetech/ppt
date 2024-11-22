import Fastify from 'fastify';
import cors from '@fastify/cors';
import pg from 'pg';
import bcrypt from 'bcryptjs';
import * as jose from 'jose';

const fastify = Fastify({ logger: true });
await fastify.register(cors, {
  origin: true
});

const { Pool } = pg;
const pool = new Pool({
  user: 'ead',
  password: 'Kabul@21',
  host: '144.168.41.114',
  port: 5432,
  database: 'eadcorp',
  ssl: false
});

const JWT_SECRET = new TextEncoder().encode('Kabul@102030405060');

// Auth middleware
async function authenticate(request, reply) {
  const authHeader = request.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    reply.code(401).send({ error: 'No token provided' });
    return;
  }

  try {
    const { payload } = await jose.jwtVerify(token, JWT_SECRET);
    request.user = payload;
  } catch (error) {
    reply.code(403).send({ error: 'Invalid token' });
    return;
  }
}

// Rest of the server code remains the same...