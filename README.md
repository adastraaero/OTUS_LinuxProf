
## Выполнение домашних работ по курсу OTUS - Administrator Linux.Professional




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
  └─md0p5 259:4    btrfs0   147M  0 md    /raid/part5
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


## Lesson3-4

<details>
При выполнении ДЗ использовались данные по настройке ZFS из статьи https://www.symmcom.com/docs/how-tos/storages/how-to-install-zfs-on-centos-7


на имеющемся образе: 

- уменьшить том под / до 8G

- выделить том под /var + в mirror

- выделить том под /home

- /home - сделать том для снэпшотов

- прописать монтирование в fstab

#### и попробовать с разными опциями и разными файловыми системами ( на выбор):

- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановится со снэпшота
- залоггировать работу можно с помощью утилиты script

⭐  на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt




#### уменьшить том под / до 8G

Данные по системе:
```
[root@localhost ~]# df -h
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00   38G  838M   37G   3% /
devtmpfs                         109M     0  109M   0% /dev
tmpfs                            118M     0  118M   0% /dev/shm
tmpfs                            118M  4.5M  114M   4% /run
tmpfs                            118M     0  118M   0% /sys/fs/cgroup
/dev/sda2                       1014M   63M  952M   7% /boot
tmpfs                             24M     0   24M   0% /run/user/1000
```

```
[root@localhost ~]# lsblk 
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00 253:0    0 37.5G  0 lvm  /
  └─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
sdb                       8:16   0   10G  0 disk 
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

Создаём:
 - временный физический том для / раздела
 - группу томов VG02
 - временный том


```
pvcreate /dev/sdb
```

```
[root@localhost ~]# vgcreate VG02 /dev/sdb
  Volume group "VG02" successfully created
```

```
[root@localhost ~]# lvcreate -n xtmp -l+100%FREE /dev/VG02
  Logical volume "xtmp" created.
```

Создаём ФС xfs и монтируем:

```
[root@localhost ~]# mkfs.xfs /dev/VG02/xtmp && mount /dev/VG02/xtmp /mnt
meta-data=/dev/VG02/xtmp         isize=512    agcount=4, agsize=655104 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2620416, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```

Переносим данные:

```
[root@localhost ~]# xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of localhost.localdomain:/
xfsdump: dump date: Tue Jan  3 12:37:23 2023
xfsdump: session id: 9c73702c-820a-4a8f-b402-bf04cd18d3a7
xfsdump: session label: ""
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
xfsdump: ino map construction complete
xfsdump: estimated dump size: 840029312 bytes
xfsdump: creating dump session media file 0 (media 0, file 0)
xfsdump: dumping ino map
xfsdump: dumping directories
xfsrestore: examining media file 0
xfsrestore: dump description: 
xfsrestore: hostname: localhost.localdomain
xfsrestore: mount point: /
xfsrestore: volume: /dev/mapper/VolGroup00-LogVol00
xfsrestore: session time: Tue Jan  3 12:37:23 2023
xfsrestore: level: 0
xfsrestore: session label: ""
xfsrestore: media label: ""
xfsrestore: file system id: b60e9498-0baa-4d9f-90aa-069048217fee
xfsrestore: session id: 9c73702c-820a-4a8f-b402-bf04cd18d3a7
xfsrestore: media id: 403bd2f6-b2d8-48af-b29f-e84101a92961
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 2673 directories and 23425 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 817206736 bytes
xfsdump: dump size (non-dir files) : 804137608 bytes
xfsdump: dump complete: 17 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 17 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```

Проверяем:

```
[root@localhost ~]# ls /mnt
bin  boot  dev  etc  home  lib  lib64  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
```

Сымитируем текущий root -> сделаем в него chroot и обновим grub:

```
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@localhost ~]# chroot /mnt/
[root@localhost /]# 
```

```
[root@localhost /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done
```

Обновим образ initrd:

```
[root@localhost /]# cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done
Executing: /sbin/dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'mdraid' will not be installed, because command 'mdadm' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'mdraid' will not be installed, because command 'mdadm' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
*** Including module: bash ***
*** Including module: nss-softokn ***
*** Including module: i18n ***
*** Including module: drm ***
*** Including module: plymouth ***
*** Including module: dm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 60-persistent-storage-dm.rules
Skipping udev rule: 55-dm.rules
*** Including module: kernel-modules ***
Omitting driver floppy
*** Including module: lvm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 56-lvm.rules
Skipping udev rule: 60-persistent-storage-lvm.rules
*** Including module: qemu ***
*** Including module: resume ***
*** Including module: rootfs-block ***
*** Including module: terminfo ***
*** Including module: udev-rules ***
Skipping udev rule: 40-redhat-cpu-hotplug.rules
Skipping udev rule: 91-permissions.rules
*** Including module: biosdevname ***
*** Including module: systemd ***
*** Including module: usrmount ***
*** Including module: base ***
*** Including module: fs-lib ***
*** Including module: shutdown ***
*** Including modules done ***
*** Installing kernel module dependencies and firmware ***
*** Installing kernel module dependencies and firmware done ***
*** Resolving executable dependencies ***
*** Resolving executable dependencies done***
*** Hardlinking files ***
*** Hardlinking files done ***
*** Stripping files ***
*** Stripping files done ***
*** Generating early-microcode cpio image contents ***
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***
```

Изменяем адрес корня и проверяем:

```
sed -i 's/VolGroup00\/LogVol00/VG02\/xtmp/g' /boot/grub2/grub.cfg

[root@localhost boot]# grep VolGroup00 /boot/grub2/grub.cfg
	linux16 /vmlinuz-3.10.0-862.2.3.el7.x86_64 root=/dev/mapper/VG02-xtmp ro no_timer_check console=tty0 console=ttyS0,115200n8 net.ifnames=0 biosdevname=0 elevator=noop crashkernel=auto rd.lvm.lv=VG02/xtmp rd.lvm.lv=VolGroup00/LogVol01 rhgb quiet 

```

Перезагружаемся:
```
[root@localhost boot]# exit
exit
[root@localhost ~]# reboot

```



Просле ребута:

```
[vagrant@localhost ~]$ lsblk
NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                       8:0    0   40G  0 disk 
├─sda1                    8:1    0    1M  0 part 
├─sda2                    8:2    0    1G  0 part /boot
└─sda3                    8:3    0   39G  0 part 
  ├─VolGroup00-LogVol01 253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LogVol00 253:2    0 37.5G  0 lvm  
sdb                       8:16   0   10G  0 disk 
└─VG02-xtmp             253:0    0   10G  0 lvm  /
sdc                       8:32   0    2G  0 disk 
sdd                       8:48   0    1G  0 disk 
sde                       8:64   0    1G  0 disk 
```

Удаляем старый том:

```
[vagrant@localhost ~]$ lvremove /dev/VolGroup00/LogVol00
Do you really want to remove active logical volume VolGroup00/LogVol00? [y/n]: y
  Logical volume "LogVol00" successfully removed
```

Создаём новый том поменьше:

```
[root@localhost vagrant]# lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
WARNING: xfs signature detected on /dev/VolGroup00/LogVol00 at offset 0. Wipe it? [y/n]: y
  Wiping xfs signature on /dev/VolGroup00/LogVol00.
  Logical volume "LogVol00" created.
```

На новом томе создаём ФС xfs:

```
[root@localhost vagrant]# mkfs.xfs /dev/VolGroup00/LogVol00
meta-data=/dev/VolGroup00/LogVol00 isize=512    agcount=4, agsize=524288 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=2097152, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```

Монтирую новый том и переношу данные:

```
[root@localhost vagrant]# mount /dev/VolGroup00/LogVol00 /mnt 
[root@localhost vagrant]# xfsdump -J - /dev/VG02/xtmp | xfsrestore -J - /mnt
xfsdump: using file dump (drive_simple) strategy
xfsdump: version 3.1.7 (dump format 3.0)
xfsdump: level 0 dump of localhost.localdomain:/
xfsdump: dump date: Tue Jan  3 15:28:31 2023
xfsdump: session id: 0f7ee57d-c18c-489f-8122-61253c32bb1d
xfsdump: session label: ""
xfsrestore: using file dump (drive_simple) strategy
xfsrestore: version 3.1.7 (dump format 3.0)
xfsrestore: searching media for dump
xfsdump: ino map phase 1: constructing initial dump list
xfsdump: ino map phase 2: skipping (no pruning necessary)
xfsdump: ino map phase 3: skipping (only one dump stream)
xfsdump: ino map construction complete
xfsdump: estimated dump size: 838556352 bytes
xfsdump: creating dump session media file 0 (media 0, file 0)
xfsdump: dumping ino map
xfsdump: dumping directories
xfsrestore: examining media file 0
xfsrestore: dump description: 
xfsrestore: hostname: localhost.localdomain
xfsrestore: mount point: /
xfsrestore: volume: /dev/mapper/VG02-xtmp
xfsrestore: session time: Tue Jan  3 15:28:31 2023
xfsrestore: level: 0
xfsrestore: session label: ""
xfsrestore: media label: ""
xfsrestore: file system id: 972bf9cc-774d-4932-94b8-269a957119b7
xfsrestore: session id: 0f7ee57d-c18c-489f-8122-61253c32bb1d
xfsrestore: media id: 58e806a7-bac8-4dea-8fcf-3936992f0795
xfsrestore: searching media for directory dump
xfsrestore: reading directories
xfsdump: dumping non-directory files
xfsrestore: 2677 directories and 23430 entries processed
xfsrestore: directory post-processing
xfsrestore: restoring non-directory files
xfsdump: ending media file
xfsdump: media file size 815869816 bytes
xfsdump: dump size (non-dir files) : 802797008 bytes
xfsdump: dump complete: 15 seconds elapsed
xfsdump: Dump Status: SUCCESS
xfsrestore: restore complete: 15 seconds elapsed
xfsrestore: Restore Status: SUCCESS
```


Готовим виртуальный рут для обратного переезда, делаю chroot, обновляем загрузчик:

```
[root@localhost vagrant]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done

[root@localhost vagrant]# for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
[root@localhost vagrant]#  chroot /mnt/
[root@localhost /]# grub2-mkconfig -o /boot/grub2/grub.cfg
Generating grub configuration file ...
Found linux image: /boot/vmlinuz-3.10.0-862.2.3.el7.x86_64
Found initrd image: /boot/initramfs-3.10.0-862.2.3.el7.x86_64.img
done


```

Обновим образ initrd:

```
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g; s/.img//g"` --force; done

xecuting: /sbin/dracut -v initramfs-3.10.0-862.2.3.el7.x86_64.img 3.10.0-862.2.3.el7.x86_64 --force
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'mdraid' will not be installed, because command 'mdadm' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
dracut module 'busybox' will not be installed, because command 'busybox' could not be found!
dracut module 'crypt' will not be installed, because command 'cryptsetup' could not be found!
dracut module 'dmraid' will not be installed, because command 'dmraid' could not be found!
dracut module 'dmsquash-live-ntfs' will not be installed, because command 'ntfs-3g' could not be found!
dracut module 'mdraid' will not be installed, because command 'mdadm' could not be found!
dracut module 'multipath' will not be installed, because command 'multipath' could not be found!
*** Including module: bash ***
*** Including module: nss-softokn ***
*** Including module: i18n ***
*** Including module: drm ***
*** Including module: plymouth ***
*** Including module: dm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 60-persistent-storage-dm.rules
Skipping udev rule: 55-dm.rules
*** Including module: kernel-modules ***
Omitting driver floppy
*** Including module: lvm ***
Skipping udev rule: 64-device-mapper.rules
Skipping udev rule: 56-lvm.rules
Skipping udev rule: 60-persistent-storage-lvm.rules
*** Including module: qemu ***
*** Including module: resume ***
*** Including module: rootfs-block ***
*** Including module: terminfo ***
*** Including module: udev-rules ***
Skipping udev rule: 40-redhat-cpu-hotplug.rules
Skipping udev rule: 91-permissions.rules
*** Including module: biosdevname ***
*** Including module: systemd ***
*** Including module: usrmount ***
*** Including module: base ***
*** Including module: fs-lib ***
*** Including module: shutdown ***
*** Including modules done ***
*** Installing kernel module dependencies and firmware ***
*** Installing kernel module dependencies and firmware done ***
*** Resolving executable dependencies ***
*** Resolving executable dependencies done***
*** Hardlinking files ***
*** Hardlinking files done ***
*** Stripping files ***
*** Stripping files done ***
*** Generating early-microcode cpio image contents ***
*** No early-microcode cpio image needed ***
*** Store current command line parameters ***
*** Creating image file ***
*** Creating image file done ***
*** Creating initramfs image file '/boot/initramfs-3.10.0-862.2.3.el7.x86_64.img' done ***

```


#### выделить том под /var + в mirror

Создаём физический том и группу томов под /var:

```
 [root@localhost boot]# pvcreate /dev/sdc /dev/sdd
  Physical volume "/dev/sdc" successfully created.
  Physical volume "/dev/sdd" successfully created.

[root@localhost boot]# vgcreate vg_var /dev/sdc /dev/sdd
  Volume group "vg_var" successfully created
```

Создаём сам том:
ml - указывает количество зеркал.

```
[root@localhost boot]# lvcreate -L 950M -m1 -n lv_var vg_var
  Rounding up size to full physical extent 952.00 MiB
  Logical volume "lv_var" created.
```


На новом томе создаём ФС ext4:


```
[root@localhost boot]# mkfs.ext4 /dev/vg_var/lv_var
mke2fs 1.42.9 (28-Dec-2013)
Filesystem label=
OS type: Linux
Block size=4096 (log=2)
Fragment size=4096 (log=2)
Stride=0 blocks, Stripe width=0 blocks
60928 inodes, 243712 blocks
12185 blocks (5.00%) reserved for the super user
First data block=0
Maximum filesystem blocks=249561088
8 block groups
32768 blocks per group, 32768 fragments per group
7616 inodes per group
Superblock backups stored on blocks: 
	32768, 98304, 163840, 229376

Allocating group tables: done                            
Writing inode tables: done                            
Creating journal (4096 blocks): done
Writing superblocks and filesystem accounting information: done
```

Монтирую новый том и переношу данные:
```
[root@localhost boot]# mount /dev/vg_var/lv_var /mnt

[root@localhost boot]# cp -aR /var/* /mnt/
[root@localhost boot]# rsync -avHPSAX /var/ /mnt/

```

Проверяем:

```
[root@localhost boot]# ls -la /mnt/
total 84
drwxr-xr-x. 19 root root  4096 Jan  3 16:07 .
drwxr-xr-x. 17 root root   224 Jan  3 15:28 ..
drwxr-xr-x.  2 root root  4096 Apr 11  2018 adm
drwxr-xr-x.  5 root root  4096 May 12  2018 cache
drwxr-xr-x.  3 root root  4096 May 12  2018 db
drwxr-xr-x.  3 root root  4096 May 12  2018 empty
drwxr-xr-x.  2 root root  4096 Apr 11  2018 games
drwxr-xr-x.  2 root root  4096 Apr 11  2018 gopher
drwxr-xr-x.  3 root root  4096 May 12  2018 kerberos
drwxr-xr-x. 28 root root  4096 Jan  3 15:28 lib
drwxr-xr-x.  2 root root  4096 Apr 11  2018 local
lrwxrwxrwx.  1 root root    11 Jan  3 15:28 lock -> ../run/lock
drwxr-xr-x.  8 root root  4096 Jan  3 15:21 log
drwx------.  2 root root 16384 Jan  3 16:04 lost+found
lrwxrwxrwx.  1 root root    10 Jan  3 15:28 mail -> spool/mail
drwxr-xr-x.  2 root root  4096 Apr 11  2018 nis
drwxr-xr-x.  2 root root  4096 Apr 11  2018 opt
drwxr-xr-x.  2 root root  4096 Apr 11  2018 preserve
lrwxrwxrwx.  1 root root     6 Jan  3 15:28 run -> ../run
drwxr-xr-x.  8 root root  4096 May 12  2018 spool
drwxrwxrwt.  4 root root  4096 Jan  3 16:00 tmp
drwxr-xr-x.  2 root root  4096 Apr 11  2018 yp
```

Делаем резервную копию с прежнего места:

```
[root@localhost boot]# mkdir /tmp/oldvar && mv /var/* /tmp/oldvar

```

Размонтируем с временного и примонтирую в целевую точку:

```
[root@localhost boot]# umount /mnt && mount /dev/vg_var/lv_var /var
```

Обновляем fstab:

[root@localhost boot]# echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab


Выходим из chroot  и делаем ребут:

```
[root@localhost boot]# exit
exit
[root@localhost vagrant]# reboot

```
Удаляем временный раздел/группу томов/ физичекий том

```
[root@localhost vagrant]# lvremove /dev/VG02/xtmp
Do you really want to remove active logical volume VG02/xtmp? [y/n]: y
  Logical volume "xtmp" successfully removed

[root@localhost vagrant]# vgremove /dev/VG02
  Volume group "VG02" successfully removed


[root@localhost vagrant]# pvremove /dev/sdb
  Labels on physical volume "/dev/sdb" successfully wiped.


```

#### Выделить том под /home

```
[root@localhost vagrant]# lvcreate -n LV_Home -L 2G /dev/VolGroup00
  Logical volume "LV_Home" created.

```

Создаём ФС xfs:

```
[root@localhost vagrant]# mkfs.xfs /dev/VolGroup00/LV_Home
meta-data=/dev/VolGroup00/LV_Home isize=512    agcount=4, agsize=131072 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0, sparse=0
data     =                       bsize=4096   blocks=524288, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
```

Монтируем во временную точку для переноса данных:

```
[root@localhost vagrant]# mount /dev/VolGroup00/LV_Home /mnt/
```

Переносим данные, удаляем их с прежнего места, размонтируем объем от целевой точки и примонтирем новый объем, обновляем запись в fstab:
```
[root@localhost vagrant]# rsync -avHPSAX --quiet /home/ /mnt/
[root@localhost vagrant]#  rm -rf /home/*
[root@localhost vagrant]#  umount /mnt && mount /dev/VolGroup00/LV_Home /home/
[root@localhost vagrant]# echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```

#### home - сделать том для снэпшотов

Создаём файлы для теста работы снэпшота:

```
[root@localhost vagrant]# touch /home/file{1..20}

[root@localhost vagrant]# ls /home/
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9  vagrant

```

Делаем снапшот:

```
[root@localhost vagrant]# lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LV_Home
  Rounding up size to full physical extent 128.00 MiB
  Logical volume "home_snap" created.

```

Удаляем часть тестовых файлов:

```
[root@localhost vagrant]# rm -f /home/file{2..19}
[root@localhost vagrant]# ls /home/
file1  file20  vagrant
```

Отмонтируем домашнюю директорию:

```
umount /home
```
Произвожу восстановление файлов и получаю ошибку:

```
[root@localhost vagrant]# lvconvert --merge /dev/VolGroup00/home_snap
  Command on LV VolGroup00/home_snap is invalid on LV with properties: lv_is_merging_cow .

```

Решение - Перезапустить мерж, указав аргументом наименование VG:

```
lvchange  --refresh VolGroup00
```


Примонтируем обратно:

[root@localhost vagrant]# mount /home
[root@localhost vagrant]# ls /home/
file1  file10  file11  file12  file13  file14  file15  file16  file17  file18  file19  file2  file20  file3  file4  file5  file6  file7  file8  file9  vagrant


#####  ⭐  на нашей куче дисков попробовать поставить btrfs/zfs - с кешем, снэпшотами - разметить здесь каталог /opt

Статья по настройке ZFS через KABI - https://www.symmcom.com/docs/how-tos/storages/how-to-install-zfs-on-centos-7

Добавляем репозиторий и указываем какой метод установки использовать:

```
yum install http://download.zfsonlinux.org/epel/zfs-release.el7_5.noarch.rpm -y

vim /etc/yum.repos.d/zfs.repo

[zfs]
name=ZFS on Linux for EL7 - dkms
baseurl=https://download.zfsonlinux.org/epel/7.4/$basearch/
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

[zfs-kmod]
name=ZFS on Linux for EL7 - kmod
baseurl=https://download.zfsonlinux.org/epel/7.4/kmod/$basearch/
enabled=1
metadata_expire=7d
gpgcheck=1 gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux


[zfs]
name=ZFS on Linux for EL7 - dkms
baseurl=https://download.zfsonlinux.org/epel/7.4/$basearch/
enabled=0
metadata_expire=7d
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

[zfs-kmod]
name=ZFS on Linux for EL7 - kmod
baseurl=https://download.zfsonlinux.org/epel/7.4/kmod/$basearch/
enabled=1
metadata_expire=7d
gpgcheck=1 gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux

lsmod | grep zfs

```

Проверяем загрузку модуля ZFS в ядро:

```
sudo lsmod | grep zfs
```
Не работает(.Загружаем вручную:

```
[root@localhost vagrant]# sudo lsmod | grep zfs
zfs                  3564468  0 
zunicode              331170  1 zfs
zavl                   15236  1 zfs
icp                   270148  1 zfs
zcommon                73440  1 zfs
znvpair                89131  2 zfs,zcommon
spl                   102412  4 icp,zfs,zcommon,znvpair

```

Создаем зеркало из 2 дисков с именем ZFSpool:

```
[root@localhost vagrant]# zpool create -f ZFSpool mirror /dev/sdb /dev/sde
[root@localhost vagrant]# zpool status
  pool: ZFSpool
 state: ONLINE
  scan: none requested
config:

	NAME        STATE     READ WRITE CKSUM
	ZFSpool     ONLINE       0     0     0
	  mirror-0  ONLINE       0     0     0
	    sdb     ONLINE       0     0     0
	    sde     ONLINE       0     0     0

errors: No known data errors
```

Смотрим куда смонтировался пул:

```
[root@localhost vagrant]# zfs list
NAME      USED  AVAIL  REFER  MOUNTPOINT
ZFSpool   252K   880M    24K  /ZFSpool


[root@localhost vagrant]# zfs list
NAME      USED  AVAIL  REFER  MOUNTPOINT
ZFSpool   252K   880M    24K  /ZFSpool
[root@localhost vagrant]# lsblk 
NAME                     MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda                        8:0    0   40G  0 disk 
├─sda1                     8:1    0    1M  0 part 
├─sda2                     8:2    0    1G  0 part /boot
└─sda3                     8:3    0   39G  0 part 
  ├─VolGroup00-LogVol00  253:0    0    8G  0 lvm  /
  ├─VolGroup00-LogVol01  253:1    0  1.5G  0 lvm  [SWAP]
  └─VolGroup00-LV_Home   253:7    0    2G  0 lvm  /home
sdb                        8:16   0   10G  0 disk 
├─sdb1                     8:17   0   10G  0 part 
└─sdb9                     8:25   0    8M  0 part 
sdc                        8:32   0    2G  0 disk 
├─vg_var-lv_var_rmeta_0  253:2    0    4M  0 lvm  
│ └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_0 253:3    0  952M  0 lvm  
  └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
sdd                        8:48   0    1G  0 disk 
├─vg_var-lv_var_rmeta_1  253:4    0    4M  0 lvm  
│ └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
└─vg_var-lv_var_rimage_1 253:5    0  952M  0 lvm  
  └─vg_var-lv_var        253:6    0  952M  0 lvm  /var
sde                        8:64   0    1G  0 disk 
├─sde1                     8:65   0 1014M  0 part 
└─sde9                     8:73   0    8M  0 part 

```

Видим наши диски которые задействованы в zfs пуле /dev/sdb и /dev/sde.
Так как диски разных размеров то массив имеет размер самого маленького из дисков.
А доступный объем 880 МБ.

```
[root@localhost vagrant]# df -h
Filesystem                       Size  Used Avail Use% Mounted on
/dev/mapper/VolGroup00-LogVol00  8.0G  918M  7.1G  12% /
devtmpfs                         110M     0  110M   0% /dev
tmpfs                            118M     0  118M   0% /dev/shm
tmpfs                            118M  4.6M  114M   4% /run
tmpfs                            118M     0  118M   0% /sys/fs/cgroup
/dev/mapper/VolGroup00-LV_Home   2.0G   33M  2.0G   2% /home
/dev/mapper/vg_var-lv_var        922M  221M  637M  26% /var
/dev/sda2                       1014M   61M  954M   6% /boot
tmpfs                             24M     0   24M   0% /run/user/1000
ZFSpool                          880M     0  880M   0% /ZFSpool

```

Переходим в   /ZFSpool  и создаём там файлы:


```
[root@localhost vagrant]# cd /ZFSpool/
[root@localhost ZFSpool]# touch test1
[root@localhost ZFSpool]# ll
total 1
-rw-r--r--. 1 root root 0 Jan  3 16:56 test1

```

Создаём снапшоты и смотрим их расположение:

Снимки файловых систем будут доступны в каталоге .zfs/snapshot в корне файловой системы. 
Но чтобы увидеть эту папку нужно выполнить команду: zfs set snapdir=visible ZFSpool.

```
[root@localhost ZFSpool]# zfs snapshot ZFSpool@test_1

[root@localhost ZFSpool]# zfs list -t snapshot
NAME             USED  AVAIL  REFER  MOUNTPOINT
ZFSpool@test_1     0B      -  25.5K  -

```

Удаляем снапшоты:

```
[root@localhost opt]# zfs destroy ZFSpool@test_1
[root@localhost opt]# zfs list -t snapshot
no datasets available
```




Монтируем наш пул в каталог /opt:

```
[root@localhost opt]# zfs set mountpoint=/opt ZFSpool


[root@localhost opt]# zfs list
NAME      USED  AVAIL  REFER  MOUNTPOINT
ZFSpool   118K   880M  25.5K  /opt

```
</details>

## Lesson5

<details>

### Задание:

Определить алгоритм с наилучшим сжатием  
Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);  
Создать 4 файловых системы на каждой применить свой алгоритм сжатия;  
Для сжатия использовать либо текстовый файл, либо группу файлов:  
Определить настройки пула  
С помощью команды zfs import собрать pool ZFS;  
Командами zfs определить настройки:  
    - размер хранилища;  
    - тип pool;  
    - значение recordsize;  
    - какое сжатие используется;  
    - какая контрольная сумма используется.  
Работа со снапшотами скопировать файл из удаленной директории.   https://drive.google.com/file/d/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG/view?usp=sharing   
восстановить файл локально. zfs receive  
найти зашифрованное сообщение в файле secret_message.  

Для конфигурации сервера (установки и настройки ZFS) необходимо написать отдельный Bash-скрипт и добавить его в Vagrantfile  

#### Определение алгоритма с наилучшим сжатием

Смотрим список всех дисков, которые есть в виртуальной машине:

```
root@localhost ~]# lsblk
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda      8:0    0  512M  0 disk 
sdb      8:16   0  512M  0 disk 
sdc      8:32   0  512M  0 disk 
sdd      8:48   0  512M  0 disk 
sde      8:64   0  512M  0 disk 
sdf      8:80   0  512M  0 disk 
sdg      8:96   0  512M  0 disk 
sdh      8:112  0  512M  0 disk 
sdi      8:128  0   40G  0 disk 
└─sdi1   8:129  0   40G  0 part /
```

Создаём 4 пула из двух дисков в режиме RAID 1:

```
[root@localhost ~]# zpool create otus1 mirror /dev/sdb /dev/sdc
[root@localhost ~]# zpool create otus2 mirror /dev/sdd /dev/sde
[root@localhost ~]# zpool create otus3 mirror /dev/sdf /dev/sdg
[root@localhost ~]# zpool create otus4 mirror /dev/sdh /dev/sda
```

Смотрим информацию о пулах:

```
[root@localhost ~]# zpool list
NAME    SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus1   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus2   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus3   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus4   480M  91.5K   480M        -         -     0%     0%  1.00x    ONLINE  -
```

Команда *zpool status* показывает информацию о каждом диске, состоянии сканирования и об
ошибках чтения, записи и совпадения хэш-сумм. Команда *zpool list* показывает информацию о размере пула,
количеству занятого и свободного места, дедупликации и т.д.

Добавим разные алгоритмы сжатия в каждую файловую систему:

```
[root@localhost ~]# zfs set compression=lzjb otus1
[root@localhost ~]# zfs set compression=lz4 otus2
[root@localhost ~]# zfs set compression=gzip-9 otus3
[root@localhost ~]# zfs set compression=zle otus4
```
Проверим, что все файловые системы имеют разные методы сжатия:
```
[root@localhost ~]# zfs get all | grep compression
otus1  compression           lzjb                   local
otus2  compression           lz4                    local
otus3  compression           gzip-9                 local
otus4  compression           zle                    local
```

Сжатие файлов будет работать только с файлами, которые были добавлены после включение настройки сжатия. 
Скачаем один и тот же текстовый файл во все пулы: 

```
[root@localhost ~]# for i in {1..4}; do wget -P /otus$i https://gutenberg.org/cache/epub/2600/pg2600.converter.log; done
--2023-01-07 17:43:50--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus1/pg2600.converter.log’

100%[==================================================================================================================================================================================================================>] 40,894,017   480KB/s   in 1m 41s 

2023-01-07 17:45:33 (396 KB/s) - ‘/otus1/pg2600.converter.log’ saved [40894017/40894017]

--2023-01-07 17:45:33--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus2/pg2600.converter.log’

100%[==================================================================================================================================================================================================================>] 40,894,017   897KB/s   in 74s    

2023-01-07 17:46:49 (542 KB/s) - ‘/otus2/pg2600.converter.log’ saved [40894017/40894017]

--2023-01-07 17:46:49--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus3/pg2600.converter.log’

100%[==================================================================================================================================================================================================================>] 40,894,017   339KB/s   in 1m 42s 

2023-01-07 17:48:32 (393 KB/s) - ‘/otus3/pg2600.converter.log’ saved [40894017/40894017]

--2023-01-07 17:48:32--  https://gutenberg.org/cache/epub/2600/pg2600.converter.log
Resolving gutenberg.org (gutenberg.org)... 152.19.134.47, 2610:28:3090:3000:0:bad:cafe:47
Connecting to gutenberg.org (gutenberg.org)|152.19.134.47|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 40894017 (39M) [text/plain]
Saving to: ‘/otus4/pg2600.converter.log’

100%[==================================================================================================================================================================================================================>] 40,894,017   881KB/s   in 93s    

2023-01-07 17:50:07 (429 KB/s) - ‘/otus4/pg2600.converter.log’ saved [40894017/40894017]
```

Проверим, что файл был скачан во все пулы:

```
[root@localhost ~]# ls -l /otus*
/otus1:
total 22037
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus2:
total 17981
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus3:
total 10953
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log

/otus4:
total 39964
-rw-r--r--. 1 root root 40894017 Jan  2 09:19 pg2600.converter.log
```
Уже на этом этапе видно, что самый оптимальный метод сжатия у нас используется в пуле otus3(gzip-9).


Проверим, сколько места занимает один и тот же файл в разных пулах и проверим степень сжатия файлов:
```
[root@localhost ~]# zfs list
NAME    USED  AVAIL     REFER  MOUNTPOINT
otus1  21.6M   330M     21.5M  /otus1
otus2  17.7M   334M     17.6M  /otus2
otus3  10.8M   341M     10.7M  /otus3
otus4  39.1M   313M     39.1M  /otus4
```

### Определение настроек пула

Скачиваем архив в домашний каталог: 

```
wget -O archive.tar.gz 'https://docs.google.com/uc?export=download&id=1KRBNW33QWqbvbVHa3hLJivOAt60yukkg'
```

Разархивируем его:
```
[vagrant@localhost ~]$ tar -xzvf archive.tar.gz
zpoolexport/
zpoolexport/filea
zpoolexport/fileb
```

Проверим, возможно ли импортировать данный каталог в пул:

```
[root@localhost vagrant]# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
 action: The pool can be imported using its name or numeric identifier.
 config:

	otus                                 ONLINE
	  mirror-0                           ONLINE
	    /home/vagrant/zpoolexport/filea  ONLINE
	    /home/vagrant/zpoolexport/fileb  ONLINE
```

 Данный вывод показывает нам имя пула, тип raid и его состав.   

Сделаем импорт данного пула к нам в ОС:

```
[root@localhost vagrant]# zpool import -d zpoolexport/ otus
```

```
[root@localhost vagrant]# zpool status
  pool: otus
 state: ONLINE
  scan: none requested
config:

	NAME                                 STATE     READ WRITE CKSUM
	otus                                 ONLINE       0     0     0
	  mirror-0                           ONLINE       0     0     0
	    /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
	    /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors
```

Запрос сразу всех параметров пула:

```
[root@localhost vagrant]# zfs get all otus
NAME  PROPERTY              VALUE                  SOURCE
otus  type                  filesystem             -
otus  creation              Fri May 15  4:00 2020  -
otus  used                  2.04M                  -
otus  available             350M                   -
otus  referenced            24K                    -
otus  compressratio         1.00x                  -
otus  mounted               yes                    -
otus  quota                 none                   default
otus  reservation           none                   default
otus  recordsize            128K                   local
otus  mountpoint            /otus                  default
otus  sharenfs              off                    default
otus  checksum              sha256                 local
otus  compression           zle                    local
otus  atime                 on                     default
otus  devices               on                     default
otus  exec                  on                     default
otus  setuid                on                     default
otus  readonly              off                    default
otus  zoned                 off                    default
otus  snapdir               hidden                 default
otus  aclinherit            restricted             default
otus  createtxg             1                      -
otus  canmount              on                     default
otus  xattr                 on                     default
otus  copies                1                      default
otus  version               5                      -
otus  utf8only              off                    -
otus  normalization         none                   -
otus  casesensitivity       sensitive              -
otus  vscan                 off                    default
otus  nbmand                off                    default
otus  sharesmb              off                    default
otus  refquota              none                   default
otus  refreservation        none                   default
otus  guid                  14592242904030363272   -
otus  primarycache          all                    default
otus  secondarycache        all                    default
otus  usedbysnapshots       0B                     -
otus  usedbydataset         24K                    -
otus  usedbychildren        2.01M                  -
otus  usedbyrefreservation  0B                     -
otus  logbias               latency                default
otus  objsetid              54                     -
otus  dedup                 off                    default
otus  mlslabel              none                   default
otus  sync                  standard               default
otus  dnodesize             legacy                 default
otus  refcompressratio      1.00x                  -
otus  written               24K                    -
otus  logicalused           1020K                  -
otus  logicalreferenced     12K                    -
otus  volmode               default                default
otus  filesystem_limit      none                   default
otus  snapshot_limit        none                   default
otus  filesystem_count      none                   default
otus  snapshot_count        none                   default
otus  snapdev               hidden                 default
otus  acltype               off                    default
otus  context               none                   default
otus  fscontext             none                   default
otus  defcontext            none                   default
otus  rootcontext           none                   default
otus  relatime              off                    default
otus  redundant_metadata    all                    default
otus  overlay               off                    default
otus  encryption            off                    default
otus  keylocation           none                   default
otus  keyformat             none                   default
otus  pbkdf2iters           0                      default
otus  special_small_blocks  0                      default
```

размер хранилища: 480M 
тип pool: mirror-0 
значение recordsize: 128K
какое сжатие используется: zle
какая контрольная сумма используется: sha256 


### Найти сообщение от преподавателей.

Скачаем файл, указанный в задании:

```
[root@localhost vagrant]# wget -O otus_task2.file 'https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG'
--2023-01-07 18:57:25--  https://docs.google.com/uc?export=download&id=1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG
Resolving docs.google.com (docs.google.com)... 74.125.131.194, 2a00:1450:4010:c0b::c2
Connecting to docs.google.com (docs.google.com)|74.125.131.194|:443... connected.
HTTP request sent, awaiting response... 303 See Other
Location: https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/33hpevo8kc2u2bibiqbqs0rq9sis9k2n/1673117775000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download&uuid=9085d409-f631-4e5e-935e-fb6cfba007e6 [following]
Warning: wildcards not supported in HTTP.
--2023-01-07 18:57:26--  https://doc-00-bo-docs.googleusercontent.com/docs/securesc/ha0ro937gcuc7l7deffksulhg5h7mbp1/33hpevo8kc2u2bibiqbqs0rq9sis9k2n/1673117775000/16189157874053420687/*/1gH8gCL9y7Nd5Ti3IRmplZPF1XjzxeRAG?e=download&uuid=9085d409-f631-4e5e-935e-fb6cfba007e6
Resolving doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)... 142.250.150.132, 2a00:1450:4010:c03::84
Connecting to doc-00-bo-docs.googleusercontent.com (doc-00-bo-docs.googleusercontent.com)|142.250.150.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 5432736 (5.2M) [application/octet-stream]
Saving to: ‘otus_task2.file’

100%[==================================================================================================================================================================================================================>] 5,432,736   20.5MB/s   in 0.3s   

2023-01-07 18:57:27 (20.5 MB/s) - ‘otus_task2.file’ saved [5432736/5432736]

```

Восстановим файловую систему из снапшота:

```
[root@localhost vagrant]# zfs receive otus/test@today < otus_task2.file
```

Далее, ищем в каталоге /otus/test файл с именем “secret_message”:

```
[root@localhost vagrant]# find /otus/test -name "secret_message"
/otus/test/task1/file_mess/secret_message
[root@localhost vagrant]# cat /otus/test/task1/file_mess/secret_message
```

Зашифрованное сообщение - это ссылка -  https://github.com/sindresorhus/awesome


### Для конфигурации сервера (установки и настройки ZFS) необходимо написать отдельный Bash-скрипт и добавить его в Vagrantfile

```
cat setup.sh 
#!/bin/env bash
yum update -y
yum install -y yum-utils
#install zfs repo
yum install -y http://download.zfsonlinux.org/epel/zfs-release.el7_8.noarch.rpm
#import gpg key
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-zfsonlinux
#install DKMS style packages for correct work ZFS
yum install -y epel-release kernel-devel zfs
#change ZFS repo
yum-config-manager --disable zfs
yum-config-manager --enable zfs-kmod
yum install -y zfs
#Add kernel module zfs
modprobe zfs
#install wget
yum install -y wget
```

```
cat Vagrantfile | grep box.vm.provision
box.vm.provision "shell", path: "setup.sh"
```
</details>


## Lesson6 - NFS


<details>

### Полезные сведения

* rpc.nfsd - Основной демон сервера.    
* rpc.mountd - обрабатывает запросы клиентов на монтирование каталогов.  
* rpc.statd - (Network Status Monitor - NSM). Корректно снимает блокировку после сбоя/перезагрузки. Для уведомления о сбое использует программу /usr/sbin/sm-notify.
* rpc.lockd - (NFS lock manager (NLM)) обрабатывает запросы на блокировку файлов. (В современных ядрах не нужен)
* rpc.idmapd - Для NFSv4 на сервере преобразует локальные uid/gid пользователей в формат вида имя@домен, а на клиенте обратно  

#### Опции экспорта

* sec=(krb5,krb5i,krbp) - какой протокол защиты использовать  
* secure/insecure - запросы с портов (<1024)  
* ro/rw - read only, read write  
* root_squash/no_root_squash - автоподмена владельца файла с root на анонимного пользователя  
* all_squash - автоподмена на анонима для всех файлов  
* anonuid=UID и anongid=GID - Явно задает UID/GID для анонимного пользователя.  


Задача:

- `vagrant up` должен поднимать 2 настроенных виртуальных машины (сервер NFS и клиента) без дополнительных ручных действий; - на сервере NFS должна быть подготовлена и экспортирована директория; 
- в экспортированной директории должна быть поддиректория с именем __upload__ с правами на запись в неё; 
- экспортированная директория должна автоматически монтироваться на клиенте при старте виртуальной машины (systemd, autofs или fstab -  любым способом); 
- монтирование и работа NFS на клиенте должна быть организована с использованием NFSv3 по протоколу UDP; 
- firewall должен быть включен и настроен как на клиенте, так и на сервере. 



### Решение:

Листинг скрипта автоматизации для клиента(nfsc_script.sh):

```
sudo su

yum install -y nfs-utils


systemctl enable firewalld --now
systemctl status firewalld

echo "192.168.50.10:/srv/share/ /mnt nfs _netdev,vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab


systemctl daemon-reload

systemctl restart remote-fs.target

```

опция _netdev даёт systemd понять, что файловая система зависит от сети.  

Листинг скрипта автоматизации для сервера(nfss_script.sh):

```
#!/bin/bash
sudo su
yum install -y nfs-utils
systemctl enable firewalld --now
systemctl status firewalld


firewall-cmd --add-service="nfs3" --permanent
firewall-cmd --add-service="rpc-bind" --permanent
firewall-cmd --add-service="mountd" --permanent
firewall-cmd --add-port=111/udp --permanent
firewall-cmd --add-port=2049/udp --permanent
firewall-cmd --zone=public --add-service=nfs --permanent

firewall-cmd --reload

systemctl enable nfs-server
systemctl start nfs-server

mkdir -p /srv/share/upload
chown -R nfsnobody:nfsnobody /srv/share
chmod 0777 /srv/share/upload
echo '/srv/share 192.168.50.11(rw,sync,root_squash,all_squash)' | tee /etc/exports.d/srv_share.exports
exportfs -a
systemctl restart nfs-server
```

all_squash — эта опция отвечает за то, что любые пользователи NFS-клиента будут считаться анонимными на NFS-сервере или же тем пользователеми NFS-сервера, чьи идентификаторы указаны в anonuid и anongid;  

If no_root_squash is used, remote root users are able to change any file on the shared file system and leave trojaned applications for other users to inadvertently execute. 
На стороне сервера мы можем решить, что мы не хотим доверять администратору клиента. Мы можем сделать это указав опцию root_squash в файле exports:
Если пользователь с UID 0 на стороне клиента попытается получить доступ (чтение, запись, удаление), то файловый сервер выполнит подстановку UID пользователя `nobody' на сервере. Это означает, что администратор клиента не сможет получить доступ или изменять файлы, которые может изменять или иметь доступ к которым может только администратор сервера


Листинг Vagrantfile:
Увеличены значения памяти и процессора, чтобы быстрее поднималось.
Убрана опция - virtualbox__intnet: "net1" с которой сеть у меня не поднималась.


```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.define "nfss" do |nfss|
    nfss.vm.network "private_network", ip: "192.168.50.10"
    nfss.vm.hostname = "nfss"
    nfss.vm.provision "shell", path: "nfss_script.sh"
  end

  config.vm.define "nfsc" do |nfsc|
    nfsc.vm.network "private_network", ip: "192.168.50.11"
    nfsc.vm.hostname = "nfsc"
    nfsc.vm.provision "shell", path: "nfsc_script.sh"
  end
```

Проверяем, что firewall включен на клиенте:

```
[root@nfsc mnt]# firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources: 
  services: dhcpv6-client ssh
  ports: 
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
	
[root@nfsc mnt]# systemctl status firewalld.service 
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2023-01-08 13:18:41 UTC; 49min ago
     Docs: man:firewalld(1)
 Main PID: 3408 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3408 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Jan 08 13:18:41 nfsc systemd[1]: Starting firewalld - dynamic firewall daemon...
Jan 08 13:18:41 nfsc systemd[1]: Started firewalld - dynamic firewall daemon.
Jan 08 13:18:41 nfsc firewalld[3408]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. It will be removed in a future release. Please consider disabling it now.

```

Проверяем, что firewall включен на сервере и соответствующие порты открыты:

```
[root@nfss share]# firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources: 
  services: dhcpv6-client mountd nfs nfs3 rpc-bind ssh
  ports: 111/udp 2049/udp
  protocols: 
  masquerade: no
  forward-ports: 
  source-ports: 
  icmp-blocks: 
  rich rules: 
	
[root@nfss share]# systemctl status firewalld.service 
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2023-01-08 13:17:28 UTC; 55min ago
     Docs: man:firewalld(1)
 Main PID: 3420 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3420 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Jan 08 13:17:28 nfss systemd[1]: Starting firewalld - dynamic firewall daemon...
Jan 08 13:17:28 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
Jan 08 13:17:28 nfss firewalld[3420]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. It will be removed in a future release. Please consider disabling it now.
Jan 08 13:17:31 nfss firewalld[3420]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration option. It will be removed in a future release. Please consider disabling it now.
```

Проверяем права на подмонтированную папку на клиенте:

```
[root@nfsc mnt]# ls -la /mnt
total 0
drwxr-xr-x.  3 nfsnobody nfsnobody  57 Jan  8 14:14 .
dr-xr-xr-x. 18 root      root      255 Jan  8 13:18 ..
-rw-r--r--.  1 nfsnobody nfsnobody   0 Jan  8 13:21 clienttest1
-rw-r--r--.  1 root      root        0 Jan  8 14:14 README.txt
drwxrwxrwx.  2 nfsnobody nfsnobody   6 Jan  8 13:17 upload


[root@nfsc mnt]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=50,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=26730)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10,_netdev)
```

Проверяем разрешение на работу только с директорией:

```
[root@nfsc mnt]# echo 'kek' > /mnt/README.txt 
bash: /mnt/README.txt: Permission denied
[root@nfsc mnt]# echo 'kek' > /mnt/test.kek
[root@nfsc mnt]# cat test.kek 
kek
```

</details>

## Lesson7 - Управление пакетами. Дистрибьюция софта

<details>

#### Задача

1) Создать свой RPM пакет.
2) Создать свой репозиторий и разместить там ранее собраннýй RPM  
⭐ реализовать дополнительно пакет через docker

Решение пунктов 1 и 2:

Собираем nginx 1.23.3 c поддержкой  tls v1.3. (openssl-1.1.1q - 2022-Oct-12)
Описание используемых параметров:

--with-openssl=путь - задаёт путь к исходным текстам библиотеки OpenSSL. 
--with-openssl-opt=параметры - задаёт дополнительные параметры сборки OpenSSL.


Листинг скрипта для установки - nfss_script.sh

```
#!/bin/bash
sudo su
yum install -y \
  redhat-lsb-core \
  wget \
  rpmdevtoools \
  rpm-build \
  createrepo \
  yum-utils \
  gcc \
  vim

#download and extract
wget http://nginx.org/packages/mainline/centos/7/SRPMS/nginx-1.23.3-1.el7.ngx.src.rpm
wget --no-check-certificate https://www.openssl.org/source/old/1.1.1/openssl-1.1.1q.tar.gz
tar -xvf openssl-1.1.1q.tar.gz --directory /usr/lib
rpm -ivh nginx-1.23.3-1.el7.ngx.src.rpm

#Install dependencies
yum-builddep /root/rpmbuild/SPECS/nginx.spec -y


#Add options for build
sed -i "s|--with-stream_ssl_preread_module|--with-stream_ssl_preread_module --with-openssl=/usr/lib/openssl-1.1.1q --with-openssl-opt=enable-tls1_3|g" /root/rpmbuild/SPECS/nginx.spec

#Compile
rpmbuild -ba /root/rpmbuild/SPECS/nginx.spec


#Install and Start

yum localinstall -y /root/rpmbuild/RPMS/x86_64/nginx-1.23.3-1.el7.ngx.x86_64.rpm
sed -i '/index  index.html index.htm;/a autoindex on;' /etc/nginx/conf.d/default.conf
systemctl enable --now nginx

# create rpm repo
mkdir /usr/share/nginx/html/repo
cp /root/rpmbuild/RPMS/x86_64/nginx-1.23.3-1.el7.ngx.x86_64.rpm /usr/share/nginx/html/repo/
createrepo /usr/share/nginx/html/repo/


# add rpm repo to available list
cat >> /etc/yum.repos.d/custom.repo << EOF
[custom]
name=custom-repo
baseurl=http://192.168.50.10/repo
gpgcheck=0
enabled=1
EOF






yum clean all
```
Листинг Vagrantfile:

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v|
    v.memory = 4096
    v.cpus = 2
  end

  config.vm.define "nfss" do |srv|
    srv.vm.network "private_network", ip: "192.168.50.10"
    srv.vm.hostname = "nfss"
    srv.vm.provision "shell", path: "nfss_script.sh"
  end

end

```

Проверяем, что nginx собрался с затребованными параметрами:

```
[root@nfss ~]# nginx -V
nginx version: nginx/1.23.3
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-44) (GCC) 
built with OpenSSL 1.1.1q  5 Jul 2022
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-openssl=/usr/lib/openssl-1.1.1q --with-openssl-opt=enable-tls1_3 --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -m64 -mtune=generic -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie'
```


Проверяем, что параметры для сборки пакета попали в спеку:

```
[root@nfss ~]# cat /root/rpmbuild/SPECS/nginx.spec
#
%define nginx_home %{_localstatedir}/cache/nginx
%define nginx_user nginx
%define nginx_group nginx
%define nginx_loggroup adm

BuildRequires: systemd
Requires(post): systemd
Requires(preun): systemd
Requires(postun): systemd

%if 0%{?rhel}
%define _group System Environment/Daemons
%endif

%if (0%{?rhel} == 7) && (0%{?amzn} == 0)
%define epoch 1
Epoch: %{epoch}
Requires(pre): shadow-utils
Requires: openssl >= 1.0.2
Requires: procps-ng
BuildRequires: openssl-devel >= 1.0.2
%define dist .el7
%endif

%if (0%{?rhel} == 7) && (0%{?amzn} == 2)
%define epoch 1
Epoch: %{epoch}
Requires(pre): shadow-utils
Requires: openssl11 >= 1.1.1
Requires: procps-ng
BuildRequires: openssl11-devel >= 1.1.1
%endif

%if 0%{?rhel} == 8
%define epoch 1
Epoch: %{epoch}
Requires(pre): shadow-utils
Requires: procps-ng
BuildRequires: openssl-devel >= 1.1.1
%define _debugsource_template %{nil}
%endif

%if 0%{?rhel} == 9
%define epoch 1
Epoch: %{epoch}
Requires(pre): shadow-utils
Requires: procps-ng
BuildRequires: openssl-devel
%define _debugsource_template %{nil}
%endif

%if 0%{?suse_version} >= 1315
%define _group Productivity/Networking/Web/Servers
%define nginx_loggroup trusted
Requires(pre): shadow
Requires: procps
BuildRequires: libopenssl-devel
%define _debugsource_template %{nil}
%endif

%if 0%{?fedora}
%define _debugsource_template %{nil}
%global _hardened_build 1
%define _group System Environment/Daemons
Requires: procps-ng
BuildRequires: openssl-devel
Requires(pre): shadow-utils
%endif

# end of distribution specific definitions

%define base_version 1.23.3
%define base_release 1%{?dist}.ngx

%define bdir %{_builddir}/%{name}-%{base_version}

%define WITH_CC_OPT $(echo %{optflags} $(pcre2-config --cflags)) -fPIC
%define WITH_LD_OPT -Wl,-z,relro -Wl,-z,now -pie

%define BASE_CONFIGURE_ARGS $(echo "--prefix=%{_sysconfdir}/nginx --sbin-path=%{_sbindir}/nginx --modules-path=%{_libdir}/nginx/modules --conf-path=%{_sysconfdir}/nginx/nginx.conf --error-log-path=%{_localstatedir}/log/nginx/error.log --http-log-path=%{_localstatedir}/log/nginx/access.log --pid-path=%{_localstatedir}/run/nginx.pid --lock-path=%{_localstatedir}/run/nginx.lock --http-client-body-temp-path=%{_localstatedir}/cache/nginx/client_temp --http-proxy-temp-path=%{_localstatedir}/cache/nginx/proxy_temp --http-fastcgi-temp-path=%{_localstatedir}/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=%{_localstatedir}/cache/nginx/uwsgi_temp --http-scgi-temp-path=%{_localstatedir}/cache/nginx/scgi_temp --user=%{nginx_user} --group=%{nginx_group} --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-openssl=/usr/lib/openssl-1.1.1q --with-openssl-opt=enable-tls1_3")

Summary: High performance web server
Name: nginx
Version: %{base_version}
Release: %{base_release}
Vendor: NGINX Packaging <nginx-packaging@f5.com>
URL: https://nginx.org/
Group: %{_group}

Source0: https://nginx.org/download/%{name}-%{version}.tar.gz
Source1: logrotate
Source2: nginx.conf
Source3: nginx.default.conf
Source4: nginx.service
Source5: nginx.upgrade.sh
Source6: nginx.suse.logrotate
Source7: nginx-debug.service
Source8: nginx.copyright
Source9: nginx.check-reload.sh



License: 2-clause BSD-like license

BuildRoot: %{_tmppath}/%{name}-%{base_version}-%{base_release}-root
BuildRequires: zlib-devel
BuildRequires: pcre2-devel

Provides: webserver
Provides: nginx-r%{base_version}

%description
nginx [engine x] is an HTTP and reverse proxy server, as well as
a mail proxy server.

%if 0%{?suse_version} >= 1315
%debug_package
%endif

%prep
%autosetup -p1

%build
./configure %{BASE_CONFIGURE_ARGS} \
    --with-cc-opt="%{WITH_CC_OPT}" \
    --with-ld-opt="%{WITH_LD_OPT}" \
    --with-debug
make %{?_smp_mflags}
%{__mv} %{bdir}/objs/nginx \
    %{bdir}/objs/nginx-debug
./configure %{BASE_CONFIGURE_ARGS} \
    --with-cc-opt="%{WITH_CC_OPT}" \
    --with-ld-opt="%{WITH_LD_OPT}"
make %{?_smp_mflags}

%install
%{__rm} -rf $RPM_BUILD_ROOT
%{__make} DESTDIR=$RPM_BUILD_ROOT INSTALLDIRS=vendor install

%{__mkdir} -p $RPM_BUILD_ROOT%{_datadir}/nginx
%{__mv} $RPM_BUILD_ROOT%{_sysconfdir}/nginx/html $RPM_BUILD_ROOT%{_datadir}/nginx/

%{__rm} -f $RPM_BUILD_ROOT%{_sysconfdir}/nginx/*.default
%{__rm} -f $RPM_BUILD_ROOT%{_sysconfdir}/nginx/fastcgi.conf

%{__mkdir} -p $RPM_BUILD_ROOT%{_localstatedir}/log/nginx
%{__mkdir} -p $RPM_BUILD_ROOT%{_localstatedir}/run/nginx
%{__mkdir} -p $RPM_BUILD_ROOT%{_localstatedir}/cache/nginx

%{__mkdir} -p $RPM_BUILD_ROOT%{_libdir}/nginx/modules
cd $RPM_BUILD_ROOT%{_sysconfdir}/nginx && \
    %{__ln_s} ../..%{_libdir}/nginx/modules modules && cd -

%{__mkdir} -p $RPM_BUILD_ROOT%{_datadir}/doc/%{name}-%{base_version}
%{__install} -m 644 -p %{SOURCE8} \
    $RPM_BUILD_ROOT%{_datadir}/doc/%{name}-%{base_version}/COPYRIGHT

%{__mkdir} -p $RPM_BUILD_ROOT%{_sysconfdir}/nginx/conf.d
%{__rm} $RPM_BUILD_ROOT%{_sysconfdir}/nginx/nginx.conf
%{__install} -m 644 -p %{SOURCE2} \
    $RPM_BUILD_ROOT%{_sysconfdir}/nginx/nginx.conf
%{__install} -m 644 -p %{SOURCE3} \
    $RPM_BUILD_ROOT%{_sysconfdir}/nginx/conf.d/default.conf

%{__install} -p -D -m 0644 %{bdir}/objs/nginx.8 \
    $RPM_BUILD_ROOT%{_mandir}/man8/nginx.8

%{__mkdir} -p $RPM_BUILD_ROOT%{_unitdir}
%{__install} -m644 %SOURCE4 \
    $RPM_BUILD_ROOT%{_unitdir}/nginx.service
%{__install} -m644 %SOURCE7 \
    $RPM_BUILD_ROOT%{_unitdir}/nginx-debug.service
%{__mkdir} -p $RPM_BUILD_ROOT%{_libexecdir}/initscripts/legacy-actions/nginx
%{__install} -m755 %SOURCE5 \
    $RPM_BUILD_ROOT%{_libexecdir}/initscripts/legacy-actions/nginx/upgrade
%{__install} -m755 %SOURCE9 \
    $RPM_BUILD_ROOT%{_libexecdir}/initscripts/legacy-actions/nginx/check-reload

# install log rotation stuff
%{__mkdir} -p $RPM_BUILD_ROOT%{_sysconfdir}/logrotate.d
%if 0%{?suse_version}
%{__install} -m 644 -p %{SOURCE6} \
    $RPM_BUILD_ROOT%{_sysconfdir}/logrotate.d/nginx
%else
%{__install} -m 644 -p %{SOURCE1} \
    $RPM_BUILD_ROOT%{_sysconfdir}/logrotate.d/nginx
%endif

%{__install} -m755 %{bdir}/objs/nginx-debug \
    $RPM_BUILD_ROOT%{_sbindir}/nginx-debug

%{__rm} $RPM_BUILD_ROOT%{_sysconfdir}/nginx/koi-utf
%{__rm} $RPM_BUILD_ROOT%{_sysconfdir}/nginx/koi-win
%{__rm} $RPM_BUILD_ROOT%{_sysconfdir}/nginx/win-utf

%check
%{__rm} -rf $RPM_BUILD_ROOT/usr/src
cd %{bdir}
grep -v 'usr/src' debugfiles.list > debugfiles.list.new && mv debugfiles.list.new debugfiles.list
cat /dev/null > debugsources.list
%if 0%{?suse_version} >= 1500
cat /dev/null > debugsourcefiles.list
%endif

%clean
%{__rm} -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)

%{_sbindir}/nginx
%{_sbindir}/nginx-debug

%dir %{_sysconfdir}/nginx
%dir %{_sysconfdir}/nginx/conf.d
%{_sysconfdir}/nginx/modules

%config(noreplace) %{_sysconfdir}/nginx/nginx.conf
%config(noreplace) %{_sysconfdir}/nginx/conf.d/default.conf
%config(noreplace) %{_sysconfdir}/nginx/mime.types
%config(noreplace) %{_sysconfdir}/nginx/fastcgi_params
%config(noreplace) %{_sysconfdir}/nginx/scgi_params
%config(noreplace) %{_sysconfdir}/nginx/uwsgi_params

%config(noreplace) %{_sysconfdir}/logrotate.d/nginx
%{_unitdir}/nginx.service
%{_unitdir}/nginx-debug.service
%dir %{_libexecdir}/initscripts/legacy-actions/nginx
%{_libexecdir}/initscripts/legacy-actions/nginx/*

%attr(0755,root,root) %dir %{_libdir}/nginx
%attr(0755,root,root) %dir %{_libdir}/nginx/modules
%dir %{_datadir}/nginx
%dir %{_datadir}/nginx/html
%{_datadir}/nginx/html/*

%attr(0755,root,root) %dir %{_localstatedir}/cache/nginx
%attr(0755,root,root) %dir %{_localstatedir}/log/nginx

%dir %{_datadir}/doc/%{name}-%{base_version}
%doc %{_datadir}/doc/%{name}-%{base_version}/COPYRIGHT
%{_mandir}/man8/nginx.8*

%pre
# Add the "nginx" user
getent group %{nginx_group} >/dev/null || groupadd -r %{nginx_group}
getent passwd %{nginx_user} >/dev/null || \
    useradd -r -g %{nginx_group} -s /sbin/nologin \
    -d %{nginx_home} -c "nginx user"  %{nginx_user}
exit 0

%post
# Register the nginx service
if [ $1 -eq 1 ]; then
    /usr/bin/systemctl preset nginx.service >/dev/null 2>&1 ||:
    /usr/bin/systemctl preset nginx-debug.service >/dev/null 2>&1 ||:
    # print site info
    cat <<BANNER
----------------------------------------------------------------------

Thanks for using nginx!

Please find the official documentation for nginx here:
* https://nginx.org/en/docs/

Please subscribe to nginx-announce mailing list to get
the most important news about nginx:
* https://nginx.org/en/support.html

Commercial subscriptions for nginx are available on:
* https://nginx.com/products/

----------------------------------------------------------------------
BANNER

    # Touch and set permisions on default log files on installation

    if [ -d %{_localstatedir}/log/nginx ]; then
        if [ ! -e %{_localstatedir}/log/nginx/access.log ]; then
            touch %{_localstatedir}/log/nginx/access.log
            %{__chmod} 640 %{_localstatedir}/log/nginx/access.log
            %{__chown} nginx:%{nginx_loggroup} %{_localstatedir}/log/nginx/access.log
        fi

        if [ ! -e %{_localstatedir}/log/nginx/error.log ]; then
            touch %{_localstatedir}/log/nginx/error.log
            %{__chmod} 640 %{_localstatedir}/log/nginx/error.log
            %{__chown} nginx:%{nginx_loggroup} %{_localstatedir}/log/nginx/error.log
        fi
    fi
fi

%preun
if [ $1 -eq 0 ]; then
    /usr/bin/systemctl --no-reload disable nginx.service >/dev/null 2>&1 ||:
    /usr/bin/systemctl stop nginx.service >/dev/null 2>&1 ||:
fi

%postun
/usr/bin/systemctl daemon-reload >/dev/null 2>&1 ||:
if [ $1 -ge 1 ]; then
    /sbin/service nginx status  >/dev/null 2>&1 || exit 0
    /sbin/service nginx upgrade >/dev/null 2>&1 || echo \
        "Binary upgrade failed, please check nginx's error.log"
fi

%changelog
* Tue Dec 13 2022 Nginx Packaging <nginx-packaging@f5.com> - 1.23.3-1%{?dist}.ngx
- 1.23.3-1

* Wed Oct 19 2022 Nginx Packaging <nginx-packaging@f5.com> - 1.23.2-1%{?dist}.ngx
- 1.23.2-1

* Tue Jul 19 2022 Nginx Packaging <nginx-packaging@f5.com> - 1.23.1-1%{?dist}.ngx
- 1.23.1-1

* Tue Jun 21 2022 Nginx Packaging <nginx-packaging@f5.com> - 1.23.0-1%{?dist}.ngx
- 1.23.0-1

* Tue Jan 25 2022 Mikhail Isachenkov <mikhail.isachenkov@nginx.com> - 1.21.6-1%{?dist}.ngx
- 1.21.6-1

* Tue Dec 28 2021 Konstantin Pavlov <thresh@nginx.com> - 1.21.5-1%{?dist}.ngx
- 1.21.5-1
- built with PCRE2

* Tue Nov  2 2021 Konstantin Pavlov <thresh@nginx.com> - 1.21.4-1%{?dist}.ngx
- 1.21.4-1

* Tue Sep  7 2021 Konstantin Pavlov <thresh@nginx.com> - 1.21.3-1%{?dist}.ngx
- 1.21.3-1

* Tue Aug 31 2021 Andrei Belov <defan@nginx.com> - 1.21.2-1%{?dist}.ngx
- 1.21.2-1

* Tue Jul  6 2021 Konstantin Pavlov <thresh@nginx.com> - 1.21.1-1%{?dist}.ngx
- 1.21.1-1

* Tue May 25 2021 Konstantin Pavlov <thresh@nginx.com> - 1.21.0-1%{?dist}.ngx
- 1.21.0-1

* Tue Apr 13 2021 Andrei Belov <defan@nginx.com> - 1.19.10-1%{?dist}.ngx
- 1.19.10-1

* Tue Mar 30 2021 Konstantin Pavlov <thresh@nginx.com> - 1.19.9-1%{?dist}.ngx
- 1.19.9-1

* Tue Mar  9 2021 Konstantin Pavlov <thresh@nginx.com> - 1.19.8-1%{?dist}.ngx
- 1.19.8-1

* Tue Feb 16 2021 Konstantin Pavlov <thresh@nginx.com> - 1.19.7-1%{?dist}.ngx
- 1.19.7-1

* Tue Dec 15 2020 Konstantin Pavlov <thresh@nginx.com> - 1.19.6-1%{?dist}.ngx
- 1.19.6-1

* Tue Nov 24 2020 Konstantin Pavlov <thresh@nginx.com> - 1.19.5-1%{?dist}.ngx
- 1.19.5-1

* Tue Oct 27 2020 Andrei Belov <defan@nginx.com> - 1.19.4-1%{?dist}.ngx
- 1.19.4-1

* Tue Sep 29 2020 Konstantin Pavlov <thresh@nginx.com> - 1.19.3-1%{?dist}.ngx
- 1.19.3

* Tue Aug 11 2020 Konstantin Pavlov <thresh@nginx.com> - 1.19.2-1%{?dist}.ngx
- 1.19.2

* Tue Jul  7 2020 Konstantin Pavlov <thresh@nginx.com> - 1.19.1-1%{?dist}.ngx
- 1.19.1

* Tue May 26 2020 Konstantin Pavlov <thresh@nginx.com> - 1.19.0-1%{?dist}.ngx
- 1.19.0

* Tue Apr 14 2020 Konstantin Pavlov <thresh@nginx.com> - 1.17.10-1%{?dist}.ngx
- 1.17.10

* Tue Mar  3 2020 Konstantin Pavlov <thresh@nginx.com> - 1.17.9-1%{?dist}.ngx
- 1.17.9

* Tue Jan 21 2020 Konstantin Pavlov <thresh@nginx.com> - 1.17.8-1%{?dist}.ngx
- 1.17.8

* Tue Dec 24 2019 Konstantin Pavlov <thresh@nginx.com> - 1.17.7-1%{?dist}.ngx
- 1.17.7

* Tue Nov 19 2019 Konstantin Pavlov <thresh@nginx.com> - 1.17.6-1%{?dist}.ngx
- 1.17.6

* Tue Oct 22 2019 Andrei Belov <defan@nginx.com> - 1.17.5-1%{?dist}.ngx
- 1.17.5

* Tue Sep 24 2019 Konstantin Pavlov <thresh@nginx.com> - 1.17.4-1%{?dist}.ngx
- 1.17.4

* Tue Aug 13 2019 Andrei Belov <defan@nginx.com> - 1.17.3-1%{?dist}.ngx
- 1.17.3

* Tue Jul 23 2019 Konstantin Pavlov <thresh@nginx.com> - 1.17.2-1%{?dist}.ngx
- 1.17.2

* Tue Jun 25 2019 Andrei Belov <defan@nginx.com> - 1.17.1-1%{?dist}.ngx
- 1.17.1

* Tue May 21 2019 Konstantin Pavlov <thresh@nginx.com> - 1.17.0-1%{?dist}.ngx
- 1.17.0

* Tue Apr 16 2019 Konstantin Pavlov <thresh@nginx.com> - 1.15.12-1%{?dist}.ngx
- 1.15.12

* Tue Apr  9 2019 Konstantin Pavlov <thresh@nginx.com> - 1.15.11-1%{?dist}.ngx
- 1.15.11

* Tue Mar 26 2019 Konstantin Pavlov <thresh@nginx.com> - 1.15.10-1%{?dist}.ngx
- 1.15.10

* Tue Feb 26 2019 Konstantin Pavlov <thresh@nginx.com> - 1.15.9-1%{?dist}.ngx
- 1.15.9

* Tue Dec 25 2018 Konstantin Pavlov <thresh@nginx.com> - 1.15.8-1%{?dist}.ngx
- 1.15.8

* Tue Nov 27 2018 Konstantin Pavlov <thresh@nginx.com> - 1.15.7-1%{?dist}.ngx
- 1.15.7

* Tue Nov  6 2018 Konstantin Pavlov <thresh@nginx.com> - 1.15.6-1%{?dist}.ngx
- 1.15.6
- Security: fixes CVE-2018-16843.
- Security: fixes CVE-2018-16844.
- Security: fixes CVE-2018-16845.

* Tue Oct  2 2018 Konstantin Pavlov <thresh@nginx.com> - 1.15.5-1%{?dist}.ngx
- 1.15.5

* Tue Sep 25 2018 Konstantin Pavlov <thresh@nginx.com> - 1.15.4-1%{?dist}.ngx
- 1.15.4

* Tue Aug 28 2018 Konstantin Pavlov <thresh@nginx.com> - 1.15.3-1%{?dist}.ngx
- 1.15.3

* Tue Jul 24 2018 Konstantin Pavlov <thresh@nginx.com> - 1.15.2-1%{?dist}.ngx
- 1.15.2

* Tue Jul  3 2018 Konstantin Pavlov <thresh@nginx.com> - 1.15.1-1%{?dist}.ngx
- 1.15.1

* Tue Jun  5 2018 Konstantin Pavlov <thresh@nginx.com> - 1.15.0-1%{?dist}.ngx
- 1.15.0

* Mon Apr  9 2018 Konstantin Pavlov <thresh@nginx.com> - 1.13.12-1%{?dist}.ngx
- 1.13.12

* Tue Apr  3 2018 Konstantin Pavlov <thresh@nginx.com> - 1.13.11-1%{?dist}.ngx
- 1.13.11

* Tue Mar 20 2018 Konstantin Pavlov <thresh@nginx.com> - 1.13.10-1%{?dist}.ngx
- 1.13.10

* Tue Feb 20 2018 Konstantin Pavlov <thresh@nginx.com> - 1.13.9-1%{?dist}.ngx
- 1.13.9

* Tue Dec 26 2017 Konstantin Pavlov <thresh@nginx.com> - 1.13.8-1%{?dist}.ngx
- 1.13.8

* Tue Nov 21 2017 Konstantin Pavlov <thresh@nginx.com> - 1.13.7-1%{?dist}.ngx
- 1.13.7

* Thu Sep 14 2017 Konstantin Pavlov <thresh@nginx.com> - 1.13.6-1%{?dist}.ngx
- 1.13.6
- Bugfix: in systemd service support
  (https://trac.nginx.org/nginx/ticket/1380).

* Thu Sep 14 2017 Konstantin Pavlov <thresh@nginx.com> - 1.13.5-1%{?dist}.ngx
- 1.13.5

* Tue Aug  8 2017 Sergey Budnevitch <sb@nginx.com> - 1.13.4-1%{?dist}.ngx
- 1.13.4

* Tue Jul 11 2017 Konstantin Pavlov <thresh@nginx.com> - 1.13.3-1%{?dist}.ngx
- 1.13.3
- Security: fixes CVE-2017-7529.

* Tue Jun 27 2017 Konstantin Pavlov <thresh@nginx.com> - 1.13.2-1%{?dist}.ngx
- 1.13.2

* Tue May 30 2017 Konstantin Pavlov <thresh@nginx.com> - 1.13.1-1%{?dist}.ngx
- 1.13.1

* Tue Apr 25 2017 Konstantin Pavlov <thresh@nginx.com> - 1.13.0-1%{?dist}.ngx
- 1.13.0

* Tue Apr  4 2017 Konstantin Pavlov <thresh@nginx.com> - 1.11.13-1%{?dist}.ngx
- 1.11.13
- Made upgrade loops/timeouts configurable via /etc/defaults/nginx.

* Fri Mar 24 2017 Konstantin Pavlov <thresh@nginx.com> - 1.11.12-1%{?dist}.ngx
- 1.11.12

* Tue Mar 21 2017 Konstantin Pavlov <thresh@nginx.com> - 1.11.11-1%{?dist}.ngx
- 1.11.11

* Tue Feb 14 2017 Konstantin Pavlov <thresh@nginx.com> - 1.11.10-1%{?dist}.ngx
- 1.11.10

* Tue Jan 24 2017 Konstantin Pavlov <thresh@nginx.com> - 1.11.9-1%{?dist}.ngx
- 1.11.9
- Extended hardening build flags.
- Added check-reload target to init script / systemd service.

* Tue Dec 27 2016 Konstantin Pavlov <thresh@nginx.com> - 1.11.8-1%{?dist}.ngx
- 1.11.8

* Tue Dec 13 2016 Konstantin Pavlov <thresh@nginx.com> - 1.11.7-1%{?dist}.ngx
- 1.11.7

* Fri Nov 25 2016 Konstantin Pavlov <thresh@nginx.com> - 1.11.6-1%{?dist}.ngx
- 1.11.6

* Mon Oct 10 2016 Andrei Belov <defan@nginx.com> - 1.11.5-1%{?dist}.ngx
- 1.11.5

* Tue Sep 13 2016 Konstantin Pavlov <thresh@nginx.com> - 1.11.4-1%{?dist}.ngx
- 1.11.4
- njs updated to 0.1.2.

* Tue Jul 26 2016 Konstantin Pavlov <thresh@nginx.com> - 1.11.3-1%{?dist}.ngx
- 1.11.3
- njs updated to 0.1.0.
- njs stream dynamic module added to nginx-module-njs package.
- geoip stream dynamic module added to nginx-module-geoip package.

* Tue Jul  5 2016 Konstantin Pavlov <thresh@nginx.com> - 1.11.2-1%{?dist}.ngx
- 1.11.2
- njs updated to ef2b708510b1.

* Tue May 31 2016 Konstantin Pavlov <thresh@nginx.com> - 1.11.1-1%{?dist}.ngx
- 1.11.1

* Tue May 24 2016 Sergey Budnevitch <sb@nginx.com> - 1.11.0-1%{?dist}.ngx
- 1.11.0
- Bugfix: fixed logrotate error if nginx is not running.

* Tue Apr 19 2016 Konstantin Pavlov <thresh@nginx.com> - 1.9.15-1%{?dist}.ngx
- 1.9.15
- njs updated to 1c50334fbea6.

* Tue Apr  5 2016 Konstantin Pavlov <thresh@nginx.com> - 1.9.14-1%{?dist}.ngx
- 1.9.14

* Tue Mar 29 2016 Konstantin Pavlov <thresh@nginx.com> - 1.9.13-1%{?dist}.ngx
- 1.9.13
- Fixed modules path
- Added perl and njs dynamic modules subpackages

* Wed Feb 24 2016 Sergey Budnevitch <sb@nginx.com> - 1.9.12-1%{?dist}.ngx
- 1.9.12
- common configure args are now in variable
- xslt, image-filter and geoip dynamic modules added

* Tue Feb  9 2016 Sergey Budnevitch <sb@nginx.com> - 1.9.11-1%{?dist}.ngx
- 1.9.11
- dynamic modules path and symlink in /etc/nginx added

* Tue Jan 26 2016 Konstantin Pavlov <thresh@nginx.com> - 1.9.10-1%{?dist}.ngx
- 1.9.10

* Wed Dec  9 2015 Konstantin Pavlov <thresh@nginx.com> - 1.9.9-1%{?dist}.ngx
- 1.9.9

* Tue Dec  8 2015 Konstantin Pavlov <thresh@nginx.com> - 1.9.8-1%{?dist}.ngx
- 1.9.8
- http_slice module enabled

* Tue Nov 17 2015 Konstantin Pavlov <thresh@nginx.com> - 1.9.7-1%{?dist}.ngx
- 1.9.7

* Tue Oct 27 2015 Sergey Budnevitch <sb@nginx.com> - 1.9.6-1%{?dist}.ngx
- 1.9.6

* Tue Sep 22 2015 Andrei Belov <defan@nginx.com> - 1.9.5-1%{?dist}.ngx
- 1.9.5
- http_spdy module replaced with http_v2 module

* Tue Aug 18 2015 Konstantin Pavlov <thresh@nginx.com> - 1.9.4-1%{?dist}.ngx
- 1.9.4

* Tue Jul 14 2015 Sergey Budnevitch <sb@nginx.com> - 1.9.3-1%{?dist}.ngx
- 1.9.3

* Tue Jun 16 2015 Sergey Budnevitch <sb@nginx.com> - 1.9.2-1%{?dist}.ngx
- 1.9.2

* Tue May 26 2015 Sergey Budnevitch <sb@nginx.com> - 1.9.1-1%{?dist}.ngx
- 1.9.1

* Tue Apr 28 2015 Sergey Budnevitch <sb@nginx.com> - 1.9.0-1%{?dist}.ngx
- 1.9.0
- thread pool support added
- stream module added
- example_ssl.conf removed

* Tue Apr  7 2015 Sergey Budnevitch <sb@nginx.com> - 1.7.12-1%{?dist}.ngx
- 1.7.12

* Tue Mar 24 2015 Sergey Budnevitch <sb@nginx.com> - 1.7.11-1%{?dist}.ngx
- 1.7.11

* Tue Feb 10 2015 Sergey Budnevitch <sb@nginx.com> - 1.7.10-1%{?dist}.ngx
- 1.7.10

* Tue Dec 23 2014 Sergey Budnevitch <sb@nginx.com> - 1.7.9-1%{?dist}.ngx
- 1.7.9
- init-script now sends signal only to the PID derived from pidfile

* Tue Dec  2 2014 Sergey Budnevitch <sb@nginx.com> - 1.7.8-1%{?dist}.ngx
- 1.7.8
- package with debug symbols added

* Tue Oct 28 2014 Sergey Budnevitch <sb@nginx.com> - 1.7.7-1%{?dist}.ngx
- 1.7.7

* Tue Sep 30 2014 Sergey Budnevitch <sb@nginx.com> - 1.7.6-1%{?dist}.ngx
- 1.7.6

* Tue Sep 16 2014 Sergey Budnevitch <sb@nginx.com> - 1.7.5-1%{?dist}.ngx
- 1.7.5

* Tue Aug  5 2014 Sergey Budnevitch <sb@nginx.com> - 1.7.4-1%{?dist}.ngx
- 1.7.4
- init-script now returns 0 on stop command if nginx is not running

* Tue Jul  8 2014 Sergey Budnevitch <sb@nginx.com> - 1.7.3-1%{?dist}.ngx
- 1.7.3

* Tue Jun 17 2014 Sergey Budnevitch <sb@nginx.com> - 1.7.2-1%{?dist}.ngx
- 1.7.2

* Tue May 27 2014 Sergey Budnevitch <sb@nginx.com> - 1.7.1-1%{?dist}.ngx
- 1.7.1

* Thu Apr 24 2014 Konstantin Pavlov <thresh@nginx.com> - 1.7.0-1%{?dist}.ngx
- 1.7.0

* Tue Apr  8 2014 Sergey Budnevitch <sb@nginx.com> - 1.5.13-1%{?dist}.ngx
- 1.5.13

* Tue Mar 18 2014 Sergey Budnevitch <sb@nginx.com> - 1.5.12-1%{?dist}.ngx
- 1.5.12
- warning added when binary upgrade returns non-zero exit code

* Tue Mar  4 2014 Sergey Budnevitch <sb@nginx.com> - 1.5.11-1%{?dist}.ngx
- 1.5.11

* Tue Feb  4 2014 Sergey Budnevitch <sb@nginx.com> - 1.5.10-1%{?dist}.ngx
- 1.5.10

* Wed Jan 22 2014 Sergey Budnevitch <sb@nginx.com> - 1.5.9-1%{?dist}.ngx
- 1.5.9

* Tue Dec 17 2013 Sergey Budnevitch <sb@nginx.com> - 1.5.8-1%{?dist}.ngx
- 1.5.8

* Fri Nov 29 2013 Sergey Budnevitch <sb@nginx.com> - 1.5.7-1%{?dist}.ngx
- 1.5.7
- init script now honours additional options sourced from /etc/default/nginx

* Tue Oct  1 2013 Sergey Budnevitch <sb@nginx.com> - 1.5.6-1%{?dist}.ngx
- 1.5.6

* Tue Sep 17 2013 Andrei Belov <defan@nginx.com> - 1.5.5-1%{?dist}.ngx
- 1.5.5

* Tue Aug 27 2013 Sergey Budnevitch <sb@nginx.com> - 1.5.4-1%{?dist}.ngx
- 1.5.4
- auth request module added

* Tue Jul 30 2013 Sergey Budnevitch <sb@nginx.com> - 1.5.3-1%{?dist}.ngx
- 1.5.3

* Tue Jul  2 2013 Sergey Budnevitch <sb@nginx.com> - 1.5.2-1%{?dist}.ngx
- 1.5.2

* Tue Jun  4 2013 Sergey Budnevitch <sb@nginx.com> - 1.5.1-1%{?dist}.ngx
- 1.5.1
- dpkg-buildflags options now passed by --with-{cc,ld}-opt

* Mon May  6 2013 Sergey Budnevitch <sb@nginx.com> - 1.5.0-1%{?dist}.ngx
- 1.5.0
- fixed openssl version detection with dash as /bin/sh

* Tue Apr 16 2013 Sergey Budnevitch <sb@nginx.com> - 1.3.16-1%{?dist}.ngx
- 1.3.16

* Tue Mar 26 2013 Sergey Budnevitch <sb@nginx.com> - 1.3.15-1%{?dist}.ngx
- 1.3.15
- gunzip module added
- spdy module added if openssl version >= 1.0.1
- set permissions on default log files at installation
```
Проверяем, что репозиторий развернулся:

```
[root@nfss ~]# yum repolist enabled | grep otus
otus                                otus-linux                                 1

[root@nfss ~]# yum list --showduplicates | grep otus
nginx.x86_64                             1:1.23.3-1.el7.ngx            otus   


lynx http://192.168.50.10/repo/ 



Index of /repo/
___________________________________________________________________________________________________________________________________________________________________________________________________________

../
repodata/                                          11-Jan-2023 10:43                   -
nginx-1.23.3-1.el7.ngx.x86_64.rpm                  11-Jan-2023 10:38             3774136


```



</details>


## Lesson8 - Загрузка системы

<details>

#### Задачи:


1.Сбросить пароль root  
2.Переименовть VG с корневым томом (сделал более расширено с переименованием и VG и LV) 
3.Добавить свой модуль в initrd  



Вся домашка выполнялась на VM c Centos 8, т.к. 7ая версия сильно устарела

```
[mity@localhost ~]$ uname -a
Linux localhost.localdomain 4.18.0-408.el8.x86_64 #1 SMP Mon Jul 18 17:42:52 UTC 2022 x86_64 x86_64 x86_64 GNU/Linux
[mity@localhost ~]$ cat /etc/centos-release
CentOS Stream release 8
```





#### 1.Сбросить пароль root 

При загрузке системы нажимаем **e**, для получения доступа к меню загрузчика, на скриншотаж ниже приведены 3 различных варианта изменений в загрузчике.
Параметр **rw**монтирует раздел /root в режиме read-write.
Файл /**.autorelabel**  подтверждает легитимность внесения изменений в /etc/shadow для selinux.
**mount -o remount,ro / -** проводит перемонтирование в режиме read-only.

![Image 1](Lesson8/otboot1.jpg)

![Image 2](Lesson8/otboot2.jpg)

![Image 3](Lesson8/otboot3.jpg)

![Image 4](Lesson8/otboot4.jpg)



#### 2.Переименовть VG с корневым томом (сделал более расширено с переименованием и VG и LV) 


Смотрим текущие параметры Logical Volume и Volume Group

```
[root@localhost ~]# lvs
  LV   VG Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  root cs -wi-ao---- <26.00g                                                    
  swap cs -wi-ao----   3.00g                                                    
[root@localhost ~]# 
```

Переименовываем:

```
[root@localhost ~]# sudo lvrename /dev/cs/root rootnew
  Renamed "root" to "rootnew" in volume group "cs"
```

Проверяем:

```
[root@localhost ~]# lvs
  LV      VG Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  rootnew cs -wi-ao---- <26.00g                                                    
  swap    cs -wi-ao----   3.00g                                                    
[root@localhost ~]# 
```

Листинги fstab и grub представлены с уже переименованными VG и LV.

Правим fstab:


```
[root@localhost ~]# cat /etc/fstab 


/dev/mapper/kek125-rootnew     /                       xfs     defaults        0 0
UUID=4073aeb1-52b7-456f-84ba-0143bc398314 /boot                   xfs     defaults        0 0
/dev/mapper/kek125-swap     none                    swap    defaults        0 0

```

Редактируем grub:

```
[root@localhost ~]# cat /etc/default/grub 
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="crashkernel=auto resume=/dev/mapper/kek125-swap rd.lvm.lv=kek125/rootnew rd.lvm.lv=kek125/swap rhgb quiet"
GRUB_DISABLE_RECOVERY="true"
GRUB_ENABLE_BLSCFG=true
```

Перезагружаемся и правим загрузчик:

![Image 5](Lesson8/otboot5.jpg)


Создаем новый grub.cfg

```
[root@localhost centos]# grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
```

Смотрим текущие параметры Volume Group

```
[root@localhost ~]# vgs
  VG #PV #LV #SN Attr   VSize   VFree
  cs   1   2   0 wz--n- <29.00g    0 
```


Переименовываем:

```
[root@localhost ~]# vgrename cs kek125
  Volume group "cs" successfully renamed to "kek125"
```

Проверяем:

```
[root@localhost ~]# lvs
  LV      VG     Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  rootnew kek125 -wi-ao---- <26.00g                                                    
  swap    kek125 -wi-ao----   3.00g
```

Редактируем grub и /etc/fstab:

Перезагружаемся и правим загрузчик:

![Image 6](Lesson8/otboot6.jpg)


Создаем новый grub.cfg

```
[root@localhost centos]# grub2-mkconfig -o /boot/efi/EFI/centos/grub.cfg
```

Проверяем:

```
[root@localhost ~]# vgs
  VG     #PV #LV #SN Attr   VSize   VFree
  kek125   1   2   0 wz--n- <29.00g    0 
```


### 3.Добавить свой модуль в initrd 

```
[root@localhost ~]# cd /usr/lib/dracut/modules.d/
[root@localhost modules.d]# mkdir 01logo && cd 01logo

[root@localhost 01logo]# cat logo.sh 
#!/bin/bash

exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'
Hello! You are in dracut module!
 ___________________
< I'm dracut module >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 10
echo " continuing...."
```
```
[root@localhost 01logo]# cat module-setup.sh 
#!/bin/bash

check() {
    return 0
}

depends() {
    return 0
}

install() {
    inst_hook cleanup 00 "${moddir}/logo.sh"
}
```

Проверяем:

```
[root@localhost 01logo]# lsinitrd -m /boot/initramfs-$(uname -r).img | grep logo
logo
```

![Image 7](Lesson8/otboot7.jpg)


</details>


## Lesson9 - Инициализация системы. Systemd.

<details>

### Задача

1. Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig).  
2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).  
3. Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.  
4. ⭐  Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл.  
 

### 1 Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig).  

Создаём конфигурацонный файл  для сервиса:


```
cat watchlog
# Configuration file for my watchlog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log

```

Создаём файлы для заполнения лога:

```
cat alert_add.sh 
#!/bin/bash
/bin/echo `/bin/date "+%b %d %T"` ALERT >> /var/log/watchlog.log

```

```
cat tail_add.sh
#!/bin/bash
/bin/tail /var/log/messages >> /var/log/watchlog.log

```

Создаём скрипт, который будет выполняться:

```
cat watchlog.sh
#!/bin/bash
WORD=$1
LOG=$2
DATE=`/bin/date`
if grep $WORD $LOG &> /dev/null; then
    logger "$DATE: I found word, Master!"
	exit 0
else
    exit 0
fi
```

Создаём unit-файл сервиса:

```
cat > /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service

[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG
```


Создаём unit-файл таймера:

```
cat > /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second

[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service

[Install]
WantedBy=multi-user.target

```

Добавляем в Vagrantfile инструкции для:

копирования файлов  
```
box.vm.provision "file", source: "/home/mity/Documents/OTUS_Linux_Prof/Lesson9/script/", destination: "/tmp/"
```

присвоения бита исполнения  
```
chmod +x /opt/*.sh
```
выполнения скриптов по заполнению лога(cron) 
```
(sudo crontab -l | 2>/dev/null; echo "*/3 * * * * /opt/tail_add.sh"; echo "*/5 * * * * /opt/alert_add.sh") | crontab -
```

перечитывания конфигурации 
```
sudo systemctl daemon-reload
```

запуска и загрузки сервиса 
```
sudo systemctl start watchlog.timer
sudo systemctl start watchlog.service
sudo systemctl enable watchlog.timer
```

Проверяем:

```
[root@Lesson9 ~]# tail -f /var/log/messages
Jan 18 17:32:02 localhost systemd: Starting My watchlog service...
Jan 18 17:32:02 localhost root: Wed Jan 18 17:32:02 UTC 2023: I found word, Master!
Jan 18 17:32:02 localhost systemd: Started My watchlog service.
Jan 18 17:30:49 localhost root: Wed Jan 18 17:30:49 UTC 2023: I found word, Master!
```

### 2. Из репозитория epel установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).  

Создаём файл spawn-fcgi.service:

```
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target
```

Создаём отредактированный файл spawn-fcgi:

```
cat spawn-fcgi
# You must set some working options before the "spawn-fcgi" service will work.
# If SOCKET points to a file, then this file is cleaned up by the init script.
#
# See spawn-fcgi(1) for all possible options.
#
# Example :
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u apache -g apache -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"

```
Добавляем копирование созданных файлов в Vagrantfile и добавляем установку необходимых пакетов:
(приведена конфигурация Vagrantfile с уже готовыми настройками на все 3 задачи).

```
cat Vagrantfile 
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :"Lesson9" => {
        :box_name => "centos/7",
        :ip_addr => '192.168.11.101'
  }
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          box.vm.network "private_network", ip: boxconfig[:ip_addr]

          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--cpus", "4"] 
            vb.customize ["modifyvm", :id, "--memory", "4096"]
          end
          
          box.vm.provision :shell, :inline => "setenforce 0", run: "always"
          box.vm.provision "file", source: "/home/mity/Documents/OTUS_Linux_Prof/Lesson9/script/", destination: "/tmp/"
          box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
                        yum install epel-release -y
                        yum install spawn-fcgi php php-cli mod_fcgid httpd -y
                        cp /tmp/script/alert_add.sh /opt
			cp /tmp/script/tail_add.sh /opt
			cp /tmp/script/watchlog /etc/sysconfig
			sudo cp /tmp/script/watchlog.service /etc/systemd/system
			sudo cp -f /tmp/script/spawn-fcgi /etc/sysconfig/
			sudo cp /tmp/script/spawn-fcgi.service /etc/systemd/system
                        sudo cp /tmp/script/first.conf /etc/httpd/conf
			sudo cp /tmp/script/httpd-first /etc/sysconfig
                        sudo cp /tmp/script/httpd-second /etc/sysconfig
                        sudo cp '/tmp/script/httpd@first.service' /etc/systemd/system
			sudo cp '/tmp/script/httpd@second.service' /etc/systemd/system
                        sudo cp /tmp/script/first.conf /etc/httpd/conf
                        sudo cp /tmp/script/second.conf /etc/httpd/conf
			cp /tmp/script/watchlog.sh /opt
			sudo cp /tmp/script/watchlog.timer /etc/systemd/system
                        chmod +x /opt/*.sh
                        (sudo crontab -l | 2>/dev/null; echo "*/3 * * * * /opt/tail_add.sh"; echo "*/5 * * * * /opt/alert_add.sh") | crontab -
                        sudo systemctl start watchlog.timer
			sudo systemctl start watchlog.service
			sudo systemctl enable watchlog.timer
                        sudo systemctl start spawn-fcgi
                        sudo systemctl daemon-reload
			sudo systemctl start httpd@first
			sudo systemctl start httpd@second


          SHELL

      end
  end
end

```

Проверяем:

```
[root@Lesson9 ~]# systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
   Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2023-01-19 11:37:10 UTC; 17min ago
 Main PID: 4740 (php-cgi)
   CGroup: /system.slice/spawn-fcgi.service
           ├─4740 /usr/bin/php-cgi
           ├─4744 /usr/bin/php-cgi
           ├─4745 /usr/bin/php-cgi
           ├─4746 /usr/bin/php-cgi
           ├─4747 /usr/bin/php-cgi
           ├─4748 /usr/bin/php-cgi
           ├─4749 /usr/bin/php-cgi
           ├─4750 /usr/bin/php-cgi
           ├─4751 /usr/bin/php-cgi
           ├─4752 /usr/bin/php-cgi
           ├─4753 /usr/bin/php-cgi
           ├─4754 /usr/bin/php-cgi
           ├─4755 /usr/bin/php-cgi
           ├─4756 /usr/bin/php-cgi
           ├─4757 /usr/bin/php-cgi
           ├─4758 /usr/bin/php-cgi
           ├─4759 /usr/bin/php-cgi
           ├─4760 /usr/bin/php-cgi
           ├─4761 /usr/bin/php-cgi
           ├─4762 /usr/bin/php-cgi
           ├─4763 /usr/bin/php-cgi
           ├─4764 /usr/bin/php-cgi
           ├─4765 /usr/bin/php-cgi
           ├─4766 /usr/bin/php-cgi
           ├─4767 /usr/bin/php-cgi
           ├─4768 /usr/bin/php-cgi
           ├─4769 /usr/bin/php-cgi
           ├─4770 /usr/bin/php-cgi
           ├─4771 /usr/bin/php-cgi
           ├─4772 /usr/bin/php-cgi
           ├─4773 /usr/bin/php-cgi
           ├─4774 /usr/bin/php-cgi
           └─4775 /usr/bin/php-cgi
```


### 3. Дополнить unit-файл httpd (он же apache) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.  

Для запуска нескольких экземпляров сервиса будем использовать шаблон в конфигурации файла окружения (/usr/lib/systemd/system/httpd.service ):  
Копируем файл из /usr/lib/systemd/system/, cp /usr/lib/systemd/system/httpd.service /etc/systemd/system, далее переименовываем mv /etc/systemd/system/httpd.service /etc/systemd/system/httpd@.service и приводим к виду:

```
 cat httpd@first.service 
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

```
cat httpd@second.service 
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-%I
ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
ExecStop=/bin/kill -WINCH ${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want
# it to kill httpd after TimeoutStopSec if something went wrong during the
# graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give
# httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

В самом файле окружения (которых будет два) задается опция для запуска веб-сервера с необходимм конфигурационным файлом:

```
# /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
```

```
# /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
```

Соответственно в директорию с конфигами httpd, кладём 2 конфига first.conf и second.conf:

```
grep -P "^PidFile|^Listen" first.conf 
PidFile "/var/run/httpd-first.pid"
Listen 80
```

```
grep -P "^PidFile|^Listen" second.conf 
PidFile "/var/run/httpd-second.pid"
Listen 8080
```

Запускаем Vagrantfile и проверяем:

```
[root@Lesson9 ~]# systemctl status httpd@first.service
● httpd@first.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@first.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2023-01-19 11:37:10 UTC; 5h 44min ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 4791 (httpd)

```
 
```
[root@Lesson9 ~]# systemctl status httpd@second.service
● httpd@second.service - The Apache HTTP Server
   Loaded: loaded (/etc/systemd/system/httpd@second.service; disabled; vendor preset: disabled)
   Active: active (running) since Thu 2023-01-19 11:37:10 UTC; 5h 45min ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 4801 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/system-httpd.slice/httpd@second.service
```

```
[root@Lesson9 ~]#  ss -tunlp | grep httpd
tcp    LISTEN     0      128    [::]:8080               [::]:*                   users:(("httpd",pid=4807,fd=4),("httpd",pid=4806,fd=4),("httpd",pid=4805,fd=4),("httpd",pid=4804,fd=4),("httpd",pid=4803,fd=4),("httpd",pid=4802,fd=4),("httpd",pid=4801,fd=4))
tcp    LISTEN     0      128    [::]:80                 [::]:*                   users:(("httpd",pid=4797,fd=4),("httpd",pid=4796,fd=4),("httpd",pid=4795,fd=4),("httpd",pid=4794,fd=4),("httpd",pid=4793,fd=4),("httpd",pid=4792,fd=4),("httpd",pid=4791,fd=4))
```



### 4. ⭐  Скачать демо-версию Atlassian Jira и переписать основной скрипт запуска на unit-файл.  
Данная часть выполнялась на ВМ с Centos 8 т.к. пришлось делать много отладки, а не через vagrant.

Отключаем SELINUX.

Скачиваем архив JIRA.

```
[root@localhost Downloads]# wget https://product-downloads.atlassian.com/software/jira/downloads/atlassian-jira-software-9.4.1.tar.gz
```

Разархивируем:

```
tar -zxvf atlassian-jira-software-9.4.1.tar.gz -C /opt/
```

Создаём домашнюю директорию

```
mkdir /jirasoftware-home
```

Устанавливаем java, задаём переменные, конфигурируем jira:

```
yum install java-1.8.0-openjdk-devel

export JIRA_HOME=/jirasoftware-home

export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.362.b01-0.3.ea.el8.x86_64/jre

[root@localhost bin]# ./config.sh 
```


Создаём Unit файл:

```
touch /lib/systemd/system/jira.service
chmod 664 /lib/systemd/system/jira.service
```

```
[root@localhost bin]# cat /lib/systemd/system/jira.service
[Unit] 
Description=Atlassian Jira
After=network.target

[Service] 
Type=forking
User=root
LimitNOFILE=20000
ExecStart=/opt/atlassian-jira-software-9.4.1-standalone/bin/start-jira.sh
ExecStop=/opt/atlassian-jira-software-9.4.1-standalone/bin/stop-jira.sh

[Install] 
WantedBy=multi-user.target 
```

Запускаем сервис и проверяем:

```
systemctl daemon-reload
systemctl enable jira.service
systemctl start jira.service
systemctl status jira.service
```

```
[root@localhost bin]# systemctl status jira.service
● jira.service - Atlassian Jira
   Loaded: loaded (/usr/lib/systemd/system/jira.service; enabled; vendor preset: disabled)
   Active: active (running) since Thu 2023-01-19 14:14:09 EST; 7s ago
  Process: 38035 ExecStart=/opt/atlassian-jira-software-9.4.1-standalone/bin/start-jira.sh (code=exited, status=0/SUCCESS)
 Main PID: 38073 (java)
    Tasks: 46 (limit: 23340)
   Memory: 290.1M
   CGroup: /system.slice/jira.service
           └─38073 /usr/bin/java -Djava.util.logging.config.file=/opt/atlassian-jira-software-9.4.1-standalone/conf/logging.properties -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager -Xms384m -Xmx204>

Jan 19 14:14:09 localhost.localdomain start-jira.sh[38046]: [1B blob data]
Jan 19 14:14:09 localhost.localdomain start-jira.sh[38046]:       Atlassian Jira
Jan 19 14:14:09 localhost.localdomain start-jira.sh[38046]:       Version : 9.4.1
```
![Image 1](Lesson9/jira.jpg)

</details>


## Lesson10 - Bash script.

<details>

#### Задача

Написать скрипт для CRON, который раз в час будет формировать письмо и отправлять на заданную почту.  
Необходимая информация в письме:  
- Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;  
- Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;  
- Ошибки веб-сервера/приложения c момента последнего запуска;  
- Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.  
- Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.  
- В письме должен быть прописан обрабатываемый временной диапазон.  

#### Решение

Установим Postfix localhost для отправки почты:
```
sudo apt-get install -y mailutils
```
Защита от мультизапуска через использование утилиты flock в crontab -e.


```
crontab -e
*/5 * * * * /usr/bin/flock -w 600 /var/tmp/myscript.lock /home/mity/Documents/OTUS_Linux_Prof/Lesson10/checksc.sh
```
Эта команда запустит /root/myscript.sh и создаст lock-файл для данного процесса. Пока он активен, новый вызов данного скрипта не произойдет.  
После завершения программы, блокировка файла снимается и процесс может быть снова запущен.  
Параметр -w 600 определяет время ожидания команды flock на освобождение lock-файла.  

Файлы:

1. [checksc.sh] - скрипт-парсер.
2. [access-4560-644067.log] - файл логов.
3. [lines] - файл в который записывается последняя доступная строка, при след. запуске файл будет парситься со след. строки, указанной в файле.
4. [mail_msg] - Результат, который приходит на почту


[checksc.sh]:https://github.com/adastraaero/OTUS_LinuxProf/blob/main/Lesson10/checksc.sh
[access-4560-644067.log]:https://github.com/adastraaero/OTUS_LinuxProf/blob/main/Lesson10/access-4560-644067.log
[lines]:https://github.com/adastraaero/OTUS_LinuxProf/blob/main/Lesson10/lines
[mail_msg]:https://github.com/adastraaero/OTUS_LinuxProf/blob/main/Lesson10/mail_msg























</details>




## Lesson15 - Автоматизация администрирования. Ansible-1

<details>

#### Задача
Подготовить стенд на Vagrant как минимум с одним сервером. На этом  
сервере используя Ansible необходимо развернуть nginx со следующими условиями:  
- необходимо использоватþ модуль yum/apt
- конфигурационные файлы должны быть взяты из шаблона jinja2 с переменными
- после установки nginx должен быть в режиме enabled в systemd  
- должен быть использован notify для старта nginx после установки  
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменную в Ansible  
⭐ Сделать все это с использованием Ansible роли



Базовые сведения и примеры работы с Ansible брал из своего репозитория, в котором тренируюсь работе с Ansible/Terraform/YandexCloud/Packer https://github.com/adastraaero/yandex-tf-ans-pck

Правим Vagrantfile, чтобы машина собиралась быстрее, можно было проверить nginx используя проброс портов,добавляем провижнер для развертывания роли:

```
# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
  :nginx => {
        :box_name => "centos/7"
  }
}

Vagrant.configure("2") do |config|

  MACHINES.each do |boxname, boxconfig|

      config.vm.define boxname do |box|

          box.vm.box = boxconfig[:box_name]
          box.vm.host_name = boxname.to_s

          #box.vm.network "private_network", ip: "192.168.50.10"
          box.vm.network "forwarded_port", guest: 8080, host: 8080
          box.vm.provider :virtualbox do |vb|
            vb.customize ["modifyvm", :id, "--memory", "2048"]
            vb.customize ["modifyvm", :id, "--cpus", "2"]
          end
          
          box.vm.provision "shell", inline: <<-SHELL
            mkdir -p ~root/.ssh; cp ~vagrant/.ssh/auth* ~root/.ssh
            sed -i '65s/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
            systemctl restart sshd
          SHELL
          
          box.vm.provision "ansible" do |ansible|
            ansible.playbook = "playbook/web.yml"
            ansible.become = "true"
          end

      end
  end
end

```

Командой ansible-galaxy init roles/nginx создаём шаблон роли.

```
 tree roles/nginx/
roles/nginx/
├── defaults
│   └── main.yml
├── files
├── handlers
│   └── main.yml
├── meta
│   └── main.yml
├── README.md
├── tasks
│   ├── main.yml
│   └── redhat.yml
├── templates
│   ├── index.html.j2
│   └── nginx.conf.j2
├── tests
│   ├── inventory
│   └── test.yml
└── vars
    └── main.yml

```

Создаём плейбук для запуска роли:

```
cat playbook/web.yml 
---
  - name: Install Nginx
    hosts: nginx
    become: yes

    roles:
     - nginx

```

Используем данные из Ansible Facts в j2 шаблоне для index.html:

```
cat roles/nginx/templates/index.html.j2 
Hey testing {{ ansible_os_family }}

```

Согласно ДЗ используем переменную (как вариант) для указания порта работы nginx:


```
cat roles/nginx/vars/main.yml 
---
# vars file for roles/nginx

nginx_listen_port: 8080
```

```
cat roles/nginx/templates/nginx.conf.j2 
# {{ ansible_managed }}
events {
 worker_connections 1024;
}
http {
 server {
 listen {{ nginx_listen_port }} default_server;
 server_name default_server;
 root /usr/share/nginx/html;
 location / {
 }
 }
}
```

Запускаем и проверяем

```
sudo vagrant up
Bringing machine 'nginx' up with 'virtualbox' provider...
==> nginx: Importing base box 'centos/7'...
==> nginx: Matching MAC address for NAT networking...
==> nginx: Checking if box 'centos/7' version '2004.01' is up to date...
==> nginx: Setting the name of the VM: Lesson15_nginx_1673797626257_21972
==> nginx: Clearing any previously set network interfaces...
==> nginx: Preparing network interfaces based on configuration...
    nginx: Adapter 1: nat
==> nginx: Forwarding ports...
    nginx: 8080 (guest) => 8080 (host) (adapter 1)
    nginx: 22 (guest) => 2222 (host) (adapter 1)
==> nginx: Running 'pre-boot' VM customizations...
==> nginx: Booting VM...
==> nginx: Waiting for machine to boot. This may take a few minutes...
    nginx: SSH address: 127.0.0.1:2222
    nginx: SSH username: vagrant
    nginx: SSH auth method: private key
    nginx: 
    nginx: Vagrant insecure key detected. Vagrant will automatically replace
    nginx: this with a newly generated keypair for better security.
    nginx: 
    nginx: Inserting generated public key within guest...
    nginx: Removing insecure key from the guest if it's present...
    nginx: Key inserted! Disconnecting and reconnecting using new SSH key...
==> nginx: Machine booted and ready!
==> nginx: Checking for guest additions in VM...
    nginx: No guest additions were detected on the base box for this VM! Guest
    nginx: additions are required for forwarded ports, shared folders, host only
    nginx: networking, and more. If SSH fails on this machine, please install
    nginx: the guest additions and repackage the box to continue.
    nginx: 
    nginx: This is not an error message; everything may continue to work properly,
    nginx: in which case you may ignore this message.
==> nginx: Setting hostname...
==> nginx: Rsyncing folder: /home/mity/Documents/OTUS_Linux_Prof/Lesson15/ => /vagrant
==> nginx: Running provisioner: shell...
    nginx: Running: inline script
==> nginx: Running provisioner: ansible...
    nginx: Running ansible-playbook...
[DEPRECATION WARNING]: "include" is deprecated, use include_tasks/import_tasks 
instead. This feature will be removed in version 2.16. Deprecation warnings can
 be disabled by setting deprecation_warnings=False in ansible.cfg.

PLAY [Install Nginx] ***********************************************************

TASK [Gathering Facts] *********************************************************
ok: [nginx]

TASK [nginx : Install EPEL] ****************************************************
changed: [nginx]

TASK [nginx : Install Nginx package] *******************************************
changed: [nginx]

TASK [nginx : Enable service nginx, and not touch the state] *******************
changed: [nginx]

TASK [nginx : Change HTML] *****************************************************
changed: [nginx]

TASK [nginx : Create NGINX config file from template] **************************
changed: [nginx]

RUNNING HANDLER [nginx : restart nginx] ****************************************
changed: [nginx]

RUNNING HANDLER [nginx : reload nginx] *****************************************
changed: [nginx]

PLAY RECAP *********************************************************************
nginx                      : ok=8    changed=7    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson15$ curl http://localhost:8080
Hey testing RedHat
```

Ответ от сервера nginx  на порту 8080 получен, роль установлена.

</details>


## Lesson17 - SELINUX

<details>


1. Запустить nginx на нестандартном порту 3-мя разными способами:  
* переключатели setsebool;  
* добавление нестандартного порта в имеющийся тип;  
* формирование и установка модуля SELinux.  
* К сдаче:  
* README с описанием каждого решения (скриншоты и демонстрация приветствуются).  

2. Обеспечить работоспособность приложения при включенном selinux.  
* развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems;  
* выяснить причину неработоспособности механизма обновления зоны (см. README);  
* предложить решение (или решения) для данной проблемы;  
* выбрать одно из решений для реализации, предварительно обосновав выбор;  
* реализовать выбранное решение и продемонстрировать его работоспособность.  
* К сдаче:
* README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;  
* исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.  


### Полезные данные для работы:

Режим по умолчанию - /etc/sysconfig/selinux

Файлы политик размещаются по пути - /etc/selinux/targeted/contexts/files  

Лог аудита храниться в файле /var/log/audit/audit.log

Просмотреть текущие правила - sesearch -A -s httpd_t

Правильно задать контекст ветвей файловой системы необходимо через semanage

```
semanage fcontext -a -t httpd_sys_content_t "/html(/.*)?"

```

audit2why - преобразовывает сообщения аудита SELinux в описание причины отказа  в  доступе (audit2allow -w)  

audit2allow  -  создаёт  правила  политики SELinux allow/dontaudit из журналов отклонённых операций.
При создании модуля создается файл .te (Type Enforcement) и файл .pp (скомпилированный пакет политики).

```
audit2allow -M httpd_add --debug < /var/log/audit/audit.log
```

Включение созданного модуля 
```
semodule -i httpd_add.pp. Убедиться что модуль подключен - semodule -l | grep httpd_add
```

Удаление модуля
```
semodule -r httpd_add
```



### 1. Запустить nginx на нестандартном порту 3-мя разными способами:  


#### Метод 1 (setsebool)

Запускаем Vagrantfile и видим, что nginx не запустился.

```
linux: ● nginx.service - The nginx HTTP and reverse proxy server
    selinux:    Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
    selinux:    Active: failed (Result: exit-code) since Sat 2023-01-21 19:09:34 UTC; 9ms ago
    selinux:   Process: 2787 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
    selinux:   Process: 2786 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
    selinux: 
    selinux: Jan 21 19:09:34 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
    selinux: Jan 21 19:09:34 selinux nginx[2787]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
    selinux: Jan 21 19:09:34 selinux nginx[2787]: nginx: [emerg] bind() to 0.0.0.0:4881 failed (13: Permission denied)
    selinux: Jan 21 19:09:34 selinux nginx[2787]: nginx: configuration file /etc/nginx/nginx.conf test failed
    selinux: Jan 21 19:09:34 selinux systemd[1]: nginx.service: control process exited, code=exited status=1
    selinux: Jan 21 19:09:34 selinux systemd[1]: Failed to start The nginx HTTP and reverse proxy server.
    selinux: Jan 21 19:09:34 selinux systemd[1]: Unit nginx.service entered failed state.
    selinux: Jan 21 19:09:34 selinux systemd[1]: nginx.service failed.
```

Запускаем audit2why  и анализируем лог:
```
[root@selinux ~]# audit2why < /var/log/audit/audit.log
type=AVC msg=audit(1674328174.938:800): avc:  denied  { name_bind } for  pid=2787 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

	Was caused by:
	The boolean nis_enabled was set incorrectly. 
	Description:
	Allow nis to enabled

	Allow access by executing:
	# setsebool -P nis_enabled 1
```

Выполняем вышепредложенную рекомендацию
```
setsebool -P nis_enabled 1
```

Проверяем, что запустилось.
```
[root@selinux ~]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2023-01-21 19:31:24 UTC; 1s ago
  Process: 2958 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 2956 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 2955 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 2960 (nginx)
   CGroup: /system.slice/nginx.service
           ├─2960 nginx: master process /usr/sbin/nginx
           └─2962 nginx: worker process
```

#### Метод 2 (setsebool)

Смотрим какие порты могут работать по http(видим, что нашего порта нет в списке):

```
[root@selinux ~]# semanage port -l | grep htt
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
```

Добавляем порт из конфига nginx и проверяем:

```
[root@selinux ~]# semanage port -a -t http_port_t -p tcp 4881
[root@selinux ~]# systemctl restart nginx.service 
[root@selinux ~]# semanage port -l | grep htt
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
[root@selinux ~]# systemctl status nginx.service 
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2023-01-21 19:48:46 UTC; 28s ago
  Process: 2902 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 2900 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 2899 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 2904 (nginx)
   CGroup: /system.slice/nginx.service
           ├─2904 nginx: master process /usr/sbin/nginx
           └─2906 nginx: worker process

```

#### Метод 3 (формирование и установка модуля SELinux)

Скомпилируем модуль на основе лог файла аудита с инфой о запретах:

```
[root@selinux ~]# audit2allow -M httpd_add --debug < /var/log/audit/audit.log
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i httpd_add.pp
```
Устанавливаем модуль и проверяем:

```
[root@selinux ~]# semodule -i httpd_add.pp
[root@selinux ~]# semodule -l | grep http
httpd_add	1.0
Failed to restart ngix.service: Unit not found.
[root@selinux ~]# systemctl restart nginx.service
[root@selinux ~]# systemctl status nginx.service
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Sat 2023-01-21 20:13:04 UTC; 5s ago
  Process: 2956 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 2954 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 2953 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 2958 (nginx)
   CGroup: /system.slice/nginx.service
           ├─2958 nginx: master process /usr/sbin/nginx
           └─2960 nginx: worker process

Jan 21 20:13:04 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Jan 21 20:13:04 selinux nginx[2954]: nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
Jan 21 20:13:04 selinux nginx[2954]: nginx: configuration file /etc/nginx/nginx.conf test is successful
Jan 21 20:13:04 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
```

![Image 1](Lesson17/Lesson17SCR1.jpg)


2. Обеспечить работоспособность приложения при включенном selinux.  

Подключаемся к клиенту и пробуем внести изменеия в зону:
```
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
```


Видим, что на клиенте отсутствуют ошибки.

```
[root@client ~]# cat /var/log/audit/audit.log | audit2why
```

Не закрывая сессию на клиенте, подключимся к серверу ns01 и проверим логи SELinux:

```
[vagrant@ns01 ~]$ sudo -i
[root@ns01 ~]# cat /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1674333563.659:1888): avc:  denied  { create } for  pid=5085 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0

	Was caused by:
		Missing type enforcement (TE) allow rule.

		You can use audit2allow to generate a loadable module to allow this access.

```

В логах мы видим, что ошибка в контексте безопасности. Вместо типа named_t используется тип etc_t. Проверим данную проблему в каталоге /etc/named.

```
[root@ns01 ~]# ls -Zla /etc/named/*
-rw-rw----. 1 system_u:object_r:etc_t:s0       root named 784 Jan 21 20:31 /etc/named/named.50.168.192.rev
-rw-rw----. 1 system_u:object_r:etc_t:s0       root named 610 Jan 21 20:30 /etc/named/named.dns.lab
-rw-rw----. 1 system_u:object_r:etc_t:s0       root named 609 Jan 21 20:30 /etc/named/named.dns.lab.view1
-rw-rw----. 1 system_u:object_r:etc_t:s0       root named 657 Jan 21 20:31 /etc/named/named.newdns.lab

/etc/named/dynamic:
total 8
drw-rwx---. 2 unconfined_u:object_r:etc_t:s0   root  named  56 Jan 21 20:31 .
drw-rwx---. 3 system_u:object_r:etc_t:s0       root  named 121 Jan 21 20:31 ..
-rw-rw----. 1 system_u:object_r:etc_t:s0       named named 509 Jan 21 20:30 named.ddns.lab
-rw-rw----. 1 system_u:object_r:etc_t:s0       named named 509 Jan 21 20:31 named.ddns.lab.view1
[root@ns01 ~]# 

```

Тут мы также видим, что контекст безопасности неправильный. Проблема заключается в том, что конфигурационные файлы лежат в другом каталоге. Посмотреть в каком каталоги должны лежать, файлы, чтобы на них распространялись правильные политики SELinux можно с помощью команды:

```
sudo semanage fcontext -l | grep named
```

Изменим тип контекста безопасности для каталога /etc/named:

```
[root@ns01 ~]# chcon -R -t named_zone_t /etc/named
[root@ns01 ~]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab

```

Попробуем снова внести изменения с клиента и проверяем:

```
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> quit
[root@client ~]# cat /var/log/audit/audit.log | audit2why
[root@client ~]# nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
[root@client ~]# dig www.ddns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.10 <<>> www.ddns.lab
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 11363
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 1, ADDITIONAL: 2

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;www.ddns.lab.			IN	A

;; ANSWER SECTION:
www.ddns.lab.		60	IN	A	192.168.50.15

;; AUTHORITY SECTION:
ddns.lab.		3600	IN	NS	ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.		3600	IN	A	192.168.50.10

;; Query time: 1 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Sat Jan 21 21:16:55 UTC 2023
;; MSG SIZE  rcvd: 96

```
Работает!

![Image 2](Lesson17/Lesson17SCR2.jpg)


Проблема с обновлением зоны заключалась в том, что Selinux блокировал доступ к обновлению файлов динамического обновления для DNS сервера

</details>


## Lesson18 - Docker

<details>

### Задание
* Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx).  
* Определите разницу между контейнером и образом. Вывод опишите в домашнем задании.  
* Ответьте на вопрос: Можно ли в контейнере собрать ядро?  
* Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий.  

### Полезные данные для работы:

Удаление контейнеров и имеджей:

```
docker rm -vf $(docker ps -a -q)
docker rmi -f $(docker images -a -q)
```
Более сложные примеры - https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes

Send a KILL signal to a container

```
 docker kill my_container
```

Подключиться внутрь контейнера:

```
docker exec -it alpcontainer sh
```

Инструкции Dockerfile:

<details>

| Инструкция | Описание |
|------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| FROM | Задаёт базовый (родительский) образ. |
| LABEL | Описывает метаданные. Например — сведения о том, кто создал и поддерживает образ. |
| ENV | Устанавливает постоянные переменные среды. |
| RUN | Выполняет команду и создаёт слой образа. Используется для установки в контейнер пакетов. |
| COPY | Копирует в контейнер файлы и директории. |
| ADD | Копирует файлы и директории в контейнер, может распаковывать локальные .tar-файлы. |
| CMD | Описывает команду с аргументами, которую нужно выполнить когда контейнер будет запущен. Аргументы могут быть переопределены при запуске контейнера. В файле может присутствовать лишь одна инструкция CMD. |
| WORKDIR | Задаёт рабочую директорию для следующей инструкции. |
| ARG | Задаёт переменные для передачи Docker во время сборки образа. |
| ENTRYPOINT | Предоставляет команду с аргументами для вызова во время выполнения контейнера. Аргументы не переопределяются. |
| EXPOSE | Указывает на необходимость открыть порт. |
| VOLUME | Создаёт точку монтирования для работы с постоянным хранилищем. |

</details>








### Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx).  

Создаём Dockerfile на базе alpine и файлы для изменения конфига nginx.

```
FROM alpine:latest

RUN apk update && apk upgrade && apk add nginx && apk add bash



EXPOSE 80

COPY host/default.conf /etc/nginx/http.d/
COPY host/index.html /var/www/default/html/


CMD ["nginx", "-g", "daemon off;"]
```

cat Docker/host/index.html 
Otus Docker Lab!




Собираем образ:
```
docker build -t alpnginx .
Sending build context to Docker daemon  4.608kB
Step 1/6 : FROM alpine:latest
latest: Pulling from library/alpine
8921db27df28: Pull complete 
Digest: sha256:f271e74b17ced29b915d351685fd4644785c6d1559dd1f2d4189a5e851ef753a
Status: Downloaded newer image for alpine:latest
 ---> 042a816809aa
Step 2/6 : RUN apk update && apk upgrade && apk add nginx && apk add bash
 ---> Running in 60cb745d6e9d
fetch https://dl-cdn.alpinelinux.org/alpine/v3.17/main/x86_64/APKINDEX.tar.gz
fetch https://dl-cdn.alpinelinux.org/alpine/v3.17/community/x86_64/APKINDEX.tar.gz
v3.17.1-113-g8adfed785b [https://dl-cdn.alpinelinux.org/alpine/v3.17/main]
v3.17.1-111-gd059a0bf3b [https://dl-cdn.alpinelinux.org/alpine/v3.17/community]
OK: 17813 distinct packages available
OK: 7 MiB in 15 packages
(1/2) Installing pcre (8.45-r2)
(2/2) Installing nginx (1.22.1-r0)
Executing nginx-1.22.1-r0.pre-install
Executing nginx-1.22.1-r0.post-install
Executing busybox-1.35.0-r29.trigger
OK: 9 MiB in 17 packages
(1/4) Installing ncurses-terminfo-base (6.3_p20221119-r0)
(2/4) Installing ncurses-libs (6.3_p20221119-r0)
(3/4) Installing readline (8.2.0-r0)
(4/4) Installing bash (5.2.15-r0)
Executing bash-5.2.15-r0.post-install
Executing busybox-1.35.0-r29.trigger
OK: 11 MiB in 21 packages
Removing intermediate container 60cb745d6e9d
 ---> b6f1debb4c7a
Step 3/6 : EXPOSE 80
 ---> Running in 7c7db2fa74d5
Removing intermediate container 7c7db2fa74d5
 ---> 218043f0447c
Step 4/6 : COPY host/default.conf /etc/nginx/http.d/
 ---> 2fef8d8a5cdd
Step 5/6 : COPY host/index.html /var/www/default/html/
 ---> 15dace252457
Step 6/6 : CMD ["nginx", "-g", "daemon off;"]
 ---> Running in 408da1a40376
Removing intermediate container 408da1a40376
 ---> 72e0c7fb1a28
Successfully built 72e0c7fb1a28
Successfully tagged alpnginx:latest
```

Смотрим что собралось:

```
docker images
REPOSITORY   TAG       IMAGE ID       CREATED              SIZE
alpnginx     latest    72e0c7fb1a28   About a minute ago   13.3MB
alpine       latest    042a816809aa   12 days ago          7.05MB
```

Запускаем контейнер:
```
docker run -d --name alpcontainer -p 8081:80 alpnginx
b7a6ef46bd08b4bed5b3b34e4d19bda4dc9d437af8bc900a33aed56b5d51af93
```

Проверяем, что контейнер запустился:

```
docker ps
CONTAINER ID   IMAGE      COMMAND                  CREATED          STATUS          PORTS                                   NAMES
b7a6ef46bd08   alpnginx   "nginx -g 'daemon of…"   47 seconds ago   Up 46 seconds   0.0.0.0:8081->80/tcp, :::8081->80/tcp   alpcontainer
```

Проверяем через localhost:
```
curl localhost:8081
Otus Docker Lab!

```

Проверяем через подключение в контейнер:

```
mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson13/Docker$ docker exec -it alpcontainer sh
/ # cat /var/www/default/html/index.html 
Otus Docker Lab!
```


### Определите разницу между контейнером и образом. Вывод опишите в домашнем задании. 

Образ - шаблон приложения, который содержит слои файловой системы в режиме "только-чтение".  

Контейнер - запущенный образ приложения, который кроме нижних слоев в режиме "только чтение" содержит верхний слой в режиме "чтение-запись.


### Ответьте на вопрос: Можно ли в контейнере собрать ядро?  
Ядро собрать можно. Загрузиться нет, т.к. контейнер использует ядро системы. 


### Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий. 

https://hub.docker.com/layers/adastraaero/otus/alpnginxnew/images/sha256-68e3854fabc5f4f445e3f5c29a8fead48ab713200f8f774ed0683dba28b16662?context=repo


</details>


## Lesson21 (Системы мониторинга)


<details>

### Задача:

Настроить дашборд с 4-мя графиками:  
* память   
* процессор  
* диск  
* сеть  
Настроить на одной из систем:
zabbix (использовать screen (комплексный экран);
prometheus - grafana.

Данное ДЗ делал на ВМ UBUNTU на свежей версии zabbix.

```
mity@ubuntu:~$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 20.04.5 LTS
Release:	20.04
Codename:	focal
```

Установим версию MariaDB 10.5 т.к. более низкие не поддерживаются:

```
sudo apt update && sudo apt upgrade
sudo apt -y install software-properties-common
sudo apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
sudo add-apt-repository 'deb [arch=amd64] http://mariadb.mirror.globo.tech/repo/10.5/ubuntu focal main'
sudo apt update
sudo apt install mariadb-server mariadb-client
sudo mysql_secure_installation
```


Установим Apache:
```
sudo apt install apache2
sudo systemctl start apache2
sudo systemctl enable apache2
```

Установим PHP и модули:

```
 sudo apt install php php-mbstring php-gd php-xml php-bcmath php-ldap php-mysql
```

Отредактируем конфиг:
```
sudo vim /etc/php/7.4/apache2/php.ini

memory_limit 256M
upload_max_filesize 16M
post_max_size 16M
max_execution_time 300
max_input_time 300
max_input_vars 10000
date.timezone="Europe/Moscow"
```

Используем официальную инструкцию для нашей версии сборки - MariaDB/Apache/Ubuntu20.04
https://www.zabbix.com/download?zabbix=6.2&os_distribution=ubuntu&os_version=20.04&components=server_frontend_agent&db=mysql&ws=apache

Установка репозитория:
```
wget https://repo.zabbix.com/zabbix/6.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.2-4%2Bubuntu20.04_all.deb
dpkg -i zabbix-release_6.2-4+ubuntu20.04_all.deb
apt update 
```

Установка сервера, фронта и агента:
```
apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent
```

Инициализация БД и установка схемы БД:

```
mysql -uroot -p
password
mysql> create database zabbix character set utf8mb4 collate utf8mb4_bin;
mysql> create user zabbix@localhost identified by 'password';
mysql> grant all privileges on zabbix.* to zabbix@localhost;
mysql> set global log_bin_trust_function_creators = 1;
mysql> quit; 

zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix 

mysql -uroot -p
password
mysql> set global log_bin_trust_function_creators = 0;
mysql> quit; 
```

Правим пароль:
```
vim /etc/zabbix/zabbix_server.conf 
DBPassword=password
```


```
systemctl restart zabbix-server zabbix-agent apache2
systemctl enable zabbix-server zabbix-agent apache
```

Устанавливаем утилиты для тестирования нагрузки:

```
apt install iperf
apt install stress
apt install stress-ng
```

Настраиваем через GUI комплексный экран (название экрана совпадает с логином в гит) и задаем нагрузку:

```
iperf -c 192.168.83.140 -u -t 300 -b 100M
stress-ng --vm 2 --vm-bytes 4G --timeout 60s
stress -c 2 -i 1 -m 1 --vm-bytes 128M -t 10s
```

![Image 1](Lesson21/Otus.jpg)

</details>


## Lesson22 - Пользователи и группы. Авторизация и аутентификация

<details>

Задание:
Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников.  


### Полезные сведения:
В Linux есть 3 группы пользователей: 
* Администраторы — привелегированные пользователи с полным доступом к системе. По умолчанию в ОС есть такой пользователь — root.    
* Локальные пользователи — их учётные записи создаёт администратор, их права ограничены. Администраторы могут изменять права локальных пользователей.    
* Системные пользователи — учетный записи, которые создаются системой для внутрениих процессов и служб. Например пользователь — nginx.  

Для более точных настроек пользователей можно использовать подключаемые модули аутентификации (PAM). 
PAM (Pluggable Authentication Modules - подключаемые модули аутентификации) — набор библиотек, которые позволяют интегрировать различные методы аутентификации в виде единого API.

#### PAM решает следующие задачи: 
* Аутентификация — процесс подтверждения пользователем своей подлиности. Например: ввод логина и пароля, ssh-ключ и т д. 
* Авторизация — процесс наделения пользователя правами
* Отчетность — запись информации о произошедших событиях
* PAM может быть реализован несколькоми способами: 
* Модуль pam_time — настройка доступа для пользователя с учётом времени
* Модуль pam_exec — настройка доступа для пользователей с помощью скириптов

### Решение
Все действия по созданию пользователей, групп, выполнению скрипта внесены в Vagrantfile.  
На ВМ вручную выполняется только редактирование /etc/pam.d/sshd.  

```
 Описание параметров ВМ
MACHINES = {
  # Имя DV "pam"
  :"pam" => {
              # VM box
              :box_name => "centos/stream8",
              #box_version
              :box_version => "20210210.0",
              # Количество ядер CPU
              :cpus => 4,
              # Указываем количество ОЗУ (В Мегабайтах)
              :memory => 406,
              # Указываем IP-адрес для ВМ
              :ip => "192.168.57.10",
            }
}

Vagrant.configure("2") do |config|
  MACHINES.each do |boxname, boxconfig|
    # Отключаем сетевую папку
    config.vm.synced_folder ".", "/vagrant", disabled: true
    # Добавляем сетевой интерфейс
    config.vm.network "private_network", ip: boxconfig[:ip]
    # Применяем параметры, указанные выше
    config.vm.define boxname do |box|
      box.vm.box = boxconfig[:box_name]
      box.vm.box_version = boxconfig[:box_version]
      box.vm.host_name = boxname.to_s

      box.vm.provider "virtualbox" do |v|
        v.memory = boxconfig[:memory]
        v.cpus = boxconfig[:cpus]
      end
      #копируем с хоста скрипт
      box.vm.provision "file", source: "/home/mity/Documents/OTUS_Linux_Prof/Lesson22/login.sh", destination: "/tmp/"
      box.vm.provision "shell", inline: <<-SHELL
          #Разрешаем подключение пользователей по SSH с использованием пароля
          sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config
          #Добавляем пользователей, назначаем пароли, создаём группы   
          sudo useradd otusadm && sudo useradd otus
          echo "Otus2022!" | sudo passwd --stdin otusadm && echo "Otus2022!" | sudo passwd --stdin otus
          sudo groupadd -f admin
          sudo usermod otusadm -a -G admin
          sudo usermod root -a -G admin
          sudo usermod vagrant -a -G admin
          sudo cp /tmp/login.sh /usr/local/bin/
          #Добавляем скрипту права на запуск
          sudo chmod +x /usr/local/bin/login.sh		
          #Перезапуск службы SSHD
          systemctl restart sshd.service
  	  SHELL
    end
  end
end

```

Проверяем, что пользователи/скрипты созданы, группы назначены, файл с настройка PAM отредактирован.

![Image 1](Lesson22/proverki.jpg)

Проверяем, что пользователи могут подключаться к ВМ по ssh.

![Image 2](Lesson22/sshcheck.jpg)

Меняем дату и проверяем, что пользователь otus не может подключиться, а otus adm может.

![Image 3](Lesson22/datecheck.jpg)


</details>


## Lesson24- Сбор и анализ логов

<details>

### Задание:  
1. В Vagrant разворачиваем 2 виртуальные машины web и log
2. на web настраиваем nginx
3. на log настраиваем центральный лог сервер на любой системе на выбор
journald;
rsyslog;
elk.
4. настраиваем аудит, следящий за изменением конфигов nginx 

Все критичные логи с web должны собираться и локально и удаленно.
Все логи с nginx должны уходить на удаленный сервер (локально только критичные).
Логи аудита должны также уходить на удаленную систему.

### Решение
Листинг Vagrantfile 

192.168.50.10 - nginx
192.168.50.15 - log

```
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "centos/7"

  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  config.vm.define "web" do |web|
    web.vm.network "private_network", ip: "192.168.50.10"
    web.vm.hostname = "web"
    web.vm.provision "shell", path: "web.sh"
  end

  config.vm.define "log" do |log|
    log.vm.network "private_network", ip: "192.168.50.15"
    log.vm.hostname = "log"
    log.vm.provision "shell", path: "log.sh"
  end

end
```
На log отредактируем /etc/rsyslog.conf .

```
# Provides UDP syslog reception
$ModLoad imudp
$UDPServerRun 514

# Provides TCP syslog reception
$ModLoad imtcp
$InputTCPServerRun 514

.
.
.
.

$template RemoteLogs,"/var/log/rsyslog/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& ~

```

Перезапускаем syslog:
```
systemctl restart rsyslog
```

Проверяем открытые порты:

```
s -tulpn | grep 514
udp    UNCONN     0      0         *:514                   *:*                   users:(("rsyslogd",pid=3444,fd=3))
udp    UNCONN     0      0      [::]:514                [::]:*                   users:(("rsyslogd",pid=3444,fd=4))
tcp    LISTEN     0      25        *:514                   *:*                   users:(("rsyslogd",pid=3444,fd=5))
tcp    LISTEN     0      25     [::]:514                [::]:*                   users:(("rsyslogd",pid=3444,fd=6))
```


На web редактируем /etc/nginx/nginx.conf:

```
    access_log syslog:server=192.168.50.15:514,tag=nginx_access main;
    error_log syslog:server=192.168.50.15:514,tag=nginx_error notice;
    access_log syslog:server=192.168.50.15:514,tag=nginx_access,severity=info combined;

```

Проверяем и перезапускаем nginx:

```
nginx -t
systemctl restart nginx

```

Удаляем картинку и проверяем сервер логов:

```
rm /usr/share/nginx/html/img/header-background.png
```

```
[root@log ~]# cat /var/log/rsyslog/web/nginx_access.log 
Mar 26 07:41:35 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:41:35 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" "-"
Mar 26 07:41:35 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:41:35 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
Mar 26 07:41:36 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:41:36 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" "-"
Mar 26 07:41:36 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:41:36 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
[root@log ~]# cat /var/log/rsyslog/web/nginx_access.log 
Mar 26 07:41:35 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:41:35 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" "-"
Mar 26 07:41:35 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:41:35 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
Mar 26 07:41:36 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:41:36 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" "-"
Mar 26 07:41:36 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:41:36 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
Mar 26 07:43:16 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:16 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" "-"
Mar 26 07:43:16 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:16 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
Mar 26 07:43:16 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:16 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" "-"
Mar 26 07:43:16 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:16 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
Mar 26 07:43:17 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:17 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" "-"
Mar 26 07:43:17 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:17 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
Mar 26 07:43:20 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:20 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" "-"
Mar 26 07:43:20 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:20 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
Mar 26 07:43:41 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:41 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0" "-"
Mar 26 07:43:41 web nginx_access: 192.168.50.1 - - [26/Mar/2023:07:43:41 +0300] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/111.0"
[root@log ~]# cat /var/log/rsyslog/web/nginx_error.log
cat: /var/log/rsyslog/web/nginx_error.log: No such file or directory
[root@log ~]# cat /var/log/rsyslog/web/nginx_error.log
Mar 26 07:51:00 web nginx_error: 2023/03/26 07:51:00 [error] 3740#3740: *2 open() "/usr/share/nginx/html/img/centos-logo.png" failed (2: No such file or directory), client: 192.168.50.1, server: _, request: "GET /img/centos-logo.png HTTP/1.1", host: "192.168.50.10", referrer: "http://192.168.50.10/"
Mar 26 07:51:00 web nginx_error: 2023/03/26 07:51:00 [error] 3741#3741: *3 open() "/usr/share/nginx/html/img/html-background.png" failed (2: No such file or directory), client: 192.168.50.1, server: _, request: "GET /img/html-background.png HTTP/1.1", host: "192.168.50.10", referrer: "http://192.168.50.10/"
Mar 26 07:51:00 web nginx_error: 2023/03/26 07:51:00 [error] 3741#3741: *4 open() "/usr/share/nginx/html/img/header-background.png" failed (2: No such file or directory), client: 192.168.50.1, server: _, request: "GET /img/header-background.png HTTP/1.1", host: "192.168.50.10", referrer: "http://192.168.50.10/"
Mar 26 07:51:00 web nginx_error: 2023/03/26 07:51:00 [error] 3740#3740: *2 open() "/usr/share/nginx/html/favicon.ico" failed (2: No such file or directory), client: 192.168.50.1, server: _, request: "GET /favicon.ico HTTP/1.1", host: "192.168.50.10", referrer: "http://192.168.50.10/"

```
![Image 1](Lesson24/Ls26ng1.jpg)

#### Настраиваем аудит 

```
cat /etc/audit/rules.d/audit.rules
## First rule - delete all
-D

## Increase the buffers to survive stress events.
## Make this bigger for busy systems
-b 8192

## Set failure mode to syslog
-f 1

-w /etc/nginx/nginx.conf -p wa -k web_config_changed
-w /etc/nginx/conf.d/ -p wa -k web_config_changed
```

Перезапускаем службу auditd:

```
 service auditd restart
```
Вносим изменения в nginx.conf:

```
search -f /etc/nginx/nginx.conf
----
time->Sun Mar 26 08:20:03 2023
type=CONFIG_CHANGE msg=audit(1679808003.306:1085): auid=1000 ses=4 op=updated_rules path="/etc/nginx/nginx.conf" key="web_config_changed" list=4 res=1
----
time->Sun Mar 26 08:20:03 2023
type=PROCTITLE msg=audit(1679808003.306:1086): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1679808003.306:1086): item=3 name="/etc/nginx/nginx.conf~" inode=67557401 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=CREATE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1679808003.306:1086): item=2 name="/etc/nginx/nginx.conf" inode=67557401 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=DELETE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1679808003.306:1086): item=1 name="/etc/nginx/" inode=67557358 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1679808003.306:1086): item=0 name="/etc/nginx/" inode=67557358 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1679808003.306:1086):  cwd="/usr/share/doc/HTML/img"
type=SYSCALL msg=audit(1679808003.306:1086): arch=c000003e syscall=82 success=yes exit=0 a0=1d97810 a1=1de1ab0 a2=fffffffffffffe80 a3=7ffc5e062420 items=4 ppid=3574 pid=3885 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
----
time->Sun Mar 26 08:20:03 2023
type=CONFIG_CHANGE msg=audit(1679808003.306:1087): auid=1000 ses=4 op=updated_rules path="/etc/nginx/nginx.conf" key="web_config_changed" list=4 res=1
----
time->Sun Mar 26 08:20:03 2023
type=PROCTITLE msg=audit(1679808003.306:1088): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1679808003.306:1088): item=1 name="/etc/nginx/nginx.conf" inode=67557402 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:httpd_config_t:s0 objtype=CREATE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=PATH msg=audit(1679808003.306:1088): item=0 name="/etc/nginx/" inode=67557358 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1679808003.306:1088):  cwd="/usr/share/doc/HTML/img"
type=SYSCALL msg=audit(1679808003.306:1088): arch=c000003e syscall=2 success=yes exit=3 a0=1d97810 a1=241 a2=1a4 a3=0 items=2 ppid=3574 pid=3885 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
----
time->Sun Mar 26 08:20:03 2023
type=PROCTITLE msg=audit(1679808003.308:1089): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1679808003.308:1089): item=0 name="/etc/nginx/nginx.conf" inode=67557402 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1679808003.308:1089):  cwd="/usr/share/doc/HTML/img"
type=SYSCALL msg=audit(1679808003.308:1089): arch=c000003e syscall=188 success=yes exit=0 a0=1d97810 a1=7f46dd57ef6a a2=1dda9d0 a3=24 items=1 ppid=3574 pid=3885 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
----
time->Sun Mar 26 08:20:03 2023
type=PROCTITLE msg=audit(1679808003.308:1090): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1679808003.308:1090): item=0 name="/etc/nginx/nginx.conf" inode=67557402 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1679808003.308:1090):  cwd="/usr/share/doc/HTML/img"
type=SYSCALL msg=audit(1679808003.308:1090): arch=c000003e syscall=90 success=yes exit=0 a0=1d97810 a1=81a4 a2=7ffc5e063aa0 a3=24 items=1 ppid=3574 pid=3885 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
----
time->Sun Mar 26 08:20:03 2023
type=PROCTITLE msg=audit(1679808003.308:1091): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
type=PATH msg=audit(1679808003.308:1091): item=0 name="/etc/nginx/nginx.conf" inode=67557402 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
type=CWD msg=audit(1679808003.308:1091):  cwd="/usr/share/doc/HTML/img"
type=SYSCALL msg=audit(1679808003.308:1091): arch=c000003e syscall=188 success=yes exit=0 a0=1d97810 a1=7f46dd134e2f a2=1de1a60 a3=1c items=1 ppid=3574 pid=3885 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
```
![Image 2](Lesson24/Ls26ng2.png)
#### Настройка пересылки логов аудита на удаленный сервер:

Устанавливаем плагин:

```
yum -y install audispd-plugins
```
Редактируем файлы на web(отредактированные файлы прилагаются в репозитории):

/etc/audit/rules.d/audit.rules
/etc/audisp/plugins.d/au-remote.conf
/etc/audisp/audisp-remote.conf

Редактируем файлы на log(отредактированные файлы прилагаются в репозитории):

/etc/audit/auditd.conf

меняем настройки в etc/nginx/nginx.conf и проверяем.

```
[root@log ~]# grep web /var/log/audit/audit.log 
node=web type=DAEMON_START msg=audit(1679808535.716:6340): op=start ver=2.8.5 format=raw kernel=3.10.0-1127.el7.x86_64 auid=4294967295 pid=4020 uid=0 ses=4294967295 subj=system_u:system_r:auditd_t:s0 res=success
node=web type=CONFIG_CHANGE msg=audit(1679808535.849:1097): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=remove_rule key="web_config_changed" list=4 res=1
node=web type=CONFIG_CHANGE msg=audit(1679808535.849:1098): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=remove_rule key="web_config_changed" list=4 res=1
node=web type=CONFIG_CHANGE msg=audit(1679808535.850:1099): audit_backlog_limit=8192 old=8192 auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 res=1
node=web type=CONFIG_CHANGE msg=audit(1679808535.850:1100): audit_failure=1 old=1 auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 res=1
node=web type=CONFIG_CHANGE msg=audit(1679808535.851:1101): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=add_rule key="web_config_changed" list=4 res=1
node=web type=CONFIG_CHANGE msg=audit(1679808535.856:1102): auid=4294967295 ses=4294967295 subj=system_u:system_r:unconfined_service_t:s0 op=add_rule key="web_config_changed" list=4 res=1
node=web type=SERVICE_START msg=audit(1679808535.856:1103): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=system_u:system_r:init_t:s0 msg='unit=auditd comm="systemd" exe="/usr/lib/systemd/systemd" hostname=? addr=? terminal=? res=success'
node=web type=CONFIG_CHANGE msg=audit(1679808652.307:1104): auid=1000 ses=4 op=updated_rules path="/etc/nginx/nginx.conf" key="web_config_changed" list=4 res=1
node=web type=SYSCALL msg=audit(1679808652.307:1105): arch=c000003e syscall=82 success=yes exit=0 a0=1f34810 a1=214f5e0 a2=fffffffffffffe80 a3=7ffd987e3ca0 items=4 ppid=3574 pid=4067 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
node=web type=CWD msg=audit(1679808652.307:1105):  cwd="/usr/share/doc/HTML/img"
node=web type=PATH msg=audit(1679808652.307:1105): item=0 name="/etc/nginx/" inode=67557358 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PATH msg=audit(1679808652.307:1105): item=1 name="/etc/nginx/" inode=67557358 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PATH msg=audit(1679808652.307:1105): item=2 name="/etc/nginx/nginx.conf" inode=67557402 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=DELETE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PATH msg=audit(1679808652.307:1105): item=3 name="/etc/nginx/nginx.conf~" inode=67557402 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=CREATE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1679808652.307:1105): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
node=web type=CONFIG_CHANGE msg=audit(1679808652.307:1106): auid=1000 ses=4 op=updated_rules path="/etc/nginx/nginx.conf" key="web_config_changed" list=4 res=1
node=web type=SYSCALL msg=audit(1679808652.307:1107): arch=c000003e syscall=2 success=yes exit=3 a0=1f34810 a1=241 a2=1a4 a3=0 items=2 ppid=3574 pid=4067 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
node=web type=CWD msg=audit(1679808652.307:1107):  cwd="/usr/share/doc/HTML/img"
node=web type=PATH msg=audit(1679808652.307:1107): item=0 name="/etc/nginx/" inode=67557358 dev=08:01 mode=040755 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=PARENT cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PATH msg=audit(1679808652.307:1107): item=1 name="/etc/nginx/nginx.conf" inode=67525612 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:httpd_config_t:s0 objtype=CREATE cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1679808652.307:1107): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
node=web type=SYSCALL msg=audit(1679808652.312:1108): arch=c000003e syscall=188 success=yes exit=0 a0=1f34810 a1=7f0b491e6f6a a2=213e010 a3=24 items=1 ppid=3574 pid=4067 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
node=web type=CWD msg=audit(1679808652.312:1108):  cwd="/usr/share/doc/HTML/img"
node=web type=PATH msg=audit(1679808652.312:1108): item=0 name="/etc/nginx/nginx.conf" inode=67525612 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=unconfined_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1679808652.312:1108): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
node=web type=SYSCALL msg=audit(1679808652.312:1109): arch=c000003e syscall=90 success=yes exit=0 a0=1f34810 a1=81a4 a2=7ffd987e5320 a3=24 items=1 ppid=3574 pid=4067 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
node=web type=CWD msg=audit(1679808652.312:1109):  cwd="/usr/share/doc/HTML/img"
node=web type=PATH msg=audit(1679808652.312:1109): item=0 name="/etc/nginx/nginx.conf" inode=67525612 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1679808652.312:1109): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
node=web type=SYSCALL msg=audit(1679808652.312:1110): arch=c000003e syscall=188 success=yes exit=0 a0=1f34810 a1=7f0b48d9ce2f a2=212b4a0 a3=1c items=1 ppid=3574 pid=4067 auid=1000 uid=0 gid=0 euid=0 suid=0 fsuid=0 egid=0 sgid=0 fsgid=0 tty=pts0 ses=4 comm="vim" exe="/usr/bin/vim" subj=unconfined_u:unconfined_r:unconfined_t:s0-s0:c0.c1023 key="web_config_changed"
node=web type=CWD msg=audit(1679808652.312:1110):  cwd="/usr/share/doc/HTML/img"
node=web type=PATH msg=audit(1679808652.312:1110): item=0 name="/etc/nginx/nginx.conf" inode=67525612 dev=08:01 mode=0100644 ouid=0 ogid=0 rdev=00:00 obj=system_u:object_r:httpd_config_t:s0 objtype=NORMAL cap_fp=0000000000000000 cap_fi=0000000000000000 cap_fe=0 cap_fver=0
node=web type=PROCTITLE msg=audit(1679808652.312:1110): proctitle=76696D002F6574632F6E67696E782F6E67696E782E636F6E66
```

![Image 3](Lesson24/Ls26ng3.png)


</details>


## Lesson26 - Резервное копирование


<details>
Задание:  
Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client.  
Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям: 

* директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB;
* репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение;
* имя бекапа должно содержать информацию о времени снятия бекапа;
* глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов;
* резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации;
* написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение;
* настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов.
* Запустите стенд на 30 минут.
* Убедитесь что резервные копии снимаются.
* Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа.


Полезные ссылки:
https://blog.andrewkeech.com/posts/170719_borg.html  
https://interface31.ru/tech_it/2022/01/borg-backup-prostoy-i-sovremennyy-instrument-rezervnogo-kopirovaniya.html  



### Решение

Листинг Vagrantfile 
bserver - машина с доп. диском примонтированным в /var/backup на которую отправляются бекапы.
bclient - машина которая отправляет бекапы.


```
ity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson26$ cat Vagrantfile 
# -*- mode: ruby -*-
# vim: set ft=ruby :
disk_controller = 'IDE' # MacOS. This setting is OS dependent. Details https://github.com/hashicorp/vagrant/issues/8105
 
MACHINES = {
  :bserver => {
        :box_name => "centos/7",
        :box_version => "2004.01",
    :disks => {
        :sata1 => {
            :dfile => './sata1.vdi',
            :size => 2048,
            :port => 1
        },
    }
        
  },
}
 
Vagrant.configure("2") do |config|
 
  MACHINES.each do |boxname, boxconfig|
      config.vm.define "bclient" do |bclient|
       bclient.vm.box = "centos/7" 
       bclient.vm.provision "file", source: "/home/mity/Documents/OTUS_Linux_Prof/Lesson26/files/", destination: "/tmp/"
       bclient.vm.provision "shell", path: "clientscript.sh" 
       bclient.vm.network "private_network", ip: "192.168.11.150"
       bclient.vm.host_name = "client"
      end

      config.vm.define boxname do |box|
 
        box.vm.box = boxconfig[:box_name]
        box.vm.box_version = boxconfig[:box_version]
        box.vm.network "private_network", ip: "192.168.11.160"     
        box.vm.host_name = "server"
        box.vm.provision "shell", path: "serverscript.sh" 

 
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
    end
  end
end
```

Проверяем, что диск подмонтировался:

```
root@server ~]# df -Ht
df: option requires an argument -- 't'
Try 'df --help' for more information.
[root@server ~]# df -Th
Filesystem     Type      Size  Used Avail Use% Mounted on
devtmpfs       devtmpfs  489M     0  489M   0% /dev
tmpfs          tmpfs     496M     0  496M   0% /dev/shm
tmpfs          tmpfs     496M  6.7M  489M   2% /run
tmpfs          tmpfs     496M     0  496M   0% /sys/fs/cgroup
/dev/sdb1      xfs        40G  5.4G   35G  14% /
/dev/sda       ext4      2.0G  6.0M  1.8G   1% /var/backup
tmpfs          tmpfs     100M     0  100M   0% /run/user/1000
```

Скрипт(*clientscript.sh*) который выполняется на клиенте для:
* установки borgbackup
* Создания ключевой пары
* Добавления обоих ВМ в /etc/hosts
* копирования в соответствующие директории таймера, юнита службы, скрипта выполняющего бекап.
* присвоения разрешений на исполнение
* добавление пользователя

```
mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson26$ cat clientscript.sh 
#!/bin/bash
sudo su
timedatectl set-timezone Europe/Moscow
#yum update
yum -y install epel-release
yum repolist
yum -y install vim
yum install ntp -y && systemctl start ntpd && systemctl enable ntpd
echo "192.168.11.150    client" >> /etc/hosts
echo "192.168.11.160    server" >> /etc/hosts
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
cp /tmp/files/borg-backup.sh /etc/
cp /tmp/files/borg-backup.timer /etc/systemd/system
cp /tmp/files/borg-backup.service /etc/systemd/system
chmod +x /etc/borg-backup.sh
yum install borgbackup -y
useradd -m borg
```

Скрипт(*serverscript.sh*) который выполняется на сервере для:
* установки borgbackup
* создания директории /var/backup/
* назначение прав на /var/backup/
* монтирования диска в /var/backup/
* Добавления обоих ВМ в /etc/hosts
* добавление пользователя

```
mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson26$ cat serverscript.sh 
#!/bin/bash
sudo su
timedatectl set-timezone Europe/Moscow
#yum update
yum -y install epel-release
yum -y install vim
yum repolist
yum install ntp -y && systemctl start ntpd && systemctl enable ntpd
yum install borgbackup -y
echo "192.168.11.150	client" >> /etc/hosts
echo "192.168.11.160    server" >> /etc/hosts

useradd -m borg
mkdir ~borg/.ssh
touch ~borg/.ssh/authorized_keys
chown -R borg:borg ~borg/.ssh
mkdir /var/backup
yes | mkfs -t ext4 /dev/sda
mount /dev/sda /var/backup/


chown borg:borg /var/backup
```

Листинг таймера(*borg-backup.timer*):
```
mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson26/files$ cat borg-backup.timer 
[Unit]
Description=Automated Borg Backup Timer

[Timer]
OnCalendar=*:0/5

[Install]
WantedBy=timers.target
```

Листинг юнита(*borg-backup.service*):
```
mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson26/files$ cat borg-backup.service 
[Unit]
Description=Automated Borg Backup
After=network.target

[Service]
Type=oneshot
ExecStart=/etc/borg-backup.sh

[Install]
WantedBy=multi-user.target
```

Листинг скрипта, который выполняет бекапы согласно заданным условиям:

```
mity@ubuntu:~/Documents/OTUS_Linux_Prof/Lesson26/files$ cat borg-backup.sh 
#!/usr/bin/env bash
# the envvar $REPONAME is something you should just hardcode

export REPOSITORY="borg@192.168.11.160:/var/backup"


# Fill in your password here, borg picks it up automatically
export BORG_PASSPHRASE="repokey"

# Backup all of /home except a few excluded directories and files
borg create -v --stats --compression lz4                 \
    $REPOSITORY::'{hostname}-{now:%Y-%m-%d_%H:%M:%S}' /etc \

# Route the normal process logging to journalctl
2>&1

# If there is an error backing up, reset password envvar and exit
if [ "$?" = "1" ] ; then
    export BORG_PASSPHRASE=""
    exit 1
fi

# Prune the repo of extra backups
borg prune -v $REPOSITORY --prefix '{hostname}-'         \
    --keep-minutely=120                                  \
    --keep-daily=90                                       \
    --keep-monthly=12                                     \
    --keep-yearly=1                                     \

borg list $REPOSITORY

# Unset the password
export BORG_PASSPHRASE=""
exit
```

### Выполняем настройку

**заходим на клиента и инициализируем репозиторий**

```
[root@client ~]# borg init -e=repokey borg@192.168.11.160:/var/backup
Enter new passphrase: 
Enter same passphrase again: 
Do you want your passphrase to be displayed for verification? [yN]: n

```

перезагружаем:
```
systemctl daemon-reload
```

Добавляем в автозагрузку:
```
[root@client etc]# systemctl enable borg-backup.timer
Created symlink from /etc/systemd/system/timers.target.wants/borg-backup.timer to /etc/systemd/system/borg-backup.timer.
```

Стартуем и проверяем:
```
[root@client etc]# systemctl start borg-backup.timer
[root@client etc]# systemctl status borg-backup.timer
● borg-backup.timer - Automated Borg Backup Timer
   Loaded: loaded (/etc/systemd/system/borg-backup.timer; enabled; vendor preset: disabled)
   Active: active (waiting) since Sun 2023-01-29 09:32:58 MSK; 2min 35s ago
```

Проверяем работу таймера:

```
[root@client etc]# systemctl list-timers --all
NEXT                         LEFT          LAST                         PASSED      UNIT                         ACTIVATES
Sun 2023-01-29 09:40:00 MSK  3min 46s left Sun 2023-01-29 09:35:08 MSK  1min 4s ago borg-backup.timer            borg-backup.service
```

Проверяем логи:
```
[root@client etc]# journalctl -u borg-backup
-- Logs begin at Sun 2023-01-29 08:28:36 MSK, end at Sun 2023-01-29 09:41:01 MSK. --
Jan 29 09:31:54 client systemd[1]: Starting Automated Borg Backup...
Jan 29 09:31:55 client borg-backup.sh[25152]: Creating archive at "borg@192.168.11.160:/var/backup::client-2023-01-29_09:31:54"
Jan 29 09:31:55 client borg-backup.sh[25152]: ------------------------------------------------------------------------------
Jan 29 09:31:55 client borg-backup.sh[25152]: Archive name: client-2023-01-29_09:31:54
Jan 29 09:31:55 client borg-backup.sh[25152]: Archive fingerprint: 302a3821e0df70a0be5fd12de444465b65a2eadc2faf9066435007435296cd75
Jan 29 09:31:55 client borg-backup.sh[25152]: Time (start): Sun, 2023-01-29 09:31:54
Jan 29 09:31:55 client borg-backup.sh[25152]: Time (end):   Sun, 2023-01-29 09:31:55
Jan 29 09:31:55 client borg-backup.sh[25152]: Duration: 0.29 seconds
Jan 29 09:31:55 client borg-backup.sh[25152]: Number of files: 1714
Jan 29 09:31:55 client borg-backup.sh[25152]: Utilization of max. archive size: 0%
Jan 29 09:31:55 client borg-backup.sh[25152]: ------------------------------------------------------------------------------
Jan 29 09:31:55 client borg-backup.sh[25152]: Original size      Compressed size    Deduplicated size
Jan 29 09:31:55 client borg-backup.sh[25152]: This archive:               28.44 MB             13.51 MB             50.83 kB
Jan 29 09:31:55 client borg-backup.sh[25152]: All archives:              142.22 MB             67.53 MB             12.05 MB
Jan 29 09:31:55 client borg-backup.sh[25152]: Unique chunks         Total chunks
Jan 29 09:31:55 client borg-backup.sh[25152]: Chunk index:                    1304                 8550
Jan 29 09:31:55 client borg-backup.sh[25152]: ------------------------------------------------------------------------------
Jan 29 09:31:57 client borg-backup.sh[25152]: client-2023-01-29_09:21:42           Sun, 2023-01-29 09:21:43 [af7eb64831ff19bf4b7ab3909dc8b5ed62ccde3dba6c4320fbb0cf0f782d741c]
Jan 29 09:31:57 client borg-backup.sh[25152]: client-2023-01-29_09:27:41           Sun, 2023-01-29 09:27:42 [454b57eabf0f7d614dec021dc7d8a6a15ba7f34e30bc0eea1d1e56199de712d4]
Jan 29 09:31:57 client borg-backup.sh[25152]: client-2023-01-29_09:28:01           Sun, 2023-01-29 09:28:01 [48e89a356579ab2e7ff1f07db719088d0542a62dac16f33bfad495f9b16269de]
Jan 29 09:31:57 client borg-backup.sh[25152]: client-2023-01-29_09:31:54           Sun, 2023-01-29 09:31:54 [302a3821e0df70a0be5fd12de444465b65a2eadc2faf9066435007435296cd75]
Jan 29 09:31:57 client systemd[1]: Started Automated Borg Backup.
Jan 29 09:35:08 client systemd[1]: Starting Automated Borg Backup...
Jan 29 09:35:09 client borg-backup.sh[25264]: Creating archive at "borg@192.168.11.160:/var/backup::client-2023-01-29_09:35:09"
Jan 29 09:35:10 client borg-backup.sh[25264]: ------------------------------------------------------------------------------
Jan 29 09:35:10 client borg-backup.sh[25264]: Archive name: client-2023-01-29_09:35:09
Jan 29 09:35:10 client borg-backup.sh[25264]: Archive fingerprint: d000c8303eeec1b88f7183cd52a862276281415d4c1a01b064a534d57b52741d
Jan 29 09:35:10 client borg-backup.sh[25264]: Time (start): Sun, 2023-01-29 09:35:09
Jan 29 09:35:10 client borg-backup.sh[25264]: Time (end):   Sun, 2023-01-29 09:35:10
Jan 29 09:35:10 client borg-backup.sh[25264]: Duration: 0.29 seconds
Jan 29 09:35:10 client borg-backup.sh[25264]: Number of files: 1714
```

Проверяем, что бекапы создаются каждые 5 мин:

```
[root@client etc]# borg list borg@192.168.11.160:/var/backup
Enter passphrase for key ssh://borg@192.168.11.160/var/backup: 
MyFirstBackup-2023-01-29_09:15:28    Sun, 2023-01-29 09:15:28 [7bcd2eb469a502896c2bf4d25de0c002ef84ea6ac57cf635a56255f74c5963ee]
client-2023-01-29_09:21:42           Sun, 2023-01-29 09:21:43 [af7eb64831ff19bf4b7ab3909dc8b5ed62ccde3dba6c4320fbb0cf0f782d741c]
client-2023-01-29_09:27:41           Sun, 2023-01-29 09:27:42 [454b57eabf0f7d614dec021dc7d8a6a15ba7f34e30bc0eea1d1e56199de712d4]
client-2023-01-29_09:28:01           Sun, 2023-01-29 09:28:01 [48e89a356579ab2e7ff1f07db719088d0542a62dac16f33bfad495f9b16269de]
client-2023-01-29_09:31:54           Sun, 2023-01-29 09:31:54 [302a3821e0df70a0be5fd12de444465b65a2eadc2faf9066435007435296cd75]
client-2023-01-29_09:35:09           Sun, 2023-01-29 09:35:09 [d000c8303eeec1b88f7183cd52a862276281415d4c1a01b064a534d57b52741d]
client-2023-01-29_09:40:09           Sun, 2023-01-29 09:40:09 [882e4cb6172cc1d039e1ef82b1a4cabeea8cda69528284cd6c81e83556f07e88]
client-2023-01-29_09:45:08           Sun, 2023-01-29 09:45:09 [3afbc9d2249ae953134a68c9dd78f6c5310715a1b33f9c75194b0ba885add1b4]
client-2023-01-29_09:50:09           Sun, 2023-01-29 09:50:09 [255a763f15a180f7b49f371f3268ced3060252ff0a9ca7a933458fb82beacddb]
client-2023-01-29_09:55:09           Sun, 2023-01-29 09:55:09 [4f9bb26b0a19a452535b065f611670a28ca157e2a101637a81145377c8b72a64]
client-2023-01-29_10:00:09           Sun, 2023-01-29 10:00:09 [d67ef85b13a6dc52e918f8e7e2dfaa15f67172e998945bb410f8815751390e0a]
client-2023-01-29_10:05:09           Sun, 2023-01-29 10:05:09 [4c8c615932cbb0c8158e6d2952cc8e8e50dcc495c5e393039081e9b2185c9387]
client-2023-01-29_10:10:09           Sun, 2023-01-29 10:10:09 [dfd4cc939b41316ac783a52b2b1eeb3c516250ee1be134bfc34f34be028ae1a5]
client-2023-01-29_10:15:09           Sun, 2023-01-29 10:15:09 [d22a6a5a31896118db33c2eae1785947c0821b893be9e3ad560b1fffc88f672a]
client-2023-01-29_10:20:09           Sun, 2023-01-29 10:20:09 [0a2c37d0d0e7820be579457760eaa616ac84e5f9b79a385909e6955eccf1a3dd]
client-2023-01-29_10:25:09           Sun, 2023-01-29 10:25:09 [416f14003c13da4445510f6ae0ea4abce6895b51035dce525cca8621896a866b]
client-2023-01-29_10:30:09           Sun, 2023-01-29 10:30:09 [f6448466fd5f9f363109ea0c46070b8829cab4b1f3d72ac268d586247a902bf6]
client-2023-01-29_10:35:09           Sun, 2023-01-29 10:35:09 [b55f43803ef8011776b00980684814df4190662332691a0739d17aec257d3278]
client-2023-01-29_10:40:09           Sun, 2023-01-29 10:40:09 [6a90f7b903c1d13733b6660e374ea4f5c50856e89ebe8b7931de6f46a8cc2b59]
client-2023-01-29_10:45:09           Sun, 2023-01-29 10:45:09 [32d58439a05a924806e169112721aba84993e8205142ac8b841edc82a7ef66a8]
client-2023-01-29_10:50:09           Sun, 2023-01-29 10:50:09 [ad5c6917956c17d90b4890d08e9ef156321da7d6a3e2dd7ace8a767bc68a7be5]
client-2023-01-29_10:55:09           Sun, 2023-01-29 10:55:09 [e86aa73696e0a1b7afdb8221f629223ba9689d125267d9a161ed2d27c6f39874]
```

Проверяем восстановление:

```
[root@client ~]# mkdir ~/restore && cd ~/restore
[root@client restore]# borg extract borg@192.168.11.160:/var/backup::client-2023-01-29_10:45:09
Enter passphrase for key ssh://borg@192.168.11.160/var/backup: 
[root@client restore]# pwd
/root/restore
[root@client restore]# dir /etc/
adjtime			 chkconfig.d   csh.login		exports      grub.d	  inputrc	 localtime	 my.cnf.d	    pam.d	    profile.d  redhat-release	 securetty	subgid		system-release-cpe  xinetd.d
aliases			 chrony.conf   dbus-1			exports.d    gshadow	  iproute2	 login.defs	 netconfig	    passwd	    protocols  request-key.conf  security	subgid-		tcsd.conf	    yum
aliases.db		 chrony.keys   default			filesystems  gshadow-	  issue		 logrotate.conf  NetworkManager     passwd-	    python     request-key.d	 selinux	subuid		terminfo	    yum.conf
alternatives		 cifs-utils    depmod.d			firewalld    gss	  issue.net	 logrotate.d	 networks	    pkcs11	    qemu-ga    resolv.conf	 services	subuid-		tmpfiles.d	    yum.repos.d
anacrontab		 cron.d        dhcp			fstab	     gssproxy	  krb5.conf	 machine-id	 nfs.conf	    pki		    rc0.d      rpc		 sestatus.conf	sudo.conf	tuned
audisp			 cron.daily    DIR_COLORS		fuse.conf    host.conf	  krb5.conf.d	 magic		 nfsmount.conf	    pm		    rc1.d      rpm		 shadow		sudoers		udev
audit			 cron.deny     DIR_COLORS.256color	gcrypt	     hostname	  ld.so.cache	 man_db.conf	 nsswitch.conf	    polkit-1	    rc2.d      rsyncd.conf	 shadow-	sudoers.d	vconsole.conf
bash_completion.d	 cron.hourly   DIR_COLORS.lightbgcolor	gnupg	     hosts	  ld.so.conf	 mke2fs.conf	 nsswitch.conf.bak  popt.d	    rc3.d      rsyslog.conf	 shells		sudo-ldap.conf	vimrc
bashrc			 cron.monthly  dracut.conf		GREP_COLORS  hosts.allow  ld.so.conf.d	 modprobe.d	 ntp		    postfix	    rc4.d      rsyslog.d	 skel		sysconfig	virc
binfmt.d		 crontab       dracut.conf.d		groff	     hosts.deny   libaudit.conf  modules-load.d  ntp.conf	    ppp		    rc5.d      rwtab		 ssh		sysctl.conf	vmware-tools
borg-backup.sh		 cron.weekly   e2fsck.conf		group	     idmapd.conf  libnl		 motd		 openldap	    prelink.conf.d  rc6.d      rwtab.d		 ssl		sysctl.d	wpa_supplicant
centos-release		 crypttab      environment		group-	     init.d	  libuser.conf	 mtab		 opt		    printcap	    rc.d       samba		 statetab	systemd		X11
centos-release-upstream  csh.cshrc     ethertypes		grub2.cfg    inittab	  locale.conf	 my.cnf		 os-release	    profile	    rc.local   sasl2		 statetab.d	system-release	xdg
```

</details>




## Lesson26Network - Архитектура сетей

<details>

### Теоретическая часть

#### В теоретической части нам необходимо продумать топологию сети, а также:
* Найти свободные подсети
* Посчитать количество узлов в каждой подсети, включая свободные
* Указать Broadcast-адрес для каждой подсети
* Проверить, нет ли ошибок при разбиении


### Решение


![Image 1](Lesson26Network/network.jpg)

![Image 2](Lesson26Network/network1.jpg)

### Практическая часть

* Соединить офисы в сеть согласно схеме и настроить роутинг
* Все сервера и роутеры должны ходить в инет черз inetRouter
* Все сервера должны видеть друг друга
* У всех новых серверов отключить дефолт на нат (eth0), который вагрант поднимает для связи


### Решение(без Ansible)

Проверяем:

*** [vagrant@office2Server ~]$ *** traceroute yandex.ru
```
traceroute to yandex.ru (5.255.255.70), 30 hops max, 60 byte packets
 1  gateway (192.168.1.1)  0.805 ms  0.740 ms  0.551 ms
 2  192.168.253.1 (192.168.253.1)  2.148 ms  1.941 ms  1.892 ms
 3  192.168.255.1 (192.168.255.1)  1.576 ms  2.889 ms  2.729 ms
30  * * *
[vagrant@office2Server ~]$ ping yandex.ru
PING yandex.ru (77.88.55.60) 56(84) bytes of data.
64 bytes from yandex.ru (77.88.55.60): icmp_seq=1 ttl=57 time=13.9 ms
64 bytes from yandex.ru (77.88.55.60): icmp_seq=2 ttl=57 time=12.9 ms
--- yandex.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
rtt min/avg/max/mdev = 12.931/13.438/13.945/0.507 ms
[vagrant@office2Server ~]$ ping 192.168.2.2
PING 192.168.2.2 (192.168.2.2) 56(84) bytes of data.
64 bytes from 192.168.2.2: icmp_seq=1 ttl=61 time=2.33 ms
64 bytes from 192.168.2.2: icmp_seq=2 ttl=61 time=2.29 ms
64 bytes from 192.168.2.2: icmp_seq=3 ttl=61 time=2.06 ms

```

*** [vagrant@office2Router ~]$ *** traceroute yandex.ru
```
traceroute to yandex.ru (77.88.55.88), 30 hops max, 60 byte packets
 1  gateway (192.168.253.1)  0.688 ms  0.620 ms  0.298 ms
 2  192.168.255.1 (192.168.255.1)  0.805 ms  0.733 ms  0.681 ms

[vagrant@office2Router ~]$ ping 192.168.2.2
PING 192.168.2.2 (192.168.2.2) 56(84) bytes of data.
From 192.168.253.1 icmp_seq=1 Redirect Host(New nexthop: 192.168.254.2)
From 192.168.253.1: icmp_seq=1 Redirect Host(New nexthop: 192.168.254.2)
64 bytes from 192.168.2.2: icmp_seq=1 ttl=62 time=1.81 ms
From 192.168.253.1 icmp_seq=2 Redirect Host(New nexthop: 192.168.254.2)
From 192.168.253.1: icmp_seq=2 Redirect Host(New nexthop: 192.168.254.2)

```

*** [vagrant@office1Server ~]$ *** traceroute yandex.ru
```
traceroute to yandex.ru (5.255.255.70), 30 hops max, 60 byte packets
 1  gateway (192.168.2.1)  0.760 ms  0.361 ms  0.332 ms
 2  192.168.254.1 (192.168.254.1)  1.025 ms  1.103 ms  0.913 ms
 3  192.168.255.1 (192.168.255.1)  1.344 ms  1.623 ms  1.666 ms
[vagrant@office1Server ~]$ ping 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=61 time=2.22 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=61 time=1.84 ms
64 bytes from 192.168.1.2: icmp_seq=3 ttl=61 time=1.79 ms
tes from 192.168.1.2: icmp_seq=19 ttl=61 time=2.11 ms
^C
--- 192.168.1.2 ping statistics ---
19 packets transmitted, 19 received, 0% packet loss, time 18038ms
rtt min/avg/max/mdev = 1.781/1.916/2.229/0.113 ms
```

*** [vagrant@office1Router ~]$ *** traceroute yandex.ru
```
traceroute to yandex.ru (5.255.255.70), 30 hops max, 60 byte packets
 1  gateway (192.168.254.1)  0.603 ms  0.472 ms  0.401 ms
 2  192.168.255.1 (192.168.255.1)  2.783 ms  4.805 ms  4.514 ms
30  * * *
[vagrant@office1Router ~]$ ping 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
From 192.168.254.1 icmp_seq=1 Redirect Host(New nexthop: 192.168.253.2)
From 192.168.254.1: icmp_seq=1 Redirect Host(New nexthop: 192.168.253.2)

```

```
[vagrant@centralServer ~]$ traceroute yandex.ru

traceroute to yandex.ru (77.88.55.60), 30 hops max, 60 byte packets
 1  gateway (192.168.0.1)  0.540 ms  0.476 ms  0.380 ms
 2  192.168.255.1 (192.168.255.1)  1.375 ms  1.500 ms  1.333 ms
30  * * *
[vagrant@centralServer ~]$ ping 192.168.1.2
PING 192.168.1.2 (192.168.1.2) 56(84) bytes of data.
64 bytes from 192.168.1.2: icmp_seq=1 ttl=62 time=1.75 ms
64 bytes from 192.168.1.2: icmp_seq=2 ttl=62 time=1.61 ms

[vagrant@centralServer ~]$ ping 192.168.2.2
PING 192.168.2.2 (192.168.2.2) 56(84) bytes of data.
64 bytes from 192.168.2.2: icmp_seq=1 ttl=62 time=1.78 ms
64 bytes from 192.168.2.2: icmp_seq=2 ttl=62 time=1.35 ms

```
### Решение(c использованием Ansible)

Репозиторий дз с использованием Ansible  https://github.com/adastraaero/OTUS_LinuxProf/tree/main/Lesson26NetworkANS


![Image 3](Lesson26NetworkANS/Server1.jpg)

![Image 4](Lesson26NetworkANS/Server2.jpg)

![Image 5](Lesson26NetworkANS/CentralServer.jpg)

</details>




## Lesson29 - Фильтрация трафика - firewalld, iptables

<details>

### Задача:

1. Реализовать knocking port  
  centralRouter может попасть на ssh inetrRouter через knock скрипт
2. Добавить inetRouter2, который виден(маршрутизируется (host-only тип сети для виртуалки)) с хоста или форвардится порт через локалхост.
3. Запустить nginx на centralServer.
4. Пробросить 80й порт на inetRouter2 8080.
5. Дефолт в инет оставить через inetRouter.

Формат сдачи ДЗ - vagrant + ansible

### Решение:

Для решения использовались статьи:

https://wiki.archlinux.org/title/Port_knocking#Simple_port_knocking

https://otus.ru/nest/post/267/

листинг iptables  inetRouter
```
*nat
:PREROUTING ACCEPT [1:44]
:INPUT ACCEPT [1:44]
:OUTPUT ACCEPT [111:8672]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
COMMIT

*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:TRAFFIC - [0:0]
:SSH-INPUT - [0:0]
:SSH-INPUTTWO - [0:0]

-A INPUT -p icmp --icmp-type 3 -j ACCEPT
-A INPUT -p icmp --icmp-type 8 -j ACCEPT
-A INPUT -p icmp --icmp-type 12 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 0 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 3 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 4 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 11 -j ACCEPT
-A OUTPUT -p icmp --icmp-type 12 -j ACCEPT

# TRAFFIC chain for Port Knocking. The correct port sequence in this example is  8881 -> 7777 -> 9991; any other sequence will drop the traffic
-A INPUT -j TRAFFIC
-A TRAFFIC -p icmp --icmp-type any -j ACCEPT
-A TRAFFIC -m state --state ESTABLISHED,RELATED -j ACCEPT
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 22 -m recent --rcheck --seconds 15 --name SSH2 -j ACCEPT
-A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH2 --remove -j DROP
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 9991 -m recent --rcheck --name SSH1 -j SSH-INPUTTWO
-A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH1 --remove -j DROP
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 7777 -m recent --rcheck --name SSH0 -j SSH-INPUT
-A TRAFFIC -m state --state NEW -m tcp -p tcp -m recent --name SSH0 --remove -j DROP
-A TRAFFIC -m state --state NEW -m tcp -p tcp --dport 8881 -m recent --name SSH0 --set -j DROP
-A SSH-INPUT -m recent --name SSH1 --set -j DROP
-A SSH-INPUTTWO -m recent --name SSH2 --set -j DROP
-A TRAFFIC -j DROP
COMMIT
# END or further rules
```


листинг iptables  inetRouter2
```
*filter
:INPUT ACCEPT [222:17823]
:FORWARD ACCEPT [4:509]
:OUTPUT ACCEPT [160:14623]
-A FORWARD -d 192.168.0.2/32 -p tcp -m tcp --dport 80 -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
COMMIT
# Completed on Mon May  1 15:26:15 2023
# Generated by iptables-save v1.4.21 on Mon May  1 15:26:15 2023
*nat
:PREROUTING ACCEPT [3:472]
:INPUT ACCEPT [3:472]
:OUTPUT ACCEPT [80:6306]
:POSTROUTING ACCEPT [1:60]
-A PREROUTING -i eth2 -p tcp -m tcp --dport 8080 -j DNAT --to-destination 192.168.0.2:80
-A POSTROUTING ! -d 192.168.0.0/16 -o eth0 -j MASQUERADE
COMMIT
```
скрипт для knocking port

```
#!/bin/bash
HOST=$1
shift
for ARG in "$@"
do
        sudo nmap -Pn --max-retries 0 -p $ARG $HOST
done
```

1. Проверяем port knocking

```
[root@centralRouter ~]# /vagrant/knock_scr.sh 192.168.255.1 8881 7777 9991

Starting Nmap 6.40 ( http://nmap.org ) at 2023-05-01 18:03 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00074s latency).
PORT     STATE    SERVICE
8881/tcp filtered unknown
MAC Address: 08:00:27:93:B2:D9 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.36 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2023-05-01 18:03 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00054s latency).
PORT     STATE    SERVICE
7777/tcp filtered cbt
MAC Address: 08:00:27:93:B2:D9 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.34 seconds

Starting Nmap 6.40 ( http://nmap.org ) at 2023-05-01 18:03 UTC
Warning: 192.168.255.1 giving up on port because retransmission cap hit (0).
Nmap scan report for 192.168.255.1
Host is up (0.00051s latency).
PORT     STATE    SERVICE
9991/tcp filtered issa
MAC Address: 08:00:27:93:B2:D9 (Cadmus Computer Systems)

Nmap done: 1 IP address (1 host up) scanned in 0.35 seconds
```

2-4 Проверяю проброс до nginx с локалхоста 

```
root@ubuntu:~# curl 192.168.11.121:8080

Check mapping inetRouter2:8080 to centralServer:80 success!
```
3. Используем ansible-playbook

```
- name: ConfigcentralServer
  hosts: centralServer
  become: true

  tasks:





    - name: Enable EPEL Repository on CentOS 7
      yum:
       name: epel-release
       state: latest

    - name: install Services
      yum:
        name:
        - vim
        - iptables
        - tcpdump
        - net-tools
        - iptables-services
        - traceroute
        - nmap
        - nginx
        state: present
        update_cache: true


    - name: change config
      ansible.builtin.lineinfile:
       path: /usr/share/nginx/html/index.html
       line: 'Check mapping inetRouter2:8080 to centralServer:80 success!'

    - name: start nginx
      service:
        name: nginx
        state: started
        enabled: yes


    - name: disable default route
      ansible.builtin.lineinfile:
       path: /etc/sysconfig/network-scripts/ifcfg-eth0
       line: DEFROUTE=no

    - name: default route
      ansible.builtin.shell: |
        echo "GATEWAY=192.168.0.1" >> /etc/sysconfig/network-scripts/ifcfg-eth1
```
5. Проверяем что идём в интернет по дефолтному маршруту

```
[root@centralServer ~]# traceroute -I google.com
traceroute to google.com (108.177.14.101), 30 hops max, 60 byte packets
 1  gateway (192.168.0.1)  0.509 ms  0.462 ms  0.590 ms
 2  192.168.255.1 (192.168.255.1)  1.125 ms  1.210 ms  1.494 ms
 3  * * *
 4  * * *
 5  * * *
 6  gw.static.spd-mgts.ru (95.165.160.1)  7.285 ms  5.938 ms  6.135 ms
 7  mpts-ss-51.msk.mts-internet.net (212.188.1.6)  5.703 ms  4.649 ms  4.944 ms
 8  mag9-cr03-be12.51.msk.mts-internet.net (212.188.1.5)  5.309 ms * *
 9  * * *
10  * * *
11  a197-cr04-be31.77.msk.mts-internet.net (212.188.56.14)  6.855 ms  6.697 ms  6.662 ms
12  * * *
13  195.34.49.178 (195.34.49.178)  6.486 ms  6.455 ms  6.303 ms
14  a197-cr04-be18.10.msk.mts-internet.net (212.188.55.25)  8.134 ms  8.103 ms  7.833 ms
15  * * *
16  a197-cr01-po6.77.msk.mts-internet.net (195.34.59.14)  7.644 ms  7.608 ms  7.095 ms
17  195.34.59.12 (195.34.59.12)  6.201 ms  6.247 ms  6.766 ms
18  74.125.118.22 (74.125.118.22)  6.582 ms  7.212 ms  6.913 ms
19  108.170.250.129 (108.170.250.129)  7.779 ms  8.653 ms  8.149 ms
20  108.170.250.146 (108.170.250.146)  7.513 ms  7.161 ms  7.701 ms
21  209.85.249.158 (209.85.249.158)  22.922 ms  22.224 ms  22.180 ms
22  216.239.43.20 (216.239.43.20)  75.489 ms  75.458 ms  76.656 ms
23  142.250.56.217 (142.250.56.217)  24.796 ms  25.116 ms  24.861 ms
24  * * *ls -
25  * * *
26  * * *
27  * * *
28  * * *
29  * * *
30  * * *
```
</details>








## Lesson32 - Статическая и динамическая маршрутизация, OSPF

<details>

### Задача:

1. Развернуть 3 виртуальные машины
2. Объединить их разными vlan
- настроить OSPF между машинами на базе Quagga;
- изобразить ассиметричный роутинг;
- сделать один из линков "дорогим", но что бы при этом роутинг был симметричным.


Формат сдачи ДЗ - vagrant + ansible

### Решение:

**Схема сети**

![Image 1](Lesson32_OSPF/screen/Network_scheme.jpg)

Разворачиваем роутеры через Vagrant и Ansible и проверяем доступность сетей с разных хостов.

![Image 1](Lesson32_OSPF/screen/r1proof.jpg)

![Image 1](Lesson32_OSPF/screen/r2proof.jpg)

![Image 1](Lesson32_OSPF/screen/r3proof.jpg)

## Настройка и проверка ассиметричного роутинга


```
root@router1:~# vtysh

Hello, this is FRRouting (version 8.1).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

router1# conf t
router1(config)# int enp0s8 
router1(config-if)# ip ospf cost 1000
router1(config-if)# exit
router1(config)# exit
```
![Image 1](Lesson32_OSPF/screen/OSPF_weight1.jpg)

![Image 1](Lesson32_OSPF/screen/OSPF_weight2.jpg)


## Настройка и проверка симетричного роутинга с дорогими интерфейсами

```
router2# conf t
router2(config)# int enp0s8
router2(config-if)# ip ospf cost 1000
router2(config-if)# exit
router2(config)# exit
```
![Image 1](Lesson32_OSPF/screen/OSPF_sim1.jpg)

![Image 1](Lesson32_OSPF/screen/OSPF_sim2.jpg)

</details>

## Lesson34 VPN

<details>

### Задача

1. Между двумя виртуалками поднять vpn в режимах:

- tun

- tap

Описать в чём разница, замерить скорость между виртуальными
машинами в туннелях, сделать вывод об отличающихся показателях
скорости.
2. Поднять RAS на базе OpenVPN с клиентскими сертификатами,
подключиться с локальной машины на виртуалку.


### Решение
Решение разделено на 3 каталога:
1 - TAP - Vagrant + Ansible развёртывание VPN в режиме tap
2 - TUN - Vagrant + Ansible развёртывание VPN в режиме tun
3 - RAS


![Image 1](Lesson26Network/network.jpg)

![Image 2](Lesson26Network/network1.jpg)

### Практическая часть

* Соединить офисы в сеть согласно схеме и настроить роутинг
* Все сервера и роутеры должны ходить в инет черз inetRouter
* Все сервера должны видеть друг друга
* У всех новых серверов отключить дефолт на нат (eth0), который вагрант поднимает для связи




</details>


## Lesson35 SPLITDNS

<details>

### Задача

1. Взять стенд https://github.com/erlong15/vagrant-bind 
* добавить еще один сервер client2
* завести в зоне dns.lab имена:
* web1 - смотрит на клиент1
* web2  смотрит на клиент2
* завести еще одну зону newdns.lab
* завести в ней запись
* www - смотрит на обоих клиентов

2. настроить split-dns
клиент1 - видит обе зоны, но в зоне dns.lab только web1
клиент2 видит только dns.lab

* настроить все без выключения selinux


### Решение

Добавляем 2го клиента в Vagrant

```
  config.vm.define "client2" do |client2|
    client2.vm.network "private_network", ip: "192.168.50.16", virtualbox__intnet: "dns"
    client2.vm.hostname = "client2"
  end
```
Запускаем Vagrant+Ansible

Проверяем, что DNS поднялся:

```
[root@ns01 ~]# ss -tulpn | grep 53
udp    UNCONN     0      0      192.168.50.10:53                    *:*                   users:(("named",pid=2204,fd=512))
udp    UNCONN     0      0         [::1]:53                 [::]:*                   users:(("named",pid=2204,fd=513))
tcp    LISTEN     0      10     192.168.50.10:53                    *:*                   users:(("named",pid=2204,fd=21))
tcp    LISTEN     0      128    192.168.50.10:953                   *:*                   users:(("named",pid=2204,fd=23))
tcp    LISTEN     0      10        [::1]:53                 [::]:*                   users:(("named",pid=2204,fd=22))
```


#### Проверка добавления имён в зону dns.lab

```
[root@client ~]# dig @192.168.50.10 web1.dns.lab

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.13 <<>> @192.168.50.10 web1.dns.lab
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 42560
;; flags: qr aa rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 2, ADDITIONAL: 3

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web1.dns.lab.                  IN      A

;; ANSWER SECTION:
web1.dns.lab.           3600    IN      A       192.168.50.15

;; AUTHORITY SECTION:
dns.lab.                3600    IN      NS      ns02.dns.lab.
dns.lab.                3600    IN      NS      ns01.dns.lab.

;; ADDITIONAL SECTION:
ns01.dns.lab.           3600    IN      A       192.168.50.10
ns02.dns.lab.           3600    IN      A       192.168.50.11

;; Query time: 0 msec
;; SERVER: 192.168.50.10#53(192.168.50.10)
;; WHEN: Thu May 25 11:31:00 UTC 2023
;; MSG SIZE  rcvd: 127

```

![Image 1](Lesson35_DNS/dig1+2.jpg)


#### Настройка split-dns

Генерируем ключи для хостов

```
[root@ns01 ~]# tsig-keygen
key "tsig-key" {
        algorithm hmac-sha256;
        secret "hhRAf5ePYIwv99SmO1/sN6HibV9u1o+mjLI4kJc0XuY=";
};

[root@ns01 ~]# tsig-keygen

key "tsig-key" {
        algorithm hmac-sha256;
        secret "FGSuvjlp+h0ZX97/OpNFQVPk0eB61OqvQ8/X+3ZjokE=";
```
<details>
Настраиваем acl и view


```
[root@ns01 ~]# cat /etc/named.conf
options {

    // На каком порту и IP-адресе будет работать служба
        listen-on port 53 { 192.168.50.10; };
        listen-on-v6 port 53 { ::1; };

    // Указание каталогов с конфигурационными файлами
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";

    // Указание настроек DNS-сервера
    // Разрешаем серверу быть рекурсивным
        recursion yes;
    // Указываем сети, которым разрешено отправлять запросы серверу
        allow-query     { any; };
    // Каким сетям можно передавать настройки о зоне
    allow-transfer { any; };

    // dnssec
        dnssec-enable yes;
        dnssec-validation yes;

    // others
        bindkeys-file "/etc/named.iscdlv.key";
        managed-keys-directory "/var/named/dynamic";
        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// RNDC Control for client
key "rndc-key" {
    algorithm hmac-md5;
    secret "GrtiE9kz16GK+OKKU/qJvQ==";
};
controls {
        inet 192.168.50.10 allow { 192.168.50.15; 192.168.50.16; } keys { "rndc-key"; };
};

key "client-key" {
    algorithm hmac-sha256;
    secret "hhRAf5ePYIwv99SmO1/sN6HibV9u1o+mjLI4kJc0XuY=";
};
key "client2-key" {
    algorithm hmac-sha256;
    secret "FGSuvjlp+h0ZX97/OpNFQVPk0eB61OqvQ8/X+3ZjokE=";
};

// ZONE TRANSFER WITH TSIG
include "/etc/named.zonetransfer.key";

server 192.168.50.11 {
    keys { "zonetransfer.key"; };
};
// Указание Access листов
acl client { !key client2-key; key client-key; 192.168.50.15; };
acl client2 { !key client-key; key client2-key; 192.168.50.16; };
// Настройка первого view
view "client" {
    // Кому из клиентов разрешено подключаться, нужно указать имя access-листа
    match-clients { client; };

    // Описание зоны dns.lab для client
    zone "dns.lab" {
        // Тип сервера — мастер
        type master;
        // Добавляем ссылку на файл зоны, который создали в прошлом пункте
        file "/etc/named/named.dns.lab.client";
        // Адрес хостов, которым будет отправлена информация об изменении зоны
        also-notify { 192.168.50.11 key client-key; };
    };

    // newdns.lab zone
    zone "newdns.lab" {
        type master;
        file "/etc/named/named.newdns.lab";
        also-notify { 192.168.50.11 key client-key; };
    };
};

// Описание view для client2
view "client2" {
    match-clients { client2; };

    // dns.lab zone
    zone "dns.lab" {
        type master;
        file "/etc/named/named.dns.lab";
        also-notify { 192.168.50.11 key client2-key; };
    };

    // dns.lab zone reverse
    zone "50.168.192.in-addr.arpa" {
        type master;
        file "/etc/named/named.dns.lab.rev";
        also-notify { 192.168.50.11 key client2-key; };
    };
};

// Зона any, указана в файле самой последней
view "default" {
    match-clients { any; };

    // root zone
    zone "." IN {
        type hint;
        file "named.ca";
    };

    // zones like localhost
    include "/etc/named.rfc1912.zones";
    // root DNSKEY
    include "/etc/named.root.key";

    // dns.lab zone
    zone "dns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab";
    };

    // dns.lab zone reverse
    zone "50.168.192.in-addr.arpa" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.dns.lab.rev";
    };

    // ddns.lab zone
    zone "ddns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        allow-update { key "zonetransfer.key"; };
        file "/etc/named/named.ddns.lab";
    };

    // newdns.lab zone
    zone "newdns.lab" {
        type master;
        allow-transfer { key "zonetransfer.key"; };
        file "/etc/named/named.newdns.lab";
    };
};
```
</details>

#### Проверка на client и client2

![Image 1](Lesson35_DNS/splitDNSCheck.jpg)


#### Проверяем, что selinux включён

![Image 1](Lesson35_DNS/sestatus.jpg)



</details>



## Lesson36  VLAN'ы,LACP

<details>

### Задача

в Office1 в тестовой подсети появляется сервера с доп интерфесами и адресами
в internal сети testLAN: 
- testClient1 - 10.10.10.254
- testClient2 - 10.10.10.254
- testServer1- 10.10.10.1 
- testServer2- 10.10.10.1

Равести вланами:
testClient1 <-> testServer1
testClient2 <-> testServer2

Между centralRouter и inetRouter "пробросить" 2 линка (общая inernal сеть) и объединить их в бонд, проверить работу c отключением интерфейсов

Формат сдачи ДЗ - vagrant + ansible


### Решение

Итоговая топология

![Image 1](Lesson36_VLAN_LACP/Topology.jpg)

Разворачиваем настроенную топологию через ansible+vagrant+jinja2, проверяем настройки и доступность:

#### Client1
```
[vagrant@testClient1 ~]$ ip a | grep 10.10.10
    inet 10.10.10.254/24 brd 10.10.10.255 scope global noprefixroute eth1.1
```

```
[vagrant@testClient1 ~]$ ping 10.10.10.254
PING 10.10.10.254 (10.10.10.254) 56(84) bytes of data.
64 bytes from 10.10.10.254: icmp_seq=1 ttl=64 time=0.028 ms
64 bytes from 10.10.10.254: icmp_seq=2 ttl=64 time=0.026 ms
64 bytes from 10.10.10.254: icmp_seq=3 ttl=64 time=0.025 ms
64 bytes from 10.10.10.254: icmp_seq=4 ttl=64 time=0.026 ms
64 bytes from 10.10.10.254: icmp_seq=5 ttl=64 time=0.026 ms
64 bytes from 10.10.10.254: icmp_seq=6 ttl=64 time=0.029 ms
64 bytes from 10.10.10.254: icmp_seq=7 ttl=64 time=0.026 ms
64 bytes from 10.10.10.254: icmp_seq=8 ttl=64 time=0.027 ms
64 bytes from 10.10.10.254: icmp_seq=9 ttl=64 time=0.025 ms
64 bytes from 10.10.10.254: icmp_seq=10 ttl=64 time=0.026 ms
64 bytes from 10.10.10.254: icmp_seq=11 ttl=64 time=0.026 ms
64 bytes from 10.10.10.254: icmp_seq=12 ttl=64 time=0.025 ms
64 bytes from 10.10.10.254: icmp_seq=13 ttl=64 time=0.026 ms
64 bytes from 10.10.10.254: icmp_seq=14 ttl=64 time=0.037 ms
64 bytes from 10.10.10.254: icmp_seq=15 ttl=64 time=0.026 ms
64 bytes from 10.10.10.254: icmp_seq=16 ttl=64 time=0.026 ms
64 bytes from 10.10.10.254: icmp_seq=17 ttl=64 time=0.081 ms
^C
--- 10.10.10.254 ping statistics ---
17 packets transmitted, 17 received, 0% packet loss, time 16600ms
rtt min/avg/max/mdev = 0.025/0.030/0.081/0.013 ms
```

```
[vagrant@testClient1 ~]$ ping yandex.ru
PING yandex.ru (77.88.55.88) 56(84) bytes of data.
64 bytes from yandex.ru (77.88.55.88): icmp_seq=1 ttl=63 time=12.1 ms
64 bytes from yandex.ru (77.88.55.88): icmp_seq=2 ttl=63 time=11.7 ms
64 bytes from yandex.ru (77.88.55.88): icmp_seq=3 ttl=63 time=11.9 ms
^C
--- yandex.ru ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 11.677/11.887/12.102/0.173 ms
```


#### inetRouter

```
[vagrant@inetRouter ~]$ ping 192.168.255.2
PING 192.168.255.2 (192.168.255.2) 56(84) bytes of data.
64 bytes from 192.168.255.2: icmp_seq=1 ttl=64 time=0.694 ms
64 bytes from 192.168.255.2: icmp_seq=2 ttl=64 time=0.573 ms
64 bytes from 192.168.255.2: icmp_seq=3 ttl=64 time=0.601 ms

--- 192.168.255.2 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2026ms
rtt min/avg/max/mdev = 0.573/0.622/0.694/0.059 ms
```


####  centralRouter

```
[root@centralRouter ~]# ip a | grep bond
3: eth1: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc fq_codel master bond0 state UP group default qlen 1000
4: eth2: <BROADCAST,MULTICAST,SLAVE,UP,LOWER_UP> mtu 1500 qdisc fq_codel master bond0 state UP group default qlen 1000
7: bond0: <BROADCAST,MULTICAST,MASTER,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    inet 192.168.255.2/30 brd 192.168.255.3 scope global noprefixroute bond0
```

```
[root@centralRouter ~]# ping 192.168.255.1
PING 192.168.255.1 (192.168.255.1) 56(84) bytes of data.
64 bytes from 192.168.255.1: icmp_seq=1 ttl=64 time=0.917 ms
64 bytes from 192.168.255.1: icmp_seq=2 ttl=64 time=0.730 ms
^C
--- 192.168.255.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1060ms
rtt min/avg/max/mdev = 0.730/0.823/0.917/0.097 ms
```

```
[root@centralRouter ~]# ping yandex.ru
PING yandex.ru (5.255.255.70) 56(84) bytes of data.
64 bytes from yandex.ru (5.255.255.70): icmp_seq=1 ttl=63 time=8.62 ms
64 bytes from yandex.ru (5.255.255.70): icmp_seq=2 ttl=63 time=8.35 ms
^C
--- yandex.ru ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1025ms
rtt min/avg/max/mdev = 8.347/8.482/8.618/0.163 ms
```

</details>





## Lesson37 LDAP

<details>

### Задача

Описание домашнего задания
1) Установить FreeIPA
2) Написать Ansible-playbook для конфигурации клиента

Дополнительное задание
3)* Настроить аутентификацию по SSH-ключам
4)** Firewall должен быть включен на сервере и на клиенте


### Дополнительные сведения
На Centos 7 необходимо обновить nss, без него настройка падает
https://access.redhat.com/solutions/4350171


```
  - name: Upgrade nss
    ansible.builtin.yum:
      name: 'nss'
      state: latest
```

Пояснение параметров для развёртывания ipa:  
-r REALM_NAME, --realm=REALM_NAME  
    The Kerberos realm name for the IPA server   
-n DOMAIN_NAME, --domain=DOMAIN_NAME  
    Your DNS domain name   
-p DM_PASSWORD, --ds-password=DM_PASSWORD  
    The password to be used by the Directory Server for the Directory Manager user   
-P MASTER_PASSWORD, --master-password=MASTER_PASSWORD  
    The kerberos master password (normally autogenerated)   
-a ADMIN_PASSWORD, --admin-password=ADMIN_PASSWORD  
    The password for the IPA admin user   
--hostname=HOST_NAME  
    The fully-qualified DNS name of this server. If the hostname does not match system hostname, the system hostname will be updated accordingly to prevent service failures.   
--ip-address=IP_ADDRESS  
    The IP address of this server. If this address does not match the address the host resolves to and --setup-dns is not selected the installation will fail. If the server hostname is not resolvable, a record for the hostname and IP_ADDRESS is added to /etc/hosts. 
-N, --no-ntp   

--setup-dns  
    Generate a DNS zone if it does not exist already and configure the DNS server. This option requires that you either specify at least one DNS forwarder through the --forwarder option or use the --no-forwarders option.   







### Решение

#### Открываем нужные порты для




#### Часть плейбука для настройки сервера и создания учетной записи пользователя

```
- name: Config IPA Server
  hosts: ipa.otus.lan
  become: yes
  tasks:

  - name: Upgrade nss
    ansible.builtin.yum:
      name: 'nss'
      state: latest

  - name: install packages
    ansible.builtin.yum:
      name:
        - ipa-server
        - ipa-server-dns



  - name: delete freeipa-server config
    command: |
      ipa-server-install -U \
      --uninstall \

  - name: configure freeipa
    command: |
      ipa-server-install -U \
      -r OTUS.LAN \
      -n otus.lan \
      -p otusotus \
      -a otusotus \
      --hostname=ipa.otus.lan \
      --ip-address=192.168.57.10 \
      --mkhomedir \
      --no-ntp \


  - ipa_user:
      name: tester1
      givenname: Dmitry
      sn: Tester
      password: testtest
      loginshell: /bin/bash
      ipa_host: ipa.otus.lan
      ipa_user: admin
      ipa_pass: otusotus

```


#### Часть плейбука для настройки клиента

```
- name: Config Clients
  hosts: client1.otus.lan,client2.otus.lan
  become: yes
  tasks:

  - name: Upgrade nss client
    ansible.builtin.yum:
      name: 'nss'
      state: latest
#Установка клиента Freeipa
  - name: install module ipa-client
    ansible.builtin.yum:
      name:
        - freeipa-client
      state: present
      update_cache: true



  - name: configure ipa-client
    command: |
      ipa-client-install -U \
      --principal admin@OTUS.LAN \
      --password otusotus \
      --server ipa.otus.lan \
      --domain otus.lan \
      --realm OTUS.LAN \
      --mkhomedir \
      --force-join
                            
```


#### Проверяем, подключение клиента

```
WARNING: ntpd time&date synchronization service will not be configured as
conflicting service (chronyd) is enabled
Use --force-ntpd option to disable it and force configuration of ntpd

Client hostname: client1.otus.lan
Realm: OTUS.LAN
DNS Domain: otus.lan
IPA Server: ipa.otus.lan
BaseDN: dc=otus,dc=lan

Skipping synchronizing time with NTP server.
Successfully retrieved CA cert
    Subject:     CN=Certificate Authority,O=OTUS.LAN
    Issuer:      CN=Certificate Authority,O=OTUS.LAN
    Valid From:  2023-06-01 04:47:00
    Valid Until: 2043-06-01 04:47:00

Enrolled in IPA realm OTUS.LAN
Created /etc/ipa/default.conf
New SSSD config will be created
Configured sudoers in /etc/nsswitch.conf
Configured /etc/sssd/sssd.conf
trying https://ipa.otus.lan/ipa/json
[try 1]: Forwarding 'schema' to json server 'https://ipa.otus.lan/ipa/json'
trying https://ipa.otus.lan/ipa/session/json
[try 1]: Forwarding 'ping' to json server 'https://ipa.otus.lan/ipa/session/json'
[try 1]: Forwarding 'ca_is_enabled' to json server 'https://ipa.otus.lan/ipa/session/json'
Systemwide CA database updated.
Hostname (client1.otus.lan) does not have A/AAAA record.
Failed to update DNS records.
Missing A/AAAA record(s) for host client1.otus.lan: 192.168.57.11.
Missing reverse record(s) for address(es): 192.168.57.11.
Adding SSH public key from /etc/ssh/ssh_host_rsa_key.pub
Adding SSH public key from /etc/ssh/ssh_host_ecdsa_key.pub
Adding SSH public key from /etc/ssh/ssh_host_ed25519_key.pub
[try 1]: Forwarding 'host_mod' to json server 'https://ipa.otus.lan/ipa/session/json'
Could not update DNS SSHFP records.
SSSD enabled
Configured /etc/openldap/ldap.conf
Configured /etc/ssh/ssh_config
Configured /etc/ssh/sshd_config
Configuring otus.lan as NIS domain.
Configured /etc/krb5.conf for IPA realm OTUS.LAN
Client configuration complete.
The ipa-client-install command was successful
```

#### Добавляем запись в /etc/hosts на localhost

```
root@ubuntu:/home/mity/Documents/OTUS_Linux_Prof/Lesson36_VLAN_LACP# cat /etc/hosts
127.0.0.1	localhost
127.0.1.1	ubuntu
10.10.10.10	appserver
10.10.10.20	dbserver
192.168.57.10 ipa.otus.lan
```
#### Проверяем через веб-интерфейс, что учетка создалась и ПК подключились к домену.


![Image 1](Lesson37_LDAP/ipa1.jpg)

![Image 1](Lesson37_LDAP/ipa2.jpg)


#### Проверяем на сервере выдачу билетов и запрашиваем список билетов

```
[root@ipa ~]# kinit admin
Password for admin@OTUS.LAN:
[root@ipa ~]# klist
Ticket cache: KEYRING:persistent:0:0
Default principal: admin@OTUS.LAN

Valid starting       Expires              Service principal
06/01/2023 15:38:20  06/02/2023 15:38:15  krbtgt/OTUS.LAN@OTUS.LAN
```

#### Пробуем залогиниться созданной в ipa учёткой с клиента

```
[vagrant@client1 ~]$ sudo -i
[root@client1 ~]# kinit tester1
Password for tester1@OTUS.LAN:
Password expired.  You must change it now.
Enter new password:
Enter it again:
[root@client1 ~]#
```





## Lesson43 MYSQL BACKUP

<details>

### Задача

Базу развернуть на мастере и настроить так, чтобы реплицировались таблицы:
| bookmaker |
| competition |
| market |
| odds |
| outcome

    Настроить GTID репликацию
    x
    варианты которые принимаются к сдаче

    рабочий вагрантафайл
    скрины или логи SHOW TABLES
    конфиги*
    пример в логе изменения строки и появления строки на реплике*


### Полезные ссылки
https://www.zyxware.com/articles/5589/solved-how-to-update-mysql-root-user-password
https://www.digitalocean.com/community/tutorials/how-to-reset-your-mysql-or-mariadb-root-password-on-ubuntu-20-04
Стенд


### Решение
Проводим настройки согласно методички, проверяем полученный результат.

На мастер хосте проверяем server_id, наличие импортированной бд, использование GTID.

![Image 1](Lesson43_mysql/master1.jpg)

Вносим изменения в бд.

![Image 1](Lesson43_mysql/master2.jpg)

На slave хосте проверяем server_id, использование GTID, наличие бд с изменениями и исключёнными таблицами:

![Image 1](Lesson43_mysql/slave1.jpg)

![Image 1](Lesson43_mysql/slave2.jpg)

</details>





