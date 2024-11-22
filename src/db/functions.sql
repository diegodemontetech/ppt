-- Authentication functions
CREATE OR REPLACE FUNCTION login(email TEXT, password TEXT)
RETURNS json AS $$
DECLARE
  _user users;
  token TEXT;
BEGIN
  SELECT * INTO _user FROM users WHERE users.email = login.email;
  
  IF _user.password = crypt(password, _user.password) THEN
    token := sign(
      json_build_object(
        'role', _user.role,
        'user_id', _user.id,
        'exp', extract(epoch from now())::integer + 3600
      ),
      current_setting('app.jwt_secret')
    );
    
    RETURN json_build_object(
      'token', token,
      'user', json_build_object(
        'id', _user.id,
        'email', _user.email,
        'role', _user.role
      )
    );
  ELSE
    RAISE EXCEPTION 'Invalid login credentials';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION signup(email TEXT, password TEXT, role TEXT DEFAULT 'user')
RETURNS json AS $$
DECLARE
  _user users;
  token TEXT;
BEGIN
  INSERT INTO users (email, password, role)
  VALUES (
    email,
    crypt(password, gen_salt('bf')),
    role
  )
  RETURNING * INTO _user;
  
  token := sign(
    json_build_object(
      'role', _user.role,
      'user_id', _user.id,
      'exp', extract(epoch from now())::integer + 3600
    ),
    current_setting('app.jwt_secret')
  );
  
  RETURN json_build_object(
    'token', token,
    'user', json_build_object(
      'id', _user.id,
      'email', _user.email,
      'role', _user.role
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;