# Gestión de Negocios - Design Document

**Date:** February 22, 2026  
**Feature:** Business Management (Gestión de Negocios)  
**Status:** Approved for Implementation  
**Author:** GitHub Copilot

---

## Executive Summary

Implementation of business management system allowing admins to create and manage multiple businesses with rich contact information, addresses, and soft-delete capabilities. Admins create businesses independently; system automatically assigns them as owners.

---

## Requirements

### Functional
- Admin can **create** multiple businesses independently
- Admin gets auto-assigned as **propietario** in `admin_negocio` table
- Each business has **multiple contact methods** (phone/email) with primary designation
- Each business has **multiple addresses** (main, branches, etc) with city/department info
- Admin can **view** list of owned businesses via dropdown selector
- Admin can **edit** business info and contacts/addresses
- Admin can **soft delete** (deactivate) businesses
- Only **creator admin** can manage each business (initial scope)

### Data Structure
- `negocios`: Core business info
- `negocio_contactos`: Phone/email entries
- `negocio_direcciones`: Physical addresses
- `admin_negocio`: Admin-business relationship (future collaboration)

### UI/UX
- **Selector:** Dropdown in admin section to choose active business context
- **CRUD Forms:** Modal dialogs for create/edit with tabs (info/contacts/addresses)
- **List View:** DataTable showing business details with action buttons
- **Display:** Expandible sections for contacts and addresses

### Validation Rules
- Business name: Required, 3-255 chars, unique per admin
- NIT: Optional, unique across all businesses
- Contacts: Minimum 1 (phone OR email required)
- Addresses: Minimum 1 primary address required
- Primary constraints: Only one primary contact/address per type
- Soft delete: Set `estado=false`, never actually delete

---

## Database Schema

```sql
CREATE TABLE negocios (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  nit VARCHAR(20),
  fecha_registro DATE,
  estado BOOLEAN DEFAULT true,
  created_by BIGINT NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE negocio_contactos (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL REFERENCES negocios(id) ON DELETE CASCADE,
  tipo VARCHAR(20) NOT NULL, -- 'telefono' | 'email'
  valor VARCHAR(255) NOT NULL,
  principal BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE negocio_direcciones (
  id BIGSERIAL PRIMARY KEY,
  negocio_id BIGINT NOT NULL REFERENCES negocios(id) ON DELETE CASCADE,
  tipo VARCHAR(50) NOT NULL, -- 'principal' | 'sucursal' | 'otro'
  calle VARCHAR(255) NOT NULL,
  ciudad VARCHAR(100),
  departamento VARCHAR(100),
  codigo_postal VARCHAR(20),
  principal BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE admin_negocio (
  admin_id BIGINT NOT NULL REFERENCES users(id),
  negocio_id BIGINT NOT NULL REFERENCES negocios(id) ON DELETE CASCADE,
  rol VARCHAR(50) NOT NULL DEFAULT 'propietario',
  asignado_en TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (admin_id, negocio_id)
);
```

---

## Data Models (Dart)

```dart
class BusinessModel {
  final int id;
  final String nombre;
  final String? nit;
  final DateTime? fechaRegistro;
  final bool estado;
  final int createdBy;
  final DateTime createdAt;
  
  List<ContactModel> contactos;
  List<AddressModel> direcciones;
  
  // Computed properties
  String get telefonoPrincipal => ...
  String get emailPrincipal => ...
  AddressModel? get direccionPrincipal => ...
}

class ContactModel {
  final int id;
  final int negocioId;
  final String tipo; // 'telefono' | 'email'
  final String valor;
  final bool principal;
}

class AddressModel {
  final int id;
  final int negocioId;
  final String tipo; // 'principal' | 'sucursal' | 'otro'
  final String calle;
  final String? ciudad;
  final String? departamento;
  final String? codigoPostal;
  final bool principal;
}
```

---

## UI Components

### Admin Dashboard - Businesses Section

**Components:**
1. **Business Selector**: Dropdown showing admin's businesses
2. **Create Button**: FAB or button to open create dialog
3. **Business Row**: Expandable row showing primary contact + address
4. **Action Buttons**: Edit, View Details, Toggle (activate/deactivate)
5. **Forms**: Modal dialogs with tabs for creating/editing

**Dialogs:**
- **Create/Edit Business**: 3 tabs - Info, Contacts, Addresses
- **Contact Manager**: Add/remove/set primary phone and email
- **Address Manager**: Add/remove/set primary addresses

---

## User Workflow

```
Admin Dashboard → Click "Negocios" menu
    ↓
[No businesses] → "+ Create Business" dialog
    ↓
Fill form (name, nit, date)
Add contacts (phone/email)
Add addresses (street, city, dept)
    ↓
Save → Creates negocios + negocio_contactos + negocio_direcciones + admin_negocio
    ↓
Dropdown shows "Mi Negocio" → Selected
    ↓
Table displays business with actions: ✏️ 📞 📍 ⏸️
    ↓
Click ✏️ Edit → Pre-populated form
Click 📞 Contacts → Expandible list
Click 📍 Addresses → Expandible list
Click ⏸️ Toggle → Soft delete/restore
```

---

## Implementation Tasks

1. ✅ Design Document (THIS FILE)
2. Create SQL migration file
3. Create Dart models: BusinessModel, ContactModel, AddressModel
4. Create business repository/service for Supabase calls
5. Implement `_buildBusinessesSection()` in AdminDashboardPage
6. Implement create/edit dialogs with validation
7. Implement contact and address managers
8. Test CRUD operations end-to-end
9. Commit and push to DEV branch

---

## Success Criteria

- ✅ Admin can create business with name, nit, date
- ✅ Admin can add multiple phones/emails (marked as primary)
- ✅ Admin can add multiple addresses with city/dept
- ✅ Business list shows in dropdown
- ✅ Admin can edit all business fields
- ✅ Admin can toggle business activation
- ✅ Soft delete works (no data loss)
- ✅ Only creator/owner can manage each business
- ✅ UI is intuitive and responsive
- ✅ All validations enforce data integrity
- ✅ No compilation errors

---

## Future Extensions (NOT in scope)

- Collaboration: Multiple admins per business
- Departments: Sub-divisions within business
- Audit: Track all business changes
- Business transfer: Change owner
- Bulk operations: Import/export businesses

