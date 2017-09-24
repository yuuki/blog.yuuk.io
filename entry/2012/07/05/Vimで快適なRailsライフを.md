---
Title: "Vimで快適なRailsライフを"
Category:
- Vim
- Rails
Date: 2012-07-05T21:21:00+09:00
URL: http://blog.yuuk.io/entry/2012/07/05/Vim%E3%81%A7%E5%BF%AB%E9%81%A9%E3%81%AARails%E3%83%A9%E3%82%A4%E3%83%95%E3%82%92
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704591929890985456
---

> QiitaのRuby Advent Calendar 7/5担当分に書いた記事の転載です．

今日はRubyというかRailsの開発環境の話です．
Railsでアプリ開発するときにVimで快適に作業するためのtipsを書きました．

## Rails開発に役に立つVimプラグインたち
- [rails.vim](https://github.com/tpope/vim-rails/) : 多分定番プラグインです．対応するモデル・ビュー・コントローラ間を簡単に行き来できます．下で詳しく解説します．便利！

- [The-NERD-tree](https://github.com/scrooloose/nerdtree/) : Railsとは関係ありませんが，上記rails.vimをインストールした状態で，Railsプロジェクト下のファイルを開いて，```:Rtree```コマンドを打つと，サブペイン内にRailsのプロジェクトツリーが表示されます．便利！

![NERD-tree](http://cdn-ak.f.st-hatena.com/images/fotolife/y/y_uuki/20120705/20120705183349_original.png)

- [dbext.vim](http://www.vim.org/scripts/script.php?script_id=356): rails.vimと合わせてインストールしておくと，database.ymlの設定を自動で読み込んでくれて，```:Select * from users;```のようにVimから直接SQLを叩いて結果を見ることができます．便利！

![dbext](http://cdn-ak.f.st-hatena.com/images/fotolife/y/y_uuki/20120705/20120705184353_original.png)

## rails.vimの機能まとめ

上で紹介したrails.vimは非常に多機能で，多分半分も使えてない気がします．
この中で普段使っているジャンプ系のコマンドをまとめてみました．

- ```:R(model/controller/view) ```
カレンドバッファに対応したModelやControllerにとべます。例えば，```UsersController```を開いているときに，```:Rmodel```すると```/app/models/user.rb```にとべます．

- ```:R(model/controller/view) name```
カレントバッファに対応していないファイルを開くために使う．例えば，```/app/models/qiita.rb```にとびたいときは，```:Rmodel qiita```します．ちなみに```name```部分は補完が効きます．

ちなみにR[command]のcommandにはmodelやcontroller以外に
helper/spec/javascript/stylesheet/unittest/plugin/lib/task/layout/migration/schema
などを指定できます．

- ```:A, :R ```
```:A ```と```:R ```はよく似ています．というか，違うのは確かなのですが，違いがよくわかってます．helpを読むと```:A```はalternate fileにとび，```:R```はrelated fileにとぶそうです．よくわからない．
手元で適当に打ち込んでみると，基本的に```:A```は対応するテストファイルにとびます．一方，```:R```はカレントバッファがModelならば，db/schema.rbにとびます．カレントバッファがControllerかつカーソル位置がアクションメソッド内あれば，対応するViewにとびます．カーソル位置がアクションメソッドの外であれば，対応するHelperにとびます．

- ```:R path```
```config/nvironment.rb```などRailsプロジェクトのルートからの相対パスを指定してファイルを開けます．

- ```:RT，:RS，:RV，:RD ```
上記コマンドのRまたはAの直後にオプションをつけるとファイルを開く方法を指定できます．
```:RT``` : 新規タブ
```:RS``` : 画面を水平分割
```:RV``` : 画面を垂直分割
```:RD``` : カレントバッファにロード

- ```gf ```
カーソル位置のシンボルに応じて定義元にジャンプしてくれます．
例えば，```Use*r.find_all_by_id```でgfするとapp/models/user.rbを開けます．

### カスタム定義
以上はデフォルトで用意されているジャンプ系のコマンドですが，```:R[commmand]```の[command]部分をユーザが定義することができます．
僕は次のようなコマンドを追加しています．
controllers/apiおよびcontrollers/tmpl以下へのジャンプ，```:Rconfig```コマンド（デフォルトではconfig/routes.rbにとぶ），```:Rcontroller``` => ```:Rc```のようなaliasを定義しています．

```vim
autocmd User Rails.controller* Rnavcommand api app/controllers/api -glob=**/* -suffix=_controller.rb
autocmd User Rails.controller* Rnavcommand tmpl app/controllers/tmpl -glob=**/* -suffix=_controller.rb
autocmd User Rails Rnavcommand config config   -glob=*.*  -suffix= -default=routes.rb
autocmd User Rails nmap :<C-u>Rcontroller :<C-u>Rc
autocmd User Rails nmap :<C-u>Rmodel :<C-u>Rm
autocmd User Rails nmap :<C-u>Rview :<C-u>Rv
```
