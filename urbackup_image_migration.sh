#! /bin/bash
# vim:ts=4:sw=4:et:ft=sh
# Migrate urbackup images between urbackup servers
# Created: 2017-02-21

# Copyright (c) 2017: Hilario J. Montoliu <hmontoliu@gmail.com>, 
#                     Fernando Brines <fbrines@ebmproyectos.com>
 
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.  See http://www.gnu.org/copyleft/gpl.html for
# the full text of the license.

# source_ -> refers to the files/db to be imported into running urbackup server
# destination_ -> refers to running urbackup server

CLIENTNAME="${1}" # TODO: handle cli params and help stuff

# custom variables
source_urbackup_files=/media/usb/${CLIENTNAME}/
source_backup_server_db=${source_urbackup_files}/source.db

destination_urbackup_files=/var/local/backup/urbackup/
destination_backup_server_db=/var/urbackup/backup_server.db

# for security, stop urbackupsrv and backup the production db.
systemctl stop urbackupsrv
for file in /var/urbackup/backup_server.*; do
    cp ${file} ${file}_`date +%s`.bak
done

# moving files to final destination  
cp --sparse=always -fva ${source_urbackup_files}/* ${destination_urbackup_files}/$CLIENTNAME/
# chown stuff if needed


# get client IDs in source and dest ddbb
source_CLIENTID=$(sqlite3 ${source_backup_server_db} "select id from clients where name = \"$CLIENTNAME\"")
destination_CLIENTID=$(sqlite3 ${destination_backup_server_db} "select id from clients where name = \"$CLIENTNAME\"")


# create temp tables in source db with new client id
sqlite3 ${source_backup_server_db} << EOF
drop table if exists backup_images_tmp;
create table backup_images_tmp as select * from backup_images where clientid = $source_CLIENTID;
update backup_images_tmp set clientid = $destination_CLIENTID;
drop table if exists  assoc_images_tmp;
create table assoc_images_tmp as select * from assoc_images where img_id in (select id from backup_images where clientid = $source_CLIENTID);
EOF

# get Max id 
destination_MAX_BACKUP_IMAGE_ID=$(sqlite3 ${destination_backup_server_db} 'select max (id) from backup_images;')

# apply new backup_image.ids to temp tables
sqlite3 ${source_backup_server_db} << EOF
update backup_images_tmp set id = id + $destination_MAX_BACKUP_IMAGE_ID;
update assoc_images_tmp set assoc_id = assoc_id + $destination_MAX_BACKUP_IMAGE_ID, img_id = img_id + $destination_MAX_BACKUP_IMAGE_ID;
EOF

# apply changes to production db
# Creamos el primer registro de backup_images:
sqlite3 ${destination_backup_server_db} << EOF
attach "${source_backup_server_db}" as source;

insert into backup_images select * from source.backup_images_tmp;
insert into assoc_images select * from source.assoc_images_tmp;
EOF

# back to routine job
systemctl stop urbackupsrv
