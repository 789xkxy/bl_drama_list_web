import os, json
from PIL import Image
base = os.environ.get('BL_BASE')
if not base:
    raise SystemExit('BL_BASE not set')
pics_dir = os.path.join(base, 'info', 'pics')
out_path = os.path.join(base, '\u5267\u96c6\u6570\u636e', '\u6d77\u62a5\u8272.json')
result = {}
for f in os.listdir(pics_dir):
    if f.lower().endswith(('.jpg', '.jpeg', '.png', '.webp')):
        try:
            im = Image.open(os.path.join(pics_dir, f)).convert('RGB')
            im = im.resize((24, 32))
            px = list(im.getdata())
            n = len(px)
            r = sum(p[0] for p in px) // n
            g = sum(p[1] for p in px) // n
            b = sum(p[2] for p in px) // n
            result[f] = '#%02x%02x%02x' % (r, g, b)
        except Exception as e:
            print('skip', f, repr(e))
with open(out_path, 'w', encoding='utf-8') as fh:
    json.dump(result, fh, ensure_ascii=False, indent=2)
print('colors computed:', len(result))