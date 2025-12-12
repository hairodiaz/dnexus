# D-Nexus Supabase Integration Guide

## Overview
D-Nexus now uses a hybrid architecture that leverages Supabase for cloud data storage while maintaining backward compatibility with native PostgreSQL connections for desktop/mobile platforms.

## Architecture

### Hybrid Approach
- **Web Platform**: Uses Supabase HTTP REST API via `SupabaseHttpClient`
- **Native Platforms** (Desktop/Mobile): Uses direct PostgreSQL connection with SSL
- **Platform Detection**: Automatic routing via `PlatformDetector` utility

### Key Components

#### 1. SupabaseHttpClient (`lib/shared/services/supabase_http_client.dart`)
HTTP bridge for web clients to interact with Supabase database.

**Configuration:**
- URL: `https://xmoqjehicmqkseejreng.supabase.co`
- Anon Key: `sb_publ1shabie_z1tR014T72qwqsCRF_8yg_rI13g1s`
- Database: PostgreSQL (Supabase managed)

**Available Methods:**
- Authentication: `login()`, `getUserByUsername()`, `getAllUsers()`
- Clients: `getClients()`, `createClient()`, `updateClient()`, `deleteClient()`, `searchClients()`, `getClientsByBusiness()`
- Products: `getProducts()`, `createProduct()`, `updateProduct()`, `deleteProduct()`, `searchProducts()`, `getProductsByBusiness()`
- Transactions: `getTransactions()`, `createTransaction()`, `getTransactionsByBusiness()`

#### 2. PlatformDetector (`lib/core/utils/platform_detector.dart`)
Detects runtime platform for automatic service routing.

**Methods:**
- `isWeb` - Running in browser
- `isNative` - Running on native platform
- `isMobile` - Android or iOS
- `isDesktop` - Windows, macOS, or Linux
- Individual platform checks: `isWindows`, `isMacOS`, `isLinux`, `isAndroid`, `isIOS`

#### 3. Updated Services (Hybrid Implementation)

##### AuthService (`lib/shared/services/auth_service_with_roles.dart`)
- **Web**: `_loginSupabase()` - HTTP authentication against Supabase users table
- **Native**: `_loginLocal()` - In-memory authentication with SuperAdmin only
- Automatic routing via `login()` method

##### ClientService (`lib/shared/services/client_service.dart`)
- **Async Methods** (Platform-aware):
  - `getAllClientsAsync()` - Get all active clients
  - `registerClientAsync()` - Create new client
  - `searchAsync()` - Search clients by name/ID
  - `getClientsByBusinessAsync()` - Get clients for specific business
  - `updateClientAsync()` - Update client data
  - `deactivateClientAsync()` - Soft delete client
- **Sync Methods** (Backward compatible):
  - `getAllClients()`, `registerClient()`, `search()`, `getClientsByBusiness()`, etc.

##### InventoryService (`lib/shared/services/inventory_service.dart`)
- **Async Methods** (Platform-aware):
  - `getProductsAsync()` - Fetch all products
  - `searchProductsAsync()` - Search products by name/code
  - `createProductAsync()` - Create new product
- **Sync Methods** (Backward compatible):
  - `getProducts()`, `searchProducts()`, `createProduct()`, etc.

##### TransactionService (`lib/shared/services/transaction_service.dart`)
- **Async Methods** (Platform-aware):
  - `getTransactionsByBusinessAsync()` - Fetch transactions for business
  - `createTransactionAsync()` - Create new transaction
- **Sync Methods** (Backward compatible):
  - `getTransactionsByBusiness()`, `createTransaction()`, etc.

## Database Schema

### Tables Created in Supabase

```sql
-- Users Table
users (
  id BIGSERIAL PRIMARY KEY,
  username VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255),
  email VARCHAR(255),
  nombre_completo VARCHAR(255),
  rol VARCHAR(50),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)

-- Business Table
negocios (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  tipo VARCHAR(100),
  descripcion TEXT,
  propietario_id BIGINT REFERENCES users(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)

-- Clients Table
clientes (
  id BIGSERIAL PRIMARY KEY,
  cedula VARCHAR(50) UNIQUE NOT NULL,
  nombre_completo VARCHAR(255) NOT NULL,
  email VARCHAR(255),
  telefono VARCHAR(20),
  direccion TEXT,
  negocio_id BIGINT REFERENCES negocios(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)

-- Products Table
productos (
  id BIGSERIAL PRIMARY KEY,
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  codigo VARCHAR(100) UNIQUE NOT NULL,
  precio DECIMAL(10, 2),
  stock INTEGER DEFAULT 0,
  negocio_id BIGINT REFERENCES negocios(id),
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)

-- Transactions Table
transacciones (
  id BIGSERIAL PRIMARY KEY,
  tipo VARCHAR(50),
  monto DECIMAL(15, 2),
  concepto VARCHAR(255),
  categoria VARCHAR(100),
  metodo_pago VARCHAR(50),
  cliente_id BIGINT REFERENCES clientes(id),
  negocio_id BIGINT REFERENCES negocios(id),
  fecha TIMESTAMP,
  observaciones TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
)
```

### Row Level Security (RLS)
All tables have RLS enabled with public read/write policies for development:
```sql
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE negocios ENABLE ROW LEVEL SECURITY;
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE transacciones ENABLE ROW LEVEL SECURITY;

-- Public policies for development (TO BE RESTRICTED IN PRODUCTION)
CREATE POLICY "Enable public read" ON users FOR SELECT USING (true);
CREATE POLICY "Enable public write" ON users FOR INSERT WITH CHECK (true);
-- ... similar for other tables
```

### Indexes Created
- `username` (users table) - For faster authentication lookups
- `negocio_id` (clients, products, transactions tables) - For business filtering
- `cliente_id` (transactions table) - For client transaction queries

## Default Users

### SuperAdmin
- **Username**: `SuperAdmin`
- **Password**: `123456`
- **Role**: `superadmin`
- **Status**: Active

*Note: Update password and implement proper authentication in production*

## Testing the Integration

### 1. Test Authentication (Web)
```bash
flutter run -d chrome
```
- Click Login
- Username: `SuperAdmin`
- Password: `123456`
- Expected: Successful login, dashboard displays
- Check: Browser DevTools > Network tab should show POST to `/rest/v1/users`

### 2. Test Client Operations (Web)
- Navigate to Clients page
- Click "Add Client"
- Fill client details (cedula, name, phone, email)
- Click Save
- Expected: Client is created in Supabase
- Refresh page: Client should still appear (data persistence test)

### 3. Test Inventory Operations (Web)
- Navigate to Inventory page
- Click "Add Product"
- Fill product details (code, name, price, stock)
- Click Save
- Expected: Product created in Supabase
- Refresh page: Product should still appear

### 4. Test Transaction Recording (Web)
- Any transaction created should be saved to Supabase
- Refresh page: Transactions should persist

## Migration Guide for Developers

### Adding New Async Methods to Services

1. **Add to SupabaseHttpClient** if it's a database operation
   ```dart
   Future<List<MyModel>> getMyData() async {
     try {
       final response = await http.get(
         Uri.parse('$supabaseUrl/rest/v1/my_table?select=*'),
         headers: _headers,
       );
       if (response.statusCode == 200) {
         final List<dynamic> data = jsonDecode(response.body);
         return List<Map<String, dynamic>>.from(data);
       }
       return [];
     } catch (e) {
       AppConfig.logger.e('Error: $e');
       return [];
     }
   }
   ```

2. **Add async wrapper in service**
   ```dart
   Future<List<MyModel>> getMyDataAsync() async {
     if (PlatformDetector.isWeb) {
       try {
         final SupabaseHttpClient supabase = SupabaseHttpClient();
         final data = await supabase.getMyData();
         return data.map((json) => MyModel.fromJson(json)).toList();
       } catch (e) {
         return [];
       }
     }
     
     // Fallback for native
     return getMyData(); // Existing sync method
   }
   ```

3. **Update UI/Widgets to use async methods**
   ```dart
   Future<void> loadData() async {
     final service = MyService();
     final data = await service.getMyDataAsync();
     setState(() => this.data = data);
   }
   ```

## Environment Configuration

### Current Setup
Credentials are currently hardcoded in `SupabaseHttpClient`. For production:

1. Create `.env` file in project root
   ```
   SUPABASE_URL=https://xmoqjehicmqkseejreng.supabase.co
   SUPABASE_ANON_KEY=sb_publ1shabie_z1tR014T72qwqsCRF_8yg_rI13g1s
   DATABASE_PASSWORD=Hernandez14
   ```

2. Update `SupabaseHttpClient` to use environment variables
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   static final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
   static final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
   ```

3. Add to `pubspec.yaml`
   ```yaml
   dependencies:
     flutter_dotenv: ^5.1.0
   ```

## Security Considerations

### For Production

1. **Implement Proper RLS Policies**
   - Restrict users to their own data
   - Allow businesses to see their clients/products/transactions only
   - Implement role-based access control

2. **Change Default Credentials**
   - Update SuperAdmin password
   - Create proper admin user account

3. **Use Service Role Key** for backend operations (never expose in app)

4. **Enable Strong Authentication**
   - Consider OAuth (Google, Microsoft)
   - Implement JWT token refresh
   - Add rate limiting to API

5. **Database Encryption**
   - Enable SSL for all connections
   - Use Supabase encryption at rest

6. **API Key Rotation**
   - Regularly rotate anonymous keys
   - Monitor API usage

## Troubleshooting

### Issue: "Unauthorized" error when calling Supabase
- Check Anon Key is correct
- Verify RLS policies allow public access
- Check network tab in DevTools for actual error

### Issue: Data not persisting after refresh
- Verify data was actually inserted (check Supabase dashboard)
- Check browser localStorage isn't overriding data
- Verify async method is being called, not sync fallback

### Issue: Service routing to wrong platform
- Check `PlatformDetector.isWeb` returns correct value
- Add debug logs: `print('Is Web: ${PlatformDetector.isWeb}')`
- Verify imports are correct in all files

### Issue: JSON mapping errors
- Ensure field names match Supabase schema (snake_case)
- Add null safety checks in fromJson methods
- Log full response before parsing

## Future Enhancements

1. **Implement Pagination** for large datasets
2. **Add Offline Support** using local SQLite cache
3. **Real-time Subscriptions** using Supabase subscriptions
4. **Better Error Handling** with retry logic
5. **API Caching** to reduce network calls
6. **Encryption** for sensitive data at rest

## Files Modified/Created

### Created
- `lib/shared/services/supabase_http_client.dart` - HTTP client for Supabase
- `lib/core/utils/platform_detector.dart` - Platform detection utility
- `supabase_schema.sql` - Database schema script
- `SUPABASE-INTEGRATION.md` - This guide

### Modified
- `lib/shared/services/auth_service_with_roles.dart` - Added Supabase authentication
- `lib/shared/services/client_service.dart` - Added async methods with Supabase support
- `lib/shared/services/inventory_service.dart` - Added async methods with Supabase support
- `lib/shared/services/transaction_service.dart` - Added async methods with Supabase support
- `lib/shared/models/user_model.dart` - Added password field and fromJson factory
- `lib/core/config/app_config.dart` - Updated Supabase credentials
- `lib/core/database/database_connection.dart` - Enabled SSL for Supabase
- `pubspec.yaml` - Added http package dependency

## Support & Documentation

- [Supabase Official Docs](https://supabase.com/docs)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [REST API Reference](https://supabase.com/docs/guides/api)
- [Authentication with JWT](https://supabase.com/docs/guides/auth)

---

**Last Updated**: 2024
**Status**: Complete for MVP, Production hardening needed
