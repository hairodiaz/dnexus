# D-Nexus

Sistema integral de gestión empresarial desarrollado en Flutter con PostgreSQL.

## 🚀 Características Principales

- **Dashboard Interactivo**: Vista general de métricas empresariales
- **Gestión de Transacciones**: CRUD completo con auditoria de cambios
- **Sistema de Auditoría**: Historial completo de ediciones y eliminaciones
- **Filtros Inteligentes**: Filtrado por periodo, tipo y método de pago
- **Arquitectura Limpia**: Implementación de Clean Architecture
- **Responsive Design**: Optimizado para PC y dispositivos móviles

## 🛠️ Tecnologías

- **Frontend**: Flutter 3.x
- **Base de Datos**: PostgreSQL 16
- **Arquitectura**: Clean Architecture
- **Estado**: Provider pattern

## 📱 Módulos Disponibles

### Dashboard
- Métricas de transacciones
- Gráficos de rendimiento
- Resumen de actividad

### Transacciones
- Crear, editar y eliminar transacciones
- Historial de auditoría completo
- Filtros por período (Hoy, Esta semana, Este mes, Últimos 30 días)
- Filtros por tipo y método de pago
- Restauración de transacciones eliminadas

### Contabilidad
- Gestión de cuentas contables
- Reportes financieros
- Balance general

### Negocios
- Gestión de clientes y proveedores
- Inventarios
- Productos y servicios

## 🔧 Instalación y Configuración

### Prerequisitos
- Flutter SDK 3.x
- PostgreSQL 16
- Dart SDK

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/hairodiaz/dnexus.git
cd dnexus
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar base de datos**
```bash
# Crear base de datos PostgreSQL
createdb dnexus_db

# Ejecutar migraciones (próximamente)
```

4. **Ejecutar la aplicación**
```bash
flutter run -d web
```

## 📊 Estructura del Proyecto

```
lib/
├── core/                 # Configuración y utilidades core
├── features/            # Módulos por características
│   ├── dashboard/       # Dashboard principal
│   ├── transacciones/   # Gestión de transacciones
│   ├── contabilidad/    # Módulo contable
│   ├── negocios/       # Gestión de negocios
│   └── auth/           # Autenticación
└── shared/             # Componentes compartidos
    ├── models/         # Modelos de datos
    ├── services/       # Servicios
    ├── widgets/        # Widgets reutilizables
    └── enums/          # Enumeraciones
```

## 🌐 Despliegue Web

El proyecto está configurado para despliegue web en plataformas como:
- Vercel
- Netlify
- Firebase Hosting

### Build para Web
```bash
flutter build web
```

## 📈 Próximas Características

- [ ] Autenticación completa
- [ ] Reportes avanzados
- [ ] Integración con APIs externas
- [ ] Modo offline
- [ ] Notificaciones push
- [ ] Exportación de datos

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama de feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit cambios (`git commit -am 'Agregar nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Crear Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## 👨‍💻 Desarrollado por

**Hairo Diaz**
- GitHub: [@hairodiaz](https://github.com/hairodiaz)

---

*D-Nexus - Conectando tu empresa al futuro digital* 🚀
