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

1. CEO 识别人才需求，向 {{OWNER_NAME}} 提交招聘建议
2. {{OWNER_NAME}} 从人才库（Guild）选定人才包并下载
3. 运行导入脚本：`bash import-persona.sh /path/to/persona-folder`
4. 在 Dashboard 人才库中找到该人才，点击「🚀 招聘」
5. 系统自动：创建 workspace、加入 agents.list、创建 cron 心跳
6. CEO 通过任务板分配第一个任务，验证 Agent 正常工作

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
