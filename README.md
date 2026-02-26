# 📱 ServiHogar - App Móvil

ServiHogar es una aplicación móvil desarrollada en **SwiftUI** que conecta a clientes con profesionales del hogar (fontaneros, electricistas, carpinteros, etc.).

## 🚀 Características
- **Registro Dual**: Perfiles diferenciados para Clientes y Profesionales.
- **Gestión de Solicitudes**: Los clientes pueden solicitar servicios con descripción, ubicación y fotos.
- **Flujo de Trabajo**: Los profesionales pueden aceptar trabajos, llamando directamente al cliente o marcando tareas como completadas.
- **Perfil Personalizado**: Cambio de foto, datos personales, contraseña y gestión de oficios.

## 🛠️ Tecnologías
- **Lenguaje**: Swift 5.x
- **Framework**: SwiftUI
- **Arquitectura**: Basada en estados (`@State`, `@Binding`) y comunicación mediante URLSession con API REST.

## ⚙️ Configuración
1. Abrir `ServiHogar.xcodeproj` en Xcode.
2. Asegurarse de que el simulador o dispositivo tenga acceso a la red donde corre la API.
3. **Importante**: Cambiar las URLs de `127.0.0.1:8000` por la IP local de tu Mac si pruebas en un iPhone físico.

---
