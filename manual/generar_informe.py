import markdown
import re

with open('/home/nestor/yoltec/manual/informe-pentesting.md', 'r') as f:
    md_content = f.read()

html_body = markdown.markdown(md_content, extensions=['tables', 'fenced_code'])

html = f"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>Informe de Pentesting — YOLTEC</title>
<style>
  @page {{ margin: 2cm 2.5cm; }}
  * {{ box-sizing: border-box; }}
  body {{
    font-family: 'Segoe UI', Arial, sans-serif;
    font-size: 11pt;
    line-height: 1.6;
    color: #1a1a1a;
    max-width: 900px;
    margin: 0 auto;
    padding: 20px;
  }}
  h1 {{
    font-size: 22pt;
    color: #1a237e;
    text-align: center;
    border-bottom: 3px solid #1a237e;
    padding-bottom: 10px;
    margin-bottom: 5px;
  }}
  h2 {{
    font-size: 14pt;
    color: #1a237e;
    border-left: 5px solid #1a237e;
    padding-left: 12px;
    margin-top: 30px;
    page-break-after: avoid;
  }}
  h3 {{
    font-size: 12pt;
    color: #283593;
    margin-top: 20px;
    page-break-after: avoid;
  }}
  h4 {{
    font-size: 11pt;
    color: #3949ab;
    margin-top: 15px;
  }}
  table {{
    width: 100%;
    border-collapse: collapse;
    margin: 15px 0;
    font-size: 10pt;
    page-break-inside: avoid;
  }}
  th {{
    background-color: #1a237e;
    color: white;
    padding: 8px 12px;
    text-align: left;
    font-weight: 600;
  }}
  td {{
    padding: 7px 12px;
    border: 1px solid #ddd;
  }}
  tr:nth-child(even) td {{
    background-color: #f5f5f5;
  }}
  tr:hover td {{
    background-color: #e8eaf6;
  }}
  code {{
    background-color: #f4f4f4;
    padding: 2px 6px;
    border-radius: 3px;
    font-family: 'Courier New', monospace;
    font-size: 9.5pt;
    color: #c62828;
  }}
  pre {{
    background-color: #1e1e1e;
    color: #d4d4d4;
    padding: 15px;
    border-radius: 6px;
    overflow-x: auto;
    font-family: 'Courier New', monospace;
    font-size: 9pt;
    line-height: 1.5;
    border-left: 4px solid #3949ab;
    page-break-inside: avoid;
  }}
  pre code {{
    background: none;
    padding: 0;
    color: #d4d4d4;
    font-size: 9pt;
  }}
  blockquote {{
    border-left: 4px solid #ffc107;
    background: #fff8e1;
    padding: 10px 15px;
    margin: 10px 0;
    border-radius: 0 4px 4px 0;
  }}
  hr {{
    border: none;
    border-top: 2px solid #e0e0e0;
    margin: 25px 0;
  }}
  /* Badges de severidad en tablas */
  td:nth-child(4) {{
    font-weight: bold;
  }}
  p {{ margin: 8px 0; }}
  ul, ol {{ padding-left: 25px; }}
  li {{ margin: 4px 0; }}
  .page-break {{ page-break-before: always; }}
  /* Header de portada */
  .portada {{
    text-align: center;
    padding: 20px 0 30px 0;
    border-bottom: 2px solid #1a237e;
    margin-bottom: 30px;
  }}
</style>
</head>
<body>
{html_body}
</body>
</html>"""

with open('/home/nestor/yoltec/manual/informe-pentesting.html', 'w') as f:
    f.write(html)

print("HTML generado OK")
