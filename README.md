# PBX CDR & CEL Cleanup and Optimization Script

## Overview

This project contains a SQL script designed to clean and optimize the Call Detail Records (CDR) and Channel Event Logging (CEL) tables in an Asterisk-based PBX system. The script efficiently manages large datasets by filtering and migrating relevant records to new tables, ensuring that the database remains performant and manageable.

## Script Details

### Filename

`pbx_cdr_cel_cleanup_optimization.sql`

### Purpose

The script's primary purpose is to:
- **Clean up** old data from the CDR and CEL tables based on a defined retention period.
- **Optimize** the PBX database by creating new tables with only the necessary data, thus reducing the table size and improving query performance.
- **Preserve data integrity** by ensuring no records are lost or duplicated during the process.

### Key Steps

1. **Setting Retention Period**:
   - The script begins by defining the retention period, specified as the number of months to look back. This period controls which records are retained in the new tables.

2. **Table Creation**:
   - The script creates new tables (`cdr_new` and `cel_new`) with the same structure as the original `cdr` and `cel` tables. These tables will store the filtered data.

3. **Data Insertion**:
   - Records from the original tables are copied into the new tables, filtered by the defined retention period.
   - The script includes fallback mechanisms to handle edge cases where expected data might not be present, ensuring that the process remains robust and complete.

4. **Final Data Synchronization**:
   - Any new records added to the original tables after the initial data copy are inserted into the new tables to ensure no data is missed.

5. **Table Swapping**:
   - After all relevant data has been copied, the original tables are renamed (as backups), and the new tables take their place in the database.
   - The old tables are then dropped to free up space.

### Transaction Management

The script uses transactions to ensure that the operations are atomic, meaning either all the changes are applied, or none are. This approach minimizes the risk of data loss or inconsistency during the renaming of the tables.

## Usage

### Prerequisites

- **MariaDB/MySQL**: Ensure you are using a database that supports the SQL syntax and functions used in this script.
- **Database Access**: Ensure you have the necessary permissions to create, drop, and rename tables within the PBX database.

### Running the Script

1. **Backup the Database**:
   - Before running the script, it's advisable to perform a full backup of the PBX database to prevent any accidental data loss.

2. **Execute the Script**:
   - You can execute the script using a database management tool (e.g., MySQL Workbench, phpMyAdmin) or via the command line using the following command:
     ```bash
     mysql -u [username] -p [database_name] < pbx_cdr_cel_cleanup_optimization.sql
     ```
   - Replace `[username]` with your database username and `[database_name]` with the name of your PBX database.

3. **Verification**:
   - After running the script, verify that the new tables (`cdr` and `cel`) are populated with the expected data.
   - Check that no data has been lost and that the old tables (`cdr_old` and `cel_old`) have been dropped.

## Contribution

Contributions to this project are welcome. If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

## Acknowledgments

Special thanks to the maintainers of the Asterisk PBX system and the MariaDB/MySQL communities for their continued support and development of these platforms.
