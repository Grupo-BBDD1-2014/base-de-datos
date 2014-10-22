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