# Gestión de Empleados - Design Document
**Date:** February 23, 2026  
**Phase:** Phase 2 of Admin System Implementation

---

## Executive Summary

System for managing employees at the business level, where employees can optionally have login credentials to access the system. Employees are always assigned to a specific business and inherit its system (Repuesto/Prestamo/Inmuebles). Access control is based on assigned roles within that business.

---

## Architecture Overview

### Three-Tier Employee Access Model

```
ADMIN (Level 1)
└─ Creates Businesses (Negocio 1, Negocio 2, Negocio 3)
   ├─ Each Business has: sistema (Repuesto/Prestamo/Inmuebles)
   └─ Admin creates EMPLOYEES for each business

EMPLOYEES (Level 2) - Optional System Users
├─ Empleado "Juan" (WITH login credential)
│  ├─ Assigned to: Negocio 1 (sistema: Repuesto)
│  ├─ Roles: Almacenero, Supervisor
│  ├─ Login: juan_garcia / password
│  └─ Access: ONLY modules for Repuesto system in Negocio 1
│
└─ Empleada "María" (NO login credential)
   ├─ Assigned to: Negocio 1
   ├─ Roles: Vendedor
   └─ Access: ❌ None (no system user = record-only, visible to admin)
```

---

## Database Schema

### 1. Employees Table
```sql
CREATE TABLE empleados (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL REFERENCES negocios(id) ON DELETE CASCADE,
  nombre VARCHAR(255) NOT NULL,
  numero_documento VARCHAR(50) UNIQUE,
  email VARCHAR(255),
  telefono VARCHAR(20),
  cargo VARCHAR(100),
  estado BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

**Purpose:** Core employee data, always linked to a business.  
**Key Points:**
- One employee per business (unique documento)
- No login info here - credentials optional via one-to-one link

### 2. Employee-User Link (Optional)
```sql
CREATE TABLE empleado_usuarios (
  empleado_id BIGINT NOT NULL UNIQUE REFERENCES empleados(id) ON DELETE CASCADE,
  usuario_id BIGINT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (empleado_id, usuario_id)
);
```

**Purpose:** Link employee with system user (for login).  
**Key Points:**
- Optional: employee can exist without this link
- One-to-one: one employee = max one system user
- If link exists: employee can login to access modules for their business

### 3. Roles Table (Per Business)
```sql
CREATE TABLE roles (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL REFERENCES negocios(id) ON DELETE CASCADE,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  estado BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);
```

**Purpose:** Define roles within a business (Almacenero, Vendedor, Supervisor, etc).  
**Key Points:**
- Scoped per business (each business defines its own roles)
- Pre-populated with defaults or admin-created

### 4. Role-Modules Mapping
```sql
CREATE TABLE role_modulos (
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  modulo_id BIGINT NOT NULL REFERENCES system_modules(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, modulo_id)
);
```

**Purpose:** Define which modules a role can access.  
**Key Points:**
- Modules filtered by business's sistema (system)
- Example: "Almacenero" role in "Repuesto" business → access Inventory, Stock Lookup modules only

### 5. Employee-Roles Mapping
```sql
CREATE TABLE empleado_roles (
  empleado_id BIGINT NOT NULL REFERENCES empleados(id) ON DELETE CASCADE,
  role_id BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  PRIMARY KEY (empleado_id, role_id)
);
```

**Purpose:** Assign roles to employees.  
**Key Points:**
- One employee can have multiple roles
- All roles must belong to same business as employee
- Modules seen = UNION of all roles' modules

---

## Data Flow

### Creating an Employee

1. **Admin opens "Gestión de Empleados"**
2. **Selects a Business** (or already viewing context)
3. **Clicks "+ Nuevo Empleado"**
4. **Form:**
   - Nombre, Documento, Email, Teléfono
   - Cargo (free text)
   - Assign Roles (checkboxes for business's roles)
   - "Crear usuario del sistema?" (toggle)
     - If YES → Generate credentials, create entry in `empleado_usuarios`
     - If NO → Employee record only, visible in admin's employee list

### Employee Login (if system user exists)

1. **Employee enters credentials** (username/password)
2. **System validates** against `users` table
3. **Looks up** `empleado_usuarios` to find associated employee
4. **Fetches:**
   - `empleado.negocio_id` → Business context
   - `negocios.sistema` → System type (Repuesto/Prestamo/Inmuebles)
   - `empleado_roles` → Assigned roles
   - `role_modulos` → Accessible modules (filtered by business.sistema)
5. **Employee dashboard loads** with ONLY those modules
6. **All data queries** scoped to `negocio_id`

---

## UI/UX Workflow

### Admin Dashboard - Employees Section

**Layout:**
- Tab in dashboard alongside "Negocios"
- Table view: Nombre | Documento | Cargo | Estado | Acciones
- "+ Nuevo Empleado" button at top

**Actions per row:**
- Edit: Update basic info & roles
- Manage User: Create/update/remove login credentials
- Deactivate/Activate: Toggle estado
- View Details: Roles, contact info, assignment

**Create Employee Dialog (3-step):**
1. **Info:** Name, Document, Email, Phone, Cargo
2. **Roles:** Assign roles for the business
3. **User:** "Create system login?" → Generate credentials if yes

---

## Access Control Logic

### On Employee Login
```dart
1. Validate credentials in users table
2. Query empleado_usuarios to get empleado_id
3. Fetch empleado → get negocio_id
4. Fetch negocios → get sistema
5. Fetch empleado_roles → get role_ids
6. Fetch role_modulos → get allowed module_ids
7. Filter modules by sistema (additional layer)
8. Set user context: {empleado_id, negocio_id, sistema, modulos}
```

### Data Queries
All queries include implicit scoping:
```sql
WHERE negocio_id = $1  -- employee's assigned business
```

### Module Visibility
Dashboard shows modules IF:
- Module.sistema == negocio.sistema, AND
- Module.id IN (employee's role_modulos)

---

## Success Criteria

- ✅ Employees created and assigned to businesses
- ✅ Employees without login visible in admin's list
- ✅ Employees with login can authenticate
- ✅ Employee sees ONLY modules for their business's system
- ✅ Role management controls module access
- ✅ Data isolation: employees can only access their business's data

---

## Dependencies

- `usuarios` table (for optional login credentials)
- `negocios` table (for business assignment & sistema)
- `system_modules` table (assumed to exist, defines available modules)

---

## Future Considerations

- Audit logging: track employee actions
- Bulk employee import: CSV upload
- Permission inheritance: department-level roles
- Two-factor authentication for employee logins
