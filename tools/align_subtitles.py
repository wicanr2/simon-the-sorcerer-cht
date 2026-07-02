#!/usr/bin/env python3
# 對齊 floppy 與 CD 的 script dump,產出 speechId -> floppy 完整文字。
# 依 subroutine ID + PRINT_STR(opcode 162) 位置配對。
# 用法: python3 tools/align_subtitles.py floppy.dump cd.dump out.tsv
import sys, re

SUB_RE = re.compile(r';Subroutine, ID=(\d+):')
# floppy: PRINT_STR b b "text"(id)   |  PRINT_STR b b NULL_STRING
FL_RE  = re.compile(r'^PRINT_STR \d+ \d+ (?:NULL_STRING|"(.*)"\((\d+)\))\s*$')
# cd: 同上但尾端多一個 speechId
CD_RE  = re.compile(r'^PRINT_STR \d+ \d+ (?:NULL_STRING|"(.*)"\((\d+)\)) (\d+)\s*$')

def parse(path, is_cd):
    subs = {}          # sub_id -> list of entries
    cur = None
    for line in open(path, encoding='latin1'):
        line = line.rstrip('\n')
        m = SUB_RE.search(line)
        if m:
            cur = int(m.group(1)); subs.setdefault(cur, [])
            continue
        if cur is None: continue
        if line.startswith('PRINT_STR'):
            if is_cd:
                mm = CD_RE.match(line)
                if not mm:  # 解析失敗,記原文
                    subs[cur].append({'raw': line}); continue
                text, sid, speech = mm.group(1), mm.group(2), mm.group(3)
                subs[cur].append({'text': text, 'id': sid, 'speech': int(speech)})
            else:
                mm = FL_RE.match(line)
                if not mm:
                    subs[cur].append({'raw': line}); continue
                text, sid = mm.group(1), mm.group(2)
                subs[cur].append({'text': text, 'id': sid})
    return subs

def main():
    fl_path, cd_path, out = sys.argv[1], sys.argv[2], sys.argv[3]
    fl = parse(fl_path, False)
    cd = parse(cd_path, True)
    mapping = {}       # speechId -> floppy_text
    stats = dict(pairs=0, cd_null=0, cd_hastext=0, mismatch=0, count_mismatch_subs=0,
                 fl_only=0, no_speech=0, dup_conflict=0)
    common = sorted(set(fl) & set(cd))
    for sid in common:
        a, b = fl[sid], cd[sid]
        if len(a) != len(b):
            stats['count_mismatch_subs'] += 1
            # 位置對不齊的 subroutine 跳過(結構不同),之後再處理
            continue
        for fe, ce in zip(a, b):
            if 'raw' in fe or 'raw' in ce:
                continue
            stats['pairs'] += 1
            sp = ce.get('speech')
            ftext = fe.get('text')
            if sp is None:
                stats['no_speech'] += 1
                continue
            # CD 有文字時驗證與 floppy 一致
            if ce.get('text') is not None:
                stats['cd_hastext'] += 1
                if ftext is not None and ce['text'] != ftext:
                    stats['mismatch'] += 1
            else:
                stats['cd_null'] += 1
            if ftext is None:
                continue
            if sp in mapping and mapping[sp] != ftext:
                stats['dup_conflict'] += 1
            mapping[sp] = ftext
    with open(out, 'w', encoding='utf-8') as f:
        f.write("# speechId\tfloppy_EN_text\n")
        for sp in sorted(mapping):
            f.write(f"{sp}\t{mapping[sp]}\n")
    print(f"共同 subroutine: {len(common)}  (floppy {len(fl)}, cd {len(cd)})")
    print(f"結構不符(len 不同)subroutine: {stats['count_mismatch_subs']}")
    print(f"配對 PRINT_STR: {stats['pairs']}")
    print(f"  CD 無字(voice-only): {stats['cd_null']}   CD 有字: {stats['cd_hastext']}")
    print(f"  CD有字但與floppy不符: {stats['mismatch']}   dup speechId 衝突: {stats['dup_conflict']}")
    print(f"產出 speechId→floppy文字: {len(mapping)} 條 → {out}")

if __name__ == '__main__':
    main()
