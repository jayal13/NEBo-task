# Ansible Playbook: LVM Configuration and /var Relocation

This Ansible playbook automates the process of creating and mounting a Logical Volume (LV) under /var on an additional disk. It checks if /var is already relocated to the correct volume, sets up a physical volume (PV) and volume group (VG) if needed, and moves the existing data to the new mount point.

---

## Overview of Tasks

1. *Safety Checks*  
   - Detects whether /var is already mounted on /dev/vg_var/lv_var.  
   - Skips the entire process if /var is already properly configured.

2. *Disk and LVM Setup*  
   - Verifies the existence of an additional disk (default path: /dev/nvme1n1).  
   - Creates a Physical Volume (PV) on the disk if not present.  
   - Checks for a Volume Group (vg_var) and creates it if needed.  
   - Verifies if a Logical Volume (lv_var) already exists, creating it if missing.

3. *Formatting and Temporary Mount*  
   - Formats the LV as *ext4* (only if it’s not already formatted).  
   - Creates a temporary mount point (/mnt/var_temp) and mounts the LV there.

4. *Data Synchronization*  
   - Uses rsync -aAX to copy data from the old /var to the new partition (only if there are changes to sync).

5. *Persistent Mount Configuration*  
   - Updates /etc/fstab to ensure that the new LV (/dev/vg_var/lv_var) is mounted at /var on system boot.

6. *Cleanup and Final Mount*  
   - Unmounts the temporary path.  
   - Mounts the new partition at /var.  
   - Verifies the final mounting status.
