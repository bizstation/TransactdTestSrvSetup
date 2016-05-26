TransactdTestSrvSetup
===============================================================================
TransactdTestSrvSetup��MySQL/MariaDB��2�̃T�[�o�[�C���X�^���X��1���Windows
��ɍ\�z����R�}���h���C���c�[���ł��B���v���P�[�V�����ȂǕ����̃T�[�o�[���K�v��
�e�X�g����f�����\�z�ł��܂��B

�T�[�o�[�̃o�[�W�����ɍ��킹�čŐV��[Transactd�v���O�C��]
(http://www.bizstation.jp/ja/transactd/)�̃C���X�g�[���������ɍs���܂��B

MySQL/MariaDB�̌����z�zzip�p�b�P�[�W��W�J���������̂��̂ɑ΂��Đݒ���s���܂��B

�p�b�P�[�W�̓W�J�f�B���N�g���ȊO�̏ꏊ�ւ̏������݂̓��W�X�g�����܂߈�؂����
����B�s�v�ɂȂ�����A�W�J�f�B���N�g�����폜���邾���ŃA���C���X�g�[���ł��܂��B

1��MySQL�v���O������2�̃C���X�^���X���N������̂ŁA�f�B�X�N�̈��ߖ�ł�
�܂��B�i�f�[�^�̈��2�j


## �ڍ�
�|�[�g�ԍ��𕪂��邱�Ƃ�1���Windows�}�V����2�̃T�[�o�[�C���X�^���X���N���ł�
��悤�ɂ��܂��B�T�[�o�[�N���p�̃V���[�g�J�b�g��MySQL�R�}���h���C���N���C�A���g
�p�V���[�g�J�b�g�����ꂼ��2���쐬���܂��B

�T�[�o�[�̓e�X�g�Ŏg���₷���悤�ɃR���\�[�����[�h�ŋN�����܂��BWindows�T�[�r�X
�ɂ͓o�^����܂���B

���̑��ׂ̍��Ȑݒ���e�͈ȉ��̒ʂ�ł��B

- MySQL/MariaDB��`my.ini`�̓��v���P�[�V�����ɕK�v�ȍŒ���̃p�����[�^�̂ݐݒ�
  ����A����ȊO�̓f�t�H���g�l�ł��B
- Transactd�̃A�N�Z�X�\�ȃz�X�g�́A�C���X�g�[���}�V���̃T�u�l�b�g�ɐݒ肳���
  ���BMySQL��̃A�J�E���g����`transactd`�Ńp�X���[�h�͐ݒ肳��Ă��܂���B
- MySQL/MariaDB�̃|�[�g�́A`3306`��`3307`���g�p���܂��B
- Transactd�̃|�[�g�́A`8610`��`8611`���g�p���܂��B
- �C���X�g�[�������}�V���ȊO����A�N�Z�X����ꍇ�́A��L�|�[�g�ɃA�N�Z�X�ł���
  �悤�t�@�C�A�E�H�[���̐ݒ���s���Ă��������B
- �f�[�^�̓f�t�H���g��`data`�f�B���N�g���ƁA�����K�w�ɃR�s�[���ꂽ`data2`�f�B��
  �N�g�����g�p����܂��B


## ���s��
* OS : Windows 64bit 7�ȍ~
* MySQL 5.5�ȏ� / MariaDB 5.5�ȏ�
  �iMariaDB 10.0.8 �` 10.0.12�̓o�O�����邽�ߎg�p�s�j


## ��������
* �C���X�g�[������R���s���[�^�̓C���^�[�l�b�g�ɐڑ�����Ă���K�v������܂��B
  �iTransactd�v���O�C�����_�E�����[�h���邽�߁j
* MySQL/MariaDB�T�[�o�[��zip�p�b�P�[�W��W�J���������ŉ������Ă��Ȃ�������Ԃ�
  �z�肵�Ă��܂��B�����łȂ��ꍇ�ɐ������Z�b�g�A�b�v�ł��邩�ǂ����͕s��ł��B
* MySQL/MariaDB�T�[�o�[�̃p�b�P�[�W�W�J�t�H���_�͋󔒂��܂܂Ȃ��p�X�Ńe�X�g����
  ���܂��B�󔒂��܂ނƐ��������삵�Ȃ��\��������܂��B


## �g����
- [MySQL](http://dev.mysql.com/downloads/mysql/) /
  [MariaDB](https://downloads.mariadb.org/)
  ��Windows 64Bit zip�p�b�P�[�W���_�E�����[�h���A�󂫗e�ʂ̂���h���C�u�ɉ�
  ���܂��B�i��Ƃ��Ă��̃t�H���_��`f:\mariadb-10.1.14-winx64`�Ƃ��܂��j
- [TransactdTestSrvSetup�̂��ׂẴt�@�C��]
  (https://github.com/bizstation/TransactdTestSrvSetup/archive/master.zip)
  ��`f:\mariadb-10.1.14-winx64`�ɃR�s�[���܂��B
- �R�s�[��������`transactd_test_srv_setup.cmd`�����s���܂��B
- `f:\mariadb-10.1.14-winx64`�t�H���_�Ɏ���4�̃V���[�g�J�b�g���쐬����܂��B
  `mysqld-3306` `mysqld-3307` `mysql_client-3306` `mysql_client-3307`
- `mysqld-3306`�A`mysqld-3307`��2�̃V���[�g�J�b�g�����ꂼ����s���܂��B2��
  �T�[�o�[�C���X�^���X���N�����܂��B

`root@localhost`�̃p�X���[�h��""�i�󕶎��j�ł��B�ŏ��ɓK���ȃp�X���[�h��ݒ肵��
���������B
```
SET PASSWORD FOR 'root'@'localhost'=password('#####'); 
```

�T�[�o�[�C���X�^���X���~����ꍇ�́A���ꂼ��̃R���\�[����`CTRL+C`�L�[������
�Ă��������B�T�[�o�[���V���b�g�_�E������܂��B
�T�[�o�[�̐ݒ�t�@�C���̃p�X�́A`f:\mariadb-10.1.14-winx64\my.ini`�Ɠ����t�H���_
��`my2.ini`�ł��B

2��̃T�[�o�[�Ń��v���P�[�V�������s���ꍇ�́A�}�X�^�[���Ƀ��v���P�[�V�����p�̃A
�J�E���g���쐬���Ă��������B�iroot�Ń��v���P�[�V����������ʂ̃A�J�E���g�ōs��
�����]�܂������߁B�j
```
//localhost��%�}�X�N�ŃJ�o�[�ł��Ȃ����Ƃ�����̂ŕʃ��[�U�[�Ƃ��č쐬���܂��B
CREATE USER 'replication_user'@'%';
CREATE USER 'replication_user'@'localhost';
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%' IDENTIFIED BY '#####';
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'localhost' IDENTIFIED BY '#####';
```


## �o�O�񍐁E�v�]�E����Ȃ�
�o�O�񍐁E�v�]�E����Ȃǂ́A[github���Issue�g���b�J�[]
(https://github.com/bizstation/TransactdTestSrvSetup/issues)�ɂ��񂹂��������B


## ���C�Z���X
GNU General Public License Version 2
```
   Copyright (C) 2016 BizStation Corp All rights reserved.

   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software 
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  
   02111-1307, USA.
```
