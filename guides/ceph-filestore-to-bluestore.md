# Migrating Ceph Filestore to Bluestore
Identify the volume group of the OSD. Take note of the PV and VG, you will need it later.
```sh
[root@ceph03 ~]# df
Filesystem                   1K-blocks    Used Available Use% Mounted on
/dev/mapper/my-root          383587332 1721972 381865360   1% /
devtmpfs                      65728280       0  65728280   0% /dev
tmpfs                         65740672       0  65740672   0% /dev/shm
tmpfs                         65740672  125316  65615356   1% /run
tmpfs                         65740672       0  65740672   0% /sys/fs/cgroup
/dev/sda2                      1038336  137288    901048  14% /boot
/dev/sda1                      1046516    9972   1036544   1% /boot/efi
tmpfs                         65740672      24  65740648   1% /var/lib/ceph/osd/ceph-20
tmpfs                         65740672      24  65740648   1% /var/lib/ceph/osd/ceph-22
tmpfs                         65740672      24  65740648   1% /var/lib/ceph/osd/ceph-19
tmpfs                         65740672      24  65740648   1% /var/lib/ceph/osd/ceph-23
tmpfs                         65740672      24  65740648   1% /var/lib/ceph/osd/ceph-21
tmpfs                         65740672      48  65740624   1% /var/lib/ceph/osd/ceph-16
tmpfs                         13148136       0  13148136   0% /run/user/0
tmpfs                         65740672      48  65740624   1% /var/lib/ceph/osd/ceph-17
tmpfs                         65740672      48  65740624   1% /var/lib/ceph/osd/ceph-18
[root@ceph03 ~]# 
[root@ceph03 ~]# ll /var/lib/ceph/osd/ceph-20
total 24
lrwxrwxrwx 1 ceph ceph 93 May 24  2019 block -> /dev/ceph-56b5ff6b-a12f-43f9-95fb-c61a2d021a72/osd-block-b5a77351-b738-42b8-b02d-0d7385bbd7f0
-rw------- 1 ceph ceph 37 May 24  2019 ceph_fsid
-rw------- 1 ceph ceph 37 May 24  2019 fsid
-rw------- 1 ceph ceph 56 May 24  2019 keyring
-rw------- 1 ceph ceph  6 May 24  2019 ready
-rw------- 1 ceph ceph 10 May 24  2019 type
-rw------- 1 ceph ceph  3 May 24  2019 whoami
[root@ceph03 ~]#pvs
  PV         VG                                        Fmt  Attr PSize    PFree
  /dev/sdd   ceph-88e79d2c-995c-4506-8e0c-fd0076916c15 lvm2 a--    <3.64t    0
  /dev/sde   ceph-4bc7e062-1789-480e-96b0-2729e3feeb38 lvm2 a--    <3.64t    0
  /dev/sdf   ceph-23072b14-baec-4b2d-9cbc-a2e4f29363eb lvm2 a--    <3.64t    0
  /dev/sdg   ceph-f52dacaf-3987-4135-88e0-64cda2a96052 lvm2 a--    <3.64t    0
  /dev/sdh   ceph-56b5ff6b-a12f-43f9-95fb-c61a2d021a72 lvm2 a--    <3.64t    0
  /dev/sdi   ceph-f829fcee-a945-49bb-99a6-5e0e48e9fbfa lvm2 a--    <3.64t    0
  /dev/sdj   ceph-e6fd262d-f922-412c-a098-fa964adcdc12 lvm2 a--    <3.64t    0
  /dev/sdk   ceph-ac3d0ddf-62d9-4c83-bfbd-5985cb0a8255 lvm2 a--    <3.64t    0
[root@ceph03 ~]#
```
Set the OSD out
```sh
ceph osd out
```
Wait until the data is migrated to other healthy OSDs before proceeding, making sure that ceph is healthy, you can monitor via
```sh
ceph -s
```
or
```sh
ceph -w
```
Once ceph is healthy again, kill the OSD process
```sh
systemctl kill ceph-osd@{osd-name}
```
Remove the OSD from the cluster
```sh
ceph osd rm {osd-name}
```
Remove the auth keys of the OSD
```sh
ceph auth del {osd-name}
```
Remove the LVM volumegroup of the OSD
```sh
vgremove {osd-volume-group}
```
Clean the OSD disk. The device name was identified earlier when we run "pvs"
```sh
ceph-volume lvm zap /dev/{physical-device-of-the-OSD}
```
Create the OSD using bluestore
```sh
ceph-volume lvm create --bluestore --data /dev/{physical-device-of-the-OSD}
```
In a production environment it's better to set a separate device (preferrably SSD) for block.wal (write ahead logs) and block.db (blockstore database).
```sh
ceph-volume lvm create --bluestore \
                       --block.wal /dev/{wal-device} \
                       --block.db /dev/{db-device} \
                       --data /dev/{physical-device-of-the-OSD}
```
