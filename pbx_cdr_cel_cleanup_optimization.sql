/*
 * Overview:
 * This script is designed to clean and optimize the Call Detail Records (CDR) 
 * and Channel Event Logging (CEL) tables in an Asterisk-based PBX system. 
 * The process involves creating new temporary tables (`cdr_new` and `cel_new`) 
 * with the same structure as the existing ones, filtering and copying relevant 
 * data into these new tables, and then replacing the old tables with the new ones.
 * 
 * Key Steps:
 * 1. Drop any existing temporary tables to avoid conflicts.
 * 2. Create new tables (`cdr_new` and `cel_new`) with the same structure 
 *    as the original `cdr` and `cel` tables.
 * 3. Insert filtered data from the original tables into the new ones, 
 *    based on a specified look-back period of 6 months.
 * 4. Handle edge cases where data may not exist in the expected range 
 *    by setting fallback values.
 * 5. Insert any new records added after the initial data copy to ensure 
 *    no records are missed.
 * 6. Rename the old tables to preserve them as backups and replace them 
 *    with the new, cleaned tables.
 * 7. Drop the old tables after the new ones have been successfully created 
 *    and swapped in.
 * 
 * The script uses transaction management to ensure the atomicity of operations, 
 * minimizing the risk of data loss or inconsistency during the table renaming phase.
 */


-- Set the number of months to look back for data filtering
SET @monthsToLookBack = 6;

-- Drop any existing temporary CDR table to avoid conflicts
DROP TABLE IF EXISTS cdr_new;

-- Create a new temporary CDR table with the same structure as the original
CREATE TABLE `cdr_new` (
	`calldate` DATETIME NOT NULL DEFAULT '0000-00-00 00:00:00',
	`clid` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`src` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`dst` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`dcontext` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`channel` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`dstchannel` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`lastapp` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`lastdata` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`duration` INT(11) NOT NULL DEFAULT '0',
	`billsec` INT(11) NOT NULL DEFAULT '0',
	`disposition` VARCHAR(45) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`amaflags` INT(11) NOT NULL DEFAULT '0',
	`accountcode` VARCHAR(20) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`uniqueid` VARCHAR(32) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`userfield` VARCHAR(255) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`did` VARCHAR(50) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`recordingfile` VARCHAR(255) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`cnum` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`cnam` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`outbound_cnum` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`outbound_cnam` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`dst_cnam` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`linkedid` VARCHAR(32) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`peeraccount` VARCHAR(80) NOT NULL DEFAULT '' COLLATE 'utf8mb4_unicode_ci',
	`sequence` INT(11) NOT NULL DEFAULT '0',
	INDEX `calldate` (`calldate`) USING BTREE,
	INDEX `dst` (`dst`) USING BTREE,
	INDEX `accountcode` (`accountcode`) USING BTREE,
	INDEX `uniqueid` (`uniqueid`) USING BTREE,
	INDEX `did` (`did`) USING BTREE,
	INDEX `recordingfile` (`recordingfile`(191)) USING BTREE
);
-- Drop any existing temporary CEL table to avoid conflicts
DROP TABLE IF EXISTS `cel_new`;

-- Create a new temporary CEL table with the same structure as the original
CREATE TABLE `cel_new` (
	`id` INT(11) NOT NULL AUTO_INCREMENT,
	`eventtype` VARCHAR(30) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`eventtime` DATETIME NOT NULL,
	`cid_name` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`cid_num` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`cid_ani` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`cid_rdnis` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`cid_dnid` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`exten` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`context` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`channame` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`appname` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`appdata` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`amaflags` INT(11) NOT NULL,
	`accountcode` VARCHAR(20) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`uniqueid` VARCHAR(32) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`linkedid` VARCHAR(32) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`peer` VARCHAR(80) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`userdeftype` VARCHAR(255) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	`extra` VARCHAR(512) NOT NULL COLLATE 'utf8mb4_unicode_ci',
	PRIMARY KEY (`id`) USING BTREE,
	INDEX `uniqueid_index` (`uniqueid`) USING BTREE,
	INDEX `linkedid_index` (`linkedid`) USING BTREE,
	INDEX `context_index` (`context`) USING BTREE
);

-- Insert filtered data from the old CDR table into the new CDR table
INSERT INTO cdr_new (calldate, clid, src, dst, dcontext, `channel`, dstchannel, lastapp, lastdata, 
	duration, billsec, disposition, amaflags, accountcode, uniqueid, userfield, did, recordingfile, 
	cnum, cnam, outbound_cnum, outbound_cnam, dst_cnam, linkedid, peeraccount, sequence)
SELECT calldate, clid, src, dst, dcontext, `channel`, dstchannel, lastapp, lastdata, 
	duration, billsec, disposition, amaflags, accountcode, uniqueid, userfield, did, recordingfile, 
	cnum, cnam, outbound_cnum, outbound_cnam, dst_cnam, linkedid, peeraccount, sequence
FROM cdr
WHERE calldate >= CURDATE() - INTERVAL @monthsToLookBack MONTH;

-- Identify the minimum ID in the CEL table to start the data copy
-- This identifies the earliest relevant record in the CEL table based on matching uniqueid values in the CDR table
SELECT @min_id:=MIN(id) min_id
FROM cel l
WHERE l.uniqueid IN (
	SELECT DISTINCT uniqueid 
	FROM cdr 
	WHERE calldate BETWEEN CURDATE() - INTERVAL @monthsToLookBack MONTH 
		AND CURDATE() - INTERVAL @monthsToLookBack MONTH + INTERVAL 10 DAY 
)
;

-- Set a fallback value for @min_id if no matching records are found
-- Ensures that the data copy starts from the earliest available record in the CEL table if no specific matches are found
SET @min_id = COALESCE(@min_id, 
		(SELECT MIN(id) min_id
			FROM cel l
			WHERE l.uniqueid = (
				SELECT MIN(uniqueid)
				FROM cdr 
			)
		)
	);


-- Insert filtered data from the old CEL table into the new CEL table starting from @min_id
INSERT INTO cel_new (id, eventtype, eventtime, cid_name, cid_num, cid_ani, cid_rdnis, cid_dnid, 
	exten, `context`, channame, appname, appdata, amaflags, accountcode, uniqueid, linkedid, 
	peer, userdeftype, extra)
SELECT l.id, l.eventtype, l.eventtime, l.cid_name, l.cid_num, l.cid_ani, l.cid_rdnis, l.cid_dnid, 
	l.exten, l.`context`, l.channame, l.appname, l.appdata, l.amaflags, l.accountcode, l.uniqueid, l.linkedid, 
	l.peer, l.userdeftype, l.extra
-- SELECT COUNT(*)
FROM cel l 
WHERE l.id >= @min_id;

-- Find the maximum sequence number in the new CDR table for current-day records
-- This is used to ensure that no data is missed during the final insertion
SELECT MAX(sequence)
INTO @cdr_max_seq
FROM cdr_new
WHERE calldate >= CURDATE();

-- Find the maximum ID in the new CEL table
-- This is used to ensure that no data is missed during the final insertion
SELECT @cel_max_id:=MAX(id)
FROM cel_new;

-- Display the maximum sequence and ID for verification
SELECT @cdr_max_seq, @cel_max_id;

-- Start a transaction to ensure atomicity of the final data insertion and table renaming
START TRANSACTION;

-- Insert any new records into the new CDR table that were added after the initial copy
INSERT INTO cdr_new (calldate, clid, src, dst, dcontext, `channel`, dstchannel, lastapp, lastdata, 
	duration, billsec, disposition, amaflags, accountcode, uniqueid, userfield, did, recordingfile, 
	cnum, cnam, outbound_cnum, outbound_cnam, dst_cnam, linkedid, peeraccount, sequence)
SELECT calldate, clid, src, dst, dcontext, `channel`, dstchannel, lastapp, lastdata, 
	duration, billsec, disposition, amaflags, accountcode, uniqueid, userfield, did, recordingfile, 
	cnum, cnam, outbound_cnum, outbound_cnam, dst_cnam, linkedid, peeraccount, sequence
FROM cdr
WHERE calldate >= CURDATE() AND sequence > @cdr_max_seq;

-- Insert any new records into the new CEL table that were added after the initial copy
INSERT INTO cel_new (id, eventtype, eventtime, cid_name, cid_num, cid_ani, cid_rdnis, cid_dnid, 
	exten, `context`, channame, appname, appdata, amaflags, accountcode, uniqueid, linkedid, 
	peer, userdeftype, extra)
SELECT l.id, l.eventtype, l.eventtime, l.cid_name, l.cid_num, l.cid_ani, l.cid_rdnis, l.cid_dnid, 
	l.exten, l.`context`, l.channame, l.appname, l.appdata, l.amaflags, l.accountcode, l.uniqueid, l.linkedid, 
	l.peer, l.userdeftype, l.extra
-- SELECT COUNT(*)
FROM cel l 
WHERE l.id >  @cel_max_id;

-- Rename the old tables to keep a backup and replace them with the new tables
RENAME TABLE cdr TO cdr_old, cdr_new TO cdr;
RENAME TABLE cel TO cel_old, cel_new TO cel;

COMMIT;

-- Drop the old tables as they are no longer needed
DROP TABLE cdr_old;
DROP TABLE cel_old;
