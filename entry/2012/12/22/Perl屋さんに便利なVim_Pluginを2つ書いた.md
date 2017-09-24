---
Title: "Perl屋さんに便利なVim Pluginを2つ書いた"
Category:
- Vim
- Perl
Date: 2012-12-22T22:00:16+09:00
URL: http://blog.yuuk.io/entry/2012/12/22/Perl%E5%B1%8B%E3%81%95%E3%82%93%E3%81%AB%E4%BE%BF%E5%88%A9%E3%81%AAVim_Plugin%E3%82%922%E3%81%A4%E6%9B%B8%E3%81%84%E3%81%9F
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704830469096677516
---

この記事は [Vim Advent Calendar 2012](http://atnd.org/events/33746) の22日目の記事です．  

21日目は @AmaiSaeta さんの
「[このVim plugin達に感謝しなければ年を越せない!私が今年使い倒した2012年のベストを全部ご紹介!](http://amaisaeta.seesaa.net/article/309227466.html)
」
でした．

---  

</br>
最近，Vim Scriptを書き始めていて，
今回は，Perl的に便利なVim Pluginを2つ書いたのでご紹介します．

## unite-perl-module.vim

[GitHub y-uuki/unite-perl-module.vim](https://github.com/y-uuki/unite-perl-module.vim)

unite-perl-module.vim はClass::Acceccor::Liteなどのモジュール名をUniteのインタフェースで検索し，選択したモジュール名をカーソル位置に書き込むPluginです．

Linda_pp先生の[unite-ruby-require.vim](https://github.com/rhysd/unite-ruby-require.vim)を参考にして作りました．

機能は以下の2つです．

- perl/global: 標準モジュールおよびcpanmなどでインストールしたモジュールの検索
- perl/loccal: プロジェクト内のモジュールおよびcartonやlocal::libでインストールしたモジュールの検索

---

インストール

[unite.vim](https://github.com/Shougo/unite.vim)をインストールしてください．

NeoBundleなどで本プラグインをインストールしてください．

```vimrc
NeoBundle "y-uuki/unite-perl-module.vim"
```

---

使い方

```vim:
:Unite perl/global
```
<p><span itemscope itemtype="http://schema.org/Photograph"><img src="http://cdn-ak.f.st-hatena.com/images/fotolife/y/y_uuki/20121222/20121222212104.png" alt="f:id:y_uuki:20121222212104p:plain" title="f:id:y_uuki:20121222212104p:plain" class="hatena-fotolife" itemprop="image"></span></p>

```vim:
:Unite perl/local
```
<p><span itemscope itemtype="http://schema.org/Photograph"><img src="http://cdn-ak.f.st-hatena.com/images/fotolife/y/y_uuki/20121222/20121222212057.png" alt="f:id:y_uuki:20121222212057p:plain" title="f:id:y_uuki:20121222212057p:plain" class="hatena-fotolife" itemprop="image"></span></p>

---

注意事項

VimのカレントパスがHOMEなどのディレクトリ以下に大量のファイルがあるところでは，perl/globalの実行時間が遅くなってしまう問題があります．
これは，perl/global内で使用している cpan -l コマンドが，カレントディレクトリ以下のモジュールを再帰的に探しに行ってしまっているためだと思います．

## perl-local-lib-path.vim

[GitHub y-uuki/perl-local-lib-path.vim](https://github.com/y-uuki/perl-local-lib-path.vim)


プロジェクト内のモジュールやcartonでインストールしたモジュールにはVimのpathが通っていないので，gfでファイル間移動ができないという問題があります．

perl-local-lib-pathは，現在のプロジェクト内のモジュールやcartonでインストールしたモジュールに自動でpathを通します．

---

インストール

依存するプラグインは特にありません．
NeoBundleなどで本プラグインをインストールしてください．

```vimrc
NeoBundle "y-uuki/perl-local-lib-path.vim"
```

---

使い方

vimrcに以下のような設定を書きます．
```vimrc
g:perl_local_lib_path = "vendor/lib"    "" 任意
autocmd FileType perl PerlLocalLibPath
```

g:perl_local_lib_path にはプロジェクトルート・ディレクトリ（.gitがあるディレクトリなど）からのモジュールディレクトリへの相対パスを指定することができます．
何も指定しなくても，デフォルトで'lib'，'local/lib/perl5'と'extlib'をモジュールディレクトリとして判定します．

これで，project-root/local/lib/perl5/Plack/Request.pmのようなcartonで管理されたモジュールにもジャンプできるようになります．

## 参考
紹介した2つのプラグインではどちらも自動でプロジェクトルートの判定を行なっています．
プロジェクトルートと同じディレクトリに".git", ".gitmodules"，"Makefile.PL"，"Build.PL"があればプロジェクトルートとして判定しています．
このあたりは，id:antipopさんの[Project::Libs](https://github.com/kentaro/perl-project-libs)を参考にしました．

carton周りのVimの話は[@taka84u9](https://twitter.com/taka84u9) さんの

- [cartonでライブラリ管理してるperlプロジェクトでvimを良い感じにする](http://qiita.com/items/abfb9f2664ee0a93b82e)

を参考にしました．  


明日の担当は [@mfumi2](https://twitter.com/mfumi2)さんです．  
よろしくお願いします．
