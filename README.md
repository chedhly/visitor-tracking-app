# Vehicle Entry System - Tunisian License Plate Recognition

A Flutter-based vehicle entry/exit management system with automatic license plate recognition for Tunisian vehicles using Google ML Kit. The system tracks vehicle entry and exit times, monitors overstay alerts, and manages access control with admin and personnel roles.

## Features

### Core Functionality
- **Automatic License Plate Recognition (LPR)**: Uses Google ML Kit Text Recognition to detect Tunisian license plates (Arabic format: numbers + "تونس" + numbers)
- **Vehicle Entry Tracking**: Automatically records entry time when vehicle enters
- **Vehicle Exit Tracking**: Records exit time and calculates total duration
- **Barrier Control**: Simulates barrier opening after successful plate recognition
- **Overstay Alerts**: Alerts guard when vehicles exceed admin-defined time threshold
- **Real-time Monitoring**: Dashboard showing current vehicles and their status
- **User Authentication**: Login system with admin and personnel clearance levels

### User Roles
- **Admin**: Full access including settings configuration (overstay threshold)
- **Personnel**: Can record entries/exits and monitor vehicles

## Prerequisites

Before running the app, you need:

1. **Supabase Account** (Free tier available)
   - Sign up at https://supabase.com
   - Create a new project

2. **Flutter SDK** (Already installed in Replit environment)

3. **Camera Access** (For mobile/desktop testing)

## Step-by-Step Setup Guide

### Step 1: Set Up Supabase Database

1. **Create a Supabase Project**
   - Go to https://supabase.com/dashboard
   - Click "New Project"
   - Choose organization and enter project name
   - Set a strong database password
   - Select nearest region
   - Wait for project to be ready (~2 minutes)

2. **Get Your Supabase Credentials**
   - Go to Project Settings > API
   - Copy the **Project URL** (starts with https://...)
   - Copy the **anon/public key** (long string starting with eyJ...)

3. **Set Up Database Tables**
   - Go to SQL Editor in your Supabase dashboard
   - Copy and paste the entire content from `database_schema.sql` file
   - Click "Run" to create all tables and default data

### Step 2: Configure Environment Variables in Replit

1. In Replit, go to the **Secrets** tab (Tools > Secrets)
2. Add the following secrets:
   - **Key**: `SUPABASE_URL`
     **Value**: Your Supabase Project URL
   - **Key**: `SUPABASE_ANON_KEY`
     **Value**: Your Supabase anon/public key

### Step 3: Run the Application

The app is already configured to run automatically in Replit!

1. **Web Version** (Recommended for Replit):
   - Click the **Run** button at the top
   - The Flutter web app will start on port 5000
   - A webview will open showing the app

2. **Command Line** (Alternative):
   ```bash
   flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0
   ```

### Step 4: Login to the System

Default admin credentials (change password after first login):
- **Email**: `admin@company.com`
- **Password**: `admin123`

### Step 5: Using the System

#### For Vehicle Entry:
1. Click "Record Vehicle Entry" on the home screen
2. Point camera at the vehicle's license plate
3. Click "Capture & Recognize Plate"
4. System will:
   - Detect Tunisian license plate (format: numbers + تونس + numbers)
   - Record entry time in database
   - Show "Barrier Opening" message
   - Return to home screen

#### For Vehicle Exit:
1. Click "Record Vehicle Exit"
2. Point camera at the vehicle's license plate
3. Click "Capture & Recognize Plate"
4. System will:
   - Recognize the plate
   - Update exit time
   - Calculate total duration
   - Show "Barrier Opening" message

#### Monitor Vehicles:
1. Click "Monitor Vehicles"
2. View all vehicles currently inside
3. See overstay alerts (vehicles exceeding threshold)
4. Check entry time and duration for each vehicle

#### Admin Settings (Admin only):
1. Click settings icon in app bar
2. Adjust overstay threshold (1-24 hours)
3. Click "Save Settings"

## Database Schema

### Tables

1. **personnel** - User authentication and access control
   - `id` (UUID): Primary key
   - `email` (TEXT): Login email
   - `password_hash` (TEXT): Hashed password
   - `name` (TEXT): Full name
   - `clearance_level` (TEXT): 'admin' or 'personnel'

2. **visitors** - Vehicle entry/exit records
   - `id` (UUID): Primary key
   - `plate_number` (TEXT): License plate number
   - `entry_time` (TIMESTAMP): When vehicle entered
   - `exit_time` (TIMESTAMP): When vehicle exited (nullable)
   - `duration_minutes` (INTEGER): Total time inside

3. **settings** - System configuration
   - `id` (UUID): Primary key
   - `overstay_threshold_hours` (INTEGER): Alert threshold
   - `updated_by` (UUID): Personnel who updated settings

## Tunisian License Plate Format

The system recognizes Tunisian license plates in the format:
- **Pattern**: `[1-3 digits] + "تونس" + [1-4 digits]`
- **Example**: `123تونس4567`
- **Character Set**: Arabic numerals and "تونس" (Tunisia in Arabic)

## Technology Stack

- **Frontend**: Flutter Web
- **Database**: Supabase (PostgreSQL)
- **License Plate Recognition**: Google ML Kit Text Recognition
- **Authentication**: Custom authentication with Supabase
- **State Management**: Provider pattern

## Features in Detail

### Automatic Barrier Control
- Opens automatically after successful plate recognition
- 2-second delay simulation
- Visual confirmation message

### Overstay Alert System
- Admin configurable threshold (1-24 hours)
- Real-time monitoring
- Visual alerts on monitoring screen
- Red highlighting for overstay vehicles

### Statistics Dashboard
- Today's total vehicles
- Vehicles currently inside
- Overstay count
- Average duration

## Troubleshooting

### Issue: Camera not working
**Solution**: 
- For web: Grant camera permissions in browser
- For mobile: Check app permissions in device settings

### Issue: License plate not recognized
**Solutions**:
- Ensure good lighting conditions
- Hold camera steady
- Make sure plate is clearly visible
- Verify plate follows Tunisian format (numbers + تونس + numbers)

### Issue: "Missing Supabase credentials" error
**Solution**: 
- Verify SUPABASE_URL and SUPABASE_ANON_KEY are set in Replit Secrets
- Restart the app after adding secrets

### Issue: Database connection failed
**Solutions**:
- Check Supabase project is active
- Verify credentials are correct
- Ensure database tables are created (run database_schema.sql)

### Issue: Login not working
**Solutions**:
- Use default credentials: admin@company.com / admin123
- Check personnel table has data
- Verify Supabase connection is working

## Development

### Project Structure
```
lib/
├── main.dart                      # App entry point
├── models/                        # Data models
│   ├── visitor.dart
│   ├── personnel.dart
│   └── app_settings.dart
├── screens/                       # UI screens
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── entry_camera_screen.dart
│   ├── exit_camera_screen.dart
│   ├── monitoring_screen.dart
│   └── admin_settings_screen.dart
└── services/                      # Business logic
    ├── auth_service.dart
    ├── visitor_service.dart
    └── settings_service.dart
```

### Running in Development Mode
```bash
# Install dependencies
flutter pub get

# Run on web
flutter run -d web-server --web-port=5000 --web-hostname=0.0.0.0

# Run on Chrome (requires Chrome installed)
flutter run -d chrome

# Build for production web
flutter build web
```

### Adding New Personnel
Use Supabase dashboard to add new personnel:
```sql
INSERT INTO personnel (email, password_hash, name, clearance_level) 
VALUES (
    'guard@company.com',
    '$2a$10$8K1p/a0dL3LK4Y5JZJxY7.WzFZH8mZxl3H9aJ9mZmZmZmZmZmZmZm',
    'Security Guard',
    'personnel'
);
```

## Security Notes

- Change default admin password immediately after first login
- Store Supabase credentials securely in environment variables
- Never commit credentials to version control
- Use strong passwords for all accounts
- Enable Row Level Security (RLS) in Supabase for production

## License

This project is private and for internal use only.

## Support

For issues or questions, contact your system administrator.

---

**Built with Flutter and Supabase**
**Powered by Google ML Kit for License Plate Recognition**
