/* 
1. Diseño de la base de datos:

Vamos a crear una tabla para almacenar la información de las cuentas bancarias y
otra para registrar las transacciones. Supongamos que tienes una tabla llamada 
"Cuentas" con las columnas con las columnas "ID_Cuenta", "Nombre_Cuenta", y "Saldo".
*/

/* Primero hay que crear un secuencia para que las claves primarias sean auto incrementable */
CREATE SEQUENCE seq_cuenta_cuentas
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE;

CREATE SEQUENCE seq_cuenta_transacciones
    START WITH 1
    INCREMENT BY 1
    NOMAXVALUE
    NOCYCLE;

/* A bien corresponde crear la tabla para registrar las cuentas */

CREATE TABLE cuentas (
    id_cuenta NUMBER DEFAULT seq_cuenta_cuentas.NEXTVAL PRIMARY KEY,
    nombre_cuenta VARCHAR2(50),
    saldo NUMBER(10,2)
);

-- Insertar datos en la tabla cuentas
INSERT INTO cuentas (nombre_cuenta, saldo)
VALUES ('Cuenta_Principal', 1000);
INSERT INTO cuentas (nombre_cuenta, saldo)
VALUES ('Cuenta_Secundaria', 1000);


CREATE TABLE transacciones (
    id_transaccion NUMBER DEFAULT seq_cuenta_transacciones.NEXTVAL PRIMARY KEY,
    id_cuenta NUMBER,
    tipo_transaccion VARCHAR2(50),
    monto NUMBER(10,2),
    fecha_transaccion DATE DEFAULT SYSDATE,
    CONSTRAINT fk_cuenta FOREIGN KEY (id_cuenta) REFERENCES cuentas(id_cuenta)
);

/* 
2. Crear triggers y procedimientos:

Vamos a crear un trigger y un procedimiento almacenado para actualizar automáticamente
el saldo de las cuentas después de cada transacción.
 */

 -- Trigger para actualizar el saldo después de una transacción
CREATE OR REPLACE TRIGGER actualizar_saldo
AFTER INSERT ON transacciones
FOR EACH ROW
DECLARE
    PRAGMA AUTONOMOUS_TRANSACTION; -- Inicia una transacción autónoma
    v_saldo NUMBER(10,2);
BEGIN
    IF :NEW.tipo_transaccion = 'Deposito' THEN
        -- Bloquear la fila de la cuenta para evitar actualización perdida
        SELECT saldo + :NEW.monto INTO v_saldo
        FROM cuentas
        WHERE id_cuenta = :NEW.id_cuenta
        FOR UPDATE; -- Con esto estamos bloqueando la fila

        -- Actualizar el saldo
        UPDATE cuentas
        SET saldo = v_saldo
        WHERE id_cuenta = :NEW.id_cuenta;
    ELSIF :NEW.tipo_transaccion = 'Retiro' THEN
        -- Bloquear la fila de la cuenta para evitar actualización perdida
        SELECT saldo - :NEW.monto INTO v_saldo
        FROM cuentas
        WHERE id_cuenta = :NEW.id_cuenta
        FOR UPDATE; -- Con esto estamos bloqueando la fila

        -- Actualizar el saldo
        UPDATE cuentas
        SET saldo = v_saldo
        WHERE id_cuenta = :NEW.id_cuenta;
    END IF;
    COMMIT; -- Confirma la transacción autónoma
END;

-- Procedimiento almacenado para realizar depósitos
CREATE OR REPLACE PROCEDURE realizardeposito(
    p_id_cuenta IN NUMBER,
    p_monto IN NUMBER
)
AS
BEGIN
    INSERT INTO transacciones (id_cuenta, tipo_transaccion, monto, fecha_transaccion)
    VALUES (p_id_cuenta, 'Deposito', p_monto, SYSDATE);
END realizardeposito;

-- Procedimiento almacenado para realizar retiros
CREATE OR REPLACE PROCEDURE realizarretiro(
    p_id_cuenta IN NUMBER,
    p_monto IN NUMBER
)
AS
BEGIN
    INSERT INTO transacciones (id_cuenta, tipo_transaccion, monto, fecha_transaccion)
    VALUES (p_id_cuenta, 'Retiro', p_monto, SYSDATE);
END realizarretiro;

/* Sentencias para llamar y hacer uso de los procedimientos almacenados */

BEGIN
  realizarretiro(1, 500);
  realizardeposito(2, 500);
END;
/


SELECT * FROM cuentas;

UPDATE cuentas SET saldo=1000 WHERE id_cuenta=1;
UPDATE cuentas SET saldo=1000 WHERE id_cuenta=2;