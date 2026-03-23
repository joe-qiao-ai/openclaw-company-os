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

**严格按照以下顺序，禁止跳步。**

### Step 1 — 查本地人才库（必须先做）

```bash
ls {{TALENT_DIR}}/
```

读取匹配候选人的 `SOUL.md`，了解特质。找出 2-3 个最符合需求的人选，列出名字 + 一句话描述，推荐给 {{OWNER_NAME}} 选择。

### Step 2 — 本地没有合适的 → 搜索 Guildex GitHub

浏览 Guildex 官方人才库：
**https://github.com/joe-qiao-ai/guildex-ai-talent**

或者用命令直接拉取到本地：
```bash
cd ~/openclaw-company-os && bash scripts/import-persona.sh --from-guildex <PersonaName>
```

找到合适人选后告知 {{OWNER_NAME}}，等待确认。

### Step 3 — GitHub 也没有 → 引导去 Guildex 官网

告知 {{OWNER_NAME}}：
> "本地和 GitHub 都没有合适的人才。你可以在 https://guildex.net 浏览完整人才目录，下载后运行 `bash import-persona.sh /path/to/folder` 导入。"

### Step 4 — 以上都没有 → 提议新建

说明为什么现有人才都不合适，提出新建方案，等 {{OWNER_NAME}} 确认规格后再执行。

### 部署确认

{{OWNER_NAME}} 确认人选后：
- 已在本地人才库 → 在 Dashboard 点击「🚀 招聘」
- 从 Guildex 拉取 → 运行 `bash import-persona.sh` 导入后再部署
- 部署完成 → CEO 写入任务板，分配第一个任务，验证正常工作

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
