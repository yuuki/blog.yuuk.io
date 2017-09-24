---
Title: "研究室のサーバに流行りのGrowthForecastを導入してみた"
Category:
- Linux
- GrowthForecast
- daemontools
Date: 2013-02-15T09:23:47+09:00
URL: http://blog.yuuk.io/entry/growthforecast-install
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/6435922169449004678
---

[http://kazeburo.github.com/GrowthForecast/:title:bookmark]

研究室で各サーバと部屋の温度をグラフ化して，値が異常ならメールで通知しろみたいなタスクが降ってきた．  
もともと各サーバの統計値をMuninでグラフ化していたけれど，VMware VSphereが入ってる物理サーバの温度とれるようなプラグインないし，自分で書かないといけない感じになったり，Muninの設定とか調べるのだるい感じになってきたから，最近コード眺めてたGrowthForecastを使ってグラフ化しようと思った．  

lm-sensorsやVsphereのAPI叩いて温度を取得し，GrowthForecastのAPIにPOSTする感じのスクリプトを作成して，各ノードからcronで定期実行すればできそう．

OSはUbuntu 12.04．
curlをインストールしておく．

## 実行ユーザ作成
まずは，最低限の実行権限だけもたせた実行ユーザ growthforecastを作成する．

```sh:
$ sudo groupadd growthforecast
$ sudo useradd -g growthforecast -d /home/growthforecast -s /sbin/nologin -m growthforecast
```

## GrowthForecastインストール

```sh:
$ sudo apt-get build-dep rrdtool
$ sudo -u growthforecast curl -kL http://install.perlbrew.pl | sudo -u growthforecast bash
$ sudo -u growthforecast /home/growthforecast/perl5/perlbrew/bin/perlbrew --notest install perl-5.14.3
$ sudo -u growthforecast /home/growthforecast/perl5/perlbrew/bin/perlbrew switch perl-5.14.3
$ curl -L http://cpanmin.us/ | perl - App::cpanminus
$ cpanm -n GrowthForecast
$ exit
```

## daemontoolsで監視

Ggrowthforecast.plはWebサーバとWorkerを子プロセスとして起動するが，そのへんは良い感じに監視してくれるらしいので，親プロセスだけdaemontoolsで監視する．
[http://blog.nomadscafe.jp/2012/06/proclet-supervisor.html:title:bookmark]

### daemontoolsで起動するスクリプトを作成

```sh:
$ cd /home/growthforecast
$ sudo -u growthforecast curl https://gist.github.com/y-uuki/4957550#file-growthforecast-run-sh > run.sh
$ sudo -u growthforecast curl https://gist.github.com/y-uuki/4957550#file-growthforecast-log-run-sh > log.run.sh
$ sudo -u growthforecast chmod +x run.sh log.run.sh
```

今回は以下のようなスクリプトを作成した．

[gist:4957550]

```sh:
$ sudo mkdir -p /etc/service/growthforecast
$ sudo chown growthforecast:growthforecast /etc/service/growthforecast
$ sudo -u growthforecast ln -s /home/growthforecast/run.sh /etc/service/growthforecast/run
$ sudo -u growthforecast mkdir -p /etc/service/growthforecast/log/main
$ sudo -u growthforecast ln -s /home/growthforecast/log.run.sh /etc/service/growthforecast/log/run

$ sudo apt-get install daemontools daemontools-run svtools
$ sudo reboot
$ sudo svc -u /etc/service/growthforecast
```

### デーモンの起動・停止
```sh:
$ sudo svc -u /etc/service/growthforecast # UP
$ sudo svc -d /etc/service/growthforecast  # DOWN
```

### logをみる

```sh:
$ tail -F /etc/service/growthforecast/log/main/current
```

log/main/currentが作成されていないかつlog/superviseが存在しない場合，svscanがlogディレクトリを検出していないので再起動すればよい．


## 感想
GrowthForecastはCPANモジュールになっているので，導入が簡単．  
daemontools、まともに使ったことなかったけど，便利そう．  
温度取得してGrowthForecastに投げるスクリプトはまた今度．


## 参考

- [http://d.hatena.ne.jp/toku_bass/20120529#1338300980:title]
- [http://blog.64p.org/entry/20100716/perlenv:title]
