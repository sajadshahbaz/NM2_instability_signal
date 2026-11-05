#!/usr/bin/env python3
import argparse,csv,subprocess
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('--manifest',required=True); p.add_argument('--trimmed-dir',required=True); p.add_argument('--index',required=True); p.add_argument('--out-dir',required=True); p.add_argument('--threads',type=int,default=8); p.add_argument('--se-mean',type=float,default=200); p.add_argument('--se-sd',type=float,default=80); a=p.parse_args()
out=Path(a.out_dir); out.mkdir(parents=True,exist_ok=True); trim=Path(a.trimmed_dir)
with open(a.manifest,encoding='utf-8') as f: rows=list(csv.DictReader(f,delimiter='\t'))
for r in rows:
 s=r['sample_id']; od=out/f'{s}_salmon'; common=['salmon','quant','-i',a.index,'-l','A','-p',str(a.threads),'--validateMappings','--gcBias','-o',str(od)]
 if r['layout']=='PE': cmd=common+['-1',str(trim/f'{s}_1.trimmed.fastq.gz'),'-2',str(trim/f'{s}_2.trimmed.fastq.gz')]
 else: cmd=common+['-r',str(trim/f'{s}.trimmed.fastq.gz'),'--fldMean',str(a.se_mean),'--fldSD',str(a.se_sd)]
 print('[salmon]',s,flush=True); subprocess.run(cmd,check=True)
 if not (od/'quant.sf').is_file(): raise SystemExit(f'ERROR missing quant.sf after Salmon: {s}')
print(f'PASS: Salmon quantification {len(rows)}/{len(rows)}')
