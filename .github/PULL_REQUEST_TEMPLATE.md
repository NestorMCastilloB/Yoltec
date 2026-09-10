<!--
Título del PR con el mismo formato que los commits: tipo(ámbito): descripción corta
Ejemplos: feat(citas): agrega validación de horario · fix(auth): corrige 2FA al reenviar
-->

## Qué se hizo

<!-- Resumen breve de la funcionalidad o corrección. -->

## Qué se cambió

<!-- Lista concreta de archivos, módulos o comportamientos. -->

-
-

## Por qué se cambió

<!--
El contexto del problema. Es la parte que más se agradece dentro de seis meses,
cuando el diff siga estando pero el motivo ya no. Enlaza el issue si existe.
-->

## Cómo se probó

- [ ] Pruebas automatizadas (`./local.sh test`)
- [ ] Pruebas manuales en el entorno local (`./local.sh up`)
- [ ] Verificado contra los servicios desplegados

<!-- Di qué probaste exactamente, no solo que lo probaste. -->

## Impacto y riesgos

<!--
¿Toca migraciones, variables de entorno, o exige pasos manuales al desplegar?
¿Rompe compatibilidad? ¿Qué se rompería si esto sale mal?
Si no hay riesgo, escribe "ninguno" — pero piénsalo antes.
-->

## Evidencia

<!-- Capturas, logs o salidas relevantes. Borra la sección si no aplica. -->

---

## Checklist

- [ ] El título y los commits siguen la nomenclatura de [`CONTRIBUTING.md`](../CONTRIBUTING.md)
- [ ] El PR toca una sola unidad de trabajo
- [ ] No hay credenciales, tokens ni datos personales en el código ni en el historial
- [ ] Se añadieron o actualizaron pruebas si el cambio lo permite
- [ ] La build pasa sin errores ni advertencias nuevas
- [ ] La documentación afectada se actualizó (`README.md`, `docs/`)
- [ ] Leí el diff completo en GitHub antes de fusionar
