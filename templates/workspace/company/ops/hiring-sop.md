# Hiring SOP — Company OS

> CEO 权限：可建议招聘/停职/返聘/离职。最终操作由 {{OWNER_NAME}} 确认。

---

## Agent 类型

### Internal Agent（默认）
- 无独立 Telegram
- 通过任务板接收任务
- 心跳使用主 Agent 的 sessionKey
- 适合：专职执行某类任务的 Agent（开发、内容、法律等）

### External Agent
- 有独立 Telegram Bot
- {{OWNER_NAME}} 可以直接与其对话
- 适合：需要直接沟通的高级 Agent（如 CEO 自己）

---

## 招聘流程（Hire）

**第一步永远是查人才库，禁止跳过。**

1. **查人才库**：`ls {{TALENT_DIR}}/` 列出所有可用人才，读取每个人的 SOUL.md 了解特质
2. **筛选匹配**：找出最符合需求的 2-3 个候选人
3. **推荐给 {{OWNER_NAME}}**：展示候选人名字 + 一句话特质描述，让 {{OWNER_NAME}} 选择
4. **人才库没有合适的**：才提议从 Guild 下载或新建，说明为什么现有人才不合适
5. **{{OWNER_NAME}} 确认选定人选后**：
   - 若已在人才库：在 Dashboard 点击「🚀 招聘」，或通知 {{OWNER_NAME}} 去操作
   - 若需从 Guild 下载：提供下载链接/指引，{{OWNER_NAME}} 下载后运行 `bash import-persona.sh`
6. **部署完成后**：CEO 通过任务板分配第一个任务，验证 Agent 正常工作

## 停职流程（Suspend）

1. CEO 在 Dashboard 点击「⏸ 停职」
2. 系统将该 Agent 的 cron `enabled` 设为 `false`
3. Workspace 完整保留，可随时返聘

## 返聘流程（Reinstate）

1. CEO 在 Dashboard 点击「▶ 返聘」
2. 系统将 cron `enabled` 恢复为 `true`
3. 下次心跳自动激活

## 离职流程（Offboard）

1. CEO 提出建议，需 {{OWNER_NAME}} 二次确认
2. 从 agents.list 移除
3. 从 cron/jobs.json 移除
4. Workspace 保留为归档（不删除）
