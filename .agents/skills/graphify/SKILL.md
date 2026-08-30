---
name: graphify
description: Uso de graphify para consulta rápida del grafo de conocimiento del proyecto en lugar de inspeccionar archivo por archivo.
---

# Skill: Graphify Navigation

Usa `graphify` para consultar inmediatamente la arquitectura, relaciones, pantallas y servicios del proyecto sin realizar búsquedas exhaustivas archivo por archivo.

## Instrucciones de uso

1. **Consulta rápida**:
   - Cuando el usuario pregunte o reporte un fallo en una funcionalidad o flujo, primero consulta el grafo de conocimiento:
     `graphify query "<pantalla o servicio a investigar>"`
2. **Explicación de conceptos**:
   - `graphify explain "<nombre_del_modulo>"`
3. **Relaciones entre componentes**:
   - `graphify path "<ComponenteA>" "<ComponenteB>"`
4. **Actualización post-modificación**:
   - Al terminar de modificar archivos de código Dart en una sesión, ejecuta:
     `graphify update .`
