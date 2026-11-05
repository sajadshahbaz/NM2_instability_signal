#!/usr/bin/env python3
import argparse,csv,subprocess,sys
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('--manifest',required=True); p.add_argument('--out-dir',required=True); p.add_argument('--threads',type=int,default=4); p.add_argument('--multiqc-dir',required=True); a=p.parse_args()
out=Path(a.out_dir); out.mkdir(parents=True,exist_ok=True)
with open(a.manifest,encoding='utf-8') as f: rows=list(csv.DictReader(f,delimiter='\t'))
for r in rows:
 s=r['sample_id']; layout=r['layout']; j=out/f'{s}_fastp.json'; h=out/f'{s}_fastp.html'
 if layout=='PE':
  o1=out/f'{s}_1.trimmed.fastq.gz'; o2=out/f'{s}_2.trimmed.fastq.gz'
  cmd=['fastp','-i',r['fastq_1'],'-I',r['fastq_2'],'-o',str(o1),'-O',str(o2),'--thread',str(a.threads),'--json',str(j),'--html',str(h)]
 else:
  o1=out/f'{s}.trimmed.fastq.gz'; cmd=['fastp','-i',r['fastq_1'],'-o',str(o1),'--thread',str(a.threads),'--json',str(j),'--html',str(h)]
 print('[fastp]',s,flush=True); subprocess.run(cmd,check=True)
mq=Path(a.multiqc_dir); mq.mkdir(parents=True,exist_ok=True)
subprocess.run(['multiqc',str(out),'-o',str(mq),'--export','--force'],check=True)
print(f'PASS: fastp {len(rows)}/{len(rows)}; MultiQC={mq}')
