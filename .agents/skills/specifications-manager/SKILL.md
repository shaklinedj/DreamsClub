---
name: specifications-manager
description: Guía y flujo estructurado para registrar, actualizar y mantener al día las especificaciones técnicas del ecosistema DreamsClub.
---

# Specifications Manager Skill & Workflow

Esta skill describe la metodología y el estándar técnico para registrar, auditar y actualizar el documento de especificaciones `ESPECIFICACION_SISTEMA_DREAMSCLUB.md`.

## 1. Cuándo actualizar las especificaciones
- **Nuevas Características:** Al implementar una funcionalidad no listada previamente (ej. filtros de reacciones, subdominios específicos de casino).
- **Alineación de Modelos/IDs:** Al modificar la estructura de datos clave (ej. realineación de IDs en el enrutamiento de casinos).
- **QA Checklist:** Al agregar nuevos casos de prueba importantes para control de calidad.

## 2. Estructura del Documento de Especificaciones
El archivo `ESPECIFICACION_SISTEMA_DREAMSCLUB.md` se compone de:
1. **Visión General:** Arquitectura del ecosistema.
2. **Dreams Admin:** Módulos de gestión web.
3. **App Móvil:** Comportamiento, permisos e interfaces de la aplicación Flutter.
4. **Directorio y Enrutamiento:** IDs oficiales, coordenadas y subdominios de cada casino.
5. **Flujos Clave:** Diagramas Mermaid de secuencias técnicas críticas (GPS, Deep Linking, etc.).
6. **Matriz de QA:** Checklist interactivo para auditar el funcionamiento.

## 3. Protocolo de Registro de Cambios
Al realizar modificaciones en el ecosistema:
1. Realizar los cambios de código.
2. Identificar qué sección de la especificación se ve afectada.
3. Actualizar la sección correspondiente (ej. cambiar tablas de enrutamiento o diagramas de secuencia).
4. Agregar nuevos ítems al Checklist QA al final del documento.
5. Verificar la consistencia general del archivo.
