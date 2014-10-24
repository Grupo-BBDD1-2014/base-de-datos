/* 
2) Listar los dni, nombre y apellido de todos los clientes ordenados por dni en forma ascendente. Realice la
consulta en ambas bases. ¿Qué diferencia nota?

En conclusión, la base de datos desnormalizada tarda más, en promedio las consultas con la base normalizada tardan alrededor de 0.01/0.1 seg
y las consultas en la base de datos desnormalizada tarda 0,03/0.7 seg (duration/fetch). 
Lo otro que encontramos, y que lo demostramos agregando una columna màs en la tabla, es que los dni aparecen repetidos una gran cantidad de veces para la tabla denormalizada. Para la tabla normalizada, solo aparecen 1 vez. 
*/

-- Desnormalizada

SELECT dniCliente, nombreApellidoCliente, count(dniCliente) as cuantos 
FROM reparacion_dn.reparacion 
group by dniCliente 
order by dniCliente asc;

-- =========================================================================
-- Normalizada 

SELECT dniCliente, nombreApellidoCliente, count(dniCliente) as Cant 
FROM reparacion.cliente 
group by dniCliente
order by dniCliente asc;

-- =========================================================================

/*
* 3) Hallar aquellos clientes que para 
* todas sus reparaciones siempre hayan usado su tarjeta de crédito primaria (nunca la tarjeta secundaria). 
* Realice la consulta en ambas bases.
*
*/

-- Desnormalizada

select dniCliente, nombreApellidoCliente
from reparacion_dn.reparacion as R
where R.dniCliente not in 
( 
	select dniCliente
	from reparacion_dn.reparacion as G
	where R.tarjetaSecundaria=G.tarjetaReparacion
)
group by dniCliente
order by dniCliente asc

-- =========================================================================
-- Normalizada 

select dniCliente, nombreApellidoCliente
from reparacion.cliente as C
where dniCliente not in 
( 
	select C.dniCliente
	from reparacion.reparacion as R
	where C.dniCliente=R.dniCliente 
	and C.tarjetaSecundaria=R.tarjetaReparacion
)
order by C.dniCliente asc

-- =========================================================================

/*
* 4) Crear una vista llamada ‘sucursalesPorCliente’ que muestre los dni 
* de los clientes y los códigos de sucursales de
* la ciudad donde vive el cliente. 
* Realice la vista en ambas bases.
*
*/

-- Desnormalizada
/*
* El problema de este ejercicio era que la base no estaba completa, es decir faltaban datos para realizar
* La consulta sin tener que realizar join's. Asumiendo que se encuentran todos los datos, la consulta 
* deberia ser asi
*/

SELECT R.dniCliente,R.codSucursal,R.ciudadCliente, R.ciudadSucursal 
FROM reparacion_dn.reparacion as R 
where R.ciudadSucursal=r.ciudadCliente
group by  dniCliente, codSucursal
order by dniCliente asc

/*
* Realizamos de todas formas, la consulta de otra manera para que nos devolviera los datos.
* Realizamos 3 vistas, aunque esto trae como problema que esas 2 vistas creadas, pueden ser
* utilizadas por un usuario por ejemplo, cuando no deberia ser asi. 
* Las 3 vistas se realizaron porque en una vista no se pueden hacer subconsultas en la clausula FROM.
* 
*/

create VIEW `sucursalvista` AS
    (select 
        `r`.`codSucursal` AS `codSucursal`,
        `r`.`ciudadSucursal` AS `ciudadSucursal`
    from
        `reparacion` `r` 
    group by `r`.`codSucursal`)


create VIEW `clientevista` AS
    select 
        `r`.`dniCliente` AS `dniCliente`,
        `r`.`ciudadCliente` AS `ciudadCliente`
    from
        `reparacion` `r`
    group by `r`.`dniCliente`

create VIEW `sucursalesporcliente` AS
    select distinct
        `c`.`dniCliente` AS `dniCliente`,
        `s`.`codSucursal` AS `codSucursal`,
        `c`.`ciudadCliente` AS `ciudadCliente`
    from
        (`clientevista` `c`
        left join `sucursalvista` `s` ON ((`c`.`ciudadCliente` = `s`.`ciudadSucursal`)))

-- =========================================================================
-- Normalizada 

create VIEW `reparacion`.`sucursalesporcliente` AS
    select 
        `reparacion`.`cliente`.`dniCliente` AS `dniCliente`,
        `reparacion`.`sucursal`.`codSucursal` AS `codSucursal`
    from
        (`reparacion`.`cliente`
        left join `reparacion`.`sucursal` 
		ON ((`reparacion`.`cliente`.`ciudadCliente` = `reparacion`.`sucursal`.`ciudadSucursal`)))

-- Usamos un left join para que muestre a los clientes que no tienen sucursales con  un NULL.
/* Nos parecio mejor mostrar todos los clientes con sus sucursales, 
*y de alguna manera notar que hay clientes sin sucursales en su ciudad
*/
-- =========================================================================
/*
* 5) En la base normalizada, hallar los clientes que dejaron vehículos a reparar en todas las sucursales de la ciudad en la que viven
* Nota: limite su consulta a los primeros 100 resultados, 
* caso contrario el tiempo que tome puede ser excesivo.
* Aqui tuvimos que tener en cuenta que algunos clientes no tenian sucursal en su ciudad.
*/

-- a. Realice la consulta sin utilizar la vista creada en el ej 4.

select distinct r.dniCliente
from reparacion.reparacion as r
where not exists 
(
	select s.codSucursal
	from reparacion.sucursal as s right join reparacion.cliente as c on s.ciudadSucursal = c.ciudadCliente
	where r.dniCliente = c.dniCliente and not exists
	(
		select r.codSucursal
		from reparacion.reparacion as r1
		where r1.dniCliente = r.dniCliente 
		and r1.fechaInicioReparacion = r.fechaInicioReparacion 
		and	r1.codSucursal = s.codSucursal
	)
)

-- =========================================================================
-- b. Realice la consulta utilizando la vista creada en el ej 4.

select distinct r.dniCliente
from reparacion.reparacion as r
where not exists
(
	select v.codSucursal
	from reparacion.sucursalesporcliente as v
	where r.dniCliente = v.dniCliente and not exists
	(
		select r1.codSucursal
		from reparacion.reparacion as r1
		where r1.dniCliente = r.dniCliente
		and r1.fechaInicioReparacion = r.fechaInicioReparacion 
		and r1.codSucursal = v.codSucursal
	)
)
-- No hay diferencia significante en tiempo, para ambas 342 row en 0.8 seg.
-- 
-- =========================================================================

/*
* 6) Hallar los clientes que en alguna de sus reparaciones hayan dejado como dato de contacto el mismo domicilio y
* ciudad que figura en su DNI. Realice la consulta en ambas bases.
*
* Nosotros interpretamos la consulta como : "tienen al menos una reparacion realizada en su ultimo domicilio"
*
* Es decir que direccionCliente y direccionReparacionCliente son la misma.
* Pueden ser distintas en el caso de que el cliente se haya mudado alguna vez.
*
*/

-- Denormalizada

select r.dniCliente
from reparacion_dn.reparacion as r
where r.domicilioCliente = r.direccionReparacionCliente 
	and r.ciudadCliente = r.ciudadReparacionCliente
group by r.dniCliente

-- =========================================================================
-- Normalizada

SELECT C.dniCliente, C.nombreApellidoCliente
from reparacion.cliente as C 
	inner join reparacion.reparacion as R on C.dniCliente = R.dniCliente
where C.domicilioCliente = R.direccionReparacionCliente and C.ciudadCliente = R.ciudadReparacionCliente
group by C.dniCliente

/*
	Estas consultas tienen diferencias en tiempos, aproximadamente el doble de tiempo le costo encontrar
	en la base sin normalizar. Esto se debe a que existe demasiada informacion repetida en la base sin normalizar, 
	debe recorrer todas las filas. 
	Si sacamos el group by, la consulta normalizada nos da 30000 row aprox, y la consulta desnormalizada nos da 130000.

*/
-- =========================================================================

/*
* 7) Para aquellas reparaciones que tengan registrados mas de 3 repuestos, listar el DNI del cliente, el código de
* sucursal, la fecha de reparación y la cantidad de repuestos utilizados. Realice la consulta en ambas bases.
*
*/

-- Denormalizada

select dniCliente, codSucursal, fechaInicioReparacion, count(*) as cantRepuestos
from 
(	select r1.dniCliente, r1.fechaInicioReparacion, repuestoReparacion, codSucursal
	from reparacion_dn.reparacion as r1
	group by r1.dniCliente, fechaInicioReparacion,  r1.repuestoReparacion
) as r
group by dniCliente, fechaInicioReparacion
having cantRepuestos > 2


-- =========================================================================
-- Normalizada

select R.dniCliente, R.codSucursal, R.fechaInicioReparacion,count(*) as cantRepuestos
from  reparacion.reparacion as R inner join reparacion.repuestoreparacion as RP on RP.dniCliente = R.dniCliente
where RP.fechaInicioReparacion = R.fechaInicioReparacion
group by R.dniCliente, R.fechaInicioReparacion
having cantRepuestos > 2


/*
	En tiempo la base sin normalizar tardo mucho màs. 
	Aprox. 0.6 frente a 0.07 segundos que tardo la consulta en la base normalizada
	
*/
-- =========================================================================

/*
* 8) Agregar la siguiente tabla:
* REPARACIONESPORCLIENTE
* idRC: int(11) PK AI
* dniCliente: int(11)
* cantidadReparaciones: int(11)
* fechaultimaactualizacion: datetime
* usuario: char(16)
*
*/

CREATE TABLE `reparacion`.`reparacionesporcliente` (
  `idRC` INT(11) NOT NULL AUTO_INCREMENT,
  `dniCliente` INT(11) NOT NULL,
  `cantidadReparaciones` INT(11) NOT NULL,
  `fechaUltimaActualizacion` DATETIME NOT NULL,
  `usuario` CHAR(16) NOT NULL,
  PRIMARY KEY (`idRC`));

/*
	Los datos de esta tabla no tendrian sentido que alguno fuera null.

*/
-- =========================================================================

/*
* 9) Crear un stored procedure que realice los siguientes pasos dentro de una transacción:
* 
* a) Realizar una consulta que para cada cliente (dniCliente), calcule la cantidad de reparaciones que tiene
* registradas. Registrar la fecha en la que se realiza la consulta y el usuario con el que la realizó.
* 
* b) Guardar el resultado de la consulta en un cursor.
* 
* c) Iterar el cursor e insertar los valores correspondientes en la tabla REPARACIONESPORCLIENTE.
*
* Ejecute el stored procedure.

* Tomamos USUARIO como el usuario que realiza la consulta current_user()
* Tomamos FECHA como la fecha en la que se realiza la consulta NOW()

* 
*/

DELIMITER $$

CREATE PROCEDURE `actualizar_reparacionesporcliente`()
BEGIN

DECLARE dni int(11);
DECLARE cant int(11) default 0;
DECLARE fecha datetime default now();
DECLARE usuario varchar(16) default current_user();
DECLARE done boolean default false;
DECLARE cursor_cliente 
	CURSOR FOR 
		select dniCliente, count(dniCliente) as cantidadReparaciones
		from reparacion
		group by dniCliente;

DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

START transaction;

	open cursor_cliente;
	
	read_loop : loop
		
		fetch cursor_cliente into dni, cant;
		IF done THEN
			LEAVE read_loop;
		END IF;

		insert into reparacionesporcliente values (NULL, dni,cant,fecha, usuario);

	end loop;
COMMIT;
END$$
DELIMITER ; 

/*
	Para llamarlo y que actualice la tabla. (solo deberia hacerse una vez esto).
*/

CALL  actualizar_reparacionesporcliente
-- =========================================================================

/*
* 10) Crear un trigger de modo que al insertar un dato en la tabla REPARACION, se actualice la cantidad de
* reparaciones del cliente, la fecha de actualización y el usuario responsable de la misma (actualiza la tabla
* REPARACIONESPORCLIENTE)
* 
*/
-- =========== Store procedure, solo para que este un poco más ordenado ================
DELIMITER $$

CREATE PROCEDURE `agregar_reparacionesporcliente`(
in dniClienteVar int(11)
)
BEGIN

	declare idActual int(11) default 0;

	set idActual = (select idRC
			from reparacionesporcliente
			where dniCliente = dniClienteVar);
	
	if (idActual > 0) THEN
		update reparacionesporcliente set cantidadReparaciones = cantidadReparaciones + 1, usuario = current_user(), fechaUltimaActualizacion = NOW()
		where idRC = idActual;
	ELSE
		insert into reparacionesporcliente values (null, dniClienteVar,1, NOW(), current_user());
	END IF;	
END$$
DELIMITER ;

-- ============================ El trigger pedido =====================================


Delimiter $$ 
create trigger nueva_reparacion 
	after insert on reparacion
	for each row begin
		
		call agregar_reparacionesporcliente(NEW.dniCliente);
	
	end$$

delimiter ;

/*
	Nos pareció un poco màs ordenado delegar en un SP.
	El problema es que el usuario puede llamar a este SP, y no debería ocurrir.
	De todas formas, la otra versión (sin SP) Sería la siguiente:
*/
Delimiter $$ 
create trigger nueva_reparacion 
	after insert on reparacion
	for each row begin
		declare dniClienteVar int(11) default NEW.dniCliente;
		declare idActual int(11) default 0;
		set idActual = (select idRC
			from reparacionesporcliente
			where dniCliente = dniClienteVar);
		
		if (idActual > 0) THEN
			update reparacionesporcliente set cantidadReparaciones = cantidadReparaciones + 1, usuario = current_user(), fechaUltimaActualizacion = NOW()
			where idRC = idActual;
		ELSE
			insert into reparacionesporcliente values (null, dniClienteVar,1, NOW(), current_user());
		END IF;	
	
	end$$

delimiter ;

-- ====================================================================================

/*
* 11) Crear un stored procedure que sirva para agregar una reparación, junto con una revisión de un empleado
* (REVISIONREPARACION) y un repuesto (REPUESTOREPARACION) relacionados dentro de una sola
* transacción. El stored procedure debe recibir los siguientes parámetros: dniCliente, codSucursal,
* fechaReparacion, cantDiasReparacion, telefonoReparacion, empleadoReparacion, repuestoReparacion.
*
*/
DELIMITER $$
create PROCEDURE `revision_repuesto`(
	in P_dniCliente int(11),
	in P_codSucursal int(11), 
	in P_fechaReparacion datetime, 
	in P_cantDiasReparacion int(11),
	in P_telefonoReparacion varchar(45),
	in P_empleadoReparacion varchar(30),
	in P_repuestoReparacion varchar(30)
)
BEGIN
	declare dir varchar(255);
	declare ciudad varchar(255);
	declare tarjeta varchar(255);
	/* verificar que hace esto */
	select C.domicilioCliente, C.ciudadCliente, C.tarjetaPrimaria into dir, ciudad, tarjeta 
	from reparacion.cliente as C 
	where C.dniCliente = P_dnicliente;
	

	start transaction;
		insert into reparacion.reparacion (`codSucursal`,`dniCliente`,`fechaInicioReparacion`, `cantDiasReparacion`,
		 `telefonoReparacionCliente`, `direccionReparacionCliente`, `ciudadReparacionCliente`, `tarjetaReparacion`) 
		values (P_codSucursal, P_dnicliente, P_fechaReparacion, P_cantDiasReparacion,
		P_telefonoReparacion, dir, ciudad, tarjeta);

		insert into reparacion.repuestoreparacion (`dniCliente`, `fechaInicioReparacion`, `repuestoReparacion`)
		values (P_dniCliente, P_fechaReparacion, P_repuestoReparacion);

		insert into reparacion.revisionreparacion (`dniCliente`, `fechaInicioReparacion`, `empleadoReparacion`) 
		values (P_dniCliente, P_fechaReparacion, P_empleadoReparacion);
	commit; 
END $$
Delimiter ;
/*
	Se tuvo en cuenta: 
		->Deberia tener tarjeta con la que el usuario paga(tarjetareparacion). Deberia recibirse como parametro.
		Nosotros hacemos una consulta y ponemos la tarjeta primaria.
		->La direccion y ciudad de reparacion son la direccion y ciudad actual del cliente.
		->Cuando se quieren agregar 2 repuestos para la misma reparacion, habria que hacer dos llamados similares a : 
	call revision_repuesto(1009443,100, '2013-12-14 12:20:31' , 4 ,4243-4255, 'Maidana','bomba de combustible')
	call revision_repuesto(1009443,100, '2013-12-14 12:20:31' , 4 ,4243-4255, 'Maidana','Repuesto2')
		Lo mismo ocurrirìa en el caso de que tenga varios usuarios que hayan hecho la revisión.

		Nosotros tomamos en cuenta que el inciso no hace referencia a nada de esto, por lo tanto
		si se llama nuevamente al SP, con los datos que son clave en reparacion (dniCliente y fechaInicioReparacion),
		genera un error de clave duplicada.
		
	-->Lo otro que se puede hacer, es como se utiliza el archivo de insersiones.sql provisto por la catedra<--

		
*/

-- ====================================================================================

/*
* 12) Ejecutar el stored procedure del punto 11 con los siguientes datos:
* dniCliente: 1009443
* codSucursal: 100
* fechaReparacion: 2013-12-14 12:20:31
* empleadoReparacion: ‘Maidana’
* repuestoReparacion: ‘bomba de combustible’
* cantDiasReparacion: 4
* telefonoReparacion: 4243-4255
*/

call revision_repuesto(1009443,100, '2013-12-14 12:20:31' , 4 ,'4243-4255', 'Maidana','bomba de combustible')

-- ====================================================================================

/*
* 13) Realizar las inserciones provistas en el archivo inserciones.sql.
* Realizamos la importaciòn del archivo al mysql (el botón en forma de carpeta)
* y luego ejecutamos la consulta completa (ctrl + shift + enter)

*/

-- ====================================================================================
/*
* 14) Validar mediante una consulta que la tabla REPARACIONESPORCLIENTE se este actualizando correctamente
*/

select 
    (cantR = cantidadReparaciones) as codigo
from
    reparacionesporcliente as r
        right join
    (select 
        i.dniCliente, count(*) as cantR
    from
        reparacion as i
    group by i.dniCliente) as s ON r.dniCliente = s.dniCliente
group by codigo

/*

se intento Verificar que las inserciones actualizaron correctamente la tabla reparacionesporcliente.
Se cuentan si la cantidad de reparaciones por cliente, en la tabla reparaciones, es la misma cantidad que 
en la tabla reparacionesporcliente.

Aqui el codigo puede tomar 3 valores: 
NULL -> en el caso de que el dniCliente no se encuentre en la tablareparacionesporcliente
0 -> en el caso que el  dniCliente se encuentre, pero la cantidad de reparaciones es distinta 
1 -> en el caso que el dniCliente se encuentre, y la cantidad de reparaciones es la misma. 

Aqui, agrupamos por codigo de error. Si los errores no aparecen, significa que no existen. 

Entonces la solucion correcta deberia dar solo una row con un valor de 1. 
Si se da que alguno de los valores es null o 0, la consulta no actualizaria correctamente ( o los datos son inconsistentes )

Como algo anexo, se podria ademas de agrupar, contar la cantidad de veces que aparece dicho codigo

*/

-- ====================================================================================


