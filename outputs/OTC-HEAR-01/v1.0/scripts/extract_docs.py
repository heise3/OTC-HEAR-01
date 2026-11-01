"""Extract documentation text with explicit PDF page markers."""
from pathlib import Path
from pypdf import PdfReader
ROOT=Path(__file__).resolve().parents[4]
for f in sorted((ROOT/'work/nhis_docs').glob('*.pdf')):
    out=f.with_suffix('.txt')
    if out.exists(): continue
    reader=PdfReader(f)
    out.write_text('\n'.join(f'\n@@PDF_PAGE_{i+1}@@\n'+(page.extract_text() or '') for i,page in enumerate(reader.pages)))
    print(f.name,len(reader.pages),flush=True)
