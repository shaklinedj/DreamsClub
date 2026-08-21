---
name: flutter-expert
description: Estándares de excelencia, buenas prácticas modernas y verificación exhaustiva de código Flutter y Dart sin errores.
---

# Flutter Expert Skill & Workflow

Esta skill define el protocolo de desarrollo experto en Flutter:

## 1. Verificación Automática
- Tras cualquier cambio de código en Flutter/Dart, ejecutar `dart analyze lib` para asegurar **0 errores** y **0 advertencias críticas**.
- Respetar de forma estricta los diagnósticos provistos por el analizador del IDE y corregir cualquier discrepancia en firmas de métodos o tipos.

## 2. Buenas Prácticas Modernas (Flutter 3.x / Dart 3.x)
- Manejo seguro de nulos (`sound null-safety`).
- Prevención de colisiones de importación mediante alias explícitos.
- Arquitectura reactiva con Riverpod / StateNotifier.
- Sincronización transparente con Firebase Firestore mediante subcolecciones y Collection Group Queries.
