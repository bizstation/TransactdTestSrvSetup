TransactdTestSrvSetup
===============================================================================
TransactdTestSrvSetupはMySQL/MariaDBの2つのサーバーインスタンスを1台のWindows
上に構築するコマンドラインツールです。レプリケーションなど複数のサーバーが必要な
テスト環境を素早く構築できます。

サーバーのバージョンに合わせて最新の[Transactdプラグイン]
(http://www.bizstation.jp/ja/transactd/)のインストールも同時に行います。

MySQL/MariaDBの公式配布zipパッケージを展開しただけのものに対して設定を行います。

パッケージの展開ディレクトリ以外の場所への書き込みはレジストリを含め一切ありま
せん。不要になったら、展開ディレクトリを削除するだけでアンインストールできます。

1つのMySQLプログラムで2つのインスタンスを起動するので、ディスク領域を節約でき
ます。（データ領域は2つ）


## 詳細
ポート番号を分けることで1台のWindowsマシンに2つのサーバーインスタンスを起動でき
るようにします。サーバー起動用のショートカットとMySQLコマンドラインクライアント
用ショートカットをそれぞれ2つずつ作成します。

サーバーはテストで使いやすいようにコンソールモードで起動します。Windowsサービス
には登録されません。

その他の細かな設定内容は以下の通りです。

- MySQL/MariaDBの`my.ini`はレプリケーションに必要な最低限のパラメータのみ設定
  され、それ以外はデフォルト値です。
- Transactdのアクセス可能なホストは、インストールマシンのサブネットに設定されま
  す。MySQL上のアカウント名は`transactd`でパスワードは設定されていません。
- MySQL/MariaDBのポートは、`3306`と`3307`を使用します。
- Transactdのポートは、`8610`と`8611`を使用します。
- インストールしたマシン以外からアクセスする場合は、上記ポートにアクセスできる
  ようファイアウォールの設定を行ってください。
- データはデフォルトの`data`ディレクトリと、同じ階層にコピーされた`data2`ディレ
  クトリが使用されます。


## 実行環境
* OS : Windows 64bit 7以降
* MySQL 5.5以上 / MariaDB 5.5以上
  （MariaDB 10.0.8 ～ 10.0.12はバグがあるため使用不可）


## 制限事項
* インストールするコンピュータはインターネットに接続されている必要があります。
  （Transactdプラグインをダウンロードするため）
* MySQL/MariaDBサーバーはzipパッケージを展開しただけで何もしていない初期状態を
  想定しています。そうでない場合に正しくセットアップできるかどうかは不定です。
* MySQL/MariaDBサーバーのパッケージ展開フォルダは空白を含まないパスでテストして
  います。空白を含むと正しく動作しない可能性があります。


## 使い方
- [MySQL](http://dev.mysql.com/downloads/mysql/) /
  [MariaDB](https://downloads.mariadb.org/)
  のWindows 64Bit zipパッケージをダウンロードし、空き容量のあるドライブに解凍
  します。（例としてそのフォルダを`f:\mariadb-10.1.14-winx64`とします）
- [TransactdTestSrvSetupのすべてのファイル]
  (https://github.com/bizstation/TransactdTestSrvSetup/archive/master.zip)
  を`f:\mariadb-10.1.14-winx64`にコピーします。
- コピーした中の`transactd_test_srv_setup.cmd`を実行します。
- `f:\mariadb-10.1.14-winx64`フォルダに次の4つのショートカットが作成されます。
  `mysqld-3306` `mysqld-3307` `mysql_client-3306` `mysql_client-3307`
- `mysqld-3306`、`mysqld-3307`の2つのショートカットをそれぞれ実行します。2つの
  サーバーインスタンスが起動します。

`root@localhost`のパスワードは""（空文字）です。最初に適当なパスワードを設定して
ください。
```
SET PASSWORD FOR 'root'@'localhost'=password('#####'); 
```

サーバーインスタンスを停止する場合は、それぞれのコンソールで`CTRL+C`キーを押し
てください。サーバーがシャットダウンされます。
サーバーの設定ファイルのパスは、`f:\mariadb-10.1.14-winx64\my.ini`と同じフォルダ
の`my2.ini`です。

2台のサーバーでレプリケーションを行う場合は、マスター側にレプリケーション用のア
カウントを作成してください。（rootでレプリケーションするより別のアカウントで行う
方が望ましいため。）
```
//localhostは%マスクでカバーできないことがあるので別ユーザーとして作成します。
CREATE USER 'replication_user'@'%';
CREATE USER 'replication_user'@'localhost';
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'%' IDENTIFIED BY '#####';
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'localhost' IDENTIFIED BY '#####';
```


## バグ報告・要望・質問など
バグ報告・要望・質問などは、[github上のIssueトラッカー]
(https://github.com/bizstation/TransactdTestSrvSetup/issues)にお寄せください。


## ライセンス
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
