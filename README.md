# System Administration Toolkit

A comprehensive shell script utility for system management, monitoring, and administration tasks.

## Overview

The System Administration Toolkit is a powerful bash-based application that provides system administrators with essential tools for managing Linux/Unix systems. It features a modular architecture with comprehensive logging, configuration management, and error handling.

## Features

### Core Functionality
- **System Information Display** - Hardware, OS, and resource details
- **Process Monitoring** - CPU and memory usage tracking
- **Service Management** - Systemd service control and monitoring
- **Network Monitoring** - Interface stats, port scanning, and traffic analysis
- **Log Analysis** - System log examination and error tracking
- **Backup Utility** - Automated backup creation and management
- **System Cleanup** - Temporary file removal and cache clearing
- **Security Scanning** - Failed login detection and port monitoring
- **Performance Monitoring** - Real-time system metrics
- **User Management** - Account monitoring and activity tracking

### Advanced Features
- **Configuration Management** - Customizable settings and thresholds
- **Comprehensive Logging** - Multi-level logging with rotation
- **Error Handling** - Robust error trapping and recovery
- **Modular Architecture** - Reusable utility libraries
- **Database Integration** - SQLite support for metrics storage
- **Notification System** - Email alerts for critical events
- **Network Utilities** - Advanced network diagnostics
- **Security Monitoring** - Real-time security event tracking

## Installation

### Prerequisites

- Bash 4.0 or higher
- Linux/Unix operating system
- Root privileges for some operations
- Optional dependencies:
  - `bc` for mathematical calculations
  - `jq` for JSON processing
  - `curl` for network operations
  - `mail` for email notifications
  - `speedtest-cli` for network speed tests

### Setup

1. Clone or download the toolkit:
```bash
git clone https://github.com/devmonixtechnologies/systuff.git
cd systuff
```

2. Make the main script executable:
```bash
chmod +x sysadmin-toolkit.sh
```

3. Run the toolkit:
```bash
./sysadmin-toolkit.sh
```

## Usage

### Interactive Mode

Launch the toolkit in interactive mode:
```bash
./sysadmin-toolkit.sh
```

This will display a menu with all available options.

### Command Line Usage

The toolkit can also be used for specific tasks:

```bash
# Show system information
./sysadmin-toolkit.sh --info

# Monitor processes
./sysadmin-toolkit.sh --processes

# Check system health
./sysadmin-toolkit.sh --health

# Generate report
./sysadmin-toolkit.sh --report
```

### Configuration

Edit `config.conf` to customize the toolkit behavior:

```bash
# Set monitoring thresholds
CPU_WARNING_THRESHOLD=80
MEMORY_CRITICAL_THRESHOLD=90

# Enable email notifications
ENABLE_EMAIL_NOTIFICATIONS=true
EMAIL_RECIPIENTS="admin@example.com"

# Configure backup settings
DEFAULT_BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION=true
```

## Project Structure

```
shellset/
├── sysadmin-toolkit.sh          # Main application script
├── config.conf                  # Configuration file
├── README.md                    # Documentation
├── lib/                         # Library modules
│   ├── utils.sh                 # General utility functions
│   ├── network.sh               # Network utilities
│   ├── config.sh                # Configuration management
│   └── logging.sh               # Logging and error handling
├── logs/                        # Log files directory
├── data/                        # Data storage directory
├── backups/                     # Backup storage directory
└── tmp/                         # Temporary files directory
```

## Module Documentation

### utils.sh

Core utility functions including:
- Input validation
- System resource monitoring
- File operations
- Password generation
- Checksum calculations
- System health checks

### network.sh

Network monitoring and diagnostic tools:
- Interface information
- Port scanning
- Traffic monitoring
- Latency testing
- DNS resolution
- Bandwidth analysis

### config.sh

Configuration management system:
- Load/save configuration
- Validation functions
- Environment variable support
- Import/export capabilities

### logging.sh

Comprehensive logging system:
- Multi-level logging (DEBUG, INFO, WARN, ERROR, CRITICAL)
- Log rotation
- Error handling and trapping
- Notification system
- Log analysis tools

## Configuration Options

### System Monitoring
- `CPU_WARNING_THRESHOLD` - CPU usage warning level (default: 80%)
- `MEMORY_WARNING_THRESHOLD` - Memory usage warning level (default: 80%)
- `DISK_WARNING_THRESHOLD` - Disk usage warning level (default: 80%)
- `LOAD_WARNING_THRESHOLD` - System load warning level (default: 2.0)

### Network Settings
- `DEFAULT_NETWORK_INTERFACE` - Default network interface (default: eth0)
- `NETWORK_TIMEOUT` - Network operation timeout (default: 5s)
- `PING_COUNT` - Ping packet count (default: 4)

### Backup Configuration
- `DEFAULT_BACKUP_RETENTION_DAYS` - Backup retention period (default: 30)
- `BACKUP_COMPRESSION` - Enable backup compression (default: true)
- `BACKUP_ENCRYPTION` - Enable backup encryption (default: false)

### Logging
- `LOG_LEVEL` - Minimum log level (default: INFO)
- `MAX_LOG_SIZE` - Maximum log file size (default: 10M)
- `MAX_LOG_FILES` - Maximum log files to keep (default: 5)

## Security Features

### Security Monitoring
- Failed login attempt tracking
- Port scanning detection
- User activity monitoring
- Sudo usage tracking
- Security event logging

### Security Best Practices
- Input validation and sanitization
- Privilege escalation checks
- Secure temporary file handling
- Audit trail maintenance
- Encryption support for sensitive data

## Troubleshooting

### Common Issues

1. **Permission Denied Errors**
   - Ensure script is executable: `chmod +x sysadmin-toolkit.sh`
   - Run with sudo for privileged operations

2. **Missing Dependencies**
   - Install required packages: `sudo apt install bc jq curl`
   - Check for missing commands in logs

3. **Configuration Errors**
   - Validate configuration: `./sysadmin-toolkit.sh --validate-config`
   - Reset to defaults: `./sysadmin-toolkit.sh --reset-config`

4. **Log File Issues**
   - Check log directory permissions
   - Verify disk space availability
   - Review log rotation settings

### Debug Mode

Enable debug mode for detailed troubleshooting:

```bash
# Set in config.conf
DEBUG_MODE=true

# Or enable temporarily
DEBUG_MODE=true ./sysadmin-toolkit.sh
```

### Log Analysis

Analyze logs for issues:

```bash
# View recent errors
./sysadmin-toolkit.sh --log-analyze "ERROR"

# Generate log report
./sysadmin-toolkit.sh --log-report
```

## Development

### Adding New Modules

1. Create new module in `lib/` directory
2. Follow existing naming conventions
3. Include proper error handling
4. Add documentation
5. Update main script to load module

### Code Style

- Use 4-space indentation
- Follow bash best practices
- Include function documentation
- Use meaningful variable names
- Implement proper error handling

### Testing

Test new functionality:

```bash
# Run with test configuration
TEST_MODE=true ./sysadmin-toolkit.sh

# Validate configuration
./sysadmin-toolkit.sh --validate-config

# Check dependencies
./sysadmin-toolkit.sh --check-deps
```

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes with proper testing
4. Update documentation
5. Submit pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support and questions:
- Check the troubleshooting section
- Review log files for errors
- Validate configuration
- Check system requirements

## Changelog

### Version 1.0
- Initial release
- Core system administration features
- Modular architecture
- Comprehensive logging
- Configuration management
- Security monitoring
- Network utilities
