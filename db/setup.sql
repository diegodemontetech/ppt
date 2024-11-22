-- Primeiro, instale as extensões necessárias
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Funções de autenticação
CREATE OR REPLACE FUNCTION login(
  email TEXT,
  pass TEXT
) RETURNS json AS $$
DECLARE
  _user users;
  result json;
BEGIN
  SELECT * INTO _user
  FROM users
  WHERE users.email = login.email;

  IF _user.password_hash = crypt(pass, _user.password_hash) THEN
    result := json_build_object(
      'id', _user.id,
      'email', _user.email,
      'role', _user.role
    );
    RETURN result;
  ELSE
    RAISE invalid_password USING message = 'invalid user or password';
  END IF;
END;
$$ language plpgsql security definer;

CREATE OR REPLACE FUNCTION signup(
  email TEXT,
  pass TEXT,
  user_role TEXT DEFAULT 'user'
) RETURNS json AS $$
DECLARE
  result json;
  new_user users;
BEGIN
  INSERT INTO users (email, password_hash, role)
  VALUES (
    email,
    crypt(pass, gen_salt('bf')),
    user_role
  )
  RETURNING * INTO new_user;

  result := json_build_object(
    'id', new_user.id,
    'email', new_user.email,
    'role', new_user.role
  );
  
  RETURN result;
END;
$$ language plpgsql security definer;

-- Recrie os roles com as permissões corretas
DROP ROLE IF EXISTS web_anon;
DROP ROLE IF EXISTS authenticator;

CREATE ROLE web_anon NOLOGIN;
CREATE ROLE authenticator NOINHERIT LOGIN PASSWORD 'mysecretpassword';

-- Configure as permissões
GRANT web_anon TO authenticator;
GRANT USAGE ON SCHEMA public TO web_anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO web_anon;
GRANT EXECUTE ON FUNCTION login(text,text) TO web_anon;
GRANT EXECUTE ON FUNCTION signup(text,text,text) TO web_anon;