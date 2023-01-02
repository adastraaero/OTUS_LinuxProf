## Lesson1

<details>

### Задача: 

- **1) Обновить ядро ОС из репозитория ELRepo**
- **2) Создать Vagrant box c помощью Packer**
- **3) Загрузить Vagrant box в Vagrant Cloud**

Создаем ВМ используя и запуская Vagrantfile:

```
# Описываем Виртуальные машины
MACHINES = {
  # Указываем имя ВМ "kernel update"
  :"kernel-update" => {
              #Какой vm box будем использовать
              :box_name => "centos/stream8",
              #Указываем box_version
              :box_version => "20210210.0",
              #Указываем количество ядер ВМ
              :cpus => 2,
              #Указываем количество ОЗУ в мегабайтах
              :memory => 4096,
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    # Отключаем проброс общей папки в ВМ
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # Применяем конфигруацию ВМ
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s
      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
    end
  end
end
```
Подключаемся к ВМ:
```
vagrant ssh
```

Перед работами проверим текущую версию ядра:
```
~/Documents/OTUS_Linux_Prof/Lesson1$ vagrant ssh
[vagrant@kernel-update ~]$ uname -r
4.18.0-277.el8.x86_64
```
Далее подключим репозиторий, откуда возьмём необходимую версию ядра:

```
sudo yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm

```

В репозитории есть две версии ядер:
- **kernel-ml — свежие и стабильные ядра**
- **kernel-lt — стабильные ядра с длительной версией поддержки, более старые, чем версия ml.**

Установим последнее ядро(kernel-ml) из репозитория:

```
dnf --enablerepo="elrepo-kernel" install -y kernel-ml
```
После перезагрузки снова проверяем версию ядра:

```
~/Documents/OTUS_Linux_Prof/Lesson1$ vagrant ssh
Last login: Thu Dec 29 09:09:45 2022 from 10.0.2.2
[vagrant@kernel-update ~]$ uname -r
6.1.1-1.el8.elrepo.x86_6
```

### Работа с Packer

Тесты показали, что при использовании 7ой версии VirtualBox стабильно получаем ошибку:
```
virtualbox dracut-initqueue
```
На 6ой версии всё проходит без проблем.

В скриптах, выданных для ДЗ были заменены:

чексумма и ссылка на образ в centos.json - т.к. старые ссылки не работают.
количество памяти и ядер для более быстрой сборки.

В файл ks.cfg добавлен код, для повышения привелегий учетки Vagrant без запроса пароля,
без этого сборка образа вылетает, потому что запрашивается sudo пароль для учётки Vagrant,
проверял это на ручной установке.Судя по коду и документации sudo пароль должен ввестись,
но этого не происходит(

Собираем образ:

```
packer build centos.json
```

Образ успешно собран:
```
==> centos-8: Gracefully halting virtual machine...
==> centos-8: Preparing to export machine...
    centos-8: Deleting forwarded port mapping for the communicator (SSH, WinRM, etc) (host port 2904)
==> centos-8: Exporting virtual machine...
    centos-8: Executing: export packer-centos-vm --output builds/packer-centos-vm.ovf --manifest --vsys 0 --description CentOS Stream 8 with kernel 5.x --version 8
==> centos-8: Cleaning up floppy disk...
==> centos-8: Deregistering and deleting VM...
==> centos-8: Running post-processor: vagrant
==> centos-8 (vagrant): Creating a dummy Vagrant box to ensure the host system can create one correctly
==> centos-8 (vagrant): Creating Vagrant box for 'virtualbox' provider
    centos-8 (vagrant): Copying from artifact: builds/packer-centos-vm-disk001.vmdk
    centos-8 (vagrant): Copying from artifact: builds/packer-centos-vm.mf
    centos-8 (vagrant): Copying from artifact: builds/packer-centos-vm.ovf
    centos-8 (vagrant): Renaming the OVF to box.ovf...
    centos-8 (vagrant): Compressing: Vagrantfile
    centos-8 (vagrant): Compressing: box.ovf
    centos-8 (vagrant): Compressing: metadata.json
    centos-8 (vagrant): Compressing: packer-centos-vm-disk001.vmdk
    centos-8 (vagrant): Compressing: packer-centos-vm.mf
Build 'centos-8' finished after 19 minutes 41 seconds.

==> Wait completed after 19 minutes 41 seconds

==> Builds finished. The artifacts of successful builds are:
--> centos-8: 'virtualbox' provider box: centos-8-kernel-5-x86_64-Minimal.box
```

После создания образа, его рекомендуется проверить. Для проверки импортируем полученный vagrant box в Vagrant:

```
mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson1/packer$ vagrant box add centos8-kernel5 centos-8-kernel-5-x86_64-Minimal.box
==> box: Box file was not detected as metadata. Adding it directly...
==> box: Adding box 'centos8-kernel5' (v0) for provider: 
    box: Unpacking necessary files from: file:///home/mity/Documents/OTUS_Linux_Prof/Lesson1/packer/centos-8-kernel-5-x86_64-Minimal.box
==> box: Successfully added box 'centos8-kernel5' (v0) for 'virtualbox'!

```

Проверим, что образ теперь есть в списке имеющихся образов vagrant:

```
mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson1/packer$ vagrant box list
centos/stream8  (virtualbox, 20210210.0)
centos8-kernel5 (virtualbox, 0)
ubuntu/xenial64 (virtualbox, 20211001.0.0)
```

Создадим Vagrantfile на основе образа centos8-kernel5: 

```
vagrant init centos8-kernel5
```

Запустим нашу ВМ:
```
 vagrant up 
```
Подключимя к ней по SSH:
```
vagrant ssh 
```
Проверим версию ядра: 
```
[vagrant@otus-c8 ~]$ uname -r
6.1.1-1.el8.elrepo.x86_64
```
### Ошибка Vagrant was unable to mount VirtualBox shared folders.

Решение:
```
vagrant destroy
vagrant plugin update vagrant-vbguest
vagrant up
```

- **3) Загрузить Vagrant box в Vagrant Cloud**

Регистрируемся на https://app.vagrantup.com/
В разделе Security создаем и сохраняем токен

Логинимся используя токен:
```
vagrant login --token ABCD1234
```

Проверяем, что успешно залогинились:
```
vagrant login --check
```
Загружаем образ командой:
```
vagrant cloud publish artofsky/centos8-kernel5 1.0.0 virtualbox centos-8-kernel-5-x86_64-Minimal.box
```

```
You are about to publish a box on Vagrant Cloud with the following options:
artofsky/centos8-kernel5:   (v1.0.0) for provider 'virtualbox'
Do you wish to continue? [y/N]y
Saving box information...
Uploading provider with file /home/mity/Documents/OTUS_Linux_Prof/Lesson1/packer/centos-8-kernel-5-x86_64-Minimal.box
Complete! Published artofsky/centos8-kernel5
Box:              artofsky/centos8-kernel5
Description:      
Private:          yes
Created:          2022-12-30T14:53:39.859Z
Updated:          2022-12-30T14:53:39.859Z
Current Version:  N/A
Versions:         1.0.0
Downloads:        0
```

</details>

## Lesson2

<details>

### Задачи

* добавить в Vagrantfile еще дисков
* собрать R0/R5/R10 на выбор
* Создание конфигурационного файла mdadm.conf
* Сломать/починить RAID
* Создать GPT раздел, пять партиций и смонтировать их на диск
⭐ Vagrantfile, который сразу собирает систему с подключенным рейдом и смонтированными разделами.


### добавить в Vagrantfile еще дисков

добавим 5ый диск 

```
MACHINES = {
  :otuslinux => {
        :box_name => "centos/7",
        :ip_addr => '192.168.11.101',
        :disks => {
                :sata1 => {
                        :dfile => './sata1.vdi',
                        :size => 250,
                        :port => 1
                },
                :sata2 => {
                        :dfile => './sata2.vdi',
                        :size => 250, # Megabytes
                        :port => 2
                },
                :sata3 => {
                        :dfile => './sata3.vdi',
                        :size => 250,
                        :port => 3
                },
                :sata4 => {
                        :dfile => './sata4.vdi',
                        :size => 250, # Megabytes
                        :port => 4
                },
                :sata5 => {
                        :dfile => './sata5.vdi',
                        :size => 250, # Megabytesvav
                        :port => 5
                }

        }


  },
}

```

Просмотр наличия блочных устройств

```
[vagrant@localhost ~]$ sudo lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  250M  0 disk 
sdb      8:16   0  250M  0 disk 
sdc      8:32   0  250M  0 disk 
sdd      8:48   0  250M  0 disk 
sde      8:64   0  250M  0 disk 
sdf      8:80   0   40G  0 disk 
└─sdf1   8:81   0   40G  0 part 
```

### собрать R0/R5/R10 на выбор

Занулим суперблоки:

```
sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
[vagrant@localhost ~]$ sudo mdadm --zero-superblock --force /dev/sd{b,c,d,e,a}
mdadm: Unrecognised md component device - /dev/sdb
mdadm: Unrecognised md component device - /dev/sdc
mdadm: Unrecognised md component device - /dev/sdd
mdadm: Unrecognised md component device - /dev/sde
mdadm: Unrecognised md component device - /dev/sda
```
Создаем рейд 6

```
[vagrant@localhost ~]$ sudo mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,a}
mdadm: layout defaults to left-symmetric
mdadm: layout defaults to left-symmetric
mdadm: chunk size defaults to 512K
mdadm: size set to 253952K
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md0 started.
```

Проверим что RAID собралсā нормалþно:

```
[vagrant@localhost ~]$ cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid6 sda[4] sde[3] sdd[2] sdc[1] sdb[0]
      761856 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/5] [UUUUU]

```
Проверяем характеристики рейда:

```
vagrant@localhost ~]$ sudo mdadm -D /dev/md0
/dev/md0:
           Version : 1.2
     Creation Time : Sun Jan  1 14:35:34 2023
        Raid Level : raid6
        Array Size : 761856 (744.00 MiB 780.14 MB)
     Used Dev Size : 253952 (248.00 MiB 260.05 MB)
      Raid Devices : 5
     Total Devices : 5
       Persistence : Superblock is persistent

       Update Time : Sun Jan  1 14:35:40 2023
             State : clean 
    Active Devices : 5
   Working Devices : 5
    Failed Devices : 0
     Spare Devices : 0

            Layout : left-symmetric
        Chunk Size : 512K

Consistency Policy : resync

              Name : localhost.localdomain:0  (local to host localhost.localdomain)
              UUID : cc00d5b1:f34e140f:a876a3fc:8759d932
            Events : 17

    Number   Major   Minor   RaidDevice State
       0       8       16        0      active sync   /dev/sdb
       1       8       32        1      active sync   /dev/sdc
       2       8       48        2      active sync   /dev/sdd
       3       8       64        3      active sync   /dev/sde
       4       8        0        4      active sync   /dev/sda
```

### Создание конфигурационного файла mdadm.conf

```
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
```

Проверяем содержимое mdadm.conf:

```
[root@localhost vagrant]# cat /etc/mdadm/mdadm.conf 
DEVICE partitions
ARRAY /dev/md0 level=raid6 num-devices=5 metadata=1.2 name=localhost.localdomain:0 UUID=cc00d5b1:f34e140f:a876a3fc:8759d932
```

### Сломать/починить RAID

Ломаю массив, искуственно переводя в статус "fail" один из дисков, проверяю статус массива:

```
mdadm /dev/md0 --fail /dev/sdc
```

```
[root@localhost vagrant]# cat /proc/mdstat
Personalities : [raid6] [raid5] [raid4] 
md0 : active raid6 sda[4] sde[3] sdd[2] sdc[1](F) sdb[0]
      761856 blocks super 1.2 level 6, 512k chunk, algorithm 2 [5/4] [U_UUU]
```

Восстанавливаю рейд, сначала удалив диск из массива, а затем "вставив" его же назад:

```
[root@localhost vagrant]# mdadm --remove /dev/md0 /dev/sdc
mdadm: hot removed /dev/sdc from /dev/md0
mdadm --add /dev/md0 /dev/sdc
```

После смотрим на дебаг:

```
$ watch --interval=1 cat /proc/mdstat
```

### Создать GPT раздел, пять партиций и смонтировать их на диск

Создаем раздел GPT на RAID
```
parted -s /dev/md0 mklabel gpt
```
Создаем партиции:
```
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
```

```
[root@localhost raid]# lsblk
NAME      MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINT
sda         8:0    0   250M  0 disk  
└─md0       9:0    0   744M  0 raid6 
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
sdb         8:16   0   250M  0 disk  
└─md0       9:0    0   744M  0 raid6 
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
sdc         8:32   0   250M  0 disk  
└─md0       9:0    0   744M  0 raid6 
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
sdd         8:48   0   250M  0 disk  
└─md0       9:0    0   744M  0 raid6 
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
sde         8:64   0   250M  0 disk  
└─md0       9:0    0   744M  0 raid6 
  ├─md0p1 259:0    0   147M  0 md    /raid/part1
  ├─md0p2 259:1    0 148.5M  0 md    /raid/part2
  ├─md0p3 259:2    0   150M  0 md    /raid/part3
  ├─md0p4 259:3    0 148.5M  0 md    /raid/part4
  └─md0p5 259:4    0   147M  0 md    /raid/part5
sdf         8:80   0    40G  0 disk  
└─sdf1      8:81   0    40G  0 part  /
```


Делаем отдельный файл, который говорит, что нужно собрать рейд:

```
cat setup.sh 
#!/bin/env bash
yum update -y
yum install -y mdadm smartmontools hdparm gdisk
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm --create --verbose /dev/md0 -l 6 -n 5 /dev/sd{b,c,d,e,f}
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done
```

Добавляем инструкцию в Vagrantfile:

```
box.vm.provision "shell", path: "setup.sh"
```

Выполняем reload:

```
/OTUS_Linux_Prof/Lesson2/otus-linux$ vagrant reload --provision
```

### ⭐ Vagrantfile, который сразу собирает систему с подключенным рейдом и смонтированными разделами.

Отредактируем Vagrantfile, укажем инструкцию для запуска скрипта и сам скрипт, который соберет 10 рейд:

```
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :otuslinux => {
        :box_name => "centos/7",
        :ip_addr => '192.168.11.101',
	:disks => {
		:sata1 => {
			:dfile => './sata1.vdi',
			:size => 250,
			:port => 1
		},
		:sata2 => {
                        :dfile => './sata2.vdi',
                        :size => 250,
			:port => 2
		},
                :sata3 => {
                        :dfile => './sata3.vdi',
                        :size => 250,
                        :port => 3
                },
                :sata4 => {
                        :dfile => './sata4.vdi',
                        :size => 250,
                        :port => 4
                },
                :sata5 => {
                        :dfile => './sata5.vdi',
                        :size => 250,
                        :port => 5
                }

	}
  },
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          box.vm.network "private_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            	  vb.customize ["modifyvm", :id, "--memory", "1024"]
                  needsController = false
		  boxconfig[:disks].each do |dname, dconf|
			  unless File.exist?(dconf[:dfile])
				vb.customize ['createhd', '--filename', dconf[:dfile], '--variant', 'Fixed', '--size', dconf[:size]]
                                needsController =  true
                          end

		  end
                  if needsController == true
                     vb.customize ["storagectl", :id, "--name", "SATA", "--add", "sata" ]
                     boxconfig[:disks].each do |dname, dconf|
                         vb.customize ['storageattach', :id,  '--storagectl', 'SATA', '--port', dconf[:port], '--device', 0, '--type', 'hdd', '--medium', dconf[:dfile]]
                     end
                  end
          end

 	  box.vm.provision "shell", path: "setup.sh"
      end
  end
end

```

```
mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson2/otus-linux$ cat setup.sh 
#!/bin/env bash
yum update -y
yum install -y mdadm smartmontools hdparm gdisk
mdadm --zero-superblock --force /dev/sd{b,c,d,e,f}
mdadm --create --verbose /dev/md0 -l 10 -n 5 /dev/sd{b,c,d,e,f}
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
parted -s /dev/md0 mklabel gpt
parted /dev/md0 mkpart primary ext4 0% 20%
parted /dev/md0 mkpart primary ext4 20% 40%
parted /dev/md0 mkpart primary ext4 40% 60%
parted /dev/md0 mkpart primary ext4 60% 80%
parted /dev/md0 mkpart primary ext4 80% 100%
for i in $(seq 1 5); do sudo mkfs.ext4 /dev/md0p$i; done
mkdir -p /raid/part{1,2,3,4,5}
for i in $(seq 1 5); do mount /dev/md0p$i /raid/part$i; done

```

Проверим:

```
[vagrant@localhost ~]$ lsblk 
NAME      MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINT
sda         8:0    0    40G  0 disk   
└─sda1      8:1    0    40G  0 part   /
sdb         8:16   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:0    0 122.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 122.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   125M  0 md     /raid/part3
  ├─md0p4 259:3    0 122.5M  0 md     /raid/part4
  └─md0p5 259:4    0 122.5M  0 md     /raid/part5
sdc         8:32   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:0    0 122.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 122.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   125M  0 md     /raid/part3
  ├─md0p4 259:3    0 122.5M  0 md     /raid/part4
  └─md0p5 259:4    0 122.5M  0 md     /raid/part5
sdd         8:48   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:0    0 122.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 122.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   125M  0 md     /raid/part3
  ├─md0p4 259:3    0 122.5M  0 md     /raid/part4
  └─md0p5 259:4    0 122.5M  0 md     /raid/part5
sde         8:64   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:0    0 122.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 122.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   125M  0 md     /raid/part3
  ├─md0p4 259:3    0 122.5M  0 md     /raid/part4
  └─md0p5 259:4    0 122.5M  0 md     /raid/part5
sdf         8:80   0   250M  0 disk   
└─md0       9:0    0   620M  0 raid10 
  ├─md0p1 259:0    0 122.5M  0 md     /raid/part1
  ├─md0p2 259:1    0 122.5M  0 md     /raid/part2
  ├─md0p3 259:2    0   125M  0 md     /raid/part3
  ├─md0p4 259:3    0 122.5M  0 md     /raid/part4
  └─md0p5 259:4    0 122.5M  0 md     /raid/part5

```
























































</details>