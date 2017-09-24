---
Title: "Perlにおける括弧なし関数とその引数と||の結合強度"
Category:
- Perl
Date: 2012-10-22T15:00:46+09:00
URL: http://blog.yuuk.io/entry/2012/10/22/Perl%E3%81%AB%E3%81%8A%E3%81%91%E3%82%8B%E6%8B%AC%E5%BC%A7%E3%81%AA%E3%81%97%E9%96%A2%E6%95%B0%E3%81%A8%E3%81%9D%E3%81%AE%E5%BC%95%E6%95%B0%E3%81%A8%7C%7C%E3%81%AE%E7%B5%90%E5%90%88%E5%BC%B7%E5%BA%A6
EditURL: https://blog.hatena.ne.jp/y_uuki/yuuki.hatenablog.com/atom/entry/12704591929891347179
---

Perlで何気なく
```perl
use File::Which qw(which);

my $cmd = which "foobar" || croak "FAIELD";
```
とか書いてたら，which "foobar"の返り値はundefなのにも関わらず，croakに引っかからなかった．
あれ？とか思ってたら単に，括弧なし関数の右からみた結合強度よりも||のほうが強かっただけだった．
つまり，まず"foobar"を見て評価値が真なのでその時点でcroak文は評価されないことになる．

以下優先順位の降順
> 左結合      || //  
> 非結合      .. ...  
> 右結合      ?:  
> 右結合      = += -= *= などの代入演算子  
> 左結合      , =>  
> 非結合      リスト演算子 (右方向に対して)  
> 右結合      not  
> 左結合      and  
> 左結合      or xor  
[http://perldoc.jp/docs/perl/5.14.1/perlop.pod:title]

ここで引数"foobar"からみたwhichは，リスト演算子（右方向に対して）扱いになる．
したがって，||の代わりにリスト演算子よりも結合が弱いorを使うか，もしくはwhich("foobar")のように括弧をつければよい．

何も特別なことはないけれど，PerlやRubyでぼんやり書いてしまいそうなので気をつけたい．
