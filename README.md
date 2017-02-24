
urbackup_image_migration.sh
===================================================

move image backups between urbackup servers

To answer this request:

https://forums.urbackup.org/t/do-first-image-backup-on-local-server-then-move-image-to-internet-server-for-subsequent-incremental-image-backups/2951

This is a working solution for migrating IMAGE backups from "temporary" local urbackup server to feed an internet server.

It also works for restoring images in low bandwidth environments.

You'll need:

    An USB disk
    A Car
    A temporary urbackup server

To feed the internet server, the process is:

1. create a client for the internet server but avoid doing any backup
1. use a local (temporal) urbackup server to create the first image (with 1 and 2 done you are sure that both local and internet servers have the same client name)
1. copy the client image files tree and a copy of server_backup.db* data base files to an USB disk
1. travel to the ISP where lives the internet server
1. Mount the usb disk to the internet urbackup server and run the script to import the backup images (link below). The script will do

    * stop urbackup server for security
    * backup the production urbackup db for security
    * move the image files to its final location
    * feed the internet urbackup server data base with the right ids (changing them as needed)
    * start the urbackup server after all the operation is done

The same script also works for restoring, the process is:

1. Travel to the ISP where the internet server lives,
2. copy both the full and incremental images of the client to be restored and the server_backup.db* files to an USB disk
3. travel to the location where the computer to be fully restored is. Take with you a temporary urbackup server.
4. feed the temporary urbackup server database and backup image folders using the script (link below).
5. restore the computer with the live CD using as restore server the temporary one.

We have tested the procedure in both ways.

To run the script:

* Edit custom variables (paths mostly)
* run:
     
     ```
     urbackup_image_migration.sh clientname
     ```
     
Use at your own risk.
