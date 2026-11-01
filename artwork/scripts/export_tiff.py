"""Lossless format conversion of the600dpi scientific plot, without resizing."""
from pathlib import Path
from PIL import Image
import json
p=Path(__file__).resolve().parents[1]
source=p/'.Figure_OTC_HEAR_01_600dpi.png'
with Image.open(source) as image:
    image=image.convert('RGB')
    assert image.size==(4080,3540),image.size
    image.save(p/'Figure_OTC_HEAR_01.tiff',compression='tiff_lzw',dpi=(600,600))
with Image.open(p/'Figure_OTC_HEAR_01.tiff') as image:
    assert image.size==(4080,3540)
    assert tuple(float(x) for x in image.info['dpi'])==(600.,600.)
    meta={'pixels':list(image.size),'dpi':[float(x) for x in image.info['dpi']],'mode':image.mode,'compression':image.info.get('compression'),'resampled':False}
(p/'figure_export_metadata.json').write_text(json.dumps(meta,indent=2)+'\n')
source.unlink()
print(meta)
