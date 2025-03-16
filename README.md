# musical_note_calculator

**BPMや音符関連の計算をするアプリ**

このアプリは、音ゲーや音楽制作、演奏時に便利なBPM（テンポ）や音符の長さに関する計算を行うツールです。

## アプリ画面例
| 音符計算画面 | 音符回数画面 |
| --- | --- |
| ![音符計算画面](https://github.com/user-attachments/assets/31724174-d531-4497-8d14-f493c64bb9df) | ![音符回数画面](https://github.com/user-attachments/assets/bf9d286c-aad7-42a8-bdc7-503c28cd42c7) |

| 音符換算画面 | 音符換算画面(展開) |
| --- | --- |
| ![音符換算画面](https://github.com/user-attachments/assets/00194d00-36c2-4aef-8ad1-fdb914e04daa) | ![音符換算画面(展開)](https://github.com/user-attachments/assets/a9e40091-57e7-4af1-b459-abeb61ddb7f1) |

| メトロノーム画面 |  |
| --- | --- |
| ![メトロノーム画面](https://github.com/user-attachments/assets/b458b8eb-1446-45dd-913e-4b2020c081dd) |  |

| 設定画面 | 設定画面 |
| --- | --- |
| ![設定画面](https://github.com/user-attachments/assets/cfb03d52-f109-4c15-830c-a2a4bf22217c) | ![設定画面](https://github.com/user-attachments/assets/bc1460df-85b6-4c2c-a5f2-0b0971c5ac90) |


## 主な機能
- **音符計算ページ**  
  設定した時間単位で各音符の長さを計算できます。  
  - 音符計算ページのカードをタップすると、**メトロノームページ**が開きます。
    
- **メトロノームページ**  
  音符換算ページでタップしたカードの音符に合わせたメトロノームが再生されます。  
  - 4分音符に変換したときのBPMが表示されます。
  - アプリがクラッシュする可能性があるので、最大BPMを制限できます。

- **音符回数ページ**  
  指定した時間内で、各音符が何回発生するかを計算できます。

- **音符換算ページ**  
  異なるBPMで音符を変換した場合、その新しいBPMを計算します。

- **設定画面**  
  以下のカスタマイズが可能です：  
  - **カスタム音符の追加**：好きな名前と長さで独自の音符を登録可能。  
  - **音符の表示/非表示**の切り替え。  
  - **デフォルトの時間単位**の設定。
  - **小数の桁数**の設定。
  - **メトロノームの最大BPM**の設定。
  - **+/-ボタンの増減値**の設定。

## ビルドについて
このプロジェクトは、GitHub Actionsでもビルド可能です。各自でリポジトリをフォークして試すこともできます。

### 手動ビルド手順

1. **Flutterをセットアップ**  
   Flutter SDKをインストールし、パスを通す。

2. **Android Studio、Xcodeなどをセットアップ**  
   必要なIDEやツールチェーンをインストールし、環境を構築する。

3. **言語ファイルを生成する**  
   ```bash
   flutter gen-l10n
   ```

4. **必要なパッケージを取得する**  
   ```bash
   flutter pub get
   ```

5. **ビルドコマンドを実行**  
   デバイスやターゲットプラットフォームに応じたビルドコマンドを実行する。例:  
   ```bash
   flutter build apk --release
   ```  
   または  
   ```bash
   flutter build ios --release
   ```

### 注意点
- リリースページにあるファイルは古い可能性があります。  
最新版を入手するには、リポジトリをフォークし、自分でビルドすることをおすすめします。

## アプリの配布予定
~~- 完成したら**Google Play**で配布する可能性があります。~~<br>
Google Playは個人開発者に人権がなかった。
- **App Store**での配布予定はありません（手数料が高いため）。

## 既知の問題
- **Windows版**  
- 一部カードが表示されない不具合があります。

## プロジェクト概要
このプロジェクトは、Flutterを使用して開発されています。

## メモ
プロセカ 白ノーツ 41.6ms <br>
Deemo 50ms <br>
Arcaea 50ms(内部25ms) <br>
Cytus Cytus II TP Perfect 70ms <br>
Phigros 80ms <br>

<br><br>
※これらは全て±の値