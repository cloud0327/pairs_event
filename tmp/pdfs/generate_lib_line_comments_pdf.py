from __future__ import annotations

import html
import re
from datetime import datetime
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[2]
LIB_DIR = ROOT / "event_pairs" / "lib"
OUTPUT = ROOT / "output" / "pdf" / "lib_line_by_line_comments.pdf"

FONT_PATH = Path("/System/Library/Fonts/Supplemental/Arial Unicode.ttf")
FONT_NAME = "ArialUnicode"


def register_fonts() -> None:
    if FONT_PATH.exists():
        pdfmetrics.registerFont(TTFont(FONT_NAME, str(FONT_PATH)))
    else:
        from reportlab.pdfbase.cidfonts import UnicodeCIDFont

        pdfmetrics.registerFont(UnicodeCIDFont("HeiseiKakuGo-W5"))


def sorted_dart_files() -> list[Path]:
    return sorted(LIB_DIR.glob("*.dart"), key=lambda path: path.name)


def describe_line(line: str, file_name: str, previous_non_empty: str) -> str:
    raw = line.rstrip("\n")
    stripped = raw.strip()

    if stripped == "":
        return "コードのまとまりを見やすく区切るための空行です。動作には直接影響しませんが、読みやすさを上げます。"

    if stripped.startswith("//"):
        return "人間向けのメモです。Dart はこの行を実行せず、コードの意図を読む人に伝えます。"

    if stripped.startswith("import "):
        return describe_import(stripped)

    if stripped.startswith("@override"):
        return "親クラスや Flutter が用意したメソッドを、このクラス用に上書きして使うことを示します。"

    if stripped.startswith("class "):
        return describe_class(stripped)

    if stripped.startswith("enum "):
        return "選べる値の種類を固定する定義です。カテゴリのように決まった候補だけを扱いたい時に使います。"

    if stripped.startswith("const "):
        return describe_const(stripped)

    if stripped.startswith("static final "):
        return "クラスから直接使える共有データを作っています。アプリ全体で同じ情報を参照するために必要です。"

    if stripped.startswith("final "):
        return describe_final(stripped)

    if re.match(r"^(String|int|bool|double|DateTime)\s+", stripped):
        return describe_variable(stripped)

    if stripped.startswith("void "):
        return "値を返さない処理のまとまりを定義しています。ボタン操作などで呼び出すために名前を付けています。"

    if stripped.startswith("Future<"):
        return "時間のかかる非同期処理を定義しています。通信や生成待ちを画面を止めずに扱うために必要です。"

    if stripped.startswith("Widget "):
        return "画面部品を返す小さな関数を定義しています。同じ見た目を何度も書かずに再利用できます。"

    if " createState()" in stripped:
        return "StatefulWidget が持つ状態管理クラスを作ります。画面の値が変わるため、この行で State と結びます。"

    if stripped.startswith("State<"):
        return "この画面の状態を管理するクラスを返します。入力値や選択状態を画面に反映するために必要です。"

    if " build(BuildContext context)" in stripped:
        return "Flutter が画面を描く時に呼ぶ build メソッドです。この中で表示する部品を組み立てます。"

    if stripped.startswith("return "):
        return describe_return(stripped)

    if stripped.startswith("if "):
        return "条件が当てはまる時だけ中の処理を実行します。入力チェックや分岐に使います。"

    if stripped.startswith("else"):
        return "直前の if 条件に当てはまらなかった場合の処理を始めます。別パターンの動きを用意するためです。"

    if stripped.startswith("try"):
        return "失敗する可能性がある処理をここから試します。通信エラーなどを安全に扱う準備です。"

    if stripped.startswith("catch"):
        return "try の中でエラーが起きた時に実行されます。アプリが落ちずにメッセージを出せます。"

    if stripped.startswith("finally"):
        return "成功しても失敗しても最後に必ず実行する処理です。ローディング解除などに使います。"

    if stripped.startswith("await "):
        return "非同期処理が終わるまで待ちます。結果が返ってから次の行へ進むために必要です。"

    if stripped.startswith("setState"):
        return "状態を変更したことを Flutter に知らせます。これがあると画面が新しい値で再描画されます。"

    if "ScaffoldMessenger" in stripped:
        return "画面下に一時的な通知を出すための入口です。入力ミスや完了をユーザーへ伝えます。"

    if "showSnackBar" in stripped or "SnackBar" in stripped:
        return "短い通知バーを表示します。処理の結果をユーザーに分かりやすく知らせます。"

    if "Navigator" in stripped:
        return "別の画面へ移動するための処理です。タップ後の画面遷移に使います。"

    if "EventStore.addEvent" in stripped:
        return "作成した募集イベントをアプリ内の保存場所へ追加します。一覧に反映するための中心になる処理です。"

    if "EventStore.apply" in stripped:
        return "選んだイベントへ申請済みとして登録します。マイページに表示するために必要です。"

    if "EventStore." in stripped:
        return "イベント情報をまとめて管理する EventStore を使っています。画面同士で同じデータを共有できます。"

    if "TextEditingController" in stripped:
        return "入力欄の文字を Dart 側から読んだり消したりするための管理役です。フォーム入力にはよく使います。"

    if ".dispose()" in stripped:
        return "使い終わった管理オブジェクトを片付けます。無駄なメモリ使用を防ぐために必要です。"

    if ".clear()" in stripped:
        return "入力欄の文字を空にします。投稿後に前の入力が残らないようにするためです。"

    if ".trim()" in stripped:
        return "文字列の前後の空白を取り除きます。空白だけの入力を正しく空として扱えます。"

    if "jsonEncode" in stripped:
        return "Dart の Map を JSON 文字列に変換します。Ollama API にデータを送るために必要です。"

    if "jsonDecode" in stripped:
        return "API から返った JSON 文字列を Dart で扱える形に変換します。返答本文を取り出すためです。"

    if ".post(" in stripped or "http.Client" in stripped:
        return "HTTP 通信で Ollama のローカル API にリクエストを送ります。AI生成をアプリから呼ぶための行です。"

    if ".timeout(" in stripped:
        return "通信が長く止まりすぎないように制限時間を付けます。アプリが待ちっぱなしになるのを防ぎます。"

    if "RegExp" in stripped or "replaceAll" in stripped:
        return "不要な文字やタグを取り除いて、画面に出しやすい文章へ整えます。AIの余分な出力対策です。"

    if "startsWith" in stripped or "endsWith" in stripped or "contains" in stripped:
        return "文字列が特定の形かどうかを調べます。文章の整形や条件判定に使います。"

    if ".map(" in stripped:
        return "リストの各要素を別の形へ変換します。カテゴリからメニュー項目を作る時などに使います。"

    if ".where(" in stripped:
        return "条件に合う要素だけを取り出します。指定カテゴリのイベント一覧を作るために使います。"

    if ".any(" in stripped:
        return "条件に合う要素が1つでもあるか確認します。申請済みかどうかの判定に便利です。"

    if ".insert(" in stripped:
        return "リストの指定位置に新しいデータを追加します。新しいイベントを先頭に出すために使います。"

    if "ValueNotifier" in stripped:
        return "値が変わったことを画面へ知らせる仕組みです。イベント追加や申請後に表示を更新できます。"

    if "Text(" in stripped:
        return "画面に文字を表示する部品です。見出しや説明文としてユーザーに情報を見せます。"

    if "TextField" in stripped:
        return "ユーザーが文字を入力する欄を作ります。タイトル、場所、メッセージなどを受け取ります。"

    if "ElevatedButton" in stripped or "TextButton" in stripped or "IconButton" in stripped:
        return "ユーザーが押せるボタンを作ります。投稿、生成、人数変更などの操作につなげます。"

    if "DropdownButtonFormField" in stripped or "DropdownMenuItem" in stripped:
        return "複数の選択肢から1つを選ぶ部品です。イベントカテゴリの選択に使います。"

    if "ListTile" in stripped:
        return "タイトル、アイコン、タップ処理をまとめて表示できる行部品です。設定項目のような見た目に使います。"

    if "Card(" in stripped or "_card(" in stripped:
        return "内容をまとまった枠として見せます。入力欄や情報を視覚的にグループ化します。"

    if "Scaffold" in stripped:
        return "画面の基本構造を作る Flutter の部品です。上部バーや本文などを配置できます。"

    if "AppBar" in stripped:
        return "画面上部のバーを作ります。ページ名や戻る操作を分かりやすくします。"

    if "SafeArea" in stripped:
        return "端末のノッチやステータスバーに重ならない安全な表示領域を使います。"

    if "SingleChildScrollView" in stripped or "ListView" in stripped:
        return "画面に収まりきらない内容をスクロールできるようにします。フォームや一覧表示に必要です。"

    if "Column" in stripped or "Row" in stripped:
        return "複数の部品を縦または横に並べます。画面レイアウトの基本になる行です。"

    if "Expanded" in stripped:
        return "空いている幅や高さを埋めるように部品を広げます。レイアウトの崩れを防ぐために使います。"

    if "Padding" in stripped:
        return "部品の内側や外側に余白を作ります。見た目を詰まりすぎないように整えます。"

    if "SizedBox" in stripped:
        return "決まった余白やサイズを作ります。部品同士の間隔やボタンの高さを整えます。"

    if "Icon(" in stripped or "Icons." in stripped:
        return "画面にアイコンを表示します。操作や意味を文字だけより直感的に伝えます。"

    if "Image.asset" in stripped:
        return "アプリ内に登録した画像ファイルを表示します。カテゴリカードを視覚的に分かりやすくします。"

    if "Decoration" in stripped or "Border" in stripped or "Radius" in stripped or "Color(" in stripped:
        return "色、角丸、枠線などの見た目を設定します。UIを読みやすく整えるための行です。"

    if "onPressed:" in stripped or "onTap:" in stripped or "onChanged:" in stripped:
        return "ユーザー操作が起きた時に実行する処理を指定します。ボタンや入力を動きにつなげます。"

    if "controller:" in stripped:
        return "入力欄と TextEditingController を結びます。入力された文字をコード側で扱えるようにします。"

    if "child:" in stripped or "children:" in stripped:
        return "この部品の中に表示する子部品を指定します。Flutter の画面は親子構造で作られます。"

    if "required " in stripped:
        return "この値は必ず渡す必要があると示します。必要なデータの渡し忘れを防げます。"

    if stripped in {"{", "},", "});", ");", "}", "],", "],", "),"}:
        return describe_closing_line(stripped, previous_non_empty)

    if stripped.endswith("{"):
        return "ここから新しい処理や設定のまとまりが始まります。中に書いた行がこのブロックに属します。"

    if stripped.endswith("(") or stripped.endswith("["):
        return "ここから複数行に分けて設定を書き始めます。長い部品設定を読みやすくするためです。"

    if stripped.endswith(","):
        return "設定値や要素を1つ追加しています。末尾のカンマで次の設定を続けやすくしています。"

    if stripped.endswith(";"):
        return "Dart の1つの命令をここで終えています。変数宣言や処理の区切りとして必要です。"

    return "この行は前後の行とセットで、値の指定や処理の一部を担当しています。アプリの画面や動作を組み立てるために必要です。"


def describe_import(stripped: str) -> str:
    if "flutter/material.dart" in stripped:
        return "Material Design の画面部品を使えるようにします。Text や Scaffold など多くの基本UIに必要です。"
    if "flutter/cupertino.dart" in stripped:
        return "iOS 風の部品を使えるようにします。時間選択の CupertinoDatePicker で必要です。"
    if "flutter/foundation.dart" in stripped:
        return "ValueNotifier など、Flutter の基礎機能を使うための読み込みです。"
    if "dart:convert" in stripped:
        return "JSON の変換機能を使えるようにします。Ollama API とデータをやり取りするために必要です。"
    if "package:http/http.dart" in stripped:
        return "HTTP 通信ライブラリを使えるようにします。アプリから Ollama にリクエストを送るためです。"
    if "event_store" in stripped:
        return "イベントの保存・取得をまとめた自作ファイルを読み込みます。画面でイベント情報を使うためです。"
    if "ollama_message_service" in stripped:
        return "Ollama へ募集文生成を依頼する自作サービスを読み込みます。AI生成ボタンで使います。"
    if "message" in stripped:
        return "メッセージ画面のファイルを読み込みます。マイページからチャット画面へ移動するためです。"
    return "別ファイルやライブラリの機能をこのファイルで使えるように読み込む行です。"


def describe_class(stripped: str) -> str:
    if "StatefulWidget" in stripped:
        return "値が変わる画面を表すクラスです。入力内容や選択状態を持つため StatefulWidget にしています。"
    if "StatelessWidget" in stripped:
        return "状態を持たない画面や部品を表すクラスです。受け取った情報を表示する時に使います。"
    if "State<" in stripped:
        return "StatefulWidget の状態を管理するクラスです。画面の変化する値と処理をここに置きます。"
    if "EventInfo" in stripped:
        return "イベント1件分のデータの形を定義します。タイトル、場所、時間などをまとめて扱えます。"
    if "EventApplication" in stripped:
        return "申請1件分のデータの形を定義します。どのイベントにいつ申請したかをまとめます。"
    if "EventStore" in stripped:
        return "イベントや申請をアプリ内で管理する置き場を定義します。複数画面で同じデータを使うためです。"
    if "OllamaMessageService" in stripped:
        return "Ollama との通信を担当するクラスです。画面側のコードを通信処理でごちゃつかせないためです。"
    return "関連する変数や処理をまとめる設計図を定義しています。Dart ではクラス単位で機能を整理します。"


def describe_const(stripped: str) -> str:
    if "super.key" in stripped:
        return "このウィジェットを作るためのコンストラクタです。super.key は Flutter が部品を識別する手助けをします。"
    if "EventCategory" in stripped:
        return "enum の各値に表示名を結び付けるためのコンストラクタです。カテゴリ名を画面に出せます。"
    if "TextStyle" in stripped:
        return "何度も使う文字スタイルを定数としてまとめています。見出しの見た目を統一できます。"
    return "コンパイル時に固定できる値や作り方を定義しています。変わらないものを効率よく扱えます。"


def describe_final(stripped: str) -> str:
    if "TextEditingController" in stripped:
        return "入力欄を管理する変数を作っています。一度作った管理役を同じ画面内で使い続けます。"
    if "OllamaMessageService" in stripped:
        return "AI募集文生成サービスを作っています。ボタンから同じサービスを呼び出せるようにします。"
    if "String " in stripped and "id" in stripped:
        return "一度決めたIDを保存する文字列です。データを区別するために変更しない値として持ちます。"
    if "EventCategory" in stripped:
        return "イベントカテゴリを保存する変数です。イベントがどのジャンルか分かるようにします。"
    if "DateTime" in stripped:
        return "日時を保存する変数です。申請した時刻などを記録できます。"
    if "List<" in stripped:
        return "複数のデータをまとめるリストです。イベント一覧や申請一覧を管理するために使います。"
    if "=" in stripped:
        return "あとから別のものに入れ替えない値を作っています。安全に同じ参照を使い続けるためです。"
    return "このクラスが持つ変更しない値を宣言しています。必要なデータを分かりやすく名前で持たせます。"


def describe_variable(stripped: str) -> str:
    if stripped.startswith("String purpose"):
        return "現在選ばれている目的を文字列で保存します。選択中のボタン表示を変えるために使います。"
    if stripped.startswith("int memberCount"):
        return "募集人数の現在値を保存します。プラス・マイナスボタンで変化する数字です。"
    if stripped.startswith("int maxMemberCount"):
        return "募集人数の上限を保存します。5人までに制限するために使います。"
    if stripped.startswith("bool isGeneratingMessage"):
        return "AI生成中かどうかを保存します。ボタンを無効化したり、生成中表示を出すためです。"
    if "label" in stripped:
        return "画面に表示する文字を保存します。enum の内部名とは別に日本語名を持てます。"
    return "変化する値を保存する変数です。画面の状態や処理に必要な情報を名前付きで持ちます。"


def describe_return(stripped: str) -> str:
    if "MaterialApp" in stripped:
        return "Flutter アプリ全体の土台を返します。テーマや最初の画面をここから設定します。"
    if "Scaffold" in stripped:
        return "1画面分の基本レイアウトを返します。本文や上部バーを置くための土台です。"
    if "SafeArea" in stripped:
        return "安全な表示領域を使った画面を返します。端末の端に内容が重ならないようにします。"
    if "List.unmodifiable" in stripped:
        return "外から直接変更できないリストとして返します。データ管理の安全性を高めます。"
    if "_events.where" in stripped:
        return "指定カテゴリだけに絞ったイベント一覧を返します。カテゴリ別一覧表示に必要です。"
    if "_applications.any" in stripped:
        return "同じイベントへ申請済みかどうかの判定結果を返します。重複申請を防ぎます。"
    if "message" in stripped or "cleaned" in stripped:
        return "整えた文字列を呼び出し元へ返します。画面のメッセージ欄に入れるためです。"
    return "この関数やメソッドの結果を呼び出し元へ返します。後続の処理がこの値を使えます。"


def describe_closing_line(stripped: str, previous_non_empty: str) -> str:
    if stripped in {"});", ");"}:
        return "直前まで複数行で書いていた命令やウィジェット作成をここで完了します。Dart の文末として必要です。"
    if stripped in {"},", "}", "),"}:
        return "ここまでが1つのブロックや部品設定の範囲です。閉じることで次の処理との境目を明確にします。"
    if stripped == "],":
        return "複数の子部品やリスト要素の並びをここで閉じます。親部品へリストを渡すために必要です。"
    return "前の行から続いていたまとまりを閉じるための記号です。コードの構造を正しく保ちます。"


def code_to_html(line: str) -> str:
    escaped = html.escape(line.rstrip("\n"))
    leading_spaces = len(line.rstrip("\n")) - len(line.rstrip("\n").lstrip(" "))
    if leading_spaces:
        escaped = "&nbsp;" * leading_spaces + escaped[leading_spaces:]
    if escaped == "":
        return "<font color='#8a8f98'>(空行)</font>"
    return escaped


def build_styles():
    styles = getSampleStyleSheet()
    base_font = FONT_NAME if FONT_PATH.exists() else "HeiseiKakuGo-W5"

    return {
        "title": ParagraphStyle(
            "title",
            parent=styles["Title"],
            fontName=base_font,
            fontSize=22,
            leading=28,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#1f2937"),
            spaceAfter=10,
        ),
        "subtitle": ParagraphStyle(
            "subtitle",
            parent=styles["BodyText"],
            fontName=base_font,
            fontSize=10,
            leading=15,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#4b5563"),
        ),
        "section": ParagraphStyle(
            "section",
            parent=styles["Heading2"],
            fontName=base_font,
            fontSize=15,
            leading=20,
            textColor=colors.HexColor("#111827"),
            spaceBefore=6,
            spaceAfter=6,
        ),
        "body": ParagraphStyle(
            "body",
            parent=styles["BodyText"],
            fontName=base_font,
            fontSize=8.2,
            leading=12,
            alignment=TA_LEFT,
            wordWrap="CJK",
        ),
        "small": ParagraphStyle(
            "small",
            parent=styles["BodyText"],
            fontName=base_font,
            fontSize=7.2,
            leading=10,
            alignment=TA_LEFT,
            textColor=colors.HexColor("#374151"),
            wordWrap="CJK",
        ),
        "code": ParagraphStyle(
            "code",
            parent=styles["Code"],
            fontName=base_font,
            fontSize=6.5,
            leading=9,
            alignment=TA_LEFT,
            textColor=colors.HexColor("#111827"),
            wordWrap="CJK",
        ),
        "line": ParagraphStyle(
            "line",
            parent=styles["BodyText"],
            fontName=base_font,
            fontSize=7,
            leading=9,
            alignment=TA_CENTER,
            textColor=colors.HexColor("#6b7280"),
        ),
        "header": ParagraphStyle(
            "header",
            parent=styles["BodyText"],
            fontName=base_font,
            fontSize=7.5,
            leading=10,
            textColor=colors.white,
            alignment=TA_CENTER,
        ),
    }


def row_table(line_no: int, code: str, explanation: str, styles: dict) -> Table:
    row = [
        Paragraph(str(line_no), styles["line"]),
        Paragraph(code_to_html(code), styles["code"]),
        Paragraph(html.escape(explanation), styles["small"]),
    ]

    table = Table(
        [row],
        colWidths=[13 * mm, 128 * mm, 128 * mm],
        hAlign="LEFT",
        splitByRow=1,
    )
    table.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("BACKGROUND", (0, 0), (0, 0), colors.HexColor("#f3f4f6")),
                ("BACKGROUND", (1, 0), (1, 0), colors.HexColor("#f8fafc")),
                ("BACKGROUND", (2, 0), (2, 0), colors.white),
                ("BOX", (0, 0), (-1, -1), 0.25, colors.HexColor("#d1d5db")),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#e5e7eb")),
                ("LEFTPADDING", (0, 0), (-1, -1), 4),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 3),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ]
        )
    )
    return table


def header_table(styles: dict) -> Table:
    table = Table(
        [
            [
                Paragraph("行", styles["header"]),
                Paragraph("コード", styles["header"]),
                Paragraph("初心者向けコメント", styles["header"]),
            ]
        ],
        colWidths=[13 * mm, 128 * mm, 128 * mm],
        hAlign="LEFT",
    )
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#374151")),
                ("BOX", (0, 0), (-1, -1), 0.25, colors.HexColor("#374151")),
                ("INNERGRID", (0, 0), (-1, -1), 0.25, colors.HexColor("#6b7280")),
                ("TOPPADDING", (0, 0), (-1, -1), 4),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
            ]
        )
    )
    return table


def draw_page(canvas, doc):
    canvas.saveState()
    width, height = landscape(A4)
    base_font = FONT_NAME if FONT_PATH.exists() else "HeiseiKakuGo-W5"
    canvas.setFont(base_font, 7)
    canvas.setFillColor(colors.HexColor("#6b7280"))
    canvas.drawString(14 * mm, height - 9 * mm, "Event Pairs lib コード行別コメント")
    canvas.drawRightString(width - 14 * mm, 8 * mm, f"Page {doc.page}")
    canvas.restoreState()


def build_pdf() -> None:
    register_fonts()
    styles = build_styles()
    files = sorted_dart_files()
    total_lines = sum(len(path.read_text(encoding="utf-8").splitlines()) for path in files)

    doc = SimpleDocTemplate(
        str(OUTPUT),
        pagesize=landscape(A4),
        rightMargin=14 * mm,
        leftMargin=14 * mm,
        topMargin=16 * mm,
        bottomMargin=14 * mm,
        title="Event Pairs lib コード行別コメント",
    )

    story = [
        Paragraph("Event Pairs lib コード行別コメント", styles["title"]),
        Paragraph(
            f"対象: event_pairs/lib 配下の Dart ファイル {len(files)} 個 / {total_lines} 行",
            styles["subtitle"],
        ),
        Spacer(1, 5 * mm),
        Paragraph(
            "このPDFは、コード初心者が各行の役割を追えるように、空行や閉じ括弧も含めて1行ずつ説明しています。",
            styles["body"],
        ),
        Paragraph(
            "コメントは学習用の説明です。実際のソースコードへコメントを挿入したものではありません。",
            styles["body"],
        ),
        Paragraph(
            f"生成日時: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
            styles["body"],
        ),
        PageBreak(),
    ]

    for file_index, path in enumerate(files):
        if file_index > 0:
            story.append(PageBreak())

        relative = path.relative_to(ROOT)
        lines = path.read_text(encoding="utf-8").splitlines()
        story.append(Paragraph(str(relative), styles["section"]))
        story.append(
            Paragraph(
                f"{path.name} は {len(lines)} 行です。下の表で、左から行番号、実際のコード、その行の役割を確認できます。",
                styles["body"],
            )
        )
        story.append(Spacer(1, 2 * mm))
        story.append(header_table(styles))

        previous_non_empty = ""
        for line_no, line in enumerate(lines, start=1):
            explanation = describe_line(line, path.name, previous_non_empty)
            story.append(row_table(line_no, line, explanation, styles))
            if line.strip():
                previous_non_empty = line.strip()

    doc.build(story, onFirstPage=draw_page, onLaterPages=draw_page)


if __name__ == "__main__":
    build_pdf()
