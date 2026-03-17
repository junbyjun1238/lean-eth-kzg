한 줄 판정부터 말하면, **그 리뷰는 대체로 타당합니다. 다만 진단은 좋고 처방은 과교정된 면이 있습니다.**
특히 `c-kzg-4844`는 Deneb/Fulu의 public KZG API를 구현하는 공식 C 라이브러리이고, bindings는 클라이언트들이 중요한 암호 함수를 재구현하지 않게 하려는 목적을 분명히 밝힙니다. 게다가 EIP-7594용 `verify_cell_kzg_proof_batch`까지 포함하고, 7594 구현은 2025년 감사도 받았습니다. Fulu는 현재 stable spec이고, Fusaka는 2025-12-03에 메인넷에 들어갔습니다. 즉 이 경계는 진짜 메인넷 경계입니다. ([GitHub][1])

그래서 원래 Hard Mode 기획의 큰 방향, 즉 **“Fulu/PeerDAS를 전면에 세우고, 실제 공식 구현과 붙고, 2025년 실버그를 regression artifact로 고정하자”**는 방향은 맞습니다. 실제로 `c-kzg-4844`는 2025년에 `verify_cell_kzg_proof_batch` 계열 버그를 두 번 수정했습니다. 하나는 point-at-infinity 경로 때문에 결과가 잘못될 수 있던 문제였고, 다른 하나는 deduplicated commitments가 challenge 계산에 제대로 반영되지 않아 potential Weak Fiat–Shamir vulnerability가 생기던 문제였습니다. ([GitHub][2])

다만 당신이 가져온 비판도 핵심을 찌릅니다. **Lean을 주 무기로 잡은 1인 프로젝트에서 “C 구현 전체 refinement proof”를 핵심 milestone으로 두는 건 잘못된 압박점**입니다. Galois도 이 문제를 SAW/Cryptol로, 그것도 Deneb 기준으로 탐색하고 있습니다. 즉 “Lean으로 C 메모리/포인터/바이트코드 레벨 검증”이 1차 본체가 되면 프로젝트가 틀어질 가능성이 큽니다. ([GitHub][3])

하지만 리뷰가 과한 부분도 분명합니다.

첫째, **“절대 불가능”은 과장**입니다. 불가능한 게 아니라, **핵심 마일스톤으로 두면 안 되는 것**에 가깝습니다. `c-kzg-4844`는 여러 클라이언트와 바인딩이 의존하는 공식 구현이므로, 구현체와의 접촉을 완전히 버리면 토이 냄새가 납니다. 다만 그 접촉 방식은 “Lean이 C 내부를 증명한다”가 아니라, **Lean이 semantic oracle을 제공하고 public API boundary에서 differential conformance를 강제한다**로 바뀌어야 합니다. ([GitHub][1])

둘째, **“regression theorem은 동어반복이라 무의미하다”도 절반만 맞습니다.**
맞는 부분은, 순수한 Lean spec 위에서 “내 spec에는 그 C 버그가 없다”라고 쓰면 공허하다는 점입니다. 틀린 부분은, 그래서 regression theorem 자체가 무가치하다는 결론입니다. 실제로 필요한 건 **버그의 구현적 모양을 재현하는 것**이 아니라, **그 버그가 깨뜨린 불변식을 정리로 박는 것**입니다. 예를 들면:

* challenge는 실제로 검증에 참여한 모든 unique commitment를 바인드해야 한다.
* deduplication은 canonical witness/statement correspondence를 유지할 때만 semantics-preserving이다.
* fast path와 naive path는 정상화된 입력 집합에서 같은 결론을 내야 한다.
* invalid point / point-at-infinity 처리 방식은 batch size나 내부 branch에 따라 달라지면 안 된다.
  2025년 두 버그는 정확히 이런 류의 불변식을 깨뜨렸습니다. point-at-infinity 이슈는 최소 8개 셀 이상일 때 fast path에서 드러났고, dedup bug는 `[a, a, b]` 같은 배열에서 challenge가 `[a, a]`만 반영되는 식으로 나타났습니다. ([GitHub][4])

셋째, **공식 테스트 벡터 연동을 비판한 것도 맞지만, 방향 수정이 필요합니다.**
지금은 “Lean에서 YAML 노가다”를 하면 안 됩니다. 게다가 `consensus-spec-tests` repo는 2025-10-22에 archive 되었고 read-only입니다. 반면 `consensus-specs`는 여전히 formal spec, executable Python spec, reference test generator 역할을 하고 있습니다. 그러니 최종 설계는 **archived released vectors를 pin해서 재현성 확보 + 현재 `consensus-specs` 생성 경로를 추적**으로 가야 맞습니다. 실제로 `consensus-spec-tests`에는 spec 변경 없이 벡터만 바뀐 hotfix release도 있었습니다. ([GitHub][5])

그리고 여기서 내가 하나 더 보태겠습니다. **그 리뷰의 대체안인 “Lean으로 soundness/completeness를 증명하자”도 그대로 가져가면 또 다른 함정**입니다.
ArkLib는 이미 Interactive Oracle Reductions, Fiat–Shamir, completeness/soundness proof, 심지어 장기적으로는 extracted code와의 equivalence까지 노리는 방향입니다. CompPoly는 computable polynomial foundation이고, clean은 Lean circuit DSL, CertiPlonk는 Plonky3 constraint extraction/verification 쪽입니다. 즉 **full KZG/Fiat–Shamir cryptographic soundness를 정면돌파**하면 오히려 ArkLib 축과 부딪히고, **새 polynomial core나 circuit framework를 같이 만들면** 다른 팀과 정면충돌합니다. ([GitHub][6])

그래서 최종 결론은 이겁니다.

## 최종 방향

**원래 Hard Mode의 “실제 경계에 붙는다”는 야심은 유지하되, refinement를 두 층으로 분해해야 합니다.**

1. **Lean 안에서 증명할 refinement**
   추상 KZG API semantics → raw-bytes / normalization / transcript를 포함한 byte-level Lean spec.
   Deneb spec 자체가 public methods가 raw bytes를 받고 normalization을 해야 한다고 명시합니다. 이 층은 Lean이 잘하는 부분입니다. ([Ethereum GitHub][7])

2. **Lean 밖에서 강제할 conformance**
   byte-level Lean spec ↔ pinned `c-kzg-4844` public API binary.
   이건 C 내부 증명이 아니라 **official vectors + historical regressions + Lean-generated adversarial corpus**로 자동 비교합니다. 이 층이 있어야 토이가 아닙니다. `c-kzg-4844`가 바로 클라이언트가 기대는 공식 구현이기 때문입니다. ([GitHub][1])

이렇게 나누면 Lean에게 SAW의 일을 시키지 않고, 동시에 Galois에게 전부 양보하지도 않습니다.

---

## 내가 최종 완결한 마일스톤

### M0 — 범위 계약서와 TCB를 먼저 박기

이 단계는 문서지만 제일 중요합니다.

반드시 박아야 할 것:

* 대상 spec: **Deneb + Fulu stable spec의 pinned commit/release**
* 대상 impl: **`c-kzg-4844`의 pinned fixed tag + historical bad tags**
* 신뢰기반: trusted setup, 외부 crypto backend가 있으면 그 backend, vector preprocessor, C toolchain/FFI
* 비목표: full C memory verification, full KZG cryptographic security proof, pairing backend from scratch, generic SNARK framework, circuit DSL, polynomial core 재구축

왜냐하면 CompPoly/ArkLib/clean/CertiPlonk는 이미 각자 자기 영역이 선명하기 때문입니다. 프로젝트가 진짜 기여가 되려면 이들과 경쟁하는 게 아니라 **Ethereum KZG verifier boundary**라는 좁고 날카로운 축을 붙들어야 합니다. ([GitHub][8])

완료 기준은 README 첫 화면만 봐도 “무엇을 증명하고, 무엇을 신뢰하며, 무엇은 안 하는지”가 드러나는 것입니다.

### M1 — Lean byte-level verifier spec 만들기

여기서부터 본체입니다.
Deneb는 public methods가 raw bytes를 받고 normalization을 수행해야 한다고 명시합니다. 또 spec은 readability 우선 reference spec입니다. 따라서 Lean spec도 **알gebra-only toy model**이 아니라 **raw bytes → deserialize/normalize → verify decision**의 흐름을 가져야 합니다. ([Ethereum GitHub][7])

v1의 mandatory core는 이 네 개입니다.

* `verify_kzg_proof`
* `verify_blob_kzg_proof`
* `verify_blob_kzg_proof_batch`
* `verify_cell_kzg_proof_batch`

`blob_to_kzg_commitment`는 강하게 권장하지만, verifier-core를 막는 이유가 되면 안 됩니다. `compute_*`와 `recover_cells_and_kzg_proofs`는 v2로 밀어도 됩니다. 다만 EIP-7594는 cell proofs가 `compute_cells(blob)`와 연결되는 semantics를 갖기 때문에, Fulu semantics는 처음부터 1급 시민이어야 합니다. ([GitHub][1])

여기서 증명할 첫 기본정리는 이 정도가 적절합니다.

* invalid/non-canonical input rejection determinism
* singleton/batch consistency
* batch verifier의 normal-form determinism
* challenge construction의 canonicality

특히 `c-kzg-4844`는 single blob에 대해 batch verifier가 single verifier를 호출한다고 README에 적고 있으니, singleton/batch 정리는 그냥 “예뻐 보이는 lemma”가 아니라 실제 public API contract에 해당합니다. ([GitHub][1])

### M2 — 공식 벡터 파이프라인, 단 Lean에서 YAML 파싱은 금지

이 단계의 핵심은 **Lean에서 YAML을 읽는 것**이 아닙니다.
핵심은 **official corpus를 신뢰 가능하게, reproducibly, 자동으로 따라가는 것**입니다.

현재 현실에 맞는 방식은 이겁니다.

* archived `consensus-spec-tests` release assets를 pin해서 재현성 확보
* current `consensus-specs` PySpec/test generator 경로를 추적
* 외부의 작은 adapter가 YAML/metadata를 normalized JSON/hex/bytes로 바꿔줌
* Lean은 그 normalized corpus만 읽음

이게 맞는 이유는 `consensus-spec-tests`가 archive 되었고, `consensus-specs`는 지금도 executable Python spec과 reference test generator 역할을 하기 때문입니다. 또한 spec 변경 없이 test-vector-only hotfix가 실제로 있었기 때문에, “spec diff”와 “vector diff”를 분리해서 추적해야 합니다. ([GitHub][5])

완료 기준:

* pinned Deneb/Fulu corpus 전부 통과
* vector-only hotfix도 감지
* spec release가 바뀌면 어떤 layer가 깨졌는지 보고

### M3 — 2025 bug classes를 “정리 + witness + failing mutant”로 고정

이게 핵심 hard mode입니다.

여기서 해야 할 일은 “옛날 버그를 감상”하는 게 아니라, **버그가 깨뜨린 규칙을 정리로 만들고, 그 정리를 깨는 concrete witness를 뽑고, buggy mutant가 그 witness에서 죽는 걸 보이는 것**입니다.

필수 regression pack은 두 축입니다.

1. **point-at-infinity / fast-path regression**
   2025 버그는 `verify_cell_kzg_proof_batch`에서 최소 8개 셀 이상이고 어떤 commitment가 point-at-infinity일 때 fast path에서 드러났고, 기존 reference tests는 `< 8`에서 naive path를 타서 못 잡았습니다. 따라서 theorem/test는 반드시 `7 / 8 / 9` 경계와 invalid-point family를 포함해야 합니다. ([GitHub][4])

2. **dedup / Weak Fiat–Shamir regression**
   2025 bug는 deduplicated commitment 수를 쓰면서도 실제 challenge 계산에는 원본 배열 prefix를 써서, 예를 들어 `[a, a, b]`가 `[a, a]`만 바인딩되는 식의 문제가 생겼습니다. 따라서 theorem은 “challenge must bind all unique commitments actually used by the statement in canonical order”류가 되어야 하고, concrete witness는 정확히 그런 duplicate pattern을 포함해야 합니다. ([GitHub][9])

완료 기준:

* 최소 3~5개의 machine-checked invariant theorem
* 각 theorem마다 concrete witness family
* buggy mutant들이 그 정리/테스트를 통과하지 못함

여기서의 mutant는 실제 C를 Lean으로 옮긴 게 아니라,

* challenge에서 unique commitments를 일부 누락하는 mutant
* batch fast path에서 invalid-point handling을 생략하는 mutant
* branch threshold에서만 semantics가 달라지는 mutant
  같은 **의미론적 가짜 구현**이면 충분합니다.

### M4 — Lean-generated adversarial corpus 만들기

이 단계가 리뷰의 “Lean을 test generator로 써라”를 살리는 부분입니다. 다만 그냥 fuzzing이 아니라 **theorem-guided adversarial generation**이어야 합니다.

반드시 포함할 case family:

* duplicate commitments
* permutation-equivalent batches
* threshold edge cases (`n = 7, 8, 9`)
* malformed / non-canonical bytes
* point-at-infinity 관련 정상화/거부 경계
* Fulu cell index ordering / grouping corner cases

공식 vectors는 기본선이고, **실제 기여는 그 위의 corpus**에서 나옵니다. point-at-infinity 버그가 기존 reference tests를 통과하고도 살아남았다는 사실이 바로 그 증거입니다. ([GitHub][4])

완료 기준:

* repo에 plain JSON/hex corpus로 산출
* Lean 밖의 구현도 그대로 먹을 수 있음
* historical bad tags를 실제로 깨뜨리는 최소 사례가 포함됨

### M5 — `c-kzg-4844` public API conformance harness

이게 “구현과 안 붙는 Lean 레포”를 피하는 단계입니다.
다만 이름은 refinement여도, 방법은 **증명**이 아니라 **public-boundary differential checking**입니다.

대상은 최소 이 네 개:

* `verify_kzg_proof`
* `verify_blob_kzg_proof`
* `verify_blob_kzg_proof_batch`
* `verify_cell_kzg_proof_batch`

가능하면 `blob_to_kzg_commitment`까지 넣습니다. `c-kzg-4844`는 Deneb/Fulu public functions를 spec에 최대한 가깝게 맞추려는 공식 구현이고, bindings는 클라이언트가 중요한 crypto를 재구현하지 않게 하려는 목적을 갖습니다. 그러니 이 layer는 절대 빼면 안 됩니다. ([GitHub][1])

여기서 내가 추가하는 진짜 hard criterion은 이겁니다.

**당신의 CI는 bad historical tags를 자동으로 죽여야 합니다.**

* point-at-infinity regression에서는 **v2.1.2** 같은 pre-fix tag가 실패해야 함
* dedup/Weak-FS regression에서는 **v2.1.4**가 실패해야 함
* fixed tag는 통과해야 함

릴리스 노트상 v2.1.3은 “previous release”의 point-at-infinity 결과 오류를 수정했고, v2.1.5는 deduplicated commitments challenge bug를 수정했습니다. 그러니 이건 그냥 말이 아니라 실제로 pin 가능한 역사입니다. ([GitHub][2])

이 단계의 완료 기준은 “최신 버전 통과”가 아니라,
**“과거의 잘못된 버전이 네 artifact에서 분명히 실패한다”**입니다.
이게 나오면 토이가 아닙니다.

### M6 — 업스트림 가능한 형태로 굳히기

마지막 단계는 논문 감성 정리가 아니라 **실제 외부 사용 가능 artifact**입니다.

최소 두 개는 나와야 합니다.

* `c-kzg-4844` 또는 `consensus-specs`에 issue/PR
* 외부 구현이 바로 먹을 수 있는 regression corpus
* 각 regression theorem이 어떤 실제 bug class를 막는지 적은 기술 노트

`c-kzg-4844`는 이미 audit history와 활발한 releases를 갖고 있고, point-at-infinity 이슈 때도 consensus-specs 쪽 regression test가 연결되었습니다. 즉 upstream으로 들어갈 수 있는 접점이 실제로 있습니다. ([GitHub][1])

---

## 내가 보기에 이 프로젝트가 “토이 아님”을 판정하는 기준

아래 셋 중 둘 이상을 만족해야 합니다.

1. **bad historical tags가 네 CI에서 재현 가능하게 실패한다.**
2. **Fulu/`verify_cell_kzg_proof_batch`가 본론이고, Deneb만으로 끝나지 않는다.**
3. **Lean 밖 구현이 그대로 가져다 쓸 수 있는 corpus/PR/issue가 나온다.**

반대로 아래로 가면 토이 냄새가 납니다.

* `c-kzg-4844`와 안 붙는다.
* Fulu 없이 Deneb만 한다.
* theorem은 예쁜데 concrete witness와 historical tag replay가 없다.
* full soundness/completeness 욕심으로 ArkLib 방향까지 먹다가 정작 regression artifact가 안 나온다.

## 최종 프로젝트 정의

내가 최종적으로 완결한 정의는 이겁니다.

**“Deneb/Fulu의 verifier-facing KZG boundary를 대상으로, Lean에서 raw-byte API semantics와 batch/challenge/dedup invariants를 formalize하고, archived/current official vectors와 Lean-generated adversarial corpus로 pinned `c-kzg-4844` tags를 differential-conformance 검증하며, 2025년 `verify_cell_kzg_proof_batch` bug classes를 machine-checked regression artifact로 고정하는 프로젝트.”**

이건 1인 개발자가 하기엔 빡셉니다.
하지만 **실제 기여**입니다. 이유는 두 가지뿐입니다.

* 붙는 대상이 메인넷 경계고, 실제 bug가 이미 났던 공식 구현이다. ([GitHub][1])
* 결과물이 “Lean에서 뭔가 formalize했다”가 아니라 **실제 bad tag를 죽이고, upstream이 먹을 수 있는 regression artifact를 남긴다**는 형태이기 때문입니다. ([GitHub][10])

다음으로 바로 이어서, 이 최종 마일스톤 기준으로 **README 초안 + 디렉터리 구조 + 첫 12개 이슈**까지 실전형으로 내려드릴 수 있습니다.

[1]: https://github.com/ethereum/c-kzg-4844 "https://github.com/ethereum/c-kzg-4844"
[2]: https://github.com/ethereum/c-kzg-4844/releases "https://github.com/ethereum/c-kzg-4844/releases"
[3]: https://github.com/GaloisInc/ckzg-eip-4844-verification "https://github.com/GaloisInc/ckzg-eip-4844-verification"
[4]: https://github.com/ethereum/c-kzg-4844/pull/600 "https://github.com/ethereum/c-kzg-4844/pull/600"
[5]: https://github.com/ethereum/consensus-spec-tests/releases "https://github.com/ethereum/consensus-spec-tests/releases"
[6]: https://github.com/Verified-zkEVM/ArkLib "https://github.com/Verified-zkEVM/ArkLib"
[7]: https://ethereum.github.io/consensus-specs/specs/deneb/polynomial-commitments/ "https://ethereum.github.io/consensus-specs/specs/deneb/polynomial-commitments/"
[8]: https://github.com/Verified-zkEVM/CompPoly "https://github.com/Verified-zkEVM/CompPoly"
[9]: https://github.com/ethereum/c-kzg-4844/pull/607 "https://github.com/ethereum/c-kzg-4844/pull/607"
[10]: https://github.com/ethereum/consensus-specs/blob/master/AGENTS.md "https://github.com/ethereum/consensus-specs/blob/master/AGENTS.md"
