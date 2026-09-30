# Performance: the rope-based port vs the Buffer port and the Ada besm2_fmt

- Date: 2026-09-30
- CPU: 13th Gen Intel(R) Core(TM) i9-13900HX
- Ropes: `./besm2_fmt`; Buffers: `/home/tkb/Repos/RPG/Tools/obesm2_fmt/besm2_fmt`; Ada: `/home/tkb/Repos/RPG/Tools/besm2_fmt/besm2_fmt`
- `BENCH_N`=200, `BENCH_ENTITIES`=2000, `BENCH_SOURCE`=`test/data/enyon-boase-2e.yaml`
- The three programs' outputs were checked to be identical on every
  input and format first.

## Per-invocation time (200 runs of `enyon-boase-2e.yaml`)

| Format | Ada (ms) | Buffers (ms) | Ropes (ms) | Ropes / Buffers | Ropes / Ada |
|---|---|---|---|---|---|
| grid | 2.50 | 3.74 | 3.57 | 0.95 | 1.43 |
| terse | 2.38 | 2.25 | 2.15 | 0.96 | 0.90 |
| h-m-m | 1.59 | 2.30 | 2.37 | 1.03 | 1.49 |
| raw ms | 2.43 | 1.91 | 2.22 | 1.16 | 0.91 |

## Throughput: 2000 entities in one document

| Format | Ada (s) | Buffers (s) | Ropes (s) | Ropes / Buffers | Ropes / Ada | Ada max RSS (KB) | Buffers max RSS (KB) | Ropes max RSS (KB) |
|---|---|---|---|---|---|---|---|---|
| grid | 0.32 | 0.80 | 0.98 | 1.22 | 3.06 | 135972 | 135116 | 134584 |
| terse | 0.20 | 0.67 | 0.41 | 0.61 | 2.05 | 135492 | 134340 | 135380 |
| h-m-m | 0.20 | 0.51 | 0.43 | 0.84 | 2.15 | 135464 | 135120 | 134632 |
| raw ms | 0.21 | 0.53 | 0.45 | 0.85 | 2.14 | 135728 | 134796 | 135052 |

## Throughput: 2000 documents of one entity each

| Format | Ada (s) | Buffers (s) | Ropes (s) | Ropes / Buffers | Ropes / Ada | Ada max RSS (KB) | Buffers max RSS (KB) | Ropes max RSS (KB) |
|---|---|---|---|---|---|---|---|---|
| grid | 0.32 | 1.89 | 0.93 | 0.49 | 2.91 | 5636 | 5088 | 5052 |
| terse | 0.18 | 0.51 | 0.37 | 0.73 | 2.06 | 5628 | 4732 | 5260 |
| h-m-m | 0.18 | 0.35 | 0.38 | 1.09 | 2.11 | 5652 | 4800 | 5260 |
| raw ms | 0.19 | 0.63 | 0.42 | 0.67 | 2.21 | 5596 | 5068 | 5096 |
