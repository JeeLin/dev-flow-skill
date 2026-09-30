# 步骤6：测试验证

## GUARD

- 前置状态：审查轮内步骤5 已执行完毕，状态行中本步为 `—`
- 幂等：重入时报告同名覆盖（`step6-test.md`），测试从头执行

## ACT

1. **前置检查**：Rust 项目先运行 `cargo check --locked`，验证 `Cargo.lock` 与 `Cargo.toml` 一致，不一致则提示修复后再进入测试；通过后跳过质量门禁中的编译检查（已验证）
2. 按质量门禁依次执行（Rust 项目跳过编译检查），报告逐项记录结果和数值（如覆盖率百分比）写入 `{version}-reports/step6-test.md`
3. 判定本步结论并登记（**不在此处勾选、不在此处打回**）：
   - 全部通过 → 本步 ✓
   - 任一项失败（测试报错 / 编译 error / Lint error / 覆盖率未达标）→ 本步 ✗，先将问题登记入 Bugs 表（🔴=测试失败、🟡=测试警告，来源=步骤6测试，描述按契约「发现登记格式」）
4. 将状态行中本步由 `—` 更新为 `✓`/`✗`，**更新后立即继续步骤7**（审查轮无短路，步骤7 的验收能当轮暴露验收类问题）

## MARK

- 状态行本步写入 ✓/✗ 即完成，判定权在轮末

## 门禁

测试全部通过 + 编译无 error + Lint 无 error + 覆盖率达到阈值。

## 质量门禁（默认值，`AGENTS.md` 的 `## 质量门禁` 可覆盖）

| 检查项 | JS/TS 项目 | Python 项目 | Rust 项目 | Go 项目 | AGENTS.md 可覆盖字段 |
|--------|-----------|------------|----------|---------|----------------------|
| 编译检查 | `bunx tsc --noEmit` | `mypy .` | `cargo check` | `go build ./...` | `编译命令` |
| Lint 检查 | `npm run lint` 无 error（warning 可忽略） | `ruff check .` 无 error（warning 可忽略） | `cargo clippy -- -D warnings` | `golangci-lint run` | `Lint 命令`、`Lint 规则` |
| 测试覆盖率 | `npm test -- --coverage` 达到 90% | `pytest --cov=. --cov-report=term-missing` 达到 90% | `cargo llvm-cov` 达到 90% | `go test -coverprofile` 达到 90% | `覆盖率命令`、`最低覆盖率` |

- 测试命令取 `AGENTS.md` 定义；JS/TS 默认命令采用 `npx`/`npm`，项目使用 `bun`/`yarn`/`pnpm` 时在 `## 质量门禁` 覆盖即可
- 其他语言在 `AGENTS.md` 中自定义；不需要某项检查（如无类型系统）时将对应命令设为空即跳过
