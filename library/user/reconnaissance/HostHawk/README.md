![HostHawk Logo](logo.png)

# HostHawk

HostHawk is a dynamic payload system focused on network and host reconnaissance for the Wifi Pineapple Pager. Commands and variables are defined in external configuration files, allowing for easy customization and expansion without modifying the core payload scripts.  

## Features
- ✨ **Dynamic Payload Generation**: Create custom reconnaissance payloads by adding your own commands and variables in JSON configuration files.
- 🌐 **Global and Local Variable Management**: Define global variables for all payloads and payload-specific variables, with automatic prompting for missing values.  Manage global variables directly on the Pager.
- 🎨 **User-Friendly UI Integration**: Automatically selects appropriate UI pickers (IP, MAC, Text, Number) based on variable names and default values.
- 📦 **Modular Structure**: Easily add new payloads by creating configuration files in the config/ directory.
- 🚀 **Beyond Reconnaissance**: While focused on reconnaissance, HostHawk's flexible design allows for adaptation to other use cases.  Any command line tool chain can be integrated, with customizable payload destination (including the 'client' and 'access_point' targeted payload categories.)


## Core Payloads

- **Generate_Payloads**: Generates custom payloads based on user-defined configurations in config/.
- **Remove_Payloads**: Cleans up and removes previously created reconnaissance payloads.
- **Config_New_Payload**: Assists users in creating new payload configurations through interactive prompts.

## Dynamic Payloads
The following payloads are dynamically generated based on the configurations defined in config/.
- **_Set_Variables/{varname}**: Sets global variables used across payloads (only generated for variables defined in HostHawk/.env).
- **{path/category/payload_name}**: Custom payloads as defined in the configuration files.

## Directory Structure
```
HostHawk/
├── README.md
├── .env                      # Global variables
├── _Generate_Payloads/
│   └── payload.sh
├── _Remove_Payloads/
│   └── payload.sh
├── config/
    └── config.json           # Payload definitions
```

## How It Works
1. **Configuration**: Define commands, variables, and settings in config/config.json or add custom JSON files in config/.
2. **Payload Generation**: The Generate_Payloads script reads all configuration files and generates payload scripts in their defined directory structure. Each payload includes a payload.sh with proper metadata. Generates global .env from examples.env if it doesn't exist.
3. **Execution**: Generated payloads can be executed on the Pager by selecting them from Payloads menu (exact location based on defined path). During execution, the system checks for required and optional variables, prompting the user as needed.
4. **Complex Functionality**: Use scripts in the scripts/ directory for advanced functionality that generated payloads can source or call.

## Variable Management

### Global Variables (HostHawk/.env)
- User-defined list of variable keys that should be available across all payloads
- Managed via Set_{VAR_NAME} dynamic payloads
- To add a global variable, manually add it to HostHawk/.env

### Payload-Specific Variables (e.g., network/ping_host/.env)
- Variables specific to individual payloads
- Can override global variables for payload-specific values
- Automatically created when user sets values during payload execution

### Variable Resolution Hierarchy
1. Load global variables from HostHawk/.env
2. Load payload-specific .env (overrides globals)
3. Missing required variable? Prompt user → save to:
   - HostHawk/.env if variable key exists there (global)
   - {payload}/.env if not in global list (local)
4. Missing optional variable? Ask user to customize (pre-filled with default) → save to {payload}/.env

### UI Picker Auto-Detection
The system automatically selects the appropriate UI picker based on variable naming and default values:

**For Required Variables (no default):**
- Variable name contains "IP", "HOST", or "GATEWAY" → IP_PICKER
- Variable name contains "MAC" → MAC_PICKER
- All others → TEXT_PICKER

**For Optional Variables (with default value):**
- Default matches IP pattern (e.g., "192.168.1.1") → IP_PICKER
- Default matches MAC pattern (e.g., "aa:bb:cc:dd:ee:ff") → MAC_PICKER
- Default is purely numeric (e.g., "4", "100") → NUMBER_PICKER
- All others → TEXT_PICKER

**Examples:**
- `TARGET_IP` (required) → IP_PICKER
- `GATEWAY` (required) → IP_PICKER
- `SOURCE_MAC` (required) → MAC_PICKER
- `"COUNT": "4"` (optional) → NUMBER_PICKER
- `"TARGET": "192.168.1.1"` (optional) → IP_PICKER
- `"INTERFACE": "eth0"` (optional) → TEXT_PICKER

## Payload Configuration Schema
```json
{
  "payloads": [
    {
      "name": "Ping Host",
      "path": "network/ping_host",
      "command": "ping -c $COUNT -W $TIMEOUT $TARGET_IP",
      "required_vars": ["TARGET_IP"],
      "optional_vars": {
        "COUNT": "4",
        "TIMEOUT": "10"
      },
      "required_packages": ["iputils-ping"],
      "description": "Ping a target host",
      "author": "username"
    }
  ]
}
```

### Configuration Fields
- **name**: Payload display name
- **path**: Directory structure (creates subdirectories as categories)
- **command**: Shell command to execute (use $VAR_NAME for variable substitution)
- **required_vars**: Array of variables that must be set (will prompt if missing)
- **optional_vars**: Object with variable names and default values
- **required_packages**: Array of package names needed for the payload to function
- **description**: Brief description of the payload's purpose
- **author**: Creator of the payload

## Generated Payload Execution Flow
1. Display CONFIRMATION_DIALOG with metadata (description, author, required/optional vars with current values)
2. Load HostHawk/.env (global variables)
3. Load {payload}/.env if exists (local variables)
4. Check required_vars:
   - If missing: prompt with IP_PICKER, TEXT_PICKER, or MAC_PICKER
   - Prompt saving to appropriate .env based on global/local status
5. Check optional_vars:
   - If missing: ask "Set {VAR}? (default: {value})"
   - If yes: prompt with default pre-filled → save to {payload}/.env
   - If no: use default from config
6. Execute command with variable substitution
7. LOG output:
   - Success: LOG green {stdout}
   - Error: LOG red {stderr + stdout}
8. Exit with command return code