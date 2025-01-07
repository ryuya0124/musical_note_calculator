# musical_note_calculator

**BPMや音符関連の計算をするアプリ**

このアプリは、音楽制作や演奏時に便利なBPM（テンポ）や音符の長さに関する計算を行うツールです。

## アプリ画面例
| 音符計算画面 | 音符回数画面 |
| --- | --- |
| ![音符計算画面](https://github.com/user-attachments/assets/1044b4ce-ab2c-4f53-ae85-f30f5cc53e89) | ![音符回数画面](https://github.com/user-attachments/assets/393343ff-236a-4e67-8b15-b2fe7fb935d8) |

| 音符換算画面 | 設定画面 |
| --- | --- |
| ![音符換算画面](https://github.com/user-attachments/assets/957122b0-5773-4652-b27c-d6083a99a985) | ![設定画面](https://github.com/user-attachments/assets/985dfaee-a90d-426c-a5c7-287c947d48f7) |

| メトロノーム画面 |  |
| --- | --- |
| ![メトロノーム画面](https://github.com/user-attachments/assets/9602d4f8-51a3-4e98-b79d-3fd1302cd203) | |

## 主な機能
- **音符計算ページ**  
  設定した時間単位で各音符の長さを計算できます。  
  - 音符計算ページのカードをタップすると、**メトロノームページ**が開きます。

- **音符回数ページ**  
  指定した時間内で、各音符が何回発生するかを計算できます。

- **音符換算ページ**  
  異なるBPMで音符を変換した場合、その新しいBPMを計算します。

- **設定画面**  
  以下のカスタマイズが可能です：  
  - **カスタム音符の追加**：好きな名前と長さで独自の音符を登録可能。  
  - **音符の表示/非表示**の切り替え。  
  - **デフォルトの時間単位**の設定。

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
- 完成したら**Google Play**で配布する可能性があります。
- **App Store**での配布予定はありません（手数料が高いため）。

## 既知の問題
- **Windows版**  
- 一部カードが表示されない不具合があります。

## プロジェクト概要
このプロジェクトは、Flutterを使用して開発されています。