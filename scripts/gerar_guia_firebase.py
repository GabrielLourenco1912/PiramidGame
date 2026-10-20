#!/usr/bin/env python3
"""Gera o guia PDF a partir de docs/FIREBASE.md. Requer reportlab."""
from pathlib import Path
from html import escape
import re

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Preformatted, PageBreak

ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "Instrucoes_Firebase_PiramidGame.pdf"
SOURCE = ROOT / "docs" / "FIREBASE.md"
FONT_DIR = Path("/usr/share/fonts/truetype/dejavu")
if FONT_DIR.exists():
    pdfmetrics.registerFont(TTFont("Guide", str(FONT_DIR / "DejaVuSans.ttf")))
    pdfmetrics.registerFont(TTFont("GuideBold", str(FONT_DIR / "DejaVuSans-Bold.ttf")))
    regular, bold = "Guide", "GuideBold"
else:
    regular, bold = "Helvetica", "Helvetica-Bold"

styles = getSampleStyleSheet()
styles.add(ParagraphStyle("GuideTitle", fontName=bold, fontSize=17, leading=21,
                         spaceAfter=14, textColor=colors.HexColor("#166534")))
styles.add(ParagraphStyle("GuideHeading", fontName=bold, fontSize=11, leading=15,
                         spaceBefore=11, spaceAfter=6, textColor=colors.HexColor("#166534")))
styles.add(ParagraphStyle("GuideBody", fontName=regular, fontSize=9, leading=13,
                         spaceAfter=7, alignment=TA_LEFT))
styles.add(ParagraphStyle("GuideBullet", parent=styles["GuideBody"], leftIndent=11,
                         firstLineIndent=-8, spaceAfter=5))
styles.add(ParagraphStyle("GuideCode", fontName="Courier", fontSize=7.8, leading=11,
                         backColor=colors.HexColor("#F0F4F1"), borderPadding=8,
                         spaceBefore=5, spaceAfter=10))


def formatted(text):
    text = escape(text)
    return re.sub(
        r"https?://[^\s<]+", lambda match: '<a href="' + match.group() + '">' + match.group() + '</a>',
        text,
    )


def footer(canvas, document):
    canvas.setStrokeColor(colors.HexColor("#D1D5DB"))
    canvas.line(40, 38, A4[0] - 40, 38)
    canvas.setFont(regular, 8)
    canvas.setFillColor(colors.HexColor("#64748B"))
    canvas.drawString(40, 24, "PiramidGame IFPR-Pgua | Guia de configuração")
    canvas.drawRightString(A4[0] - 40, 24, str(document.page))


def build():
    document = SimpleDocTemplate(
        str(OUTPUT), pagesize=A4, leftMargin=40, rightMargin=40,
        topMargin=34, bottomMargin=49,
        title="PiramidGame — Instruções do Firebase",
        author="PiramidGame IFPR-Pgua",
    )
    story = []
    paragraph = []
    code = []
    in_code = False

    def flush():
        if paragraph:
            story.append(Paragraph(formatted(" ".join(paragraph)), styles["GuideBody"]))
            paragraph.clear()

    for line in SOURCE.read_text(encoding="utf-8").splitlines():
        if line.startswith("```"):
            flush()
            if in_code:
                story.append(Preformatted("\n".join(code), styles["GuideCode"]))
                code.clear()
            in_code = not in_code
        elif in_code:
            code.append(line)
        elif line == "<!-- pagebreak -->":
            flush()
            story.append(PageBreak())
        elif line.startswith("# "):
            flush()
            story.append(Paragraph(formatted(line[2:]), styles["GuideTitle"]))
        elif line.startswith("## "):
            flush()
            story.append(Paragraph(formatted(line[3:]), styles["GuideHeading"]))
        elif line.startswith("- "):
            flush()
            story.append(Paragraph("• " + formatted(line[2:]), styles["GuideBullet"]))
        elif not line.strip():
            flush()
        else:
            paragraph.append(line.strip())
    flush()
    document.build(story, onFirstPage=footer, onLaterPages=footer)
    print(OUTPUT)


if __name__ == "__main__":
    build()
